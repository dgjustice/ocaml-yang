let
  nixpkgs = import <nixpkgs-unstable> {};
  inherit (nixpkgs) stdenv fetchurl which;
  unpackPhase = "true";

  myenv = stdenv.mkDerivation rec {
    name = "env";
  
    buildInputs = with nixpkgs; [
      nixpkgs.opam
      nixpkgs.ocaml
      nixpkgs.ocamlformat
      nixpkgs.gmp
      nixpkgs.openssl
      nixpkgs.pkg-config
      ocamlPackages.findlib
      ocamlPackages.utop
      ocamlPackages.base
      ocamlPackages.core
      ocamlPackages.dune_2
      ocamlPackages.menhir
      ocamlPackages.uutf
      ocamlPackages.ppx_jane
      ocamlPackages.ppx_tools_versioned
      # Testing deps
      ocamlPackages.ounit2
      ocamlPackages.bisect_ppx
      ocamlPackages.ocaml-lsp
    ];
  
  };
in myenv
