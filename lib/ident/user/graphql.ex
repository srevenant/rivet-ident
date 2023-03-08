defmodule Rivet.Ident.User.Graphql do
  @moduledoc false
  use Absinthe.Schema.Notation
  alias Rivet.Ident
  import Ident.User.Resolver
  import Rivet.Graphql
  require Logger

  import_types(Ident.Access.Graphql)
  import_types(Ident.Factor.Graphql)
  import_types(Ident.Role.Graphql)

  @desc "An email address"
  object :email do
    field(:id, non_null(:string))
    field(:user_id, non_null(:string))
    field(:address, non_null(:string))
    field(:primary, non_null(:boolean))
    field(:verified, non_null(:boolean))
  end

  @desc "A phone number"
  object :phone do
    field(:id, non_null(:string))
    field(:user_id, non_null(:string))
    field(:number, non_null(:string))
    field(:primary, non_null(:boolean))
    field(:verified, non_null(:boolean))
  end

  ## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  @desc "A person (internal)"
  object :person do
    field(:id, :string)
    field(:name, :string)
    field(:last_seen, :datetime)
    field(:updated_at, :datetime)
    field(:inserted_at, :datetime)

    field :verified, :boolean do
      resolve(&resolve_verified_email/2)
    end

    field :handle, :string do
      resolve(&reduce_handle/2)
    end

    field :settings, :json do
      resolve(&resolve_settings/2)
    end

    field :emails, list_of(:email) do
      resolve(&resolve_emails/2)
    end

    field :phones, list_of(:phone) do
      resolve(&resolve_phones/2)
    end

    field :factors, list_of(:factor) do
      arg(:historical, :boolean, default_value: false)
      arg(:created, :boolean, default_value: false)
      arg(:type, :string)
      resolve(&resolve_factors/2)
    end

    field :access, :access do
      resolve(&resolve_access/2)
    end

    field :auth_status, :auth_status do
      # note: only when my_auth queried as user==connection_user
      resolve(&resolve_auth_status/2)
    end

    # field :tags, list_of(:tag_user) do
    # resolve(&TagResolver.resolve_tags/3)
    # end

    field :data, list_of(:user_data) do
      arg(:types, list_of(:string))
      resolve(&resolve_user_data/3)
    end
  end

  ## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  @desc "a person (public)"
  object :public_person do
    field(:id, non_null(:string))

    field(:name, :string)

    field(:last_seen, :datetime)
    field(:updated_at, :datetime)
    field(:inserted_at, :datetime)

    # todo: perhaps make this a primary value on the row
    field :verified, :boolean do
      resolve(&resolve_verified_email/2)
    end

    field :handle, :string do
      resolve(&reduce_handle/2)
    end

    # field :tags, list_of(:tag_user) do
    # resolve(&TagResolver.resolve_tags/3)
    # end

    field :data, list_of(:user_data) do
      arg(:types, list_of(:string))
      resolve(&resolve_public_user_data/3)
    end
  end

  ## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  object :user_data do
    field(:id, :string)
    field(:type, :user_data_types)
    field(:value, :json)
  end

  scalar :auth_domain do
    serialize(&Atom.to_string/1)
    parse(&parse_enum(&1, Ident.Access.Domains))
  end

  scalar :user_data_types do
    serialize(&Atom.to_string/1)
    parse(&parse_enum(&1, Ident.UserData.Types))
  end

  scalar :auth_status do
    description("""
    A token representing the status of the currently connected user's authentication
    """)

    serialize(&Atom.to_string/1)
    parse(&parse_enum(&1, Ident.User.Types))
  end

  object :public_person_result do
    field(:success, non_null(:boolean))
    field(:reason, :string)
    field(:result, :public_person)
  end

  object :person_result do
    field(:success, non_null(:boolean))
    field(:reason, :string)
    field(:result, :person)
  end

  object :public_people do
    field(:success, non_null(:boolean))
    field(:reason, :string)
    field(:total, :integer)
    field(:result, list_of(:public_person))
  end

  object :people do
    field(:success, non_null(:boolean))
    field(:reason, :string)
    field(:total, :integer)
    field(:result, list_of(:person))
  end

  input_object :people_filter do
    field(:name, :string)
    field(:handle, :string)
    field(:skills, list_of(:string))
    field(:types, list_of(:string))
    field(:roles, list_of(:string))
  end

  enum :user_change_actions do
    value(:upsert)
    value(:remove)
    # value(:verify)
    # value(:disable)
    # value(:enable)
  end

  input_object :input_person do
    field(:name, :string)
    field(:settings, :json)
    field(:disable, :boolean)
  end

  input_object :input_handle do
    field(:id, :string)
    field(:handle, :string)
  end

  input_object :input_email do
    field(:id, :string)
    field(:email, :string)
    field(:verify, :boolean)
  end

  input_object :input_phone do
    field(:id, :string)
    field(:phone, :string)
  end

  input_object :input_user_data do
    field(:id, :string)
    field(:type, non_null(:string))
    field(:value, non_null(:string))
  end

  input_object :input_role do
    field(:id, :string)
    field(:name, :string)
  end

  object :api_key do
    field(:key, non_null(:string))
    field(:secret, non_null(:string))
    field(:access, :string)
  end

  ##############################################################################
  object :user_queries do
    field :self, :person do
      resolve(&query_self/2)
    end

    field :people, :people do
      arg(:matching, :string)
      arg(:id, :string)
      resolve(&query_people/2)
    end

    field :public_person, :person_result do
      arg(:target, :string)
      arg(:id, :string)
      resolve(&query_public_person/2)
    end

    field :public_people, :public_people do
      arg(:filter, :people_filter)
      resolve(&query_public_people/2)
    end

    field :get_access, list_of(:string) do
      arg(:type, non_null(:auth_domain))
      arg(:ref_id, non_null(:string))
      resolve(&query_get_access/2)
    end
  end

  ##############################################################################
  object :user_mutations do
    # Only one change is allowed to change at a time, taken in order as shown
    field :update_person, type: :person_result do
      arg(:id, :string)
      arg(:action, :user_change_actions, default_value: :upsert)

      # action=UPSERT: id=nil, name="something"          <<create>>
      #      optional: settings
      # action=UPSERT: action=upsert, id="some id"       <<update>>
      #      optional: name, settings
      # action=DISABLE: id="some id"                     <<disable>>
      arg(:user, :input_person)
      # action=UPSERT: user_id="user id", handle: "name" <<change to this>>
      arg(:handle, :input_handle)
      # action=UPSERT: user_id="user id", email: "email@" << add this >>
      # action=REMOVE: user_id="user id", id: "email id"  << remove this >>
      # action=VERIFY: user_id="user id", id: "email id"  << send verification for this >>
      arg(:email, :input_email)
      # action=UPSERT: user_id="user id", phone: "555-.." << add this >>
      # action=REMOVE: user_id="user id", id: "email id"  << remove this >>
      arg(:phone, :input_phone)
      # action=UPSERT: user_id="user id", ...
      arg(:data, :input_user_data)
      arg(:role, :input_role)

      resolve(&mutate_update_person/2)
    end

    field :request_password_reset, :status_result do
      arg(:email, non_null(:string))
      resolve(&request_password_reset/2)
    end

    field :change_password, :status_result do
      arg(:current, non_null(:string))
      arg(:new, non_null(:string))
      arg(:email, :string)
      resolve(&mutate_change_password/2)
    end

    # field :update_role, type: :person_result do
    #   arg(:id, non_null(:string))
    #   arg(:role, non_null(:string))
    #   resolve(&mutate_update_role/2)
    # end

    field :gen_api_key, :api_key do
      resolve(&mutate_gen_apikey/2)
    end
  end
end
