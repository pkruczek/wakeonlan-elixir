defmodule Machine.Starter.Supervisor do
  def start_link do
    Task.Supervisor.start_link(name: __MODULE__)
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Task.Supervisor,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end
end
