if Code.ensure_compiled?(Poison) do
  defprotocol Minuet.Format.JSON do
    def enter(type, vars)
    def exit(type, vars)
  end

  defimpl Minuet.Format.JSON, for: Minuet.Type.Root do
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

  defimpl Minuet.Format.JSON, for: Minuet.Type.Constant do
    def enter(%{expression: expression, line: line}, vars) do
      %{buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(buffer) = [
           unquote(Poison.encode!(expression))
           | unquote(buffer)
         ]
       end, vars}
    end

    def exit(_, vars) do
      {nil, vars}
    end
  end

  defimpl Minuet.Format.JSON, for: Minuet.Type.Enumerable do
    def enter(%{line: line}, vars) do
      %{enum_prefix: [enum_prefix | _], buffer: [buffer | _]} =
        vars =
        vars
        |> Map.update(:enum_prefix, [suffix_var(0)], fn suffixes ->
          [suffix_var(length(suffixes)) | suffixes]
        end)
        |> Map.update(:buffer, [buffer_var(0)], fn suffixes ->
          [buffer_var(length(suffixes)) | suffixes]
        end)

      {quote line: line do
         unquote(buffer) = []
         unquote(enum_prefix) = []
       end, vars}
    end

    def exit(%{line: line}, vars) do
      %{buffer: [items, buffer | rest], enum_prefix: [suffix | enum_prefix]} = vars

      {quote line: line do
         _ = unquote(suffix)
         unquote(buffer) = ["[", unquote(items), "]" | unquote(buffer)]
       end, %{vars | enum_prefix: enum_prefix, buffer: [buffer | rest]}}
    end

    defp suffix_var(id) do
      Macro.var(:"enum_prefix_#{id}", __MODULE__)
    end

    defp buffer_var(id) do
      Macro.var(:"enum_items_#{id}", __MODULE__)
    end
  end

  defimpl Minuet.Format.JSON, for: Minuet.Type.Enumerable.Item do
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
      %{enum_prefix: [enum_prefix | _], buffer: [item_buffer, items | buffer]} = vars

      {quote line: line do
         unquote(item_buffer) = [unquote(enum_prefix) | unquote(item_buffer)]
         unquote(items) = [unquote(items), unquote(item_buffer)]
         unquote(enum_prefix) = ","
       end, %{vars | buffer: [items | buffer]}}
    end

    defp buffer_var(id) do
      Macro.var(:"enum_item_buffer_#{id}", __MODULE__)
    end
  end

  defimpl Minuet.Format.JSON, for: Minuet.Type.Map do
    def enter(%{line: line}, vars) do
      %{map_suffix: [map_suffix | _]} =
        vars =
        Map.update(vars, :map_suffix, [suffix_var(0)], fn suffixes ->
          [suffix_var(length(suffixes)) | suffixes]
        end)

      %{buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(map_suffix) = []
         unquote(buffer) = ["}" | unquote(buffer)]
       end, vars}
    end

    def exit(%{line: line}, vars) do
      %{buffer: [buffer | _], map_suffix: [suffix | map_suffix]} = vars

      {quote line: line do
         _ = unquote(suffix)
         unquote(buffer) = ["{" | unquote(buffer)]
       end, %{vars | map_suffix: map_suffix}}
    end

    defp suffix_var(id) do
      Macro.var(:"map_suffix_#{id}", __MODULE__)
    end
  end

  defimpl Minuet.Format.JSON, for: Minuet.Type.Map.Field do
    def enter(%{line: line}, vars) do
      %{map_suffix: [map_suffix | _], buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(buffer) = [unquote(map_suffix) | unquote(buffer)]
       end, vars}
    end

    def exit(%{name: name, line: line}, vars) do
      %{map_suffix: [map_suffix | _], buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(buffer) = [
           unquote(Poison.encode!(name) <> ":") | unquote(buffer)
         ]

         unquote(map_suffix) = ","
       end, vars}
    end
  end

  defimpl Minuet.Format.JSON, for: Minuet.Type.Value do
    def enter(%{expression: expression, line: line}, vars) do
      %{buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(buffer) = [
           Poison.Encoder.encode(unquote(expression), %{})
           | unquote(buffer)
         ]
       end, vars}
    end

    def exit(_, vars) do
      {nil, vars}
    end
  end
end
