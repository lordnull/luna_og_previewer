defmodule LunaOgPreviewerWeb.UrlController do
	use LunaOgPreviewerWeb, :controller

	def show(conn, %{"id" => id}) do
		text(conn, id);
	end

end
