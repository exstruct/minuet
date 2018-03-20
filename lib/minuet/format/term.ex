defprotocol Minuet.Format.TERM do
  def enter(type, vars)
  def exit(type, vars)
end

defimpl Minuet.Format.TERM, for: Minuet.Type.Root do
  def enter(%{line: line}, vars) do
    subject = Macro.var(:subject, __MODULE__)
    vars = Map.put(vars, :subject, [subject])

    {quote line: line do
       unquote(subject) = nil
       _ = unquote(subject)
     end, vars}
  end

  def exit(%{line: line}, %{subject: [subject]} = vars) do
    {quote line: line do
       _ = unquote(subject)
     end, %{vars | subject: subject}}
  end
end

defimpl Minuet.Format.TERM, for: Minuet.Type.Constant do
  def enter(%{expression: expression, line: line}, vars) do
    %{subject: [subject | _]} = vars

    {quote line: line do
      unquote(subject) = unquote(Macro.escape(expression))
    end, vars}
  end

  def exit(_, vars) do
    {nil, vars}
  end
end

defimpl Minuet.Format.TERM, for: Minuet.Type.Enumerable do
  def enter(%{line: line}, vars) do
    %{subject: [subject | _]} = vars

    {quote line: line do
       unquote(subject) = []
     end, vars}
  end

  def exit(%{line: line}, vars) do
    %{subject: [subject | _]} = vars

    {quote line: line do
       unquote(subject) = :lists.reverse(unquote(subject))
     end, vars}
  end
end

defimpl Minuet.Format.TERM, for: Minuet.Type.Enumerable.Item do
  def enter(_, vars) do
    vars =
      Map.update(vars, :subject, [subject_var(0)], fn subjects ->
        [subject_var(length(subjects)) | subjects]
      end)

    {nil, vars}
  end

  def exit(%{line: line}, vars) do
    %{subject: [item_subject, items | subjects]} = vars

    {quote line: line do
       unquote(items) = [unquote(item_subject) | unquote(items)]
     end, %{vars | subject: [items | subjects]}}
  end

  defp subject_var(id) do
    Macro.var(:"subject_#{id}", __MODULE__)
  end
end

defimpl Minuet.Format.TERM, for: Minuet.Type.Map do
  def enter(%{line: line}, vars) do
    %{subject: [subject | _]} = vars

    {quote line: line do
       unquote(subject) = %{}
     end, vars}
  end

  def exit(_, vars) do
    {nil, vars}
  end
end

defimpl Minuet.Format.TERM, for: Minuet.Type.Map.Field do
  def enter(_, vars) do
    vars =
      Map.update(vars, :subject, [subject_var(0)], fn subjects ->
        [subject_var(length(subjects)) | subjects]
      end)

    {nil, vars}
  end

  def exit(%{line: line, name: name}, vars) do
    %{subject: [value, map | subjects]} = vars

    {quote line: line do
       unquote(map) = :maps.put(unquote(name), unquote(value), unquote(map))
     end, %{vars | subject: [map | subjects]}}
  end

  defp subject_var(id) do
    Macro.var(:"subject_#{id}", __MODULE__)
  end
end

defimpl Minuet.Format.TERM, for: Minuet.Type.Value do
  def enter(%{expression: expression, line: line}, vars) do
    %{subject: [subject | _]} = vars

    {quote line: line do
      unquote(subject) = unquote(expression)
    end, vars}
  end

  def exit(_, vars) do
    {nil, vars}
  end
end
