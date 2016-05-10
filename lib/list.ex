defmodule Remixdb.List do
  use GenServer
  def start(key_name) do
    GenServer.start __MODULE__, {:ok, key_name}, []
  end

  def init({:ok, key_name}) do
    {:ok, %{items: [], key_name: key_name}}
  end

  def rpush(name, items) do
    GenServer.call(name, {:rpush, items})
  end

  def lpop(nil) do; :undefined; end
  def lpop(name) do
    GenServer.call(name, :lpop)
  end

  def llen(nil) do; 0; end
  def llen(name) do
    GenServer.call(name, :llen)
  end

  def popped_out(name) do
    spawn(fn ->
      GenServer.stop(name, :normal)
    end)
  end

  def handle_call(:llen, _from, state) do
    %{items: items} = state
    list_sz = items |> Enum.count
    {:reply, list_sz, state}
  end

  def handle_call({:rpush, new_items}, _from, state) do
    %{items: items} = state
    updated_items = items ++ new_items
    new_state = Dict.merge(state, %{items: updated_items})
    list_sz = updated_items |> Enum.count
    {:reply, list_sz, new_state}
  end

  def handle_call(:lpop, _from, state) do
    {head, updated_items} = case Dict.get(state, :items) do
      []    ->
        Remixdb.List.popped_out self
        {:undefined, []}
      [h|t] -> {h, t}
    end
    new_state = Dict.merge(state, %{items: updated_items})
    {:reply, head, new_state}
  end

  # SantoshTODO: Mixin Termination stuff
  def terminate(:normal, %{key_name: key_name}) do
    Remixdb.KeyHandler.remove key_name
    :ok
  end
end
