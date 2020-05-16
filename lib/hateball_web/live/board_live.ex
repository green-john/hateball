defmodule HateballWeb.BoardLive do
  use HateballWeb, :live_view

  alias HateballWeb.Presence
  alias Hateball.Cards

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Hateball.PubSub, "cards")

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

    {:noreply, assign(socket, question: Cards.get_question())}
  end

  def handle_event("draw_answer", _, socket) do
    Cards.draw_answer(socket.id)

    Cards.inspect_data()

    {:noreply, assign(socket, answers: Cards.get_answers(socket.id))}
  end

  def handle_info(%{event: "presence_diff", payload: payload}, socket) do
    users = get_connected_users()
    #    IO.puts "in: #{inspect socket.id} msg: #{inspect socket}"

    {:noreply, assign(socket, players: users)}
  end

  defp get_connected_users() do
    Presence.list("cards")
    |> Enum.map(fn ({user_id, _data}) -> user_id end)
  end

end
