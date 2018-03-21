defmodule Minuet do
  @doc """
  Compile minuet structs into an elixir ast
  """
  def compile(ast, format, vars \\ %{}) do
    {ast, _vars} = Minuet.Type.compile(ast, format, vars)
    ast
  end
end
