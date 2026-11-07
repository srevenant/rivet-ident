defmodule Rivet.Ecto.SchemaExtensions do
  defmacro extend_fields(app, key) do
    app = Macro.expand(app, __CALLER__)
    key = Macro.expand(key, __CALLER__)

    fields = Application.compile_env(__CALLER__, app, key, [])

    for {kind, name, type, opts} <- fields do
      quote do
        unquote(kind)(unquote(name), unquote(type), unquote(Macro.escape(opts)))
      end
    end
    |> then(fn declarations ->
      quote do
        unquote_splicing(declarations)
      end
    end)
  end
end
