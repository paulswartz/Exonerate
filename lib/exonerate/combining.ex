defmodule Exonerate.Combining do
  @modules %{
    "anyOf" => Exonerate.Combining.AnyOf,
    "allOf" => Exonerate.Combining.AllOf,
    "oneOf" => Exonerate.Combining.OneOf,
    "not" => Exonerate.Combining.Not,
    "$ref" => Exonerate.Combining.Ref,
    "if" => Exonerate.Combining.If
  }

  @filters Map.keys(@modules)

  def merge(map), do: Map.merge(map, @modules)

  def modules, do: @modules

  def filters, do: @filters

  def filter?(filter), do: is_map_key(@modules, filter)

  def adjust("not"), do: ["not", ":entrypoint"]
  def adjust("if"), do: ["if", ":entrypoint"]
  def adjust(other), do: [other]
end
