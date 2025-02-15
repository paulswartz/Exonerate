defmodule Exonerate.Filter.PatternProperties do
  @moduledoc false

  alias Exonerate.Context
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> build_filter(resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter(subschema, resource, pointer, opts) do
    {subfilters, contexts} =
      subschema
      |> Enum.map(&filters_for(&1, resource, pointer, opts))
      |> Enum.unzip()

    init =
      if opts[:tracked] do
        {:ok, false}
      else
        :ok
      end

    capture =
      if opts[:tracked] do
        quote do
          {:ok, visited}
        end
      else
        :ok
      end

    evaluation =
      if opts[:tracked] do
        quote do
          require Exonerate.Tools

          case fun.(value, Path.join(path, key)) do
            :ok -> {:ok, true}
            Exonerate.Tools.error_match(error) -> error
          end
        end
      else
        quote do
          fun.(value, Path.join(path, key))
        end
      end

    negative =
      if opts[:tracked] do
        quote do
          {:ok, visited}
        end
      else
        :ok
      end

    quote do
      defp unquote(Tools.call(resource, pointer, opts))({key, value}, path) do
        require Exonerate.Tools

        Enum.reduce_while(unquote(subfilters), unquote(init), fn
          {regex, fun}, unquote(capture) ->
            result =
              if Regex.match?(regex, key) do
                unquote(evaluation)
              else
                unquote(negative)
              end

            {:cont, result}

          _, Exonerate.Tools.error_match(error) ->
            {:halt, error}
        end)
      end

      unquote(contexts)
    end
  end

  defp filters_for({regex, _}, resource, pointer, opts) do
    opts = Context.scrub_opts(opts)
    pointer = JsonPointer.join(pointer, regex)
    fun = Tools.call(resource, pointer, opts)

    {quote do
       {sigil_r(<<unquote(regex)>>, []), &(unquote({fun, [], Elixir}) / 2)}
     end,
     quote do
       require Exonerate.Context

       Exonerate.Context.filter(
         unquote(resource),
         unquote(pointer),
         unquote(opts)
       )
     end}
  end
end
