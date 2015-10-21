defmodule Remixdb.String do
  def start(key) do
    pid = spawn Remixdb.String, :loop, [key]
    name = ("remixdb_string|" <> key) |> String.to_atom
    Process.register pid, name
    pid
  end

  def loop(key) do
    loop key, nil
  end

  def loop(key, val) do
    receive do
      {sender, :get} ->
        send sender, {:ok, self(), val}
        loop key, val
      {sender, {:set, [^key, new_val]}} ->
        IO.puts "got SET command: for key: #{key}"
        IO.inspect new_val
        IO.puts "from sender: "
        IO.inspect sender
        IO.puts "and self:"
        IO.inspect self()
        send sender, {:ok, self()}
        loop key, new_val
    end
  end
end

