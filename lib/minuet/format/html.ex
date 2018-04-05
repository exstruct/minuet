if Code.ensure_compiled?(HTMLBuilder) do
  defprotocol Minuet.Format.HTML do
    def enter(type, vars)
    def exit(type, vars)
  end

  defimpl Minuet.Format.HTML, for: Minuet.Type.Root do
    def enter(%{line: line}, vars) do
      buffer = Macro.var(:buffer, __MODULE__)
      vars = Map.put(vars, :buffer, [buffer])

      {quote line: line do
         unquote(buffer) = []
       end, vars}
    end

    def exit(%{line: line}, %{buffer: [buffer]} = vars) do
      {quote line: line do
         _ = unquote(buffer)
       end, %{vars | buffer: buffer}}
    end
  end

  defimpl Minuet.Format.HTML, for: Minuet.Type.Enumerable do
    def enter(%{line: line}, vars) do
      %{buffer: [buffer | _]} =
        vars =
        vars
        |> Map.update(:buffer, [buffer_var(0)], fn suffixes ->
          [buffer_var(length(suffixes)) | suffixes]
        end)

      {quote line: line do
         unquote(buffer) = []
       end, vars}
    end

    def exit(%{line: line}, vars) do
      %{buffer: [items, buffer | rest]} = vars

      {quote line: line do
         unquote(buffer) = [unquote(items) | unquote(buffer)]
       end, %{vars | buffer: [buffer | rest]}}
    end

    defp buffer_var(id) do
      Macro.var(:"enum_items_#{id}", __MODULE__)
    end
  end

  defimpl Minuet.Format.HTML, for: Minuet.Type.Enumerable.Item do
    def enter(%{line: line}, vars) do
      %{buffer: [buffer | _]} =
        vars =
        vars
        |> Map.update(:buffer, [buffer_var(0)], fn suffixes ->
          [buffer_var(length(suffixes)) | suffixes]
        end)

      {quote line: line do
         unquote(buffer) = []
       end, vars}
    end

    def exit(%{line: line}, vars) do
      %{buffer: [item_buffer, items | buffer]} = vars

      {quote line: line do
         unquote(items) = [unquote(items), unquote(item_buffer)]
       end, %{vars | buffer: [items | buffer]}}
    end

    defp buffer_var(id) do
      Macro.var(:"enum_item_buffer_#{id}", __MODULE__)
    end
  end

  defimpl Minuet.Format.HTML, for: Minuet.Type.Element do
    def enter(_, vars) do
      {nil, vars}
    end

    def exit(_, vars) do
      {nil, vars}
    end
  end

  defimpl Minuet.Format.HTML, for: Minuet.Type.Element.Open do
    # TODO handle void elements
    def enter(%{line: line}, vars) do
      %{buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(buffer) = [">" | unquote(buffer)]
       end, vars}
    end

    def exit(%{tag: tag, line: line}, vars) do
      %{buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(buffer) = [unquote("<#{tag}") | unquote(buffer)]
       end, vars}
    end
  end

  defimpl Minuet.Format.HTML, for: Minuet.Type.Element.Close do
    def enter(_, vars) do
      {nil, vars}
    end

    def exit(%{tag: tag, line: line}, vars) do
      %{buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(buffer) = [unquote("</#{tag}>") | unquote(buffer)]
       end, vars}
    end
  end

  defimpl Minuet.Format.HTML, for: Minuet.Type.Constant do
    def enter(%{expression: expression, line: line}, vars) do
      %{buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(buffer) = [
           unquote(HTMLBuilder.encode!(expression))
           | unquote(buffer)
         ]
       end, vars}
    end

    def exit(_, vars) do
      {nil, vars}
    end
  end

  defimpl Minuet.Format.HTML, for: Minuet.Type.Value do
    def enter(%{expression: expression, line: line}, vars) do
      %{buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(buffer) = [
           HTMLBuilder.Encoder.encode(unquote(expression), %{})
           | unquote(buffer)
         ]
       end, vars}
    end

    def exit(_, vars) do
      {nil, vars}
    end
  end
end
