defmodule Machine.State do
  defstruct enabled: false, last_update: nil, address: nil

  def new(address) do
    %Machine.State{enabled: false, last_update: now(), address: address}
  end

  def enable(state) do
    %Machine.State{state | enabled: true, last_update: now()}
  end

  def disable(state) do
    %Machine.State{state | enabled: false, last_update: now()}
  end

  defp now() do
    :os.system_time(:seconds)
  end
end
