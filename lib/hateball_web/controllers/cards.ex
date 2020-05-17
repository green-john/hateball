defmodule HateballWeb.Controllers.Cards do
  use HateballWeb, :controller
  alias HateballWeb.BoardLive
  import Phoenix.LiveView.Controller

  def start_game(conn, params) do
    IO.puts "conn #{inspect conn}"
    IO.puts "params #{inspect params}"

    live_render(conn, BoardLive)
  end

end
