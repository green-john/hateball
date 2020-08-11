defmodule HateballWeb.ParquesLive do
  use HateballWeb, :live_view

  alias HateballWeb.Presence
  alias Hateball.Cards

  defp get_and_track_user(socket, game_id) do
    if not connected?(socket) do
      ""
    else
      subscribe(game_id)

      %{"username" => username} = get_connect_params(socket)

      Presence.track(
        self(),
        "parques:" <> game_id,
        username,
        %{}
      )

      username
    end
  end

  def mount(_params, %{"game_id" => game_id}, socket) do
    username = get_and_track_user(socket, game_id)
    {
      :ok,
      assign(
        socket,
        game_id: game_id,
        page_title: game_id,
        username: username
      )
    }
  end

  defp subscribe(game_id) do
    Phoenix.PubSub.subscribe(Hateball.PubSub, "parques:" <> game_id)
  end

  defp broadcast(game_id, event) do
    Phoenix.PubSub.broadcast(Hateball.PubSub, "parques:" <> game_id, event)
  end

end
