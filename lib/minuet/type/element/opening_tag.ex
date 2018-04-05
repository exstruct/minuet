defmodule Minuet.Type.Element.Open do
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
            attributes: attributes,
            enter: v_enter,
            exit: v_exit
          } = open,
          serializer,
          vars
        ) do
      {v_enter, vars} = Util.compile(v_enter, serializer, vars)
      {enter, vars} = serializer.enter(open, vars)

      {attributes, vars} =
        Enum.reduce(attributes, {[], vars}, fn attr, {acc, vars} ->
          {attr, vars} = Util.compile(attr, serializer, vars)
          {[attr | acc], vars}
        end)

      {exit, vars} = serializer.exit(open, vars)
      {v_exit, vars} = Util.compile(v_exit, serializer, vars)

      {Util.join(
         [
           v_enter,
           enter,
           attributes,
           exit,
           v_exit
         ],
         line
       ), vars}
    end
  end
end
