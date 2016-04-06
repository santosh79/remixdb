defmodule Remixdb.String do
  def init do
    %{}
  end

  def get(name, key) do
    Remixdb.SimpleServer.rpc name, {:get, key}
  end

  def set(name, key, val) do
    Remixdb.SimpleServer.rpc name, {:set, key, val}
  end

  def append(name, key, val) do
    Remixdb.SimpleServer.rpc name, {:append, key, val}
  end

  def handle(request, state) do
    case request do
      {:get, key} ->
        {Dict.get(state, key), state}
      {:append, key, val} ->
        new_val = Dict.get(state, key) <> val
        {new_val, Dict.put(state, key, new_val)}
      {:set, key, val} ->
        {:ok, Dict.put(state, key, val)}
    end
  end

end

