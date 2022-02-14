defmodule Machine.Server do
  use GenServer, restart: :transient

  @impl true
  def init(address) do
    # TODO: maybe an Application.get_env
    :timer.send_interval(get_process_timeout(), self(), :tick)

    {:ok,
     %{
       address: address,
       task: nil,
       enabled: false,
       listeners: %{},
       state_change_callback: fn _ -> :ok end
     }}
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

  def subscribe(pid) do
    GenServer.call(pid, :subscribe)
  end

  def register_callback(pid, callback) do
    GenServer.call(pid, {:register_callback, callback})
  end

  @impl true
  def handle_call(:enabled, _, state) do
    {:reply, state.enabled, state}
  end

  @impl true
  def handle_call(:subscribe, {pid, _}, %{listeners: listeners} = state) do
    if Map.has_key?(listeners, pid) do
      {:reply, :already_listener, state}
    else
      ref = Process.monitor(pid)
      {:reply, :ok, %{state | listeners: Map.put(listeners, pid, ref)}}
    end
  end

  @impl true
  def handle_call({:register_callback, callback}, _, state) do
    {:reply, :ok, %{state | state_change_callback: callback}}
  end

  @impl true
  def handle_info(:tick, %{listeners: listeners} = state) when map_size(listeners) == 0 do
    {:stop, :normal, state}
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
  def handle_info(
        {ref, result},
        %{task: %{ref: ref}, enabled: enabled, state_change_callback: state_change_callback} =
          state
      ) do
    Process.demonitor(ref, [:flush])

    if enabled != result do
      state_change_callback.(result)
    end

    {:noreply, %{state | enabled: result, task: nil}}
  end

  @impl true
  def handle_info(
        {:DOWN, ref, :process, _pid, _reason},
        %{task: %{ref: ref}, enabled: enabled, state_change_callback: state_change_callback} =
          state
      ) do
    # TODO: enabled: false?
    if enabled do
      state_change_callback.(false)
    end

    {:noreply, %{state | enabled: false, task: nil}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{listeners: listeners} = state) do
    {:noreply, %{state | listeners: Map.delete(listeners, pid)}}
  end

  defp via_tuple(machine_address) do
    Machine.Registry.via_tuple({__MODULE__, machine_address})
  end

  defp get_process_timeout do
    Application.get_env(:wakeonlan, :pinger_server_timeout, 5)
    |> :timer.seconds
  end
end
