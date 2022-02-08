defmodule Machine.StateTest do
  use ExUnit.Case

  test "should create a new Machine.State" do
    created = Machine.State.new("172.16.0.1")

    assert created.address == "172.16.0.1"
    assert created.last_update <= :os.system_time(:seconds)
    assert created.enabled == false
  end

  test "should enable machine" do
    machine = Machine.State.new("172.16.0.1")
    enabled_machine = machine |> Machine.State.enable()

    assert enabled_machine == %Machine.State{machine | enabled: true}
  end

  test "should disable machine" do
    machine = Machine.State.new("172.16.0.1") |> Machine.State.enable()
    disabled_machine = machine |> Machine.State.disable()

    assert disabled_machine == %Machine.State{machine | enabled: false}
  end
end
