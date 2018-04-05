defmodule Test.Minuet do
  use ExUnit.Case
  use ExUnitProperties

  alias Minuet.Type, as: T

  defp t_struct(s) do
    s
    |> :maps.to_list()
    |> fixed_map()
  end

  defp data_root() do
    leaf = t_leaf()
    tree = tree(leaf, &t_data_subtree/1)

    t_struct(%T.Root{
      value:
        one_of([
          leaf,
          tree,
          t_condition(leaf),
          t_condition(tree)
        ])
    })
  end

  defp element_root() do
    leaf =
      one_of([
        t_struct(%T.Constant{
          expression: string(:alphanumeric)
        })
      ])

    # tree = tree(leaf, &t_element_subtree/1)
    tree = t_element_subtree(leaf)

    t_struct(%T.Root{
      value:
        one_of([
          tree,
          t_condition(tree)
        ])
    })
  end

  defp t_data_subtree(child) do
    child =
      one_of([
        child,
        t_condition(child)
      ])

    one_of([
      t_enumerable(child),
      t_map(child)
    ])
  end

  defp t_element_subtree(child) do
    child =
      one_of([
        child,
        t_condition(child)
      ])

    elem = t_element(child)

    one_of([
      t_enumerable(elem),
      elem
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
    |> tree(fn expr ->
      one_of([
        expr,
        list_of(expr),
        map_of(string(:printable), expr)
      ])
    end)
  end

  defp t_constant do
    t_struct(%T.Constant{
      expression: t_expression()
    })
  end

  defp t_value do
    t_struct(%T.Value{
      expression:
        t_expression()
        |> bind(&constant(Macro.escape(&1)))
    })
  end

  defp t_enumerable(child) do
    child = t_enumerable_item(child)

    t_struct(%T.Enumerable{
      expression: list_of(integer()),
      assign: constant(quote(do: _)),
      item:
        one_of([
          child,
          t_condition(child)
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

  defp t_element(child) do
    t_struct(%T.Element{
      tag: string(:alphanumeric),
      # TODO
      attributes: constant([]),
      children: list_of(child)
    })
  end

  defp t_condition(child) do
    t_struct(%T.Condition{
      expression: boolean(),
      value: child
    })
  end

  property "data structure" do
    check all tree <- data_root() do
      term = check_term(tree)
      assert term == check_json(tree)
      assert term == check_msgpack(tree)
    end
  end

  property "elements" do
    check all tree <- element_root() do
      # term = check_term(tree)
      check_xml(tree)
      # assert term == check_xml(tree)
      check_html(tree)
      # assert term == check_html(tree)
    end
  end

  if Mix.env() == :bench do
    test "benchmark" do
      ast = data_root() |> resize(100) |> pick()
      data = check_term(ast)
      json = compile_fun(ast, Minuet.Format.JSON)
      msgpack = compile_fun(ast, Minuet.Format.MSGPACK)

      Benchee.run(
        %{
          "json | minuet" => &json.run/0,
          "json | poison" => fn ->
            Poison.encode_to_iodata!(data)
          end,
          "msgpack | minuet" => &msgpack.run/0,
          "msgpack | msgpax" => fn ->
            Msgpax.pack!(data)
          end
        },
        measure_memory: true
      )
    end

    defp compile_fun(ast, format) do
      body = Minuet.compile(ast, format)

      quote do
        module = unquote(Module.concat(__MODULE__, format)).BENCH

        defmodule module do
          def run do
            unquote(body)
          end
        end

        module
      end
      |> eval()
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

  defp check_xml(ast) do
    ast
    |> Minuet.compile(Minuet.Format.XML)
    |> eval()
    |> :erlang.iolist_to_binary()
    |> case do
      "" ->
        nil

      data ->
        # TODO parse
        data
    end
  end

  defp check_html(ast) do
    ast
    |> Minuet.compile(Minuet.Format.HTML)
    |> eval()
    |> :erlang.iolist_to_binary()
    |> case do
      "" ->
        nil

      data ->
        # TODO parse
        data
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
