defmodule Exonerate.Filter.PatternProperties do
  @moduledoc false

  alias Exonerate.Cache
  alias Exonerate.Tools

  defmacro filter(name, pointer, opts) do
    call = Tools.pointer_to_fun_name(pointer, authority: name)

    {tracker, opts} = Keyword.pop!(opts, :internal_tracking)

    __CALLER__.module
    |> Cache.fetch!(name)
    |> JsonPointer.resolve!(pointer)
    |> Enum.map(&filter_for(&1, name, pointer, opts))
    |> Enum.unzip()
    |> build_code(call, tracker)
    |> Tools.maybe_dump(opts)
  end

  defp filter_for({regex, _}, name, pointer, opts) do
    pointer = JsonPointer.join(pointer, regex)
    fun = Tools.pointer_to_fun_name(pointer, authority: name)

    {quote do
       {sigil_r(<<unquote(regex)>>, []), &(unquote({fun, [], Elixir}) / 2)}
     end,
     quote do
       require Exonerate.Context

       Exonerate.Context.filter(
         unquote(name),
         unquote(pointer),
         unquote(Tools.drop_tracking(opts))
       )
     end}
  end

  @should_track [:additional, :unevaluated]

  defp build_code({filters, accessories}, call, tracked) when tracked in @should_track do
    quote do
      defp unquote(call)({k, v}, path, seen) do
        Enum.reduce_while(unquote(filters), {:ok, seen}, fn
          {regex, fun}, {:ok, seen} ->
            if Regex.match?(regex, k) do
              case fun.(v, Path.join(path, k)) do
                :ok -> {:cont, {:ok, true}}
                error = {:error, _} -> {:halt, error}
              end
            else
              {:cont, {:ok, seen}}
            end
        end)
      end

      unquote(accessories)
    end
  end

  defp build_code({filters, accessories}, call, _) do
    quote do
      defp unquote(call)({k, v}, path) do
        Enum.reduce_while(unquote(filters), :ok, fn
          _, error = {:error, _} ->
            {:halt, error}

          {regex, fun}, :ok ->
            if Regex.match?(regex, k) do
              {:cont, fun.(v, Path.join(path, k))}
            else
              {:cont, :ok}
            end
        end)
      end

      unquote(accessories)
    end
  end
end
