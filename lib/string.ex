defmodule Remixdb.String do
  use GenServer
  def start do
    GenServer.start __MODULE__, :ok, []
  end

  def init(:ok) do
    {:ok, %{val: :undefined}}
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def getset(name, val) do
    GenServer.call(name, {:getset, val})
  end

  def set(name, val) do
    GenServer.call(name, {:set, val})
  end

  def decr(name) do
    GenServer.call(name, :decr)
  end

  def incr(name) do
    GenServer.call(name, :incr)
  end

  def incrby(name, val) do
    GenServer.call(name, {:incrby, val})
  end

  def decrby(name, val) do
    GenServer.call(name, {:decrby, val})
  end

  def append(name, val) do
    GenServer.call(name, {:append, val})
  end

  def setex(name, timeout, val) do
    GenServer.call(name, {:setex, timeout, val})
  end

  def ttl(name) do
    GenServer.call(name, :ttl)
  end

  def expire(name) do
    GenServer.stop(name, :expired)
  end

  def handle_call(:get, _from, state) do
    %{val: val} = state
    {:reply, val, state}
  end

  def handle_call({:getset, val}, _from, state) do
    %{val: old_val} = state
    new_state       = Dict.put(state, :val, val)
    {:reply, old_val, new_state}
  end

  def handle_call({:set, val}, _from, state) do
    new_state = Dict.put(state, :val, val)
    {:reply, :ok, new_state}
  end

  def handle_call({:incrby, val_str}, _from, state) do
    to_i = &String.to_integer/1
    new_val = case Dict.get(state, :val) do
      :undefined -> to_i.(val_str)
      old_val    -> (old_val + to_i.(val_str))
    end
    new_state = Dict.put(state, :val, new_val)
    {:reply, new_val, new_state}
  end

  def handle_call(:decr, _from, state) do
    new_val = case Dict.get(state, :val) do
      :undefined -> -1
      old_val    -> old_val - 1
    end
    new_state = Dict.put(state, :val, new_val)
    {:reply, new_val, new_state}
  end

  def handle_call({:decrby, val_str}, _from, state) do
    to_i = &String.to_integer/1
    new_val = case Dict.get(state, :val) do
      :undefined -> to_i.(val_str) * -1
      old_val    -> (old_val - to_i.(val_str))
    end
    new_state = Dict.put(state, :val, new_val)
    {:reply, new_val, new_state}
  end

  def handle_call(:incr, _from, state) do
    new_val = case Dict.get(state, :val) do
      :undefined -> 1
      old_val    -> old_val + 1
    end
    new_state = Dict.put(state, :val, new_val)
    {:reply, new_val, new_state}
  end

  def handle_call({:append, val}, _from, state) do
    new_val = case Dict.get(state, :val) do
      :undefined -> val
      old_val    -> (old_val <> val)
    end
    string_length = new_val |> String.length
    new_state     = Dict.put(state, :val, new_val)
    {:reply, string_length, new_state}
  end

  def handle_call({:setex, timeout, val}, _from, state) do
    new_state =  state |> Dict.merge(%{timeout: timeout, val: val})
    {:reply, :ok, new_state}
  end

  def handle_call(:ttl, _from, state) do
    %{timeout: timeout} = state
    {:reply, timeout, state}
  end

  def terminate(:expired, _state) do
    :ok
  end
end

