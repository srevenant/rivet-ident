defmodule Cato.Data.Auth.Test.AuthFactory do
  use ExMachina.Ecto, repo: Cato.Data.Repo
  alias Cato.Data.Auth

  defmacro __using__(_) do
    quote location: :keep do
      ################################################################################
      def action_factory do
        %Auth.Action{
          name: Utils.Types.to_atom(sequence("action") <> "_edit"),
          description: Faker.Cat.name()
        }
      end

      ################################################################################
      def role_factory do
        %Auth.Role{
          name: Utils.Types.to_atom("#{sequence("role")}"),
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
        %Auth.Tenant{}
      end

      ################################################################################
      def user_factory do
        %Auth.User{
          tenant: build(:tenant),
          type: :authed,
          name: "#{Faker.Person.first_name()} #{Faker.Person.last_name()}",
          settings: %{cat: Faker.Cat.name()}
        }
      end

      def handle_factory do
        user = build(:user)
        tenant = build(:tenant)
        seq_id = sequence(:handle, &"#{&1}")

        %Auth.UserHandle{
          user: user,
          tenant: tenant,
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
        tenant = build(:tenant)

        %Auth.UserEmail{
          user: user,
          tenant: tenant,
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
          expires_at: Utils.Time.epoch_time(:second) + 900
        }
      end

      ################################################################################
      # separate factory because hashing is expensive, and we only need this for a few
      # tests.  With it on everything it is slow. -BJG
      #
      # TODO: it shouldn't be necessary to hash it here, but the factory is bypassing
      # the Ecto module
      def hashpass_factor_factory do
        pass = Utils.RandChars.random()

        %Auth.Factor{
          user: build(:user),
          type: :password,
          password: pass,
          hash: Utils.Hash.password(pass),
          expires_at: Utils.Time.epoch_time(:second) + 900
        }
      end

      ################################################################################
      def setting_group_factory do
        tenant = build(:tenant)

        %Auth.SettingGroup{
          tenant: tenant,
          name: sequence("setting.group"),
          help: "this is the parent for a group of settings"
        }
      end

      def setting_global_factory do
        group = build(:setting_group)

        %Auth.SettingGlobal{
          group: group,
          name: sequence("setting.global"),
          help: "this is a global setting",
          value: %{}
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
