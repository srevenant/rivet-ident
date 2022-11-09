{ buildMix, erlang, fetchFromGitHub, fetchHex, mixRelease }:
mixRelease {
  pname = "protoc-gen-elixir";
  version = "0.9.0";
  src = fetchFromGitHub {
    owner = "elixir-protobuf";
    repo = "protobuf";
    rev = "v0.9.0";
    sha256 = "QicwaPxGNkBnUWpJgDSYP2Y9XYnYma4mfjppscO0Kws=";
  };

  propagatedBuildInputs = [ erlang ];

  mixEnv = "prod";

  mixNixDeps = rec {
    decimal = buildMix rec {
      name = "decimal";
      version = "2.0.0";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0xzm8hfhn8q02rmg8cpgs68n5jz61wvqg7bxww9i1a6yanf6wril";
      };

      beamDeps = [];
    };

    jason = buildMix rec {
      name = "jason";
      version = "1.2.2";

      src = fetchHex {
        pkg = "${name}";
        version = "${version}";
        sha256 = "0y91s7q8zlfqd037c1mhqdhrvrf60l4ax7lzya1y33h5y3sji8hq";
      };

      beamDeps = [ decimal ];
    };
  };

  postBuild = ''
    mix escript.build --no-deps-check
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp protoc-gen-elixir $out/bin/
  '';

  dontCheck = true;
}
