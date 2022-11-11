defmodule Rivet.Data.Auth.Test.AuthFactory do
  use ExMachina.Ecto, repo: Rivet.Data.Repo
  alias Rivet.Data.Auth

  defmacro __using__(_) do
    quote location: :keep do
      ################################################################################
      def action_factory do
        %Auth.Action{
          name: Rivet.Utils.Types.as_atom(sequence("action") <> "_edit"),
          description: Faker.Cat.name()
        }
      end

      ################################################################################
      def role_factory do
        %Auth.Role{
          name: Rivet.Utils.Types.as_atom("#{sequence("role")}"),
          description: "#{sequence("role")} #{Faker.Cat.name()}"
        }
      end

      ################################################################################
      def access_factory do
        user = build(:user)
        role = build(:role)

        %Auth.Access{
          user: user,
          role: role,
          domain: :global
        }
      end

      ################################################################################
      def role_map_factory do
        action = build(:action)
        role = build(:role)

        %Auth.RoleMap{
          action: action,
          role: role
        }
      end

      ################################################################################
      def account_factory(args) do
        %Auth.Account{}
      end

      ################################################################################
      def user_factory do
        %Auth.User{
          type: :authed,
          name: "#{Faker.Person.first_name()} #{Faker.Person.last_name()}",
          settings: %{cat: Faker.Cat.name()}
        }
      end

      def handle_factory do
        user = build(:user)
        seq_id = sequence(:handle, &"#{&1}")

        %Auth.UserHandle{
          user: user,
          handle: "user-#{seq_id}"
        }
      end

      def phone_factory do
        user = build(:user)

        %Auth.UserPhone{
          user: user,
          number: Faker.Phone.EnUs.phone(),
          primary: false,
          verified: false
        }
      end

      def email_factory do
        user = build(:user)

        %Auth.UserEmail{
          user: user,
          address: Faker.Internet.email(),
          primary: false,
          verified: false
        }
      end

      ################################################################################
      def factor_factory do
        %Auth.Factor{
          user: build(:user),
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
      def hashpass_factor_factory do
        pass = Rivet.Utils.RandChars.random()

        %Auth.Factor{
          user: build(:user),
          type: :password,
          password: pass,
          hash: Rivet.Utils.Hash.password(pass),
          expires_at: Rivet.Utils.Time.epoch_time(:second) + 900
        }
      end

      def user_data_factory do
        user = build(:user)

        %Auth.UserData{
          user: user,
          type: :available,
          value: %{}
        }
      end
    end
  end
end
