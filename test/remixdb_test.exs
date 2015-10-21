defmodule RemixdbTest do
  defmodule Server do
    use ExUnit.Case

    defp start_server do
      Remixdb.Server.start
    end

    test "start_tcp_server" do
      Remixdb.Server.start_tcp_server
      client = Exredis.start_using_connection_string("redis://127.0.0.1:6379")
    end

  end
end
