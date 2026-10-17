defmodule Rivet.Ident.Test.NullTemplate do
  @moduledoc """

  This is a "look ahead" type module, since we are in a circular dependency
  with Mailer, we have to mock out some things knowing their shape.

  So this supports the shape of general Mailer template with .queue, and also
  the CriticalFail template

  """
  require Logger

  def queue(_), do: :ok
  def queue(_, _), do: :ok

  def report(msg, opts), do: report_(msg, opts)

  def report_(msg, opts) do
    Logger.error(msg, opts)
    {:error, msg}
  end

  def report_if_error({:error, e}, msg, opts) do
    report(msg, opts ++ [error: e])
    {:error, msg}
  end

  def report_if_error({:ok, _} = pass, _, _), do: pass

  def unattended_task(func), do: func.()
end
