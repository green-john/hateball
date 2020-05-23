defmodule Hateball.GameSupervisor do
  alias Hateball.Cards.Constants

  def create_game(game_id) do
    # This is the main data structure
    initial_data = %{

      # ID of the game auto generated
      game_id: game_id,

      # Person who's turn it currently is
      game_master: "",

      # Current question
      question_card: "",

      # Pile of question cards
      question_pile: Constants.get_questions,

      # Pile of answer cards
      answer_pile: Constants.get_answers,

      # Cards each player has in hand
      cards_in_hand: %{},

      # Cards that are currently being played
      played_cards: %{},

      # Score of each player
      player_scores: %{}
    }

    DynamicSupervisor.start_child(
      Hateball.DynamicSupervisor,
      {Hateball.Cards, fn -> initial_data end}
    )
  end
end
