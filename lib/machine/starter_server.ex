defmodule Machine.Starter.Server do
  use GenServer, restart: :transient

  def start_link({_mac_address, _broadcast_address} = address) do
    GenServer.start_link(__MODULE__, address, name: via_tuple(address))
  end

  @impl true
  def init(address) do
    {:ok, %{address: address, task: nil}, get_process_timeout()}
  end

  def start_machine(pid) do
    GenServer.call(pid, :start_machine)
  end

  @impl true
  def handle_call(:start_machine, _, %{address: address, task: nil} = state) do
    task =
      Task.Supervisor.async_nolink(Machine.Starter.Supervisor, Machine.Starter, :start, [address])

    Process.send_after(self(), :start_timeout, get_start_timeout())
    {:reply, :ok, %{state | task: task}, get_process_timeout()}
  end

  @impl true
  def handle_call(:start_machine, _, %{task: _task} = state) do
    {:reply, :already_starting, state, get_process_timeout()}
  end

  @impl true
  def handle_info(:start_timeout, %{task: nil} = state) do
    {:noreply, state, get_process_timeout()}
  end

  @impl true
  def handle_info(:start_timeout, %{task: task} = state) do
    Process.exit(task.pid, :kill)
    {:noreply, state, get_process_timeout()}
  end

  @impl true
  def handle_info({ref, _result}, %{task: %{ref: ref}} = state) do
    Process.demonitor(ref, [:flush])
    {:noreply, %{state | task: nil}, get_process_timeout()}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{task: %{ref: ref}} = state) do
    # TODO: Log?
    {:noreply, %{state | task: nil}, get_process_timeout()}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  defp get_start_timeout do
    Application.get_env(:wakeonlan, :start_timeout, 2)
  end

  defp via_tuple(address) do
    Machine.Registry.via_tuple({__MODULE__, address})
  end

  defp get_process_timeout do
    Application.get_env(:wakeonlan, :starter_server_timeout, 20)
    |> :timer.seconds()
  end
end
