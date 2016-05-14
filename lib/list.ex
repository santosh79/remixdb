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

  def lpush(name, items) do
    GenServer.call(name, {:lpush, items})
  end

  def lpop(nil) do; :undefined; end
  def lpop(name) do
    GenServer.call(name, :lpop)
  end

  def rpop(nil) do; :undefined; end
  def rpop(name) do
    GenServer.call(name, :rpop)
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
    add_items_to_list :right, new_items, state
  end

  def handle_call({:lpush, new_items}, _from, state) do
    add_items_to_list :left, new_items, state
  end

  def handle_call(:lpop, _from, state) do
    pop_items_from_list :left, state
  end

  def handle_call(:rpop, _from, state) do
    pop_items_from_list :right, state
  end

  # SantoshTODO: Mixin Termination stuff
  def terminate(:normal, %{key_name: key_name}) do
    Remixdb.KeyHandler.remove key_name
    :ok
  end

  defp add_items_to_list(push_direction, new_items, state) do
    %{items: items} = state
    updated_items = case push_direction do
      :left  -> (new_items ++ items)
      :right -> (items ++ new_items)
    end
    new_state = Dict.merge(state, %{items: updated_items})
    list_sz = updated_items |> Enum.count
    {:reply, list_sz, new_state}
  end

  defp pop_items_from_list(pop_direction, state) do
    {head, updated_items} = case Dict.get(state, :items) do
      []    ->
        Remixdb.List.popped_out self
        {:undefined, []}
      list ->
        case pop_direction do
          :left ->
            [h|t] = list
            {h, t}
          :right ->
            [h|t] = list |> :lists.reverse
            {h, (t |> :lists.reverse)}
        end
    end
    new_state = Dict.merge(state, %{items: updated_items})
    {:reply, head, new_state}
  end
end
