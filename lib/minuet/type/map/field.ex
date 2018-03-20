defmodule Minuet.Type.Map.Field do
  defstruct name: nil,
            value: nil,
            enter: nil,
            exit: nil,
            line: nil

  defimpl Minuet.Type do
    alias Minuet.Util

    def compile(
          %{value: %Minuet.Type.Condition{value: value} = condition} = field,
          serializer,
          vars
        ) do
      %{condition | value: %{field | value: value}}
      |> @protocol.compile(serializer, vars)
    end

    def compile(
          %{line: line, value: value, enter: v_enter, exit: v_exit} = field,
          serializer,
          vars
        ) do
      {v_enter, vars} = Util.compile(v_enter, serializer, vars)
      {enter, vars} = serializer.enter(field, vars)
      {value, vars} = Util.compile(value, serializer, vars)
      {exit, vars} = serializer.exit(field, vars)
      {v_exit, vars} = Util.compile(v_exit, serializer, vars)

      {Util.join(
         [
           v_enter,
           enter,
           value,
           exit,
           v_exit
         ],
         line
       ), vars}
    end
  end
end
