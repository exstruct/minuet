defmodule Minuet.Type.Root do
  defstruct value: nil,
            enter: nil,
            exit: nil,
            line: nil

  defimpl Minuet.Type do
    alias Minuet.Util

    def compile(
          %{line: line, value: value, enter: v_enter, exit: v_exit} = root,
          serializer,
          vars
        ) do
      {v_enter, vars} = Util.compile(v_enter, serializer, vars)
      {enter, vars} = serializer.enter(root, vars)
      {value, vars} = Util.compile(value, serializer, vars)
      {exit, vars} = serializer.exit(root, vars)
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
