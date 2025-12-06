{
  description = "Advent of Code rust flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    process-compose-flake = {
      url = "github:Platonic-Systems/process-compose-flake";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      process-compose-flake,
      deploy-rs,
      disko,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      forAllSystems =
        function:
        nixpkgs.lib.genAttrs systems (
          system:
          function {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                rust-overlay.overlays.default
              ];
              config = {
                allowUnfree = true;
              };
            };
            inherit system;
            process-compose-lib = process-compose-flake.lib.${system};
          }
        );
    in
    {
      devShells = forAllSystems (
        { pkgs, process-compose-lib, ... }:
        {
          default =
            with pkgs;
            mkShell rec {
              name = "Advent of Code Rust devshell";

              motd = ''
                Welcome to the Advent of Code Rust environment.
              '';

              buildInputs = [
                # Rust toolchain
                (rust-bin.stable.latest.default.override {
                  extensions = [
                    "rust-src"
                    "rustfmt"
                    "clippy"
                  ];
                })

                # Development tools
                just
                eza
                fd

                # LSPs and formatters
                rust-analyzer
                taplo # TOML formatter
                rustfmt
              ];

              shellHook = ''
                alias ls=eza
                alias find=fd
              '';
            };
        }
      );
    };
}
