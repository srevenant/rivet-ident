defmodule Rivet.Ident.Role do
  @moduledoc """

  - Ident.Actions describe specific actions a user may take.
  - Ident.Actions are mapped to Roles through Ident.Role.Map.
  - Ident.Actions may be shared across many Roles, which is why authorization
    code should be checking actions, not roles.
  - Ident.Roles are mapped to users through Ident.Access

  - Ident.Access can be mapped in one of two ways: associated to a domain,
    or global. A domain is another object somewhere else identified by a uuid.
    Typically these are records in your database, such as an Organization, or
    a Project.

    A system exists through actions where you can have a fallback to a global
    permission, so if you have a :org_change action, and it is typically mapped
    to a %Db.Org{} object through its domain, but you also have a sysadmin role
    that has a global form of :org_change, then sysadmins may still access things
    checking for :org_change.
    
  """
  use TypedEctoSchema
  use Rivet.Ecto.Model, id_type: :intid

  typed_schema "ident_roles" do
    field(:name, Rivet.Ecto.Atom)
    field(:domain, Rivet.Ident.Access.Domains, default: :global)
    field(:description, :string)

    many_to_many(:actions, Rivet.Ident.Action,
      join_through: Rivet.Ident.Role.Map,
      unique: true
    )
  end

  use Rivet.Ecto.Collection,
    not_found: :atom,
    required: [:name, :description],
    update: [:description, :name, :domain]
end
