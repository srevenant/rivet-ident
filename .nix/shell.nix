let
  sources = import ./sources.nix;
  pkgs = import sources.nixpkgs {};
  erlang = pkgs.beam.packages.erlang;
  elixir = erlang.elixir;
  protocGenElixir = erlang.callPackage ./protobuf.nix { inherit (erlang) buildMix fetchHex mixRelease; };
in
with pkgs;
mkShell {
  buildInputs = [
    elixir
    pkgconfig
    protobuf
    protocGenElixir
  ];

  shellHook = ''
    # ERL_LIBS causes a load of compile warnings (warning: this clause cannot
    # match because of a previous clause at line 1 that always matches) in the
    # standard library. It appears to be because things are evaluated twice.
    # An actual export -n isn't inherited properly so we just set it blank.
    export ERL_LIBS=""
  '';

  ERL_AFLAGS = "-kernel shell_history enabled";

  ERL_INCLUDE_PATH = "${elixir}/lib/erlang/usr/include";
}
