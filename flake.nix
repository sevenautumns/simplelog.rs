{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "git+https://github.com/numtide/flake-utils.git";
    devshell.url = "github:numtide/devshell";
    fenix = {
      url = "git+https://github.com/nix-community/fenix.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      url = "git+https://github.com/nix-community/naersk.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, utils, naersk, devshell, ... }@inputs:
    utils.lib.eachSystem [ "x86_64-linux" "i686-linux" "aarch64-linux" ] (system:
      let
        lib = nixpkgs.lib;
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ devshell.overlays.default ];
        };

        # Rust distribution for our hostSystem
        fenix = inputs.fenix.packages.${system};

        rust-toolchain = with fenix;
          combine [
            latest.rustc
            latest.cargo
            latest.clippy
            latest.rustfmt
          ];
      in
      rec {
        # a devshell with all the necessary bells and whistles
        devShells.default = (pkgs.devshell.mkShell {
          imports = [ "${devshell}/extra/git/hooks.nix" ];
          name = "simplelog-dev-shell";
          packages = with pkgs; [
            stdenv.cc
            coreutils
            rust-toolchain
            rust-analyzer
            cargo-outdated
            cargo-udeps
            cargo-watch
            cargo-expand
            nixpkgs-fmt
            nodePackages.prettier
          ];
        });

        # always check these
        checks = {
          nixpkgs-fmt = pkgs.runCommand "nixpkgs-fmt"
            {
              nativeBuildInputs = [ pkgs.nixpkgs-fmt ];
            } "nixpkgs-fmt --check ${./.}; touch $out";
        };
      });
}

