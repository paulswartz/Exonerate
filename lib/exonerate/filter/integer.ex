defmodule Exonerate.Filter.Integer do
  @moduledoc false
  # the filter for "string" parameters

  @behaviour Exonerate.Filter

  import Exonerate.Filter, only: [drop_type: 2]

  defguardp has_integer_props(schema) when
    is_map_key(schema, "minimum") or
    is_map_key(schema, "maximum") or
    is_map_key(schema, "exlcusiveMinimum") or
    is_map_key(schema, "exlcusiveMaximum") or
    is_map_key(schema, "multipleOf")

  @impl true
  def filter(schema, state = %{types: types}) when has_integer_props(schema) and is_map_key(types, :integer) do
    {[integer_filter(schema, state.path, state.extra_validations)], drop_type(state, :integer)}
  end
  def filter(_schema, state) do
    {[], state}
  end

  defp integer_filter(schema, schema_path, extra_validations) do
    guard_clauses =
      compare_guard(schema, "minimum", schema_path) ++
      compare_guard(schema, "maximum", schema_path) ++
      compare_guard(schema, "exclusiveMinimum", schema_path) ++
      compare_guard(schema, "exclusiveMaximum", schema_path) ++
      multiple_guard(schema, schema_path)

    quote do
      unquote_splicing(guard_clauses)
      defp unquote(schema_path)(integer, path) when is_integer(integer) do
        require Exonerate.Filter
        Exonerate.Filter.apply_extra(unquote(extra_validations), integer, path)
      end
    end
  end

  @operands %{
    "minimum" => :<,
    "maximum" => :>,
    "exclusiveMinimum" => :<=,
    "exclusiveMaximum" => :>=
  }

  defp compare_guard(schema, op, _) when not is_map_key(schema, op), do: []
  defp compare_guard(schema, op, schema_path) do
    compexpr = {@operands[op], [], [quote do integer end, schema[op]]}
    [quote do
      defp unquote(schema_path)(integer, path) when is_integer(integer) and unquote(compexpr) do
        Exonerate.mismatch(integer, path, schema_subpath: unquote(op))
      end
    end]
  end

  defp multiple_guard(schema, _) when not is_map_key(schema, "multipleOf"), do: []
  defp multiple_guard(schema, schema_path) do
    factor = schema["multipleOf"]
    [quote do
      defp unquote(schema_path)(integer, path) when rem(integer, unquote(factor)) != 0 do
        Exonerate.mismatch(integer, path, schema_subpath: "multipleOf")
      end
    end]
  end

end
