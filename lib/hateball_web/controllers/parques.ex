defmodule HateballWeb.ParquesController do
  use HateballWeb, :controller
  alias HateballWeb.ParquesLive

  import Phoenix.LiveView.Controller

  def start_game(conn, params) do
    game_id = gen_random_url()
    #    ParquesCatalog.add_game(game_id)

    live_render(
      conn,
      ParquesLive,
      session: %{
        "game_id" => game_id
      }
    )
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
