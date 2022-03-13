defmodule Machine.PingerTest do
  use ExUnit.Case

  import Mox

  setup :set_mox_from_context

  test "returns :undetermined when ping has not been performed yet" do
    stub(Machine.MockPinger, :ping, fn _ -> true end)
    enabled =
      Machine.Pinger.Cache.server_process("172.16.15.15")
      |> Machine.Pinger.Server.enabled()

    assert enabled == :undetermined
  end

  test "ping" do
    parent_pid = self()
    ref = make_ref()

    expect(Machine.MockPinger, :ping, fn _ ->
      send(parent_pid, {ref, :ping})
      true
    end)

    pinger_server = Machine.Pinger.Cache.server_process("172.16.15.225")
    assert_receive {^ref, :ping}

    assert Machine.Pinger.Server.enabled(pinger_server) == true
    verify!()
  end

  test "termination after timeout" do
    timeout = Application.get_env(:wakeonlan, :pinger_worker_timeout, 100)

    stub(Machine.MockPinger, :ping, fn _ -> true end)

    first_pid = Machine.Pinger.Cache.server_process("10.0.0.1")

    Process.sleep(2 * timeout)

    second_pid = Machine.Pinger.Cache.server_process("10.0.0.1")

    assert first_pid != second_pid
  end

  test "multiple calls to Pinger.Server should not cause multiple pings" do
    expect(Machine.MockPinger, :ping, 1, fn _ -> false end)
    pinger_server = Machine.Pinger.Cache.server_process("10.0.0.2") 

    enabled_list = for _ <- 1..3, do: Machine.Pinger.Server.enabled(pinger_server)

    for result <- enabled_list do
        assert undetermined_or_false(result)
    end

    verify!()
  end

  defp undetermined_or_false(term) do
    term == false || term == :undetermined
  end
end
