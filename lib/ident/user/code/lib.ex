defmodule Rivet.Ident.UserCode.Lib do
  alias Rivet.Ident
  alias Ident.UserCode
  use Rivet.Ecto.Collection.Context, model: UserCode

  def reset_generate(for_user_id, type, meta \\ %{}) do
    clear_all_codes(for_user_id, type)
    expire = Application.get_env(:core, :user_code_expires)[type] || 60
    generate_code(for_user_id, type, expire, meta)
  end

  def generate_code(for_user_id, type, expiration_minutes, meta \\ %{}) when is_atom(type) do
    code =
      Ecto.UUID.generate()
      |> String.replace(~r/[-IO0]+/i, "")
      |> String.slice(1..8)
      |> String.upcase()

    case UserCode.one(code: code) do
      {:ok, _} ->
        generate_code(for_user_id, type, expiration_minutes)

      {:error, _} ->
        case UserCode.create(%{
               user_id: for_user_id,
               code: code,
               type: type,
               meta: meta,
               expires: DateTime.utc_now() |> DateTime.shift(minute: expiration_minutes)
             }) do
          {:ok, code} ->
            {:ok, code}

          {:error, chgset} ->
            IO.inspect(chgset, label: "Cannot generate code?")
            {:error, "cannot generate code"}
        end
    end
  end

  def get_valid(code) do
    with {:ok, code} <- UserCode.one(code: code) do
      if DateTime.before?(DateTime.utc_now(), code.expires) do
        {:ok, code}
      else
        {:error, "Code Expired"}
      end
    end
  end

  # housekeeper
  def clear_expired_codes() do
    now = DateTime.utc_now()

    from(c in UserCode, where: c.expires < ^now)
    |> Ident.UserCode.delete_all()
  end

  def clear_all_codes(for_user_id, type) do
    from(c in UserCode,
      where:
        c.user_id == ^for_user_id and
          c.type == ^type
    )
    |> Ident.UserCode.delete_all()
  end

  # ##############################################################################
  # def email_verify_code(code) when not_empty_str(code) do
  #   case UserCode.one(code: code) do
  #     {:ok, %{type: :email_verify, meta: %{"email_id" => eid}} = code} when is_uuid(eid) ->
  #       UserCode.delete(code)
  #
  #       url = Rivet.Mailer.Utils.Constants.frontend("/")
  #
  #       case Db.Ident.Email.one([id: eid], user: [:handle]) do
  #         {:ok, %{user} = email} ->
  #           uid = Rivet.Mailer.Utils.Constants.get_user_ref!(user)
  #           Db.Ident.Email.update(email, %{verified: true, status: :verified})
  #
  #           # if only identified redirect to password reset
  #           Logger.info("Email Verified", code: code.code, user: code.user_id)
  #
  #           Core.Mailer.Template.User.Verified.queue(user)
  #
  #           # the redirect isn't currently used; and may go away
  #           # if user.type == :authed do
  #           {:redirect, external: "#{url}/u/#{uid}/contact"}
  #
  #         # else
  #         #   {:redirect, external: "#{url}/u/#{uid}/password"}
  #         # end
  #
  #         _ ->
  #           {:error, "Email Verification Failed: cannot lookup by email_id"}
  #       end
  #
  #     _bad ->
  #       {:error, "Invalid EmailVerify Code code=#{code}"}
  #   end
  # end
end
