defmodule RemixdbTest do
  use ExUnit.Case

  defp set(key, val) do
    Remixdb.Server.set self, key, val
  end

  defp get(key) do
    import Remixdb.Server, only: [get: 2, get_connection: 0]
    conn = get_connection
    conn |> get(key)
  end

  defp stop_server do
    Remixdb.Server.stop self
  end

  defp start_server do
    Remixdb.Server.start
  end


  test "start" do
    assert Process.whereis(:remixdb_server) == nil
    Remixdb.Server.start
    server_pid = Process.whereis(:remixdb_server)
    assert Process.alive?(server_pid)
    stop_server()
  end

  test "stop" do
    start_server()
    Remixdb.Server.stop self
    assert_receive :ok
    server = Process.whereis(:remixdb_server)
    assert server == nil
  end

  test "set" do
    start_server()
    Remixdb.Server.set self, "foo", "bar"
    assert_receive :ok
    stop_server()
  end

  test "get" do
    start_server()
    set "foo", "bar"
    Remixdb.Server.get self, "foo"
    assert_receive "bar"
    stop_server()
  end
end
