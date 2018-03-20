defmodule Minuet.Type.Value do
  defstruct expression: nil,
            enter: nil,
            exit: nil,
            line: nil

  defimpl Minuet.Type do
    alias Minuet.Util

    def compile(%{line: line, enter: v_enter, exit: v_exit} = value, serializer, vars) do
      {v_enter, vars} = Util.compile(v_enter, serializer, vars)
      {enter, vars} = serializer.enter(value, vars)
      {exit, vars} = serializer.exit(value, vars)
      {v_exit, vars} = Util.compile(v_exit, serializer, vars)

      {Util.join(
         [
           v_enter,
           enter,
           exit,
           v_exit
         ],
         line
       ), vars}
    end
  end
end
