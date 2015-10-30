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

  def handle(request, state) do
    case request do
      {:get, key} ->
        {Dict.get(state, key), state}
      {:set, key, val} ->
        {:ok, Dict.put(state, key, val)}
    end
  end

end

