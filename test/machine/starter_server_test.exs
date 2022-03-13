defmodule Machine.StarterTest do
  use ExUnit.Case

  import Mox

  setup :set_mox_from_context

  test "machine start" do
    parent_pid = self()
    ref = make_ref()

    machine_start_addres = {"11:22:33:44:55:66", "172.16.0.255"}

    expect(Machine.MockStarter, :start, fn start_address ->
      send(parent_pid, {ref, :start})
      assert start_address == machine_start_addres
      true
    end)

    starter_pid = Machine.Starter.Cache.server_process(machine_start_addres)
    Machine.Starter.Server.start_machine(starter_pid)

    assert_receive {^ref, :start}

    verify!()
  end

  test "rate limiting" do
    parent_pid = self()
    ref = make_ref()

    machine_start_address = {"00:22:33:44:55:66", "172.16.0.255"}

    expect(Machine.MockStarter, :start, 1, fn start_address ->
      send(parent_pid, {ref, :start_machine})
      assert start_address == machine_start_address
      true
    end)

    starter_pid = Machine.Starter.Cache.server_process(machine_start_address)

    for _ <- 1..5 do
      Machine.Starter.Server.start_machine(starter_pid)
    end

    assert_receive {^ref, :start_machine}
  end

  test "termination after timeout" do
     timeout = Application.get_env(:wakeonlan, :starter_server_timeout, 200) 
     machine_start_address = {"00:11:22:44:55:66", "172.16.0.255"}

     first_starter = Machine.Starter.Cache.server_process(machine_start_address)

     Process.sleep(timeout * 2)

     second_starter = Machine.Starter.Cache.server_process(machine_start_address)

     assert first_starter != second_starter
     assert !Process.alive?(first_starter)
  end
end
