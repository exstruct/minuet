defmodule Minuet.Type.Map do
  defstruct fields: [],
            enter: nil,
            exit: nil,
            line: nil

  defimpl Minuet.Type do
    alias Minuet.Util

    def compile(
          %{line: line, fields: fields, enter: v_enter, exit: v_exit} = map,
          serializer,
          vars
        ) do
      {v_enter, vars} = Util.compile(v_enter, serializer, vars)
      {enter, vars} = serializer.enter(map, vars)

      {body, vars} =
        Enum.reduce(fields, {[], vars}, fn field, {acc, vars} ->
          {field, vars} = Util.compile(field, serializer, vars)
          {[field | acc], vars}
        end)

      {exit, vars} = serializer.exit(map, vars)
      {v_exit, vars} = Util.compile(v_exit, serializer, vars)

      {Util.join(
         [
           v_enter,
           enter,
           body,
           exit,
           v_exit
         ],
         line
       ), vars}
    end
  end
end
