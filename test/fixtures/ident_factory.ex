defmodule Rivet.Ident.Test.IdentFactory do
  defmacro __using__(_) do
    quote location: :keep do
      use Rivet.Ident
      alias Rivet.Ident

      ################################################################################
      def ident_action_factory do
        %Ident.Action{
          name: Transmogrify.As.as_atom!(sequence("action") <> "_edit"),
          description: Faker.Cat.name()
        }
      end

      ################################################################################
      def ident_access_factory do
        user = build(:ident_user)
        role = build(:ident_role)

        %Ident.Access{
          user: user,
          role: role,
          domain: :global
        }
      end

      ################################################################################
      def ident_role_factory do
        %Ident.Role{
          name: Transmogrify.As.as_atom!("#{sequence("role")}"),
          description: "#{sequence("role")} #{Faker.Cat.name()}"
        }
      end

      ################################################################################
      def ident_role_map_factory do
        action = build(:ident_action)
        role = build(:ident_role)

        %Ident.Role.Map{
          action: action,
          role: role
        }
      end

      ################################################################################
      def ident_user_factory do
        %Ident.User{
          type: :authed,
          name: "#{Faker.Person.first_name()} #{Faker.Person.last_name()}",
          settings: %{cat: Faker.Cat.name()}
        }
      end

      def ident_user_extid_factory do
        %Ident.User.ExtId{
          origin: Faker.Internet.domain_name(),
          extid: sequence("user_extid"),
          user: build(:ident_user)
        }
      end

      def verify_email_code_factory do
        %{id, user} = insert(:ident_email, verified: false)

        %Ident.User.Code{
          user: user,
          type: :email_verify,
          code: sequence(Ecto.UUID.generate() |> String.slice(0, 7)),
          meta: %{"email_id" => id},
          expires: DateTime.utc_now() |> DateTime.shift(day: 1)
        }
      end

      defp gen_handle(), do: String.slice(sequence("h") <> Ecto.UUID.generate(), 0..29)

      def ident_handle_factory do
        %Ident.Handle{user: build(:ident_user), handle: gen_handle()}
      end

      def ident_phone_factory do
        user = build(:ident_user)

        %Ident.Phone{
          user: user,
          number: Faker.Phone.EnUs.phone(),
          primary: false,
          verified: false
        }
      end

      def ident_email_factory do
        user = build(:ident_user)

        %Ident.Email{
          user: user,
          address: Faker.Internet.email(),
          primary: false,
          verified: false
        }
      end

      def ident_email_issue_factory do
        %Ident.Email.Issue{
          email: build(:ident_email),
          type: :bouncing,
          issue: %{"message" => "ugly"}
        }
      end

      def auth_domain_signin_factory(args) do
        handle =
          case args do
            %{handle} when not_empty_str(handle) -> handle
            _ -> gen_handle()
          end

        args = Map.delete(args, :handle)

        %Rivet.Auth.Domain{
          input: %{
            handle,
            email: %{address: Faker.Internet.email()},
            secret: "BigPassword98!?"
          }
        }
        |> merge_attributes(args)
      end

      ################################################################################
      def ident_factor_factory do
        %Ident.Factor{
          user: build(:ident_user),
          type: :unknown,
          expires_at: Rivet.Utils.Time.epoch_time(:second) + 900
        }
      end

      def ident_factor_federated_factory do
        %Ident.Factor{
          user: build(:ident_user),
          type: :federated,
          fedtype: :google,
          name: Ecto.UUID.generate(),
          expires_at: Rivet.Utils.Time.epoch_time(:second) + 900,
          details: %{sub: Ecto.UUID.generate()}
        }
      end

      def ident_factor_google_factory do
        %Ident.Factor.FedId{
          name: "fedid" <> Ecto.UUID.generate(),
          handle: gen_handle(),
          email: %Ident.Factor.FedId.Email{
            address: Ecto.UUID.generate() <> Faker.Internet.email(),
            verified: false
          },
          provider: %Ident.Factor.FedId.Provider{
            type: :google,
            # set extra high so our limit kicks in on tests
            exp: Rivet.Utils.Time.epoch_time(:second) + 86400 * 400
            # sub: payload["sub"],
            # jti: payload["jti"],
            # iss: payload["iss"],
            # iat: payload["iat"],
            # azp: payload["azp"],
            # aud: payload["aud"],
            # token: payload["token"]
          }
        }
      end

      ################################################################################
      # separate factory because hashing is expensive, and we only need this for a few
      # tests.  With it on everything it is slower -BJG
      #
      # TODO: it shouldn't be necessary to hash it here, but the factory is bypassing
      # the Ecto module
      def ident_hashpass_factor_factory do
        pass = Ident.Factor.Password.generate()

        %Ident.Factor{
          user: build(:ident_user),
          type: :password,
          password: pass,
          hash: Ident.Factor.Password.hash(pass),
          expires_at: Rivet.Utils.Time.epoch_time(:second) + 900
        }
      end

      def ident_user_data_factory do
        user = build(:ident_user)

        %Ident.User.Data{
          user: user,
          type: :address,
          value: %{}
        }
      end

      def ident_user_code_factory do
        code =
          Ecto.UUID.generate()
          |> String.replace(~r/[-IO0]+/i, "")
          |> String.slice(1..8)
          |> String.upcase()

        %Ident.User.Code{
          user: build(:ident_user),
          type: :password_reset,
          code: code,
          expires: DateTime.utc_now() |> DateTime.shift(minute: 10)
          # expires: DateTime.from_unix!(Rivet.Utils.Time.epoch_time(:second) + 900)
        }
      end
    end
  end
end
