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
    assert world.game_state == {0, :to_play}
    assert Enum.all?(world.pieces_left, &(Kernel.elem(&1, 1) == 4))
    assert Enum.all?(world.second_lap, fn {_, val} -> not val end)
  end

  test "only one player comes out of jail" do
    world = create_initial_world()
            |> ParquesService.out_of_jail(0)

    ones_pieces = Enum.filter(
      world.positions,
      fn {{player, _}, _} ->
        player == 0
      end
    )

    assert Enum.all?(
             ones_pieces,
             fn {_, pos} ->
               pos == {0, ParquesService.salida()}
             end
           )

    rest = Enum.filter(
      world.positions,
      fn {{player, _}, _} ->
        player != 0
      end
    )

    assert Enum.all?(rest, fn {_key, pos} -> pos == :jail end)
  end

  test "first player can roll" do
    {:ok, world} = create_initial_world(true)

    assert world.game_state == {0, :move_first}

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

    {:ok, world} = ParquesService.play_turn(world, {0, 3})

    assert world.dices == {3}
    assert world.game_state == {0, :move_second}
    assert world.positions[{0, 0}] == {0, 7}
  end

  test "player plays twice move two pieces" do
    {:ok, world} = create_initial_world(true)

    {:ok, world} = ParquesService.play_turn(world, {0, 3})
    {:ok, world} = ParquesService.play_turn(world, {0, 3})

    assert world.dices == {}
    assert world.game_state == {1, :to_play}
    assert world.positions[{0, 0}] == {0, 10}
  end

  test "first player play all dices at once" do
    {:ok, world} = create_initial_world(true)
    {:ok, world} = ParquesService.play_turn(world, {0, 6})

    assert world.dices == {}
    assert world.positions[{0, 0}] == {0, 10}
    assert world.game_state == {1, :to_play}
  end

  test "second player rolls the dice" do
    {:ok, world} = create_initial_world(true)
    {:ok, world} = ParquesService.play_turn(world, {0, 6})
    world = ParquesService.out_of_jail(world, 1)
    IO.inspect world
    {:ok, world} = ParquesService.play_turn(world, fn -> 4 end)
    IO.inspect world
    {:ok, world} = ParquesService.play_turn(world, {0, 8})
    IO.inspect world

    assert world.dices == {}
    assert world.positions[{1, 0}] == {1, 12}
    assert world.game_state == {2, :to_play}
  end

  test "player moves to the next color" do
    {:ok, world} = create_initial_world()
                   |> ParquesService.out_of_jail(0)
                   |> ParquesService.play_turn(fn -> 7 end)

    {:ok, world} = ParquesService.play_turn(world, {0, 14})

    assert world.dices == {}
    assert world.positions[{0, 0}] == {1, 1}
  end

  test "player can move to last pos of color" do
    {:ok, world} = create_initial_world()
                   |> ParquesService.out_of_jail(0)
                   |> ParquesService.play_turn(fn -> 6 end)

    {:ok, world} = ParquesService.play_turn(world, {0, 12})

    assert world.dices == {}
    assert world.positions[{0, 0}] == {0, 16}
  end

  test "player comes back to first color" do
    {:ok, world} = create_initial_world()
                   |> ParquesService.out_of_jail(1)
                   |> update_pos({0, 0}, {3, 15})
                   |> ParquesService.play_turn(fn -> 2 end)

    {:ok, world} = ParquesService.play_turn(world, {0, 2})

    assert world.dices == {2}
    assert world.positions[{0, 0}] == {0, 0}
    assert world.second_lap[{0, 0}]
  end

  test "player goes into heaven" do
    {:ok, world} = create_initial_world()
                   |> ParquesService.out_of_jail(1)
                   |> update_pos({0, 0}, {3, 15})
                   |> update_second_lap({0, 0}, true)
                   |> ParquesService.play_turn(fn -> 2 end)

    {:ok, world} = ParquesService.play_turn(world, {0, 2})

    assert world.dices == {2}
    assert world.positions[{0, 0}] == {0, 17}
  end

  # Going into heaven
  # Winning
  # Jail dynamics
  # Eating other pieces

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
      |> ParquesService.out_of_jail(0)
      |> ParquesService.play_turn(fn -> 3 end)
    end
  end

  defp update_pos(world, key, pos) do
    Map.put(
      world,
      :positions,
      Map.put(world.positions, key, pos)
    )
  end

  defp update_second_lap(world, key, val) do
    Map.put(
      world,
      :second_lap,
      Map.put(world.second_lap, key, val)
    )
  end

end
