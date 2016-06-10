defmodule RemixDB.SortedSet do
  def new do
    { RedBlackTree.new(), %{} }
  end

  def member?({_scores_tree, keys_to_score_hash}, key) do
     Map.has_key?(keys_to_score_hash, key)
  end

  def to_list({scores_tree, _keys_to_score_hash}) do
    scores_tree |> RedBlackTree.to_list |> Enum.reduce([], fn({_score, item}, acc) ->
      (item |> Enum.sort |> :lists.reverse) ++ acc
    end) |> :lists.reverse
  end

  def insert({scores_tree, keys_to_score_hash}, key, score) do
    old_score                  = Map.get(keys_to_score_hash, key)
    updated_scores_tree        = scores_tree |> add_score_to_tree(old_score, score, key)
    updated_keys_to_score_hash = Map.put(keys_to_score_hash, key, score)
    { updated_scores_tree, updated_keys_to_score_hash }
  end

  def size({_tree, hash}) do
    hash |> Map.keys |> Enum.count
  end

  @doc """
  Accepts a string as input and returns back a string.
  The input string will have to be a number representation,
  e.g. "1" or "10".
  If the string starts with "(" it increments the number.

  ## Examples

      "10"  |> increment_if_non_inclusive  === "10"
      "(10" |> increment_if_non_inclusive  === "11"
  """
  defp increment_if_non_inclusive(str) do
    case (str =~ ~r/^\(/) do
      false -> str
      true ->
        ((str
        |> String.replace(~r/^\((.)/, "\\1")
        |> String.to_integer) + 1)
        |> Integer.to_string
    end
  end

  @doc """
  Accepts a tuple containing two strings as input and returns
  back a two string tuple. These two strings will be string
  numbers, like "10", "1000" etc.

  However, they could also begin with an optional "(" character,
  in which case they will be incremented.

  ## Examples

      {"10", "100"} |> handle_non_inclusive_range === {"10, "100"}
      {"(9", "17"}  |> handle_non_inclusive_range === {"10, "17"}
      {"(9", "(17"} |> handle_non_inclusive_range === {"10, "18"}
  """
  defp handle_non_inclusive_range({min_str, max_str}) do
    cleaned_min = min_str |> increment_if_non_inclusive
    cleaned_max = max_str |> increment_if_non_inclusive
    {cleaned_min, cleaned_max}
  end

  def count_items_in_range({tree, hash}, min_str_raw, max_str_raw) do
    {min_str, max_str} = {min_str_raw, max_str_raw}
                          |> handle_non_inclusive_range

    case {min_str, max_str} do
      {"-inf", "+inf"} -> hash
      {"-inf", max_str} ->
        max = max_str |> String.to_integer
        tree |> Enum.filter(fn({item_score, _item}) ->
          item_score <= max
        end)
      {min_str, "+inf"} ->
        min = min_str |> String.to_integer
        tree |> Enum.filter(fn({item_score, _item}) ->
          item_score >= min
        end)
      _ ->
        min = min_str |> String.to_integer
        max = max_str |> String.to_integer
        range = Range.new(min, max)
        tree |> Enum.filter(fn({item_score, _item}) ->
          item_score in range
        end)
    end |> Enum.count
  end

  def score({_scores_tree, keys_to_score_hash}, member) do
    Map.get(keys_to_score_hash, member, :undefined)
  end

  def rank({scores_tree, keys_to_score_hash}, member) do
    case Map.get(keys_to_score_hash, member, :undefined) do
      :undefined -> :undefined
      score ->
        scores_tree |> Enum.filter(fn({item_score, _item}) ->
          item_score <= score
        end) |> Enum.count
    end
  end

  def remove({scores_tree, keys_to_score_hash}, members) do
    members_set = members |> MapSet.new
    updated_hash = keys_to_score_hash
                   |> remove_members_from_hash(members_set)
    updated_scores_tree = scores_tree
                          |> remove_members_from_scores_tree(members_set)

    updated_sorted_set = { updated_scores_tree, updated_hash }
    num_items_removed = (keys_to_score_hash |> Enum.count) - (updated_hash |> Enum.count)
    {num_items_removed, updated_sorted_set}
  end

  defp remove_members_from_scores_tree(scores_tree, members_set) do
    scores_tree
    |> Enum.reduce(RedBlackTree.new, fn({score, items}, acc) ->
      updated_items = items |> Enum.reject(fn(item) ->
        members_set |> Set.member?(item)
      end)
      acc |> RedBlackTree.insert(score, updated_items)
    end)
    |> cleanup_tree
  end

  defp remove_members_from_hash(keys_to_score_hash, members_set) do
    allowed_keys = keys_to_score_hash
                    |> Map.keys
                    |> MapSet.new
                    |> Set.difference(members_set)

    allowed_keys |> Enum.reduce(%{}, fn(key, hash) ->
      val = hash |> Map.get(key)
      hash |> Map.put(key, val)
    end)
  end

  defp add_score_to_tree(tree, old_score, new_score, key) do
    tree
    |> RedBlackTree.update(new_score, [key], fn(items) ->
      [key|items]
    end)
    |> RedBlackTree.update(old_score, [], fn(items) ->
      items |> List.delete(key)
    end)
    |> cleanup_tree
  end

  defp cleanup_tree(tree) do
    tree |> Enum.reduce(RedBlackTree.new, fn({score, item}, acc) ->
      case item do
        [] -> acc
        _ -> RedBlackTree.insert(acc, score, item)
      end
    end)
  end
end

