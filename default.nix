let
  nixpkgs = import <nixpkgs> {};
  inherit (nixpkgs) stdenv fetchurl which;

  myenv = stdenv.mkDerivation rec {
    name = "env";
  
    buildInputs = with nixpkgs; [
      nixpkgs.opam
      nixpkgs.gmp
      nixpkgs.openssl
      nixpkgs.pkg-config
      ocamlPackages.utop
      ocamlPackages.ocaml_pcre
      ocamlPackages.base
      ocamlPackages.core
      ocamlPackages.dune_2
      ocamlPackages.async
      ocamlPackages.yojson
      ocamlPackages.menhir
      ocamlPackages.core_extended
      ocamlPackages.core_bench
      ocamlPackages.bisect_ppx
      ocamlPackages.fmt
      ocamlPackages.ocaml-lsp
    ];
  
  };
in myenv
