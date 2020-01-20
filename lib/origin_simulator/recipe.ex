defmodule OriginSimulator.Recipe do
  defstruct origin: nil, body: nil, random_content: nil, headers: %{}, stages: [], route: nil

  @type t :: %__MODULE__{
          origin: String.t(),
          body: String.t(),
          random_content: String.t(),
          headers: map(),
          route: String.t()
        }

  @spec parse({:ok, binary(), any()}) :: binary()
  def parse({:ok, body, _conn}) do
    Poison.decode!(body, as: %__MODULE__{})
  end
end
