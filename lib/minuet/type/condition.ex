defmodule Minuet.Type.Condition do
  defstruct expression: nil,
            enter: nil,
            exit: nil,
            value: nil,
            line: nil

  defimpl Minuet.Type do
    alias Minuet.Util

    def compile(
          %{line: line, enter: v_enter, exit: v_exit, expression: expression, value: value},
          serializer,
          prev_vars
        ) do
      {v_enter, vars} = Util.compile(v_enter, serializer, prev_vars)
      {value, vars} = Util.compile(value, serializer, vars)
      {v_exit, vars} = Util.compile(v_exit, serializer, vars)

      scope = Util.scope(vars)

      body =
        Util.join(
          [
            v_enter,
            value,
            v_exit,
            scope
          ],
          line
        )

      {
        quote line: line do
          unquote(scope) =
            case unquote(expression) do
              res when res === nil or res === false ->
                # TODO fill in additional scope values with nil
                unquote(scope)

              _ ->
                unquote(body)
            end
        end,
        vars
      }
    end
  end
end
