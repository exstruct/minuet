defmodule Minuet.Type.Enumerable do
  defstruct expression: [],
            assign: nil,
            item: nil,
            enter: nil,
            exit: nil,
            line: nil

  defimpl Minuet.Type do
    alias Minuet.Util

    def compile(
          %{line: line, expression: expression, assign: assign, enter: v_enter, exit: v_exit} =
            enumerable,
          serializer,
          vars
        ) do
      {v_enter, vars} = Util.compile(v_enter, serializer, vars)
      {enter, vars} = serializer.enter(enumerable, vars)

      scope = Util.scope(vars)

      {body, vars} = Util.compile(enumerable.item, serializer, vars)

      body =
        quote line: line do
          unquote(scope) =
            Enum.reduce(unquote(expression), unquote(scope), fn unquote(assign), unquote(scope) ->
              unquote(
                Util.join([
                  body,
                  scope
                ])
              )
            end)
        end

      {exit, vars} = serializer.exit(enumerable, vars)
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
