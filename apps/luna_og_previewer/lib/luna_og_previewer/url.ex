defmodule LunaOgPreviewer.Url do
	use Ecto.Schema

	schema "urls" do
		field :normalized_url, :string, primary_key: true
      	field :use_https, :boolean
      	field :preview_url, :string
      	field :in_progress, :boolean
      	field :last_update, :utc_datetime
	end

	def fetch_from_db(url) do
			LunaOgPreviewer.Url
			|> LunaOgPreviewer.Repo.get(URI.to_string(normalize_url(url)))
			|> Kernel.then(fn
				{:ok, row} ->
					row.preview_url
				error ->
					error

			end)
	end

	def fetch_from_remote(url) do
		Req.get(url)
		|> extract_preview
		|> maybe_stash(url)
	end

	defp maybe_stash(_, {:error, _} = input) do
		input
	end

	defp maybe_stash(url, {:ok, preview_url}) do
		parsed = URI.parse(url)
		normalized = normalize_url(parsed)
		row = %LunaOgPreviewer.Url{
			normalized_url: URI.to_string(normalized),
			use_https: parsed.scheme == "https",
			preview_url: preview_url,
			in_progress: false,
			last_update: DateTime.utc_now(:seconds)
		}
		LunaOgPreviewer.Repo.insert(row, on_conflict: :replace_all)
	end

	defp extract_preview({:error, _} = input) do
		input
	end

	defp extract_preview({:ok, response}) do
		queried = LazyHTML.from_fragment(response.body)
			|> LazyHTML.query("meta[property=\"og:image\"]")
			|> LazyHTML.attribute("content")
			|> Enum.to_list
		case queried do
			[] ->
				{:error, :no_preview}
			[ url | _] ->
				{:ok, url}
		end
	end

	@doc """
		To ensure we don't poplate the database with meaningless duplicates,
		this normalizes a url to the most basic representation.

		The following is ignored:
		* http vs https
		* anchor/fragment

		The following is compared exactly:
		* fully qualified domain.
			eg www.example.com, example.com, and sub.example.com are all different
		* port, eg exmaple.com:443 and example.com:80 are different
		* userinfo
			user1@example.com and user2@exmple.com are different

		Paths are simplified:
		* "/" and "" are the same.
		* /a/deep/path and /a/deep/path/deeper/.. are the same
		* /a/path and /a/path/ are _not_ the same.
			We have no way to now if /path is routed different from /path/ on the remote side.
		* query parameter keys value pairs are sorted and compared
			eg ?from=0&to=100 is the same as ?to=100&from=0
			eg ?from=0&to=100 is _not_ the same as ?from=00&to=100

		Returns the structure rather than a string, thus allowing it to be
		better inspected by whatever calls this.
	"""
	def normalize_url(url) when is_binary(url) do
		normalize_url(URI.parse(url))
	end

	def normalize_url(parsed) do
		path = case parsed.path do
			nil ->
				nil
			"/" ->
				nil
			_not_nil ->
				# when URI.parse finds a path, it always puts a / in front,
				# thus negating Path.expand's attempt to resolve '~'
				case Path.expand(parsed.path) do
					"/" -> nil
					not_nil -> not_nil
				end
		end
		parsed_query = case parsed.query do
			nil ->
				nil
			_a_string ->
				URI.query_decoder(parsed.query)
				|> Enum.to_list
				|> Enum.sort
				|> URI.encode_query
		end
		port = case parsed.port do
			nil ->
				nil
			_not_nil ->
				cond do
					URI.default_port(parsed.scheme) == parsed.port ->
						nil
					true ->
						parsed.port

				end
		end
		%{parsed |
			scheme: nil,
			port: port,
			path: path,
			query: parsed_query,
			fragment: nil
		}
	end

end
