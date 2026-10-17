defmodule Rivet.Ident.Test.NullTemplate do
  require Logger

  def queue(_), do: :ok
  def queue(_, _), do: :ok

  def report(msg, opts) do
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
