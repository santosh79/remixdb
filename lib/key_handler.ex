defmodule Remixdb.KeyHandler do
  def start do
    pid = spawn Remixdb.KeyHandler, :loop, []
    Process.register pid, :remixdb_key_handler
    pid
  end

  def stop do
    Remixdb.ProcessCleaner.stop :remixdb_key_handler
  end

  defp wait_for_val(key_pid) do
    receive do
      {:ok, ^key_pid, val} -> val
    end
  end

  defp wait_for_ok(key_pid) do
    receive do
      {:ok, ^key_pid} -> :void
    end
  end

  def loop do
    receive do
      {sender, {:set, [key, val]}} ->
        # TODO: Re-factor this
        key_pid = case (key |> get_key_pid) do
          nil -> Remixdb.String.start key
          pid -> pid
        end
        send key_pid, {self(), {:set, [key, val]}}
        wait_for_ok key_pid
        send sender, {self(), :ok}
      {sender, {:exists, key}} ->
        val = !!(key |> get_key_pid)
        send sender, {self(), val}
      {sender, {:get, key}} ->
        val = case(key |> get_key_pid) do
          nil -> nil
          key_pid -> 
            send key_pid, {self(), :get}
            wait_for_val(key_pid)
        end
        send sender, {self(), val}
    end
    loop
  end

  def wait_for_response do
    key_handler = get_key_handler
    receive do
      {^key_handler, val} -> val
    end
  end

  def set(key, val) do
    key_handler = get_key_handler
    send key_handler, {self(), {:set, [key, val]}}
    val = case wait_for_response do
      :error -> :error
      val -> val
    end
    IO.puts "KeyHandler returning for set: "
    IO.inspect val
    val
  end

  def get(key) do
    key_handler = get_key_handler
    send key_handler, {self(), {:get, key}}
    case wait_for_response do
      :error -> :error
      val -> val
    end
  end

  def exists?(key) do
    key_handler = get_key_handler
    send key_handler, {self(), {:exists, key}}
    case wait_for_response do
      :error -> :error
      val -> val
    end
  end

  def get_key_pid(key) do
    ("remixdb_string|" <> key) |> String.to_atom |> Process.whereis
  end

  defp get_key_handler do
    pid = Process.whereis :remixdb_key_handler
    IO.puts "get_key_handler: "
    IO.inspect pid
    pid
  end
end

