defmodule Hateball.Cards do
  use Agent
  alias Hateball.GameCatalog

  def start_link(initial_data) do
    Agent.start_link(initial_data)
  end

  def get_question(game_id) do
    agent_pid = GameCatalog.get_game_agent_pid(game_id)
    case agent_pid do
      nil -> ""
      _ -> Agent.get(agent_pid, fn data -> data.question_card end)
    end
  end

  def get_answers(game_id, player_id) do
    agent_pid = GameCatalog.get_game_agent_pid(game_id)
    case Agent.get(agent_pid, fn data -> data.cards_in_hand[player_id] end) do
      nil -> []
      x -> x
    end
  end

  def draw_question(game_id) do
    agent_pid = GameCatalog.get_game_agent_pid(game_id)
    Agent.update(
      agent_pid,
      fn data ->
        {top, rest} = draw_from_pile(data.question_pile)

        Map.put(data, :question_card, top)
        |> Map.put(:question_pile, rest)
        |> Map.put(:played_cards, %{})
      end
    )
  end

  defp draw_from_pile(pile) do
    case pile do
      [top | rest] -> {top, rest}
      _ -> {"", []}
    end
  end

  def draw_answer(game_id, player_id) do
    agent_pid = GameCatalog.get_game_agent_pid(game_id)
    Agent.update(
      agent_pid,
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
          if length(player_cards) >= 10 do
            data
          else
            Map.put(
              data,
              :cards_in_hand,
              Map.put(cards_in_hand, player_id, [top | player_cards])
            )
            |> Map.put(:answer_pile, rest)
          end
        end
      end
    )
  end

  def score_one(game_id, player_id) do
    agent_pid = GameCatalog.get_game_agent_pid(game_id)
    Agent.update(
      agent_pid,
      fn data ->
        players = if Map.has_key?(data.player_scores, player_id) do
          data.player_scores
        else
          Map.put(data.player_scores, player_id, 0)
        end

        IO.puts "players #{inspect players}"

        Map.put(
          data,
          :player_scores,
          Map.put(players, player_id, players[player_id] + 1)
        )
      end
    )
  end

  def play_card(game_id, player_id, card_idx) do
    agent_pid = GameCatalog.get_game_agent_pid(game_id)
    Agent.update(
      agent_pid,
      fn data ->
        {card, remaining_cards_in_hand} = List.pop_at(
          data.cards_in_hand[player_id],
          card_idx
        )

        remaining_cards_in_hand = return_currently_played_card_to_hand(
          player_id,
          remaining_cards_in_hand,
          data.played_cards
        )

        data
        |> Map.put(
             :cards_in_hand,
             Map.put(data.cards_in_hand, player_id, remaining_cards_in_hand)
           )
        |> Map.put(
             :played_cards,
             Map.put(data.played_cards, player_id, {card, false})
           )
      end
    )
  end

  defp return_currently_played_card_to_hand(player_id, cards_in_hand, played_cards) do
    if Map.has_key?(played_cards, player_id) do
      {card, _turned} = played_cards[player_id]
      [card | cards_in_hand]
    else
      cards_in_hand
    end
  end

  def get_player_scores(game_id, player_ids) do
    IO.puts "inputs #{inspect player_ids}"

    agent_pid = GameCatalog.get_game_agent_pid(game_id)
    player_scores = Agent.get(agent_pid, fn data -> data.player_scores end)

    IO.puts "player scores #{inspect player_scores}"

    res = player_ids
          |> Enum.map(fn id -> {id, 0} end)
          |> Enum.map(
               fn {k, v} -> {k, Map.get(player_scores, k, 0)}
               end
             )

    IO.puts "results #{inspect res}"
    res
  end

  def get_played_cards(game_id, player_id, player_ids) do
    agent_pid = GameCatalog.get_game_agent_pid(game_id)
    Agent.get(agent_pid, fn data -> data.played_cards end)
    |> Enum.filter(fn {k, _} -> Enum.member?(player_ids, k) end)
  end

  defp display_answer(my_player_id, player_id, shown, text) do
    if shown do
      text
    else
      "??" <>
      if my_player_id == player_id do
        " (#{text})."
      else
        "."
      end
    end
  end

  def turn_card(game_id, player_id) do
    agent_pid = GameCatalog.get_game_agent_pid(game_id)
    Agent.update(
      agent_pid,
      fn data ->
        {card, turned} = Map.get(data.played_cards, player_id)

        Map.put(
          data,
          :played_cards,
          Map.put(data.played_cards, player_id, {card, not turned})
        )
      end
    )
  end
end
