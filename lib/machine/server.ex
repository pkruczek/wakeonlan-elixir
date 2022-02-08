defmodule Machine.Server do
  use GenServer, restart: :transient

  @impl true
  def init(address) do
    # TODO: maybe an Application.get_env
    :timer.send_interval(:timer.seconds(5), self(), :tick)
    {:ok, %{address: address, task: nil, enabled: false}}
  end

  def start_link(address) do
    GenServer.start_link(
      __MODULE__,
      address,
      name: via_tuple(address)
    )
  end

  def enabled?(pid) do
    GenServer.call(pid, :enabled)
  end

  @impl true
  def handle_call(:enabled, _, state) do
    {:reply, state.enabled, state}
  end

  @impl true
  def handle_info(:tick, %{task: nil, address: address} = state) do
    task =
      Task.Supervisor.async_nolink(Machine.Pinger.Supervisor, Machine.Pinger, :ping, [address])

    {:noreply, %{state | task: task}}
  end

  @impl true
  def handle_info(:tick, %{task: task} = state) do
    Process.exit(task.pid, :kill)
    {:noreply, state}
  end

  @impl true
  def handle_info({ref, result}, %{task: %{ref: ref}} = state) do
    Process.demonitor(ref, [:flush])
    {:noreply, %{state | enabled: result, task: nil}}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{task: %{ref: ref}} = state) do
    # TODO: enabled: false?
    {:noreply, %{state | enabled: false, task: nil}}
  end

  defp via_tuple(machine_address) do
    Machine.Registry.via_tuple({__MODULE__, machine_address})
  end
end
