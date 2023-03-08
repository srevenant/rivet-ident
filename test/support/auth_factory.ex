defmodule Rivet.Ident.Test.AuthFactory do
  defmacro __using__(_) do
    quote location: :keep do
      alias Rivet.Ident

      ################################################################################
      def ident_action_factory do
        %Ident.Action{
          name: Rivet.Utils.Types.as_atom(sequence("action") <> "_edit"),
          description: Faker.Cat.name()
        }
      end

      ################################################################################
      def ident_role_factory do
        %Ident.Role{
          name: Rivet.Utils.Types.as_atom("#{sequence("role")}"),
          description: "#{sequence("role")} #{Faker.Cat.name()}"
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
      def ident_role_map_factory do
        action = build(:ident_action)
        role = build(:ident_role)

        %Ident.RoleMap{
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

      def ident_handle_factory do
        user = build(:ident_user)
        seq_id = sequence(:ident_handle, &"#{&1}")

        %Ident.Handle{
          user: user,
          handle: "user-#{seq_id}"
        }
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

      def ident_user_ident_factory do
        user = build(:ident_user)

        %Ident.UserIdent{
          ident: sequence("ident"),
          origin: Faker.Internet.domain_name(),
          user: user
        }
      end

      ################################################################################
      def ident_factor_factory do
        %Ident.Factor{
          user: build(:ident_user),
          type: :unknown,
          expires_at: Rivet.Utils.Time.epoch_time(:second) + 900
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

      def ident_user_code_factory do
        code =
          Ecto.UUID.generate()
          |> String.replace(~r/[-IO0]+/i, "")
          |> String.slice(1..8)
          |> String.upcase()

        %Ident.UserCode{
          user: build(:ident_user),
          type: :password_reset,
          code: code,
          expires: DateTime.from_unix!(Rivet.Utils.Time.epoch_time(:second) + 900)
        }
      end

      def ident_user_data_factory do
        user = build(:ident_user)

        %Ident.UserData{
          user: user,
          type: :available,
          value: %{}
        }
      end
    end
  end
end
