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

