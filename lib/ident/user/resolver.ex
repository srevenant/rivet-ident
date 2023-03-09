defmodule Rivet.Ident.User.Resolver do
  @moduledoc """
  GraphQL resolver for interacting with Rivet.Ident.User.
  """
  import Rivet.Graphql
  import Rivet.Auth.Graphql
  require Logger
  alias Rivet.Auth
  alias Rivet.Ident
  alias Ident.User

  @doc """
  If handle exists, put it in so the GraphQL query returns a string.
  """
  def reduce_handle(_args, %{source: %User{} = user}) do
    case User.preload(user, :handle, force: true) do
      {:ok, %User{handle: handle}} when not is_nil(handle) ->
        {:ok, handle.handle}

      {:ok, %User{}} ->
        {:ok, ""}

      error ->
        error
    end
  end

  def reduce_handle(_args, _info), do: {:ok, nil}

  def resolve_verified_email(_args, %{source: %User{} = user}) do
    case User.preload(user, :emails) do
      {:ok, %User{emails: emails}} ->
        if is_list(emails) do
          if Enum.find(emails, fn e -> e.verified end),
            do: {:ok, true},
            else: {:ok, false}
        else
          {:ok, false}
        end

      _ ->
        {:ok, false}
    end
  end

  def resolve_verified_email(_args, _) do
    {:ok, false}
  end

  @doc """
  Resolve the current user from context
  """
  def query_self(_args, info) do
    with_current_user(
      info,
      "self",
      fn current_user ->
        User.one(id: current_user.id)
      end,
      fn _ ->
        Logger.info("query self when not signed in")
        {:error, "not signed in"}
      end
    )
  end

  ##############################################################################
  defp user_edit_allowed(args, info) do
    with {:ok, user} <- current_user(info) do
      target_id = Map.get(args, :id)

      if not is_nil(target_id) and user.id == target_id do
        graphql_log("updatePerson(self)")
        {:ok, user, :self, target_id}
      else
        with {:ok, user} <-
               Auth.authz_action(
                 info,
                 %Auth.Assertion{action: :user_admin},
                 "updatePerson(other)"
               ) do
          {:ok, user, :admin, target_id}
        end
      end
    end
    |> case do
      {:ok, actor, type, target_id} when is_binary(target_id) ->
        case User.one(id: target_id) do
          {:ok, user} ->
            {:ok, actor, type, user}

          {:error, _} ->
            {:error, "User not found"}
        end

      pass ->
        pass
    end
  end

  def mutate_update_person(args, info) do
    with {:ok, _actor, type, target} <- user_edit_allowed(args, info),
         {:ok, %User{} = u} <- User.Lib.Update.update(args, type, target) do
      {:ok, %{success: true, result: u}}
    end
    |> graphql_status_result()
  end

  ##############################################################################
  def resolve_emails(_args, %{source: %User{} = user}) do
    {:ok, User.preload!(user, :emails).emails}
  end

  # if not authed
  def resolve_emails(_args, _info), do: {:ok, nil}

  def resolve_phones(_args, %{source: %User{} = user}) do
    {:ok, User.preload!(user, :phones).phones}
  end

  # if not authed
  def resolve_phones(_args, _info), do: {:ok, nil}

  ##############################################################################
  # created=true means use whatever is preloaded on the user struct. This is
  # used with creating a new user, where a generated password is inserted into
  # the struct as a factor.
  def resolve_factors(%{created: true}, %{source: source}), do: {:ok, source.factors}

  def resolve_factors(%{historical: true}, %{source: %User{} = user}) do
    {:ok, User.preload!(user, :factors).factors}
  end

  def resolve_factors(%{type: type}, %{source: %User{id: user_id} = user})
      when not is_nil(user_id) do
    {:ok, Ident.Factor.Lib.all_not_expired!(user, type)}
  end

  def resolve_factors(_, %{source: %User{id: user_id} = user}) when not is_nil(user_id) do
    {:ok, Ident.Factor.Lib.all_not_expired!(user)}
  end

  def resolve_factors(_args, _info), do: {:ok, nil}

  ##############################################################################
  def resolve_access(_args, %{source: %User{} = user}) do
    user = User.Lib.get_authz(user)

    {:ok,
     %{
       # only give global, call get_access for additional detail
       actions:
         MapSet.to_list(user.authz)
         |> Enum.reduce([], fn
           {act, :global, _}, acts -> [act | acts]
           _, acts -> acts
         end),
       roles:
         Enum.map(user.accesses, fn access ->
           Ident.Access.preload!(access, :role).role.name
         end)
     }}
  end

  def resolve_access(_args, _info), do: {:ok, %{roles: [], actions: []}}

  def query_get_access(%{type: type, ref_id: ref_id}, %{context: %{user: %User{} = u}}) do
    {:ok,
     MapSet.to_list(u.authz)
     |> Enum.reduce([], fn
       {act, ^type, ^ref_id}, acts -> [act | acts]
       _, acts -> acts
     end)}
  end

  def query_get_access(_, _), do: {:error, "Unauthenticated"}

  ##############################################################################
  defp ecto_query_to_result({:ok, result}, total),
    do: {:ok, %{success: true, result: result, total: total}}

  defp ecto_query_to_result({:error, chgset}, _total),
    do: {:ok, %{success: false, reason: error_string(chgset)}}

  def resolve_settings(_, %{source: %User{} = user}) do
    {:ok, user.settings}
  end

  def resolve_settings(_, _), do: {:ok, %{}}

  def query_people(%{id: id}, info) when is_binary(id) do
    with {:ok, _} <- Auth.authz_action(info, %Auth.Assertion{action: :user_admin}, "listPeople"),
         {:ok, user} <- User.one(id: id) do
      {:ok, %{success: true, total: 1, result: [user]}}
    else
      _ -> {:ok, %{success: false}}
    end
  end

  def query_people(%{matching: matching}, info) when is_binary(matching) do
    if String.length(matching) == 0 do
      query_people(%{}, info)
    else
      with {:ok, admin} <-
             Auth.authz_action(info, %Auth.Assertion{action: :user_admin}, "listPeople") do
        matching = "%" <> matching <> "%"

        User.Lib.Search.search(%{matching: matching, limit: 25}, admin)
        |> ecto_query_to_result(User.count!())
      end
    end
  end

  def query_people(%{}, info) do
    with {:ok, _admin} <-
           Auth.authz_action(info, %Auth.Assertion{action: :user_admin}, "listPeople") do
      User.all([], limit: 25)
      |> ecto_query_to_result(User.count!())
    end
  end

  ##############################################################################
  # private
  def query_public_people(%{filter: %{name: name} = filter}, info) when is_binary(name) do
    if Application.get_env(:rivet_ident, :public_people) do
      with_current_user(info, "listPublicPeople", fn user ->
        matches =
          case Ident.Handle.one([handle: name], [:user]) do
            {:ok, handle} ->
              [handle.user]

            _ ->
              []
          end

        with {:ok, result} <-
               User.Lib.Search.search(filter, user) do
          mapped = (matches ++ result) |> Enum.reduce(%{}, fn m, acc -> Map.put(acc, m.id, m) end)
          {:ok, Map.values(mapped)}
        end
      end)
    else
      Logger.warn("Query for public people ignored <disabled by system config>")
      {:error, :authz}
    end
    |> graphql_status_result
  end

  ##############################################################################
  def query_public_person(%{target: handle}, _info) do
    if Application.get_env(:rivet_ident, :public_people) do
      case Ident.Handle.one([handle: handle], [:user]) do
        {:ok, handle} ->
          {:ok, %{success: true, result: handle.user}}

        {:error, _} ->
          {:ok, %{success: false, reason: "cannot find user #{handle}"}}
      end
    else
      Logger.warn("Query for public person ignored <disabled by system config>")
      {:error, :authz}
    end
  end

  ##############################################################################
  def request_password_reset(%{email: eaddr}, _info) when is_binary(eaddr) do
    if Application.get_env(:rivet_ident, :password_user_reset) do
      eaddr = String.trim(eaddr)
      Logger.info("password reset request", eaddr: eaddr)

      case Ident.Email.one([address: eaddr], [:user]) do
        {:ok, %Ident.Email{} = email} ->
          if User.enabled?(email.user) do
            Ident.Email.Lib.send_reset_code(email)
          else
            Logger.info("Ignoring attempt to reset disabled user", uid: email.user.id)
          end

        _ ->
          :ok
      end

      {:ok, %{success: true}}
    else
      {:ok, %{success: false, reason: "feature disabled"}}
    end
  end

  ##############################################################################
  # need to throttle this ... (behind Hammer)
  def mutate_change_password(%{current: c, new: n, email: ""}, info),
    do: mutate_change_password(%{current: c, new: n}, info)

  def mutate_change_password(%{new: new, code: code}, _info) do
    with {:ok, %Ident.UserCode{} = code} <- Ident.UserCode.one([code: code], [:user]),
         true <- Auth.change_password(code, new) do
      Ident.UserCode.delete(code)
      {:ok, %{success: true}}
    else
      _ ->
        {:ok, %{success: false, reason: "reset code does not match"}}
    end
  end

  def mutate_change_password(%{current: current, new: new}, info) do
    with_current_user(info, "changePassword(change)", fn user ->
      # pass to authX module; accept reset code in lieu of password
      if Auth.change_password(user, current, new) do
        {:ok, %{success: true}}
      else
        {:ok, %{success: false, reason: "current password or reset code do not match"}}
      end
    end)
  end

  ##############################################################################
  def mutate_gen_apikey(%{}, %{context: %{hostname: hostname}} = info) do
    with_current_user(info, "genApikey", fn user ->
      validation =
        case Ident.Factor.all(user_id: user.id, type: :valtok, name: "generated apikey") do
          {:ok, [validation | _]} ->
            validation

          {:ok, []} ->
            generate_new_validation(user, hostname)
        end

      token = Auth.Token.Access.jwt(%Ident.Factor{validation | user: user}, hostname)

      {:ok, valtok, _, validation} =
        Auth.Token.Validation.jwt(validation, hostname, %{"t" => "refresh"})

      secret =
        %{
          sub: "cas2:#{valtok}",
          aud: "caa1:val:#{hostname}",
          sec: validation.value
        }
        |> Jason.encode!()
        |> Base.encode32(padding: false, case: :lower)
        |> random_upper()

      {:ok, %{key: validation.id, secret: secret, access: token}}
    end)
  end

  def generate_new_validation(user, hostname) do
    {:ok, _token, _secret, validation} =
      Auth.Token.Validation.jwt(user, hostname, %{"t" => "refresh"})

    {:ok, validation} = Ident.Factor.update(validation, %{name: "generated apikey"})
    validation
  end

  defp random_upper(str) do
    for <<x <- str>>, into: "" do
      if :rand.uniform(2) == 1 do
        String.upcase(<<x>>)
      else
        <<x>>
      end
    end
  end

  ##############################################################################
  def resolve_auth_status(_, %{
        source: %User{id: user_id1} = src,
        context: %{user: %User{id: user_id2} = user}
      }) do
    if user_id1 == user_id2 do
      {:ok, user.type}
    else
      with {:ok, _authed} <- Auth.authz_action(user, %Auth.Assertion{action: :user_admin}) do
        {:ok, src.type}
      else
        _ ->
          {:ok, :unknown}
      end
    end
  end

  def resolve_auth_status(_, _) do
    {:ok, :unknown}
  end

  ##############################################################################
  # todo: add in types filter
  @public_allowed %{profile: true, toggles: true}
  def resolve_public_user_data(src, args, info) do
    with {:ok, data} <- resolve_user_data(src, args, info) do
      {:ok,
       Enum.filter(data, fn elem ->
         ## TODO: use a switch to further filter things like address,
         ## after moving toggle for hiding or not onto address
         not is_nil(Map.get(@public_allowed, elem.type))
       end)}
    end
  end

  def resolve_user_data(%User{} = user, %{types: types}, _) do
    {:ok, Ident.UserData.Lib.list_types(user, types)}
  end

  def resolve_user_data(%User{} = user, _, _) do
    case User.preload(user, :data) do
      {:ok, %User{data: nil}} -> {:ok, []}
      {:ok, %User{data: data}} -> {:ok, data}
    end
  end

  def resolve_user_data(_, _, _) do
    {:error, nil}
  end
end
