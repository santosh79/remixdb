defmodule Remixdb.Benchmark.DataStructures do
  def map_perf(num_elms \\ 1_000_000) when is_integer(num_elms) and num_elms > 1 do
    _el = :rand.uniform(num_elms)
    :timer.tc(fn ->
      mp_st = 1..num_elms |> Enum.reduce(%{}, fn(x, map) ->
        Map.put(map, x, 1)
      end)
      1..num_elms |> Enum.each(fn(x) ->
        1 == Map.get(mp_st, x)
      end)
    end)
  end

  def set_perf(num_elms) when is_integer(num_elms) and num_elms > 1 do
    mp_st = 1..num_elms |> Enum.into(MapSet.new())
    el = :rand.uniform(num_elms)
    :timer.tc(MapSet, :member?, [mp_st, el])
  end

  def list_perf(num_elms) when is_integer(num_elms) and num_elms > 1 do
    lst = 1..num_elms |> Enum.into([])
    :timer.tc(fn ->
      el = :rand.uniform(num_elms)
      lst |> Enum.any?(fn(x) ->
        x == el
      end)
    end)
  end

  def sets_vs_maps(num_elms \\ 1_000_000) when is_integer(num_elms) and num_elms > 1 do
    set_task = Task.async(__MODULE__, :set_perf, [num_elms])
    map_task = Task.async(__MODULE__, :map_perf, [num_elms])

    set_result = Task.await(set_task, :timer.seconds(10))
    map_result = Task.await(map_task, :timer.seconds(10))

    [{:map_time, map_result}, {:set_time, set_result}]
  end

  def sets_vs_list(num_elms) when is_integer(num_elms) and num_elms > 1 do
    set_task = Task.async(__MODULE__, :set_perf, [num_elms])
    list_task = Task.async(__MODULE__, :list_perf, [num_elms])

    set_result = Task.await(set_task)
    lst_result = Task.await(list_task)

    [{:list_time, lst_result}, {:set_time, set_result}]
  end
end
