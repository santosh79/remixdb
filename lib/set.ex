defmodule Remixdb.Set do
  use GenServer
  def start(key_name) do
    GenServer.start __MODULE__, {:ok, key_name}, []
  end

  def init({:ok, key_name}) do
    {:ok, %{items: MapSet.new(), key_name: key_name}}
  end

  def sadd(name, item) do
    GenServer.call name, {:sadd, item}
  end

  def smembers(nil) do; []; end
  def smembers(name) do
    GenServer.call name, :smembers
  end

  def scard(nil) do; 0; end
  def scard(name) do
    GenServer.call name, :scard
  end

  def handle_call(:smembers, _from, %{items: items} = state) do
    members = items |> Enum.into([])
    {:reply, members, state}
  end

  def handle_call({:sadd, item}, _from, %{items: items} = state) do
    {num_items_added, updated_items} = case MapSet.member?(items, item) do
      true  -> {0, items}
      false -> {1, MapSet.put(items, item)}
    end
    new_state = update_state state, updated_items
    {:reply, num_items_added, new_state}
  end

  def handle_call(:scard, _from, %{items: items} = state) do
    num_items = items |> Enum.count
    {:reply, num_items, state}
  end

  defp update_state(state, updated_items) do
    Dict.merge(state, %{items: updated_items})
  end
end

