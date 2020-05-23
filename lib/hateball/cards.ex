defmodule Hateball.Cards do
  use Agent
  alias Hateball.GameCatalog

  def start_link(initial_data) do
    Agent.start_link(initial_data)
  end

  def get_question(game_id) do
    game_id
    |> get_from_data(fn data -> data.question_card end, "")
  end

  def get_answers(game_id, player_id) do
    cards_in_hand = fn data ->
      case data.cards_in_hand[player_id] do
        nil -> []
        x -> x
      end
    end

    game_id
    |> get_from_data(cards_in_hand, [])
  end

  def draw_question(game_id) do
    game_id
    |> update_data(&pick_question_card/1)
  end

  defp pick_question_card(data) do
    {top, rest} = draw_from_pile(data.question_pile)

    Map.put(data, :question_card, top)
    |> Map.put(:question_pile, rest)
    |> Map.put(:played_cards, %{})
  end

  def draw_answer(game_id, player_id) do
    game_id
    |> update_data(
         fn data ->
           cards_in_hand = if Map.has_key?(data.cards_in_hand, player_id) do
             data.cards_in_hand
           else
             Map.put(data.cards_in_hand, player_id, [])
           end

           player_cards = cards_in_hand[player_id]
           {picked_cards, rest} = draw_from_pile(data.answer_pile, 10 - length(player_cards))

           if rest == [] do
             data
           else
             Map.put(
               data,
               :cards_in_hand,
               Map.put(cards_in_hand, player_id, player_cards ++ picked_cards)
             )
             |> Map.put(:answer_pile, rest)
           end
         end
       )
  end

  defp draw_from_pile(pile, n \\ 1) do
    case {pile, n} do
      {p, 0} -> {[], p}
      {[top | rest], r} ->
        {picked, remaining} = draw_from_pile(rest, r - 1)
        {[top | picked], remaining}

      {[], r} -> {[], []}
    end
  end

  def score_one(game_id, giving_player_id, receiver_player_id) do
    update_data(
      game_id,
      fn data ->
        if data.game_master != giving_player_id do
          data
        else
          player_scores = if Map.has_key?(data.player_scores, receiver_player_id) do
            data.player_scores
          else
            Map.put(data.player_scores, receiver_player_id, 0)
          end

          Map.put(
            data,
            :player_scores,
            Map.put(player_scores, receiver_player_id, player_scores[receiver_player_id] + 1)
          )
          |> pick_question_card
        end
      end
    )
  end

  def play_card(game_id, player_id, card_idx) do
    game_id
    |> update_data(
         fn data ->
           if data.game_master == player_id do
             data
           else
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

  def turn_card(game_id, user_playing, turned_card_player) do
    game_id
    |> update_data(
         fn data ->
           if data.game_master == user_playing do
             {card, turned} = Map.get(data.played_cards, turned_card_player)

             Map.put(
               data,
               :played_cards,
               Map.put(data.played_cards, turned_card_player, {card, not turned})
             )
           else
             data
           end
         end
       )
  end

  def is_game_master(game_id, player_id) do
    game_id
    |> get_from_data(
         fn data ->
           data.game_master == player_id
         end,
         false
       )
  end

  def make_game_master(game_id, player_id) do
    game_id
    |> update_data(
         fn data ->
           Map.put(data, :game_master, player_id)
         end
       )
  end

  defp update_data(game_id, func) do
    agent_pid = GameCatalog.get_game_agent_pid(game_id)
    Agent.update(
      agent_pid,
      func
    )
  end

  defp get_from_data(game_id, func, empty_return) do
    case GameCatalog.get_game_agent_pid(game_id) do
      nil -> empty_return
      agent_pid -> Agent.get(agent_pid, func)
    end
  end
end
