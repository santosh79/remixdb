defmodule RemixdbTest do
  use ExUnit.Case

  defp set(key, val) do
    import Remixdb.Server, only: [set: 3, get_connection: 0]
    conn = get_connection
    conn |> set(key, val)
  end

  defp get(key) do
    import Remixdb.Server, only: [get: 2, get_connection: 0]
    conn = get_connection
    conn |> get(key)
  end

  test "set" do
    res = set("foo", "bar")
    assert res == "OK"
  end

  test "get" do
    set "foo", "bar"
    res = get "foo"
    assert res == "bar"
  end
end
