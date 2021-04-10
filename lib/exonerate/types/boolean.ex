defmodule Exonerate.Types.Boolean do
  use Exonerate.Builder, []

  def build(_schema, path), do: %__MODULE__{
    path: path
  }

  defimpl Exonerate.Buildable do
    def build(%{path: spec_path}) do
      quote do
        defp unquote(spec_path)(value, _path) when not is_boolean(value) do
          Exonerate.Builder.mismatch(value, path, subpath: "type")
        end
        defp unquote(spec_path)(value, path), do: :ok
      end
    end
  end
end
