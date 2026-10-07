defmodule Rivet.Ident.Test.AccessTest do
  use Rivet.Ident.Case, async: true
  alias Rivet.Ident.Access

  test "model tests" do
    assert %Access{id} = insert(:ident_access)
    assert is_integer(id)
    assert %Access{id: ^id} = Access.one!(id: id)
    params = params_with_assocs(:ident_access)
    assert {:ok, %Access{} = x} = Access.create(params)
    assert {:ok, _} = Access.delete(x)
  end

  # describe "integration tests" do
  #   setup do
  #     user = insert(:user)
  #     project = insert(:project)
  #
  #     %{user: user, project: project}
  #   end
  #
  #   test "can use various shapes of access", %{user: user, project: project} do
  #     {:ok, access} = Access.Lib.add(user, :project_member, project.id)
  #     assert access.domain == User
  #     assert access.ref_id == project.id
  #
  #     # fails
  #     assert {:error, _} = Rivet.Auth.check_authz(user, @global_user_edit_assert)
  #
  #     # works on domain scope
  #     assert {:ok, user} =
  #              Rivet.Auth.check_authz(user, %Rivet.Db.Ident.Auth.Assertion{
  #                action: @project_edit_action,
  #                ref_id: project.id,
  #                domain: Rivet.Db.Project
  #              })
  #
  #     # now set superadmin and it should work globally too
  #     {:ok, _} = Db.Ident.Access.Lib.add(user, :superadmin)
  #
  #     assert {:ok, _} =
  #              Rivet.Auth.check_authz(
  #                %{user | authz: nil},
  #                @global_user_edit_assert,
  #                force: true
  #              )
  #   end
  # end
  #
  # test "Lib" do
  #   u = insert(:ident_user)
  #   new = MapSet.new([])
  #   assert ^new = Db.Ident.Access.Lib.get_actions(u, :global, Ecto.UUID.generate())
  # end
end
