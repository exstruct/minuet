defprotocol Minuet.Type do
  def compile(type, serializer, vars \\ %{})
end
