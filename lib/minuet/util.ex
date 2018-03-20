defmodule Minuet.Util do
  def compile(nil, _, vars) do
    {nil, vars}
  end

  def compile(type, serializer, vars) do
    Minuet.Type.compile(type, serializer, vars)
  end

  def join(items, line \\ 1) do
    {:__block__, [line: line], items |> join_r |> Enum.to_list()}
  end

  defp join_r(items) do
    items
    |> Stream.flat_map(fn
      {:__block__, _, items} ->
        join_r(items)

      nil ->
        []

      [] ->
        []

      items when is_list(items) ->
        join_r(items)

      item ->
        [item]
    end)
  end

  def scope(vars) do
    vars
    |> Map.values()
    |> Stream.map(fn
      [] ->
        nil

      [var | _] when is_tuple(var) ->
        var

      var when is_tuple(var) ->
        var
    end)
    |> Stream.filter(& &1)
    |> Enum.sort()
    |> case do
      [var] ->
        var

      vars ->
        {:{}, [], vars}
    end
  end
end
