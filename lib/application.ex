defmodule Wakeonlan.Application do
  use Application

  def start(_type, _args) do
    children = [
      Machine.Registry,
      Machine.Pinger.Supervisor,
      Machine.Cache,
      Machine.Starter.Supervisor,
      Machine.Starter.Cache,
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
