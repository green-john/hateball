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
    {a, b} = world.dices
    if amount_to_move != a and amount_to_move != b do
      {:error, bad_movement_error(world.dices)}
    else
      {_, new_pos} = Map.get_and_update(
        world.positions,
        {current_player, piece},
        fn curr_pos -> {curr_pos, curr_pos + amount_to_move} end
      )
      {
        :ok,
        world
        |> Map.put(:dices, leave_other(world.dices, amount_to_move))
        |> Map.put(:game_state, {current_player, :move_second})
        |> Map.put(:positions, new_pos)
      }
    end
  end

  def play_turn(world, roll_die) when is_function(roll_die) do
    {current_player, _state} = world.game_state
    {
      :ok,
      world
      |> Map.put(:game_state, {current_player, :move_first})
      |> Map.put(:dices, {roll_die.(), roll_die.()})
    }
  end

  defp leave_other({a, b}, element) do
    if a == element, do: {b}, else: {a}
  end

end