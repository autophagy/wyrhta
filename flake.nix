{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    naersk.url = "github:nix-community/naersk/master";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, naersk }:
    utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
          naersk-lib = pkgs.callPackage naersk { };
        in
        rec {
          packages = {
            wyrhta = naersk-lib.buildPackage {
              root = ./.;
              doCheck = true;
            };
            default = packages.wyrhta;
          };

          devShell = with pkgs; mkShell {
            buildInputs = [ cargo rustc rustfmt rustPackages.clippy ];
            RUST_SRC_PATH = rustPlatform.rustLibSrc;
          };

          formatter = pkgs.nixpkgs-fmt;
        });
}
