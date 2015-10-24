defmodule Remixdb.KeyHandler do
  def get_or_create_key_pid(key) do
    case (key |> get_key_pid) do
      nil -> Remixdb.String.start key
      pid -> pid
    end
  end

  def get_key_pid(key) do
    ("remixdb_string|" <> key) |> String.to_atom |> Process.whereis
  end

  def key_exists?(key) do
    !!(key |> get_key_pid)
  end
end

