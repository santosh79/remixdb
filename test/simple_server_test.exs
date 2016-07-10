defmodule Remixdb.NameServerTest do
  def init do
    %{}
  end

  def find(server_name, key) do
    Remixdb.SimpleServer.rpc server_name, {:find, key}
  end

  def get(server_name, key) do
    Remixdb.SimpleServer.rpc server_name, {:get, key}
  end

  def set(server_name, key, val) do
    Remixdb.SimpleServer.rpc server_name, {:set, key, val}
  end

  def handle(request, dict) do
    case request do
      {:get, key} ->
        {Dict.get(dict, key), dict}
      {:set, k, v} ->
        {:ok, (dict |> Dict.put(k, v))}
      {:find, _k} ->
        {"hey", dict}
    end
  end
end

defmodule RemixdbTest.SimpleServer do
  use ExUnit.Case

  setup_all _context do
    :ok
  end

  test "name server test" do
    Remixdb.SimpleServer.start :remixdb_nameserver_test, Remixdb.NameServerTest
    Remixdb.NameServerTest.set :remixdb_nameserver_test, "name", "john"
    val = Remixdb.NameServerTest.get :remixdb_nameserver_test, "name"
    assert val === "john"
  end

end

