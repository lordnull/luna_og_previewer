defmodule LunaOgPreviewerWeb.UrlJson do

	def show(url) do
			LunaOgPreviewer.Url.fetch_from_db(url)
			|> maybe_remote_fetch(url)
			|> finalize
	end

	defp maybe_remote_fetch(url, {:error, _} = input) do
		LunaOgPreviewer.Url.fetch_from_remote(url)
	end

	defp maybe_remote_fetch({:ok, _} = ok) do
		ok
	end




end
