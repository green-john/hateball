defmodule Hateball.ParquesServiceTest do
  use ExUnit.Case

  alias Hateball.ParquesService

  @moduletag :capture_log

  test "module exists" do
    assert is_list(ParquesService.module_info())
  end

  test "create initial parques world" do
    world = create_initial_world()

    assert world.name == "one"
    assert world.dices == {}
    assert Kernel.map_size(world.positions) == 16
    assert Enum.all?(world.positions, fn {_key, pos} -> pos == :jail end)
    assert world.game_state == {1, :to_play}

    assert Enum.all?(world.pieces_left, &(Kernel.elem(&1, 1) == 4))
  end

  test "only one player comes out of jail" do
    world = create_initial_world()
            |> ParquesService.out_of_jail(1)

    ones_pieces = Enum.filter(
      world.positions,
      fn {{player, _}, _} ->
        player == 1
      end
    )

    assert Enum.all?(
             ones_pieces,
             fn {_, pos} ->
               pos == {1, ParquesService.salida()}
             end
           )

    rest = Enum.filter(
      world.positions,
      fn {{player, _}, _} ->
        player != 1
      end
    )

    assert Enum.all?(rest, fn {_key, pos} -> pos == :jail end)
  end

  test "first player can roll" do
    {:ok, world} = create_initial_world(true)

    assert world.game_state == {1, :move_first}

    {a, b} = world.dices
    assert a != -1
    assert b != -1
  end

  test "error when first player moves wrong" do
    {:ok, world} = create_initial_world(true)

    {:error, reason} = ParquesService.play_turn(world, {1, 1})
    assert reason == "solo puede mover 3 o 3 espacios"

    {:error, reason} = ParquesService.play_turn(world, {1, 4})
    assert reason == "solo puede mover 3 o 3 espacios"
  end

  test "player plays once move a piece" do
    {:ok, world} = create_initial_world(true)

    {:ok, world} = ParquesService.play_turn(world, {1, 3})

    assert world.dices == {3}
    assert world.game_state == {1, :move_second}
    assert world.positions[{1, 1}] == {1, 8}
  end

  test "player plays twice move two pieces" do
    {:ok, world} = create_initial_world(true)

    {:ok, world} = ParquesService.play_turn(world, {1, 3})
    {:ok, world} = ParquesService.play_turn(world, {1, 3})

    assert world.dices == {}
    assert world.game_state == {2, :to_play}
    assert world.positions[{1, 1}] == {1, 11}
  end

  test "first player play all dices at once" do
    {:ok, world} = create_initial_world(true)
    {:ok, world} = ParquesService.play_turn(world, {1, 6})

    assert world.dices == {}
    assert world.positions[{1, 1}] == {1, 11}
    assert world.game_state == {2, :to_play}
  end

  test "second player rolls the dice" do
    {:ok, world} = create_initial_world(true)
    {:ok, world} = ParquesService.play_turn(world, {1, 6})
    world = ParquesService.out_of_jail(world, 2)
    {:ok, world} = ParquesService.play_turn(world, fn -> 4 end)
    {:ok, world} = ParquesService.play_turn(world, {1, 8})

    assert world.dices == {}
    assert world.positions[{2, 1}] == {2, 13}
    assert world.game_state == {3, :to_play}
  end

  test "player can move out of quadrant" do
    {:ok, world} = create_initial_world()
                   |> ParquesService.out_of_jail(1)
                   |> ParquesService.play_turn(fn -> 7 end)

    {:ok, world} = ParquesService.play_turn(game, {1, 14})

    assert world.dices = {}
    assert positions[{1, 1}] = {2, 2}
  end

  # Move out of own quadrant
  # Move from last to first quadrant
  # Jail dynamics
  # Eating other pieces
  # Going into heaven
  # Winning

  defp create_initial_world(initialize \\ false) do
    world =
      ParquesService.create_world(
        name: "one",
        player_count: 4,
        piece_count: 4
      )

    if not initialize do
      world
    else
      world
      |> ParquesService.out_of_jail(1)
      |> ParquesService.play_turn(fn -> 3 end)
    end
  end
end
