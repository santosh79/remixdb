defmodule Remixdb.KeyHandler do
  use GenServer

  def start_link(_args) do
    GenServer.start_link __MODULE__, :ok, [name: :remixdb_key_handler]
  end

  def init(:ok) do
    Process.flag :trap_exit, true
    {:ok, %{}}
  end

  def exists?(key) do
    GenServer.call :remixdb_key_handler, {:exists, key}
  end

  def get_pid(key_type, key) do
    term = get_term key_type
    GenServer.call :remixdb_key_handler, {:get_pid, term, key}
  end

  def get_or_create_pid(key_type, key) do
    term = get_term key_type
    GenServer.call :remixdb_key_handler, {:get_or_create_pid, term, key}
  end

  def dbsize do
    GenServer.call :remixdb_key_handler, :dbsize
  end

  def flushall do
    GenServer.call :remixdb_key_handler, :flushall
  end

  def remove(key) do
    GenServer.cast :remixdb_key_handler, {:remove, key}
  end

  def rename_key(old_name, new_name) do
    GenServer.call :remixdb_key_handler, {:rename_key, old_name, new_name}
  end

  def renamenx_key(old_name, new_name) do
    GenServer.call :remixdb_key_handler, {:renamenx_key, old_name, new_name}
  end

  defp valid_keytype?(key_type) do
    case key_type do
      :list   -> true
      :string -> true
      :set    -> true
      :hash   -> true
    end
  end

  def handle_info(_, state), do: {:noreply, state}

  def handle_cast({:remove, key}, state)  do
    new_state = Map.delete(state, key)
    {:noreply, new_state}
  end

  def handle_call({:get_pid, key_type, key}, _from, state) do
    case valid_keytype?(key_type) do
      true -> do_lookup(state, key)
    end
    do_lookup state, key
  end

  def handle_call({:get_or_create_pid, type_of_key, key}, _from, state) do
    pid           = create_pid_if_not_exists?(type_of_key, state, key)
    updated_state = Map.put(state, key, pid)
    {:reply, pid, updated_state}
  end

  def handle_call({:exists, key}, _from, state) do
    val = !! lookup_pid(state, key)
    {:reply, val, state}
  end

  def handle_call(:dbsize, _from, state) do
    count = state |> Map.keys |> Enum.count
    {:reply, count, state}
  end

  def handle_call(:flushall, _from, state) do
    state |> Map.values |> Enum.each(fn(pid) ->
      Process.exit(pid, :kill)
    end)
    {:reply, :ok, %{}}
  end

  def handle_call({:rename_key, old_name, new_name}, _from, state)  do
    case Map.get(state, old_name) do
      nil ->
        {:reply, "ERR no such key", state}
      pid ->
        new_state = state |> Map.drop([old_name]) |> Map.put(new_name, pid)
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:renamenx_key, old_name, new_name}, _from, state)  do
    {response, new_state} = case Map.get(state, old_name) do
      nil -> {"ERR no such key", state}
      val -> case Map.get(state, new_name) do
        nil -> {1, (state |> Map.drop([old_name]) |> Map.put(new_name, val))}
        _   -> {0, state}
      end
    end
    {:reply, response, new_state}
  end

  defp lookup_pid(state, key) do
    Map.get(state, key)
  end

  defp create_pid_if_not_exists?(type_of_key, state, key) do
    case lookup_pid(state, key) do
      nil ->
        key_type = case type_of_key do
          :string -> Remixdb.String
          :list   -> Remixdb.List
          :set    -> Remixdb.Set
          :hash   -> Remixdb.Hash
        end
        {:ok, pid} = key_type.start(key)
        pid
      p -> p
    end
  end

  defp get_term(:string) do; :string; end
  defp get_term(:set) do; :set; end
  defp get_term(:list) do; :list; end
  defp get_term(:hash) do; :hash; end

  defp do_lookup(state, key) do
    pid = lookup_pid(state, key)
    {:reply, pid, state}
  end

end

