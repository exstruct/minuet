defmodule Minuet do
  def compile(ast, format, vars \\ %{}) do
    {ast, _vars} = Minuet.Type.compile(ast, format, vars)
    ast
  end
end
