defmodule Minuet.Type.Element.Close do
  defstruct tag: nil,
            attributes: [],
            children: [],
            enter: nil,
            exit: nil,
            line: nil

  defimpl Minuet.Type do
    alias Minuet.Util

    def compile(
          %{
            line: line,
            enter: v_enter,
            exit: v_exit
          } = close,
          serializer,
          vars
        ) do
      {v_enter, vars} = Util.compile(v_enter, serializer, vars)
      {enter, vars} = serializer.enter(close, vars)
      {exit, vars} = serializer.exit(close, vars)
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
