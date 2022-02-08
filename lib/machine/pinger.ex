defmodule Machine.Pinger do

  def ping(address) do
    address
    |> execute_ping_command()
    |> is_success()
  end

  defp is_success({_, 0}), do: true
  defp is_success(_), do: false

  defp execute_ping_command(address) do
    System.cmd(ping_command(), ["-c", "1", address])
  end

  defp ping_command do
    Application.get_env(:wakeonlan, :ping_command, "ping")
  end

end
