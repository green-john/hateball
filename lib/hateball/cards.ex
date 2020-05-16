defmodule Hateball.Cards do
  use Agent

  def start_link(initial_data) do
    IO.puts "STARTING HERERERER #{inspect __MODULE__}"
    Agent.start_link(fn -> initial_data end, name: __MODULE__)
  end

  def draw_question_card() do
    Agent.update(
      __MODULE__,
      fn data ->
        {top, rest} = draw_card_from_pile(data.question_pile)

        Map.put(data, :question_card, top)
        |> Map.put(data, :question_pile, rest)
      end
    )
  end

  def inspect() do
    Agent.get(__MODULE__, fn data ->
      IO.puts "-------*********--------- -> data: #{inspect data}"
    end)
  end

  def draw_answer_card(player_id) do
    Agent.update(
      __MODULE__,
      fn data ->
        {top, rest} = draw_card_from_pile(data.answer_card)

        if rest = "" do
          data
        else
          players = data.players
          if not Map.has_key?(players, player_id), do: players = Map.put(players, player_id, [])
          player_cards = players[player_id]

          Map.put(
            data,
            :players,
            Map.put(players, player_id, top | player_cards)
          )
        end
      end
    )
  end

  def get_question_card() do
    Agent.get(__MODULE__, fn data -> data.question_card end)
  end

  def get_answer_card(player_id) do
    Agent.get(__MODULE__, fn data -> List.first data.player[player_id] end)
  end

  defp draw_card_from_pile(pile) do
    case pile do
      [top | rest] -> {top, rest}
      _ -> {"", []}
    end
  end
end
