defmodule Remixdb.String do
  use GenServer
  def start_link do
    GenServer.start_link __MODULE__, :ok, []
  end

  def init(:ok) do
    {:ok, :undefined}
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

  def handle_call(:get, _from, val) do
    {:reply, val, val}
  end

  def handle_call({:getset, val}, _from, old_val) do
    {:reply, old_val, val}
  end

  def handle_call({:set, val}, _from, old_val) do
    {:reply, :ok, val}
  end

  def handle_call({:incrby, val_str}, _from, :undefined) do
    val = val_str |> String.to_integer
    {:reply, val, val}
  end
  def handle_call({:incrby, val_str}, _from, old_val) do
    val     = val_str |> String.to_integer
    new_val = old_val + val
    {:reply, new_val, new_val}
  end

  def handle_call(:decr, _from, :undefined) do
    {:reply, -1, -1}
  end
  def handle_call(:decr, _from, old_val) do
    new_val = old_val - 1
    {:reply, new_val, new_val}
  end

  def handle_call({:decrby, val_str}, _from, :undefined) do
    val = val_str |> String.to_integer
    val = val * -1
    {:reply, val, val}
  end
  def handle_call({:decrby, val_str}, _from, old_val) do
    val     = val_str |> String.to_integer
    new_val = old_val - val
    {:reply, new_val, new_val}
  end

  def handle_call(:incr, _from, :undefined) do
    {:reply, 1, 1}
  end
  def handle_call(:incr, _from, old_val) do
    new_val = old_val + 1
    {:reply, new_val, new_val}
  end

  def handle_call({:append, new_val}, _from, :undefined) do
    string_length = new_val |> String.length
    {:reply, string_length, new_val}
  end
  def handle_call({:append, val}, _from, old_val) do
    new_val = old_val <> val
    string_length = new_val |> String.length
    {:reply, string_length, new_val}
  end
end

