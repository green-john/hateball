defmodule Hateball.GameSupervisor do
  alias Hateball.Cards.Constants

  def create_game(game_id) do
    initial_data = %{
      game_id: game_id,
      question_card: "",
      question_pile: Constants.get_questions,
      answer_pile: Constants.get_answers,
      cards_in_hand: %{},
      played_cards: %{},
      player_scores: %{}
    }

    DynamicSupervisor.start_child(
      Hateball.DynamicSupervisor,
      {Hateball.Cards, fn -> initial_data end}
    )
  end
end
