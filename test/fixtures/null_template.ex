defmodule Rivet.Ident.Test.NullTemplate do
  @moduledoc """

  This is a "look ahead" type module, since we are in a circular dependency
  with Mailer, we have to mock out some things knowing their shape.

  So this supports the shape of general Mailer template with .queue, and also
  the CriticalFail template

  """
  require Logger

  # used for test callbacks where desired
  @listener {__MODULE__, :listener}
  def listen(pid \\ self()), do: Process.put(@listener, pid)

  defp test_callback(hook, args) do
    if pid = Process.get(@listener) do
      IO.inspect({hook, args}, label: "SENDING")
       send(pid, {hook, args})
     end
  end

  # could instrument more callbacks here if/when desired
  def queue(_), do: :ok
  def queue(_, _), do: :ok

  def report(msg, opts), do: report_(msg, opts)

  def report_(msg, opts) do
    test_callback(:report_, {msg, opts})
    Logger.error(msg, opts)
    {:error, msg}
  end

  def report_if_error({:error, e}, msg, opts) do
    test_callback(:report_if_error, {e, msg, opts})
    report(msg, opts ++ [error: e])
    {:error, msg}
  end

  def report_if_error({:ok, _} = pass, _, _), do: pass

  def unattended_task(func), do: func.()

  #
end
