defmodule Machine.Starter.Cache do
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

  def server_process({_mac_address, _broadcast_address} = address) do
    case start_child(address) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  defp start_child(address) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Machine.Starter.Server, address}
    )
  end
end
