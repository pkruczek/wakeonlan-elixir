defmodule Machine.Pinger.Server do
  use GenServer, restart: :transient

  @impl true
  def init(address) do
    # TODO: maybe an Application.get_env
    :timer.send_interval(worker_interval(), self(), :tick)

    {:ok,
     %{
       address: address,
       task: nil,
       enabled: :undetermined,
       last_query_time: now()
     }, {:continue, :initial_ping}}
  end

  def start_link(address) do
    GenServer.start_link(
      __MODULE__,
      address,
      name: via_tuple(address)
    )
  end

  def enabled(pid) do
    GenServer.call(pid, :enabled)
  end

  @impl true
  def handle_call(:enabled, _, state) do
    {:reply, state.enabled, %{state | last_query_time: now()}}
  end

  @impl true
  def handle_continue(:initial_ping, %{address: address} = state) do
    {:noreply, %{state | task: start_pinger_task(address)}}
  end

  @impl true
  def handle_info(:tick, %{task: nil, address: address, last_query_time: last_query_time} = state) do
    unless timeout_exceeded?(last_query_time) do
      {:noreply, %{state | task: start_pinger_task(address)}}
    else
      {:stop, :normal, state}
    end
  end

  @impl true
  def handle_info(:tick, %{task: task} = state) do
    Process.exit(task.pid, :kill)
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {ref, result},
        %{task: %{ref: ref}} = state
      ) do
    Process.demonitor(ref, [:flush])
    {:noreply, %{state | enabled: result, task: nil}}
  end

  @impl true
  def handle_info(
        {:DOWN, ref, :process, _pid, _reason},
        %{task: %{ref: ref}} = state
      ) do
    {:noreply, %{state | enabled: false, task: nil}}
  end

  defp start_pinger_task(address) do
    Task.Supervisor.async_nolink(Machine.Pinger.Supervisor, Machine.Pinger, :ping, [address])
  end

  defp via_tuple(machine_address) do
    Machine.Registry.via_tuple({__MODULE__, machine_address})
  end

  defp timeout_exceeded?(last_query_time) do
    now() > last_query_time + worker_timeout()
  end

  defp worker_timeout do
    Application.get_env(:wakeonlan, :pinger_worker_timeout, 20)
    |> :timer.seconds()
  end

  defp worker_interval do
    Application.get_env(:wakeonlan, :pinger_worker_interval, 5)
    |> :timer.seconds()
  end

  defp now do
    :os.system_time(:millisecond)
  end
end
