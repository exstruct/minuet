defmodule Minuet.Type.Constant do
  defstruct expression: nil,
            line: nil

  defimpl Minuet.Type do
    alias Minuet.Util

    def compile(%{line: line} = constant, serializer, vars) do
      {enter, vars} = serializer.enter(constant, vars)
      {exit, vars} = serializer.exit(constant, vars)

      {Util.join(
         [
           enter,
           exit
         ],
         line
       ), vars}
    end
  end
end
