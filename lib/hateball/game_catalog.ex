defmodule Hateball.GameCatalog do
  use Agent

  alias Hateball.GameSupervisor

  def start_link(initial_data) do
    Agent.start_link(fn -> initial_data end, name: __MODULE__)
  end

  def add_game(game_id) do
    Agent.update(
      __MODULE__,
      fn data ->
        get_or_create_game(data, game_id)
      end
    )
  end

  def get_game_agent_pid(game_id) do
    Agent.get(
      __MODULE__,
      fn data ->
        Map.get(data, game_id)
      end
    )
  end

  def game_exists?(game_id) do
    Agent.get(__MODULE__, fn data -> Map.has_key?(data, game_id) end)
  end

  defp get_or_create_game(data, game_id) do
    if Map.has_key?(data, game_id) do
      data
    else
      {:ok, agent_pid} = GameSupervisor.create_game(game_id)
      Map.put(data, game_id, agent_pid)
    end
  end

end
