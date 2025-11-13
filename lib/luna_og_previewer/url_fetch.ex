defmodule LunaOgPreviewer.UrlFetch do


	def fetch_from_remote(url) do
		# Using httpc because:
		# * I don't need all the bells and whistles other libraries have
		# * Therefore I don't want to add any extra dependencies
		# * The api is straight forward
		:httpc.request(:get, {url, []}, [], [{:body_format, :binary}])
		|> extract_preview
	end

	defp extract_preview({:error, _} = input) do
		input
	end

	defp extract_preview({:ok, {{_http_version, 200, ~c"OK"}, _headers, body}}) do
		queried = LazyHTML.from_fragment(body)
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


end
