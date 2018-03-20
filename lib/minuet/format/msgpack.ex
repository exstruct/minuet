if Code.ensure_compiled?(Msgpax) do
  defprotocol Minuet.Format.MSGPACK do
    def enter(type, vars)
    def exit(type, vars)
  end

  defimpl Minuet.Format.MSGPACK, for: Minuet.Type.Root do
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

  defimpl Minuet.Format.MSGPACK, for: Minuet.Type.Constant do
    def enter(%{expression: expression, line: line}, vars) do
      %{buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(buffer) = [
           unquote(pack(expression))
           | unquote(buffer)
         ]
       end, vars}
    end

    def exit(_, vars) do
      {nil, vars}
    end

    defp pack(value) do
      value
      |> Msgpax.Packer.pack()
      |> :erlang.iolist_to_binary()
    end
  end

  defimpl Minuet.Format.MSGPACK, for: Minuet.Type.Enumerable do
    def enter(%{line: line}, vars) do
      %{enum_size: [enum_size | _], buffer: [buffer | _]} =
        vars =
        vars
        |> Map.update(:enum_size, [enum_size(0)], fn sizes ->
          [enum_size(length(sizes)) | sizes]
        end)
        |> Map.update(:buffer, [buffer_var(0)], fn buffers ->
          [buffer_var(length(buffers)) | buffers]
        end)

      {quote line: line do
         unquote(buffer) = []
         unquote(enum_size) = 0
       end, vars}
    end

    def exit(%{line: line}, vars) do
      %{buffer: [items, buffer | rest], enum_size: [size | enum_size]} = vars

      {quote line: line do
         unquote(buffer) = [
           case unquote(size) do
             s when s < 16 ->
               <<0b10010000 + s::8>>

             s when s < 0x10000 ->
               <<0xDC, s::16>>

             s when s < 0x100000000 ->
               <<0xDD, s::32>>
           end,
           unquote(items) | unquote(buffer)
         ]
       end, %{vars | enum_size: enum_size, buffer: [buffer | rest]}}
    end

    defp enum_size(id) do
      Macro.var(:"enum_size_#{id}", __MODULE__)
    end

    defp buffer_var(id) do
      Macro.var(:"enum_items_#{id}", __MODULE__)
    end
  end

  defimpl Minuet.Format.MSGPACK, for: Minuet.Type.Enumerable.Item do
    def enter(%{line: line}, vars) do
      %{buffer: [buffer | _]} =
        vars =
        vars
        |> Map.update(:buffer, [buffer_var(0)], fn buffers ->
          [buffer_var(length(buffers)) | buffers]
        end)

      {quote line: line do
         unquote(buffer) = []
       end, vars}
    end

    def exit(%{line: line}, vars) do
      %{enum_size: [enum_size | _], buffer: [item_buffer, items | buffer]} = vars

      {quote line: line do
         unquote(items) = [unquote(items), unquote(item_buffer)]
         unquote(enum_size) = unquote(enum_size) + 1
       end, %{vars | buffer: [items | buffer]}}
    end

    defp buffer_var(id) do
      Macro.var(:"enum_item_buffer_#{id}", __MODULE__)
    end
  end

  defimpl Minuet.Format.MSGPACK, for: Minuet.Type.Map do
    def enter(%{line: line}, vars) do
      %{map_size: [map_size | _]} =
        vars =
        Map.update(vars, :map_size, [map_size_var(0)], fn sizes ->
          [map_size_var(length(sizes)) | sizes]
        end)

      {quote line: line do
         unquote(map_size) = 0
       end, vars}
    end

    def exit(%{line: line}, vars) do
      %{buffer: [buffer | _], map_size: [map_size | map_sizes]} = vars

      {quote line: line do
         unquote(buffer) = [
           case unquote(map_size) do
             s when s < 16 -> <<0b10000000 + s::8>>
             s when s < 0x10000 -> <<0xDE, s::16>>
             s when s < 0x100000000 -> <<0xDF, s::32>>
           end
           | unquote(buffer)
         ]
       end, %{vars | map_size: map_sizes}}
    end

    defp map_size_var(id) do
      Macro.var(:"map_size_#{id}", __MODULE__)
    end
  end

  defimpl Minuet.Format.MSGPACK, for: Minuet.Type.Map.Field do
    def enter(_, vars) do
      {nil, vars}
    end

    def exit(%{name: name, line: line}, vars) do
      %{map_size: [map_size | _], buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(buffer) = [
           unquote(pack(name)) | unquote(buffer)
         ]

         unquote(map_size) = unquote(map_size) + 1
       end, vars}
    end

    defp pack(value) do
      value
      |> Msgpax.Packer.pack()
      |> :erlang.iolist_to_binary()
    end
  end

  defimpl Minuet.Format.MSGPACK, for: Minuet.Type.Value do
    def enter(%{expression: expression, line: line}, vars) do
      %{buffer: [buffer | _]} = vars

      {quote line: line do
         unquote(buffer) = [
           Msgpax.Packer.pack(unquote(expression))
           | unquote(buffer)
         ]
       end, vars}
    end

    def exit(_, vars) do
      {nil, vars}
    end
  end
end
