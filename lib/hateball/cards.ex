defmodule Hateball.Cards do
  use Agent

  def start_link(initial_data) do
    IO.puts "---------- ** ---------  initial data #{inspect initial_data}"
    Agent.start_link(fn -> initial_data end, name: __MODULE__)
  end

  def draw_question() do
    Agent.update(
      __MODULE__,
      fn data ->
        {top, rest} = draw_from_pile(data.question_pile)

        Map.put(data, :question_card, top)
        |> Map.put(:question_pile, rest)
      end
    )
  end

  def inspect_data() do
    Agent.get(
      __MODULE__,
      fn data ->
        IO.puts "-------*********--------- -> data: #{inspect data}"
      end
    )
  end

  def draw_answer(player_id) do
    Agent.update(
      __MODULE__,
      fn data ->
        {top, rest} = draw_from_pile(data.answer_pile)
        if rest == "" do
          data
        else
          cards_in_hand = if Map.has_key?(data.cards_in_hand, player_id) do
            data.cards_in_hand
          else
            Map.put(data.cards_in_hand, player_id, [])
          end

          player_cards = cards_in_hand[player_id]
          Map.put(
            data,
            :cards_in_hand,
            Map.put(cards_in_hand, player_id, [top | player_cards])
          )
          |> Map.put(:answer_pile, rest)
        end
      end
    )
  end

  def play_card(player_id, card_idx) do
    Agent.update(
    __MODULE__,
      fn data ->
        {card, player_cards} = data.cards_in_hand
      end
    )
  end

  def get_question() do
    Agent.get(__MODULE__, fn data -> data.question_card end)
  end

  def get_answers(player_id) do
    case Agent.get(__MODULE__, fn data -> data.cards_in_hand[player_id] end) do
      nil -> []
      x -> x
    end
  end

  defp draw_from_pile(pile) do
    case pile do
      [top | rest] -> {top, rest}
      _ -> {"", []}
    end
  end
end
