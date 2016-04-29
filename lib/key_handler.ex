defmodule Remixdb.KeyHandler do
  use GenServer

  def start_link do
    GenServer.start_link __MODULE__, :ok, [name: :remixdb_key_handler]
  end

  def init(:ok) do
    Process.flag :trap_exit, true
    {:ok, %{}}
  end

  def exists?(key) do
    GenServer.call :remixdb_key_handler, {:exists, key}
  end

  def get_pid(:string, key) do
    GenServer.call :remixdb_key_handler, {:get_pid, key}
  end

  def get_or_create_pid(:string, key) do
    GenServer.call :remixdb_key_handler, {:get_or_create_pid, key}
  end

  def dbsize do
    GenServer.call :remixdb_key_handler, :dbsize
  end

  def flushall do
    GenServer.call :remixdb_key_handler, :flushall
  end

  def handle_call({:get_pid, key}, _from, state) do
    pid = lookup_pid(state, key)
    {:reply, pid, state}
  end

  def handle_call({:get_or_create_pid, key}, _from, state) do
    pid           = create_pid_if_not_exists?(state, key)
    updated_state = Dict.put(state, key, pid)
    {:reply, pid, updated_state}
  end

  def handle_call({:exists, key}, _from, state) do
    val = !! lookup_pid(state, key)
    {:reply, val, state}
  end

  def handle_call(:dbsize, _from, state) do
    count = state |> Dict.keys |> Enum.count
    {:reply, count, state}
  end

  def handle_call(:flushall, _from, state) do
    state |> Dict.values |> Enum.each(fn(pid) ->
      Process.exit(pid, :kill)
    end)
    {:reply, :ok, %{}}
  end

  defp lookup_pid(state, key) do
    Dict.get(state, key)
  end

  defp create_pid_if_not_exists?(state, key) do
    case lookup_pid(state, key) do
      nil ->
        {:ok, pid} = Remixdb.String.start
        pid
      p -> p
    end
  end

end

