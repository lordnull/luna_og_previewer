defmodule LunaOgPreviewerWeb.PageController do
  use LunaOgPreviewerWeb, :controller

  def home(conn, _params) do
    render(conn, :home, has_preview?: false)
  end
end
