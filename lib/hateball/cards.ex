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
        IO.puts "top: #{inspect top} rest: #{inspect rest}"

        if rest == "" do
          data
        else
          players = if Map.has_key?(data.players, player_id) do
            data.players
          else
            Map.put(data.players, player_id, [])
          end

          IO.puts "players #{inspect players}"

          player_cards = players[player_id]
          IO.puts "player cards #{inspect player_cards}"

          Map.put(
            data,
            :players,
            Map.put(players, player_id, [top | player_cards])
          )
        end
      end
    )
  end

  def get_question() do
    Agent.get(__MODULE__, fn data -> data.question_card end)
  end

  def get_answers(player_id) do
    case Agent.get(__MODULE__, fn data -> data.players[player_id] end) do
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
