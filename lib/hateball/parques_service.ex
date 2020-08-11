defmodule Hateball.ParquesService do
  alias Hateball.ParquesWorld

  def salida, do: 5

  defp bad_movement_error({a, b}), do: "solo puede mover #{a} o #{b} espacios"
  defp bad_movement_error(a), do: "solo puede mover #{a} espacios"

  def create_world(
        name: name,
        player_count: player_count,
        piece_count: piece_count
      ) do
    %ParquesWorld{
      name: name,
      pieces_left: (1..player_count)
                   |> Enum.zip(List.duplicate(4, player_count))
                   |> Map.new(),
      dices: {},
      positions: Map.new(create_positions(player_count, piece_count)),
      game_state: {1, :to_play},
    }
  end

  defp create_positions(player_count, piece_count) do
    cartesian = for a <- 1..player_count, b <- 1..piece_count, do: {a, b}

    cartesian
    |> Enum.map(fn elt -> {elt, :jail} end)
  end

  def out_of_jail(game, player_id) do
    new_pos = calculate_new_positions(
      game.positions,
      player_id,
      fn {key, _pos} -> {key, salida()} end
    )

    put_in game.positions,
           Map.merge(
             game.positions,
             new_pos,
             fn _k, _v1, v2 -> v2 end
           )
  end

  defp calculate_new_positions(old_positions, player_id, new_position_fun) do
    belongs_to_player? = fn {{p_id, _}, _} -> p_id == player_id end
    (for pos <- old_positions, belongs_to_player?, do: new_position_fun.(pos))
    |> Map.new()
  end

  def play_turn(world, {piece, amount_to_move}) do
    {current_player, _state} = world.game_state
    if not can_move(world.dices, amount_to_move) do
      {:error, bad_movement_error(world.dices)}
    else
      {_, new_positions} = Map.get_and_update(
        world.positions,
        {current_player, piece},
        fn curr_pos -> {curr_pos, curr_pos + amount_to_move} end
      )

      new_dices = use_dices(world.dices, amount_to_move)
      new_game_state = case new_dices do
        {_a} -> {current_player, :move_second}
        # TODO replace this hardcoded player amount
        {} -> {rem(current_player + 1, 4), :to_play}
      end

      {
        :ok,
        %{
          world |
          dices: new_dices,
          game_state: new_game_state,
          positions: new_positions
        }
      }
    end
  end

  def play_turn(world, roll_die) when is_function(roll_die) do
    {current_player, _state} = world.game_state
    {
      :ok,
      %{
        world |
        game_state: {current_player, :move_first},
        dices: {roll_die.(), roll_die.()}
      }
    }
  end

  defp use_dices({_a}, element), do: {}
  defp use_dices({a, b}, element) do
    cond  do
      a == element -> {b}
      b == element -> {a}
      a + b == element -> {}
    end
  end

  defp can_move({a}, to_move), do: to_move == a
  defp can_move({a, b}, to_move) do
    to_move == a or to_move == b or to_move == (a + b)
  end
end
