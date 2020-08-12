defmodule Hateball.ParquesService do
  alias Hateball.ParquesWorld

  def salida, do: 4

  @doc """
  Last space in a color. That is
  every color has a this many spaces.
  """
  def last_space, do: 17
  def last_space_heaven, do: 17 + 8

  defp bad_movement_error(), do: "movimiento inválido"

  def create_world(
        name: name,
        player_count: player_count,
        piece_count: piece_count
      ) do
    all_positions = (for a <- 0..(player_count - 1), b <- 0..(piece_count - 1), do: {a, b})
    %ParquesWorld{
      name: name,
      dices: {},
      positions: all_positions
                 |> Enum.map(fn elt -> {elt, :jail} end)
                 |> Map.new(),
      game_state: {0, :to_play},
      second_lap: all_positions
                  |> Enum.map(fn key -> {key, false} end)
                  |> Map.new(),
      player_count: player_count
    }
  end

  def out_of_jail(game, player_id) do
    new_pos = calculate_new_positions(
      game.positions,
      player_id,
      fn {key, _} -> {key, {player_id, salida()}} end
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
    (for pos <- old_positions, belongs_to_player?.(pos), do: new_position_fun.(pos))
    |> Map.new()
  end

  @spec play_turn(ParquesWorld, tuple) :: ParquesWorld
  def play_turn(world, {piece, amount_to_move}) do
    {current_player, _state} = world.game_state
    if not is_movement_valid?(world, {piece, amount_to_move}) do
      {:error, bad_movement_error()}
    else
      world = calculate_new_position_second_lap(
        world,
        {piece, amount_to_move}
      )
      new_dices = use_dices(world.dices, amount_to_move)
      new_game_state = case new_dices do
        {_} -> {current_player, :move_second}
        {} -> {rem(current_player + 1, world.player_count), :to_play}
      end

      {
        :ok,
        %{
          world |
          dices: new_dices,
          game_state: new_game_state,
        }
      }
    end
  end

  @spec play_turn(ParquesWorld, function) :: ParquesWorld
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

  defp calculate_new_position_second_lap(world, {piece_id, amount}) do
    {player, _} = world.game_state
    piece = {player, piece_id}
    %{^piece => {color, curr_pos}} = world.positions

    new_pos = curr_pos + amount
    moved_to =
      if world.second_lap[piece] and new_pos >= salida()  do
        if new_pos == last_space_heaven() - 1 do
          :heaven
        else
          {color, new_pos}
        end
      else
        advance_colors = div(new_pos, last_space())
        new_pos = rem(new_pos, last_space())
        new_color = rem(color + advance_colors, world.player_count)
        {new_color, new_pos}
      end

    positions = Map.put(world.positions, piece, moved_to)
    made_a_lap = new_pos < curr_pos
    second_lap = Map.put(world.second_lap, piece, made_a_lap)

    %{world | :positions => positions, :second_lap => second_lap}
  end


  defp use_dices({_}, _), do: {}
  defp use_dices({a, b}, element) do
    cond  do
      a == element -> {b}
      b == element -> {a}
      a + b == element -> {}
    end
  end

  defp is_movement_valid?(world, {piece, amount}) do
    if not uses_dice_values?(world.dices, amount) do
      false
    else
      {player, _} = world.game_state
      piece_key = {player, piece}
      {_, pos} = world.positions[piece_key]
      if not world.second_lap[piece_key] do
        true
      else
        (pos + amount) <= last_space_heaven()
      end
    end
  end

  defp uses_dice_values?({a}, to_move), do: to_move == a
  defp uses_dice_values?({a, b}, to_move) do
    to_move == a or to_move == b or to_move == (a + b)
  end

end
