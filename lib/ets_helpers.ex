defmodule Remixdb.ETSHelpers do
  def get_val(table, key) do
    case :ets.lookup(table, key) do
      [{^key, val}] -> val
      [] -> nil
    end
  end

  def exists?(table, key) do
    :ets.lookup(table, key) != []
  end

  def rename(table, old_key, new_key) do
    case :ets.lookup(table, old_key) do
      [] -> false
      [{^old_key, val}] ->
        true = :ets.insert(table, {new_key, val})
        true = :ets.delete(table, old_key)
        true
    end
  end

  def renamenx(table, old_key, new_key) do
    case :ets.lookup(table, old_key) do
      [] -> {:error, "ERR no such key"}
      [{^old_key, val}] ->
        case :ets.lookup(table, new_key) do
          [] ->
            :ets.insert(table, {new_key, val})
            :ets.delete(table, old_key)
            "1"
          _ ->
            "0"
        end
    end
  end

  def del_keys(table, keys) when is_list(keys) do
    Enum.each(keys, fn key ->
      true = :ets.delete(table, key)
    end)
    :ok
  end

  def put_val(table, key, val) do
    true = :ets.insert(table, {key, val})
    :ok
  end
end
