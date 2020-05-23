defmodule HateballWeb.BoardLive do
  use HateballWeb, :live_view

  alias HateballWeb.Presence
  alias Hateball.Cards

  def mount(_params, %{"game_id" => game_id}, socket) do
    username =
      if connected?(socket) do
        subscribe(game_id)

        connect_params = get_connect_params(socket)
        %{"username" => username} = connect_params

        Presence.track(
          self(),
          "cards:" <> game_id,
          username,
          %{}
        )

        username
      else
        ""
      end
    {
      :ok,
      assign(
        socket,
        game_id: game_id,
        page_title: game_id,
        username: username,
        is_game_master: Cards.is_game_master(game_id, username),
        question: Cards.get_question(game_id),
        answers: Cards.get_answers(game_id, username),
        player_scores: Cards.get_player_scores(
          game_id,
          get_connected_users(game_id)
        ),
        played_cards: Cards.get_played_cards(game_id, username, get_connected_users(game_id))
      )
    }
  end

  def handle_event("draw_question", _, socket) do
    Cards.draw_question(socket.assigns.game_id)

    broadcast(socket.assigns.game_id, {:reload_question})
    broadcast(socket.assigns.game_id, {:reload_played_cards})
    {:noreply, socket}
  end

  def handle_event("draw_answer", _, socket) do
    username = socket.assigns.username
    Cards.draw_answer(socket.assigns.game_id, username)

    {
      :noreply,
      assign(
        socket,
        answers: Cards.get_answers(socket.assigns.game_id, username)
      )
    }
  end

  def handle_event("play_answer", %{"idx" => idx}, socket) do
    username = socket.assigns.username
    {number, ""} = Integer.parse(idx)
    Cards.play_card(socket.assigns.game_id, username, number)
    broadcast(socket.assigns.game_id, {:reload_played_cards})
    {
      :noreply,
      assign(
        socket,
        answers: Cards.get_answers(socket.assigns.game_id, username)
      )
    }
  end

  def handle_event("turn_card", %{"player_id" => player_id}, socket) do
    Cards.turn_card(socket.assigns.game_id, socket.assigns.username, player_id)
    broadcast(socket.assigns.game_id, {:reload_played_cards})
    {:noreply, socket}
  end

  def handle_event("request_game_master", _params, socket) do
    Cards.make_game_master(socket.assigns.game_id, socket.assigns.username)
    broadcast(socket.assigns.game_id, {:reload_is_game_master})
    {:noreply, socket}
  end

  def handle_event("add_point", %{"player_id" => player_id}, socket) do
    %{:game_id => game_id, :username => username} = socket.assigns
    IO.puts "game #{inspect game_id} username #{inspect username}"
    Cards.score_one(game_id, username, player_id)
    broadcast(game_id, {:reload_player_scores})
    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    broadcast(socket.assigns.game_id, {:reload_player_scores})
    {:noreply, socket}
  end

  def handle_info({:reload_question}, socket) do
    {
      :noreply,
      assign(
        socket,
        question: Cards.get_question(socket.assigns.game_id)
      )
    }
  end

  def handle_info({:reload_played_cards}, socket) do
    %{:game_id => game_id, :username => username} = socket.assigns

    {
      :noreply,
      assign(
        socket,
        played_cards: Cards.get_played_cards(
          game_id,
          username,
          get_connected_users(game_id)
        )
      )
    }
  end

  def handle_info({:reload_player_scores}, socket) do
    %{:game_id => game_id, :username => username} = socket.assigns
    {
      :noreply,
      assign(
        socket,
        player_scores: Cards.get_player_scores(
          socket.assigns.game_id,
          get_connected_users(socket.assigns.game_id)
        ),
        played_cards: Cards.get_played_cards(
          game_id,
          username,
          get_connected_users(game_id)
        ),
        question: Cards.get_question(socket.assigns.game_id)
      )
    }
  end

  def handle_info({:reload_is_game_master}, socket) do
    %{:game_id => game_id, :username => username} = socket.assigns
    {
      :noreply,
      assign(
        socket,
        is_game_master: Cards.is_game_master(game_id, username),
      )
    }
  end

  defp get_connected_users(game_id) do
    Presence.list("cards:" <> game_id)
    |> Enum.map(fn ({user_id, _data}) -> user_id end)
  end

  defp subscribe(game_id) do
    Phoenix.PubSub.subscribe(Hateball.PubSub, "cards:" <> game_id)
  end

  defp broadcast(game_id, event) do
    Phoenix.PubSub.broadcast(Hateball.PubSub, "cards:" <> game_id, event)
  end

end
