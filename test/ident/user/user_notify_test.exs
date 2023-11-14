defmodule Rivet.Ident.Test.UserNotifyTest do
  use Rivet.Ident.Case, async: true
  alias Rivet.Ident.User.Notify

  @templates %{
    Notify.UserFailedChange => %{
      assigns: %{action: "reset"},
      template: ~S"""
      === rivet-template-v1
      sections:
        subject: eex
        body: eex
      === subject
      <%= @site.org_name %> Account Change Failed
      === body
      <p>
      We recently received a request to <%= @action %>, but it was unsuccessful.
      <p>
      If you did not request this change, you can ignore this email and nothing
      will change.
      <p>
      <%= @site.email_sig %>
      """
    },
    Notify.PasswordChanged => %{
      assigns: %{},
      template: ~S"""
      === rivet-template-v1
      sections:
        subject: eex
        body: eex
      === subject
      <%= @site.org_name %> email notification - password changed
      === body
      <p>
      The account at <%= @site.org_name %> associated with this email had its password
      changed.
      <p>
      <%= @site.email_sig %>
      """
    },
    Notify.PasswordReset => %{
      assigns: %{reqaddr: "me", code: "code"},
      template: ~S"""
      === rivet-template-v1
      sections:
        subject: eex
        body: eex
      === subject
      <%= @site.org_name %> Password Reset
      === body
      <% link = "#{@site.link_front}/pwreset/#{@code}" %>
      <p>
      We recently received a request to a password on an email associated with
      your account (<%= @reqaddr %>). If you initiated this request, you can reset
      your password with this one-time-use code by clicking the Reset Password
      link:
      <p>
      <a href="<%= link %>">Reset Password</a>
      <p>
      If you are unable to view or click the link in this message, copy the
      following URL and paste it in your browser:
      <p><code><%= link %></code>
      <p>
      This reset code will expire in 1 hour.
      <p>
      If you did not request this change, you can ignore this email and your
      password will not be changed.
      <p>
      <%= @site.email_sig %>
      """
    },
    Notify.UserVerification => %{
      assigns: %{code: "code"},
      template: ~S"""
      === rivet-template-v1
      sections:
        subject: eex
        body: eex
      === subject
      <%= @site.org_name %> email verification
      === body
      <p>
      This email was added to an account at <%= @site.org_name %>.  However, it is not yet
      verified.  Please verify this email address by clicking the Verify link:
      <p>
      <a href="<%= @site.link_back %>/ev?code=<%= @code %>">Verify</a>
      <p>
      If you are unable to view or click the link in this message, copy the
      following URL and paste it in your browser:
      <p><code><%= @site.link_back %>/ev?code=<%= @code %></code>
      <p>
      This verification code will expire in 1 day.
      <p>
      <%= @site.email_sig %>
      """
    }
  }

  @site_data %{
    link_front: "http://localhost:3000",
    link_back: "http://localhost:4000",
    org_name: "Cato Digital",
    email_from: "noreply@cato.digital",
    email_sig: "Cato Digital"
  }

  test "notify" do
    eaddr = insert(:ident_email)

    for {template, %{template: data, assigns: assigns}} <- @templates do
      assert {:ok, %{body: _, subject: _}} =
               template.eval(data, eaddr, Map.put(assigns, :site, @site_data))
    end
  end
end
