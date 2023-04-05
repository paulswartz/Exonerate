defmodule :"const-const with true does not match 1-gpt-3.5" do
  def validate(const) when const === true do
    :ok
  end

  def validate(_) do
    :error
  end
end