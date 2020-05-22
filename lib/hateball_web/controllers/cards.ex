defmodule HateballWeb.CardsController do
  use HateballWeb, :controller
  alias Hateball.GameCatalog
  alias HateballWeb.BoardLive
  alias HateballWeb.Router.Helpers, as: Routes

  import Phoenix.LiveView.Controller

  def start_game(conn, params) do
    game_id = gen_random_url()
    GameCatalog.add_game(game_id)

    redirect(conn, to: Routes.cards_path(conn, :resume_game, game_id))
  end

  def resume_game(conn, %{"game_id" => game_id}) do
    if GameCatalog.game_exists?(game_id) do
      live_render(
        conn,
        BoardLive,
        session: %{
          "game_id" => game_id
        }
      )

    else
      redirect(conn, to: Routes.cards_path(conn, :start_game))
    end
  end

  defp get_range(length) when length > 1, do: (1..length)
  defp get_range(length), do: [1]

  defp gen_random_url() do
    length = 10
    alphabets = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    lists = alphabets <> String.downcase(alphabets)
            |> String.split("", trim: true)

    get_range(length)
    |> Enum.reduce([], fn (_, acc) -> [Enum.random(lists) | acc] end)
    |> Enum.join("")
  end
end
