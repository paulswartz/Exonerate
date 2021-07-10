defmodule Exonerate.Tools do
  defguard is_member(mapset, element) when
    is_map_key(:erlang.map_get(:map, mapset), element)

  def inspect(macro, filter \\ true) do
    if filter do
      macro
      |> Macro.to_string
      |> IO.puts
    end

    macro
  end

  def collect(accumulator, enumerable, reducer) do
    Enum.reduce(enumerable, accumulator, &(reducer.(&2, &1)))
  end

  def flatten([]), do: []
  def flatten(list) when is_list(list) do
    if Enum.all?(list, &is_list/1) do
      flatten(Enum.flat_map(list, &(&1)))
    else
      list
    end
  end
end
