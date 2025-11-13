defmodule LunaOgPreviewerWeb.PageController do
  use LunaOgPreviewerWeb, :live_view
  import LunaOgPreviewer.UrlFetch

  def render(assigns) do
    ~H"""
    <Layouts.flash_group flash={@flash} />
    <div>
    <.form
      for={@url_fetch_form}
      id="url-fetch-form"
      phx-submit="fetch_url"
    >

      <.input
        field={@url_fetch_form[:url]}
        name="url"
        value={@url_fetch_form[:url]}
        label="URL to scan"
      />

      <.button type="submit" >Fetch</.button>

    </.form>

    </div>
    <div :for={{request_url, status} <- @requests} id={request_url} >
      <div>{request_url}</div>
      <div>
        <.fetch_display status={status} />
      </div>
    </div>
    """
  end

  defp fetch_display(assigns) do
    case assigns[:status] do
      {:error, {:no_scheme}} ->
        ~H"""
        Failed: The url should start with http or https.
        """
      {:error, wut} ->
        ~H"""
        failed: {wut}
        """
      {:ok, img_url} when is_binary(img_url) ->
        ~H"""
        <img src={img_url} />
        """
      {pid, _monref} when is_pid(pid) ->
        ~H"""
        Fetching...
        """
      end
  end

  def mount(params, _session, socket) do
    {:ok, assign(socket, %{url_fetch_form: params, requests: []})}
  end

  def handle_info({:DOWN, monref, :process, pid, :normal}, socket) do
    # we should already have gotten a success message from this, so we'll
    # ignore it.
    {:noreply, socket}
  end

  def handle_info({:DOWN, monref, :process, _pid, why}, socket) do
    {:noreply, update(socket, :requests, &handle_fetch_failure(&1, monref, why))}
  end

  def handle_info({:fetched, url, fetch_result}, socket) do
    {:noreply, update(socket, :requests, &handle_fetch_complete(&1, url, fetch_result))}
  end

  def handle_event("fetch_url", %{"url" => url_to_fetch}, socket) do
    {:noreply, update(socket, :requests, &handle_fetch_request(&1, url_to_fetch))}
  end

  defp handle_fetch_request(old_fetches, new_fetch) do
    remove_in_progress(old_fetches, new_fetch)
    |> spawn_new_fetch(new_fetch)
  end

  defp remove_in_progress(fetches, key) do
    case List.keytake(fetches, key, 0) do
      nil ->
        fetches
      {{^key, {in_progress, monref}}, clean} when is_pid(in_progress) ->
        Process.demonitor(monref, [:flush])
        Process.exit(in_progress, :canceled)
        # I'm not bothering to clean up old messages if the fetcher process already
        # succeeded. Worst case scenario, the user sees a brief flash of the
        # preview before it gets overwritten with an in-progess indicator.
        clean
      {{^key, _done}, clean} ->
        clean
    end
  end

  defp spawn_new_fetch(fetches, new_fetch) do
    self = self()
    pidmon = spawn_monitor(fn ->
      fetched = fetch_from_remote(new_fetch)
        send(self, {:fetched, new_fetch, fetched})
    end)
    [{new_fetch, pidmon} | fetches ]
  end

  defp handle_fetch_failure(requests, monref, why) do
    maybe_entry = Enum.find(requests, fn element ->
      match?({_url, {_pid, ^monref}}, element)
    end)
    case maybe_entry do
      {url, _old_status} ->
        [{url, normalize_complete({:error, why})} | List.delete(requests, maybe_entry)]
      nil ->
        # we have no idea what happened, and we can't even associate it with a
        # process. Throw up our hands and shrug.
        requests
    end
  end

  defp handle_fetch_complete(requests, url, fetch_result) do
    cleaned = remove_in_progress(requests, url)
    [{url, normalize_complete(fetch_result)} | cleaned]
  end

  defp normalize_complete({:error, {:no_scheme}}) do
    {:error, "Your url should start with http:// or https://."}
  end

  defp normalize_complete({:error, {:failed_connect, details}}) do
    case details do
      [_to_info, {:inet, _, :nxdomain}] ->
        {:error, "Domain name could not be resolved."}
      [_to_info, {:inet, _, wut}] ->
        :io_lib.format("~p", [wut])
      end
  end

  defp normalize_complete({:error, :no_preview}) do
    {:error, "Returned page did not contain an OpenGraph preview meta data element."}
  end

  defp normalize_complete({:ok, _url} = ok) do
    ok
  end
end
