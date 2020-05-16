defmodule HateballWeb.BoardLive do
  use HateballWeb, :live_view

  alias HateballWeb.Presence

  def mount(_params, _session, socket) do
    if connected?(socket) do
      HateballWeb.Endpoint.subscribe("cards")

      Presence.track(
        self(),
        "cards",
        socket.id,
        %{}
      )
    end

    socket = assign(
      socket,
      top_question: "",
      question_pile: ["a", "b"],
      answer_pile: ["c", "d"],
      players: []
    )
    {:ok, socket}
  end

  def handle_event("drawQuestion", _, socket) do
    socket = case socket.assigns.question_pile do
      [top | rest] -> assign(socket, question_pile: rest, top_question: top)
      _ -> assign(socket, question_pile: [], top_question: "")
    end

    Hateball.Cards.sum(3, 4)

    {:noreply, socket}
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