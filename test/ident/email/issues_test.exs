defmodule Rivet.Ident.Test.Email.IssuesTest do
  use Rivet.Ident.Case, async: true
  use Rivet.Ident
  alias Ident.Email.Issue

  test "model tests" do
    assert %Issue{id: id} = insert(:ident_email_issue)
    assert is_uuid(id)
    assert %Issue{id: ^id} = Issue.one!(id: id)
    params = params_with_assocs(:ident_email_issue)
    assert {:ok, %Issue{} = d} = Issue.create(params)
    assert {:ok, _} = Issue.delete(d)
  end

  test "add" do
    bogun_id = Ecto.UUID.generate()
    assert {:ok, %{value: :narf}} = Issue.log(bogun_id, :delivered, :narf)

    # insert good, verify email status changed
    e = insert(:ident_email, status: :verified)

    assert {:ok, %{issue_id}} = Issue.log(e.id, :bouncing, %{reason: "happy"})
    assert %{status: :bouncing, issues: [%{id: ^issue_id}]} = Email.one!([id: e.id], [:issues])

    # create w/bad email id
    log =
      ExUnit.CaptureLog.capture_log(fn ->
        assert {:ok, %{value: %{reason: "x"}}} = Issue.log(bogun_id, :bouncing, %{reason: "x"})
      end)

    assert log =~ ~r/Unexpected failure updating email status/
    assert log =~ ~r/Failed to add Email.Issue: email_id does not exist/
  end
end
