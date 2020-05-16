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
      players: %{}
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

  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    users = get_connected_users()
    #    IO.puts "in: #{inspect socket.id} msg: #{inspect socket}"

    {:noreply, assign(socket, players: users)}
  end

  def handle_info({:reload_question}, socket) do
    {:noreply, assign(socket, question: Cards.get_question())}
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
