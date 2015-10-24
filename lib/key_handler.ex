defmodule Remixdb.KeyHandler do
  def get_key_pid(key) do
    ("remixdb_string|" <> key) |> String.to_atom |> Process.whereis
  end

  def get_or_create_key_pid(key) do
    key_atom = ("remixdb_string|" <> key) |> String.to_atom
    key_pid = case Process.whereis(key_atom) do
      nil -> Remixdb.String.start key
      pid -> pid
    end
  end
end

