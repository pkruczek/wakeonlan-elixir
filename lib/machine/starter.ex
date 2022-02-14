defmodule Machine.Starter do
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
