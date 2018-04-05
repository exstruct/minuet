defmodule Minuet.Type.Element do
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
            children: children,
            enter: v_enter,
            exit: v_exit
          } = element,
          serializer,
          vars
        ) do
      {v_enter, vars} = Util.compile(v_enter, serializer, vars)
      {enter, vars} = serializer.enter(element, vars)

      close = Map.put(element, :__struct__, @for.Close)
      {close, vars} = Util.compile(close, serializer, vars)

      {children, vars} =
        Enum.reduce(children, {[], vars}, fn child, {acc, vars} ->
          {child, vars} = Util.compile(child, serializer, vars)
          {[child | acc], vars}
        end)

      open = Map.put(element, :__struct__, @for.Open)
      {open, vars} = Util.compile(open, serializer, vars)

      {exit, vars} = serializer.exit(element, vars)
      {v_exit, vars} = Util.compile(v_exit, serializer, vars)

      {Util.join(
         [
           v_enter,
           enter,
           close,
           children,
           open,
           exit,
           v_exit
         ],
         line
       ), vars}
    end
  end
end
