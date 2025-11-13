defmodule LunaOgPreviewerWeb.Router do
  use LunaOgPreviewerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LunaOgPreviewerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LunaOgPreviewerWeb do
    pipe_through :browser

    live "/", PageController
  end

  # Other scopes may use custom stacks.
  # scope "/api", LunaOgPreviewerWeb do
  #   pipe_through :api
  # end
end
