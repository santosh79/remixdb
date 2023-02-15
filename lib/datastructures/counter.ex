defmodule Remixdb.Counter do
  def incr(nil) do
    1
  end

  def incr(cur) do
    incrby cur, 1
  end

  def incrby(nil, amount) when is_integer(amount) do
    amount
  end

  def incrby(cur, amount) when is_binary(cur) do
    incrby :erlang.binary_to_integer(cur), amount
  end

  def incrby(cur, amount) when is_integer(amount) do
    cur + amount
  end

  def incrby(cur, amount) do
    {val, ""} = Integer.parse(amount)
    incrby cur, val
  end
end
