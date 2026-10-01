defmodule Rivet.Ident.Email.Issue do
  use TypedEctoSchema
  use Rivet.Ecto.Model
  use Rivet.Ident
  import Rivet.Guards

  typed_schema "user_email_issues" do
    belongs_to(:email, Email, type: :binary_id)
    field(:type, Email.Status)
    field(:issue, :map)
    timestamps()
  end

  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: [:email_id, :type, :issue],
    update: [],
    foreign_keys: [:email_id]

  @fails [:bouncing, :complaint, :rejected]
  def log(email_id, type, issue) when type in @fails and is_uuid_shape?(email_id) do
    update_fail_status(email_id, type)

    attrs = %{email_id, type, issue}

    case create(attrs) |> critical_report_if_error("Failed to add Email.Issue", Map.to_list(attrs)) do
      {:ok, %{id: issue_id}} -> {:ok, %{issue_id}}
      {:error, _db_error_} -> {:ok, %{value: issue}}
    end
  end

  def log(_, _, value), do: {:ok, %{value}}

  ##############################################################################
  def update_fail_status(email_id, status) do
    from(e in Email, where: e.id == ^email_id)
    |> Repo.update_all(set: [status: status, verified: false])
    |> case do
      {1, _} -> :ok
      other -> critical_report("Unexpected failure updating email status", result: other)
    end
  end
end
