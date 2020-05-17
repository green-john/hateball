defmodule HateballWeb.BoardLive do
  use HateballWeb, :live_view

  alias HateballWeb.Presence
  alias Hateball.Cards

  def mount(_params, _session, socket) do
    if connected?(socket) do
      subscribe()

      Presence.track(
        self(),
        "cards",
        socket.id,
        %{}
      )
    end

    socket = assign(
      socket,
      question: Cards.get_question(),
      answers: Cards.get_answers(socket.id),
      players: %{},
      played_cards: [],
    )
    {:ok, socket}
  end

  def handle_event("draw_question", _, socket) do
    Cards.draw_question()

    broadcast({:reload_question})
    {:noreply, socket}
  end

  def handle_event("draw_answer", _, socket) do
    Cards.draw_answer(socket.id)

    {:noreply, assign(socket, answers: Cards.get_answers(socket.id))}
  end

  def handle_event("play_answer", %{"idx" => idx}, socket) do
    {number, ""} = Integer.parse(idx)
    Cards.play_card(socket.id, number)
    broadcast({:reload_played_cards})
    {:noreply, assign(socket, answers: Cards.get_answers(socket.id))}
  end

  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    users = get_connected_users()
    {:noreply, assign(socket, players: users)}
  end

  def handle_info({:reload_question}, socket) do
    {:noreply, assign(socket, question: Cards.get_question())}
  end

  def handle_info({:reload_played_cards}, socket) do
    {:noreply, assign(socket, played_cards: Cards.get_played_cards(get_connected_users()))}
  end

  defp get_connected_users() do
    Presence.list("cards")
    |> Enum.map(fn ({user_id, _data}) -> user_id end)
  end

  defp subscribe() do
    Phoenix.PubSub.subscribe(Hateball.PubSub, "cards")
  end

  defp broadcast(event) do
    Phoenix.PubSub.broadcast(Hateball.PubSub, "cards", event)
  end

end
