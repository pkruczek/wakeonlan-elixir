defmodule Machine.Starter do
  @doc """
  Starts machine with given tuple address `{mac_address, broadcast}`.
  """
  @callback start({String.t(), String.t()}) :: boolean()

  def start({_mac_address, _broadcast_address} = address) do
    impl().start(address)
  end

  defp impl() do
    Application.get_env(:wakeonlan, :starter_impl, Machine.WolStarter)
  end
end

defmodule Machine.WolStarter do
  @behaviour Machine.Starter

  @impl true
  def start({_mac_address, _broadcast_address} = address) do
    address
    |> execute_start_command()
    |> is_success()
  end

  defp is_success({_, 0}), do: true
  defp is_success(_), do: false

  defp execute_start_command({mac_address, broadcast_address}) do
    System.cmd(start_command(), ["-i", broadcast_address, mac_address])
  end

  defp start_command do
    Application.get_env(:wakeonlan, :start_command, "wakeonlan")
  end
end
