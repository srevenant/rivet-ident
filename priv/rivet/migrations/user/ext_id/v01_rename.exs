defmodule Rivet.Ident.User.ExtId.Migrations.V01Rename do
  @moduledoc false
  use Ecto.Migration

  def change do
    drop(index(:user_idents, [:origin, :ident]))

    flush()

    rename_table(:user_idents, :user_extids, indexes: [:user_id], fkeys: [:user_id])

    rename(table(:user_extids), :ident, to: :extid)
    create(unique_index(:user_extids, [:origin, :extid]))
  end

  ################ eventually delete once rivet utils is updated with MigraitonHelpers
  defp from_fields(opts) do
    src = Keyword.get(opts, :fields, Keyword.get(opts, :from))
    {src, Keyword.get(opts, :to, src)}
  end

  def rename_fkey(from_table_name, to_table_name, opts \\ []) do
    {from_field, to_field} = from_fields(opts)

    from_fkey = build_identifier(from_table_name, from_field, :fkey)
    to_fkey = build_identifier(to_table_name, to_field, :fkey)

    rename_constraint(from_table_name, from_fkey, to_fkey)
  end

  def rename_pkey(from_table_name, to_table_name) do
    from_pkey = build_identifier(from_table_name, nil, :pkey)
    to_pkey = build_identifier(to_table_name, nil, :pkey)

    rename_constraint(from_table_name, from_pkey, to_pkey)
  end

  def rename_sequence(from_table_name, to_table_name, fields: fields) do
    from_seq = build_identifier(from_table_name, fields, :seq)
    to_seq = build_identifier(to_table_name, fields, :seq)

    execute(
      "ALTER SEQUENCE #{from_seq} RENAME TO #{to_seq};",
      "ALTER SEQUENCE #{to_seq} RENAME TO #{from_seq};"
    )
  end

  def rename_index(table_name, opts),
    do: rename_index(table_name, table_name, opts)

  def rename_index(from_table_name, to_table_name, opts) do
    {from_fields, to_fields} = from_fields(opts)

    from_index = build_identifier(from_table_name, from_fields, :index)
    to_index = build_identifier(to_table_name, to_fields, :index)

    execute(
      ~s[ALTER INDEX #{from_index} RENAME TO #{to_index};],
      ~s[ALTER INDEX #{to_index} RENAME TO #{from_index}]
    )
  end

  def rename_table(src, dst, opts \\ []) do
    rename_pkey(src, dst)

    Keyword.get(opts, :indexes, [])
    |> Enum.each(fn i ->
      rename_index(src, dst, fields: i)
    end)

    Keyword.get(opts, :fkeys, [])
    |> Enum.each(fn i ->
      rename_fkey(src, dst, fields: i)
    end)

    src_t = table(src)
    dst_t = table(dst)
    rename(src_t, to: dst_t)
  end

  def rename_constraint(table, from, to) do
    execute(
      ~s[ALTER TABLE #{table} RENAME CONSTRAINT "#{from}" TO "#{to}";],
      ~s[ALTER TABLE #{table} RENAME CONSTRAINT "#{to}" TO "#{from}";]
    )
  end

  @max_identifier_length 63
  def build_identifier(table_name, field_or_fields, ending) do
    ([table_name] ++ List.wrap(field_or_fields) ++ List.wrap(ending))
    |> Enum.join("_")
    |> String.slice(0, @max_identifier_length)
  end
end
