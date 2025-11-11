defmodule LunaOgPreviewerWeb.PageController do
  use LunaOgPreviewerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
