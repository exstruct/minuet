defmodule Test.Minuet do
  use ExUnit.Case
  use ExUnitProperties

  alias Minuet.Type, as: T

  defp t_struct(s) do
    s
    |> :maps.to_list()
    |> fixed_map()
  end

  defp root() do
    tree = tree(t_leaf(), &t_subtree/1)

    t_struct(%T.Root{
      value:
        one_of([
          t_leaf(),
          tree,
          t_condition(t_leaf()),
          t_condition(tree)
        ])
    })
  end

  defp t_subtree(child) do
    one_of([
      t_enumerable(child),
      t_map(child)
    ])
  end

  defp t_leaf do
    one_of([
      t_constant(),
      t_value()
    ])
  end

  defp t_expression do
    one_of([
      boolean(),
      integer(),
      float(),
      string(:printable)
    ])
  end

  defp t_constant do
    t_struct(%T.Constant{
      expression: t_expression()
    })
  end

  defp t_value do
    t_struct(%T.Value{
      expression: t_expression()
    })
  end

  defp t_enumerable(child) do
    t_struct(%T.Enumerable{
      expression: list_of(integer()),
      assign: constant(quote(do: _)),
      item:
        one_of([
          t_enumerable_item(child),
          t_condition(t_enumerable_item(child))
        ])
    })
  end

  defp t_enumerable_item(child) do
    t_struct(%T.Enumerable.Item{
      value: child
    })
  end

  defp t_map(child) do
    fields =
      string(:printable)
      |> map_of(nil)
      |> bind(fn names ->
        names
        |> Map.keys()
        |> Enum.map(fn name ->
          field =
            t_struct(%T.Map.Field{
              name: constant(name),
              value: child
            })

          one_of([
            field,
            t_condition(field)
          ])
        end)
        |> fixed_list()
      end)

    t_struct(%T.Map{
      fields: fields
    })
  end

  defp t_condition(child) do
    t_struct(%T.Condition{
      expression: boolean(),
      value: child
    })
  end

  property "compilation" do
    check all tree <- root() do
      term = check_term(tree)
      assert term == check_json(tree)
      assert term == check_msgpack(tree)
    end
  end

  defp check_json(ast) do
    ast
    |> Minuet.compile(Minuet.Format.JSON)
    |> eval()
    |> :erlang.iolist_to_binary()
    |> case do
      "" ->
        nil

      data ->
        data
        |> Poison.decode!()
    end
  end

  defp check_msgpack(ast) do
    ast
    |> Minuet.compile(Minuet.Format.MSGPACK)
    |> eval()
    |> :erlang.iolist_to_binary()
    |> case do
      "" ->
        nil

      data ->
        data
        |> Msgpax.unpack!()
    end
  end

  defp check_term(ast) do
    ast
    |> Minuet.compile(Minuet.Format.TERM)
    |> eval()
  end

  def inspect_ast(ast) do
    ast |> Macro.to_string() |> IO.puts()
    ast
  end

  def eval(ast, scope \\ []) do
    ast
    |> Code.eval_quoted(scope)
    |> elem(0)
  end
end
