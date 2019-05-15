defmodule OriginSimulator.Simulation do
  use GenServer

  alias OriginSimulator.Payload

  ## Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: :simulation)
  end

  def state(server) do
    GenServer.call(server, :state)
  end

  def recipe(server) do
    GenServer.call(server, :recipe)
  end

  def add_recipe(server, new_recipe) do
    GenServer.call(server, {:add_recipe, new_recipe})
  end

  def restart do
    GenServer.stop(:simulation)
  end

  ## Server Callbacks

  @impl true
  def init(_) do
    {:ok, %{ recipe: nil, status: 406, latency: 0 }}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, { state.status, state.latency }, state}
  end

  @impl true
  def handle_call(:recipe, _from, state) do
    {:reply, state.recipe, state}
  end

  @impl true
  def handle_call({:add_recipe, new_recipe}, _caller, state) do
    Payload.fetch(:payload, new_recipe)

    Enum.map(new_recipe.stages, fn item ->
      Process.send_after(self(), {:update, item["status"], parse_latency(item["latency"])}, item["at"])
    end)

    {:reply, :ok, %{state | recipe: new_recipe }}
  end

  @impl true
  def handle_info({:update, status, latency}, state) do
    new_state = Map.merge(state, %{status: status, latency: latency})
    {:noreply, new_state}
  end

  defp parse_latency(latency) when is_binary(latency) do
    String.split(latency, "..")
    |> Enum.map(fn d -> process_duration(Integer.parse(d)) end)
  end

  defp parse_latency(latency) when is_integer(latency) do
    Integer.to_string(latency) |> parse_latency()
  end

  defp process_duration({duration, "ms"}), do: duration
  defp process_duration({duration, "s"}), do: duration * 1000
  defp process_duration({duration, ""}), do: duration
end
