defmodule Exonerate.Combining.OneOf do
  @moduledoc false

  alias Exonerate.Combining
  alias Exonerate.Tools

  defmacro filter(resource, pointer, opts) do
    __CALLER__
    |> Tools.subschema(resource, pointer)
    |> Enum.with_index(&call_and_context(&1, &2, resource, pointer, opts))
    |> Enum.unzip()
    |> build_filter(resource, pointer, opts)
    |> Combining.dedupe(__CALLER__, resource, pointer, opts)
    |> Tools.maybe_dump(__CALLER__, opts)
  end

  defp build_filter({[all_of_call], [context]}, resource, pointer, opts) do
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(data, path) do
        unquote(all_of_call)(data, path)
      end

      unquote(context)
    end
  end

  defp build_filter({calls, contexts}, resource, pointer, opts) do
    function =
      case opts[:tracked] do
        :object ->
          build_tracked(calls, resource, pointer, opts)

        :array ->
          build_tracked(calls, resource, pointer, opts)

        nil ->
          build_untracked(calls, resource, pointer, opts)
      end

    quote do
      unquote(function)
      unquote(contexts)
    end
  end

  defp build_tracked(calls, resource, pointer, opts) do
    lambdas = Enum.map(calls, &to_lambda/1)
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(data, path) do
        require Exonerate.Tools

        unquote(lambdas)
        |> Enum.reduce_while(
          {Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path,
             reason: "no matches"
           ), 0},
          fn
            fun, {{:error, opts}, index} ->
              case fun.(data, path) do
                ok = {:ok, _seen} ->
                  {:cont, {ok, index, index + 1}}

                Exonerate.Tools.error_match(error) ->
                  {:cont,
                   {{:error, Keyword.update(opts, :errors, [error], &[error | &1])}, index + 1}}
              end

            fun, {ok = {:ok, _seen}, last, index} ->
              case fun.(data, path) do
                {:ok, _} ->
                  matches =
                    Enum.map([last, index], fn slot ->
                      "/" <> Path.join(unquote(pointer) ++ ["#{slot}"])
                    end)

                  {:halt,
                   {Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path,
                      matches: matches,
                      reason: "multiple matches"
                    )}}

                Exonerate.Tools.error_match(error) ->
                  {:cont, {ok, last, index}}
              end
          end
        )
        |> elem(0)
      end
    end
  end

  defp build_untracked(calls, resource, pointer, opts) do
    lambdas = Enum.map(calls, &to_lambda/1)
    call = Tools.call(resource, pointer, opts)

    quote do
      defp unquote(call)(data, path) do
        require Exonerate.Tools

        unquote(lambdas)
        |> Enum.reduce_while(
          {Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path,
             reason: "no matches"
           ), 0},
          fn
            fun, {{:error, opts}, index} ->
              case fun.(data, path) do
                :ok ->
                  {:cont, {:ok, index, index + 1}}

                Exonerate.Tools.error_match(error) ->
                  {:cont,
                   {{:error, Keyword.update(opts, :errors, [error], &[error | &1])}, index + 1}}
              end

            fun, {:ok, last, index} ->
              case fun.(data, path) do
                :ok ->
                  matches =
                    Enum.map([last, index], fn slot ->
                      "/" <> Path.join(unquote(pointer) ++ ["#{slot}"])
                    end)

                  {:halt,
                   {Exonerate.Tools.mismatch(data, unquote(resource), unquote(pointer), path,
                      matches: matches,
                      reason: "multiple matches"
                    )}}

                Exonerate.Tools.error_match(error) ->
                  {:cont, {:ok, last, index}}
              end
          end
        )
        |> elem(0)
      end
    end
  end

  defp to_lambda(call) do
    quote do
      &(unquote({call, [], Elixir}) / 2)
    end
  end

  defp call_and_context(_, index, resource, pointer, opts) do
    pointer = JsonPointer.join(pointer, "#{index}")
    call = Tools.call(resource, pointer, opts)

    context =
      quote do
        require Exonerate.Context
        Exonerate.Context.filter(unquote(resource), unquote(pointer), unquote(opts))
      end

    {call, context}
  end
end
