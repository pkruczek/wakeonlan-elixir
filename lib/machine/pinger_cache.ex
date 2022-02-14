defmodule Machine.Pinger.Cache do
  def start_link do
    DynamicSupervisor.start_link(
      name: __MODULE__,
      strategy: :one_for_one
    )
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def server_process(machine_address) do
    case start_child(machine_address) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  defp start_child(machine_address) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Machine.Pinger.Server, machine_address}
    )
  end
end
