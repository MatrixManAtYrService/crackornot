{
  description = "Hello world flake using uv2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, uv2nix, pyproject-nix, pyproject-build-systems }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        python = pkgs.python312;
        workspace = uv2nix.lib.workspace.loadWorkspace { 
          workspaceRoot = ./.;
        };

        overlay = workspace.mkPyprojectOverlay {
          sourcePreference = "wheel";
        };

        # Add test overrides
        pyprojectOverrides = final: prev: {
          hello-world = prev.hello-world.overrideAttrs (old: {
            passthru = old.passthru // {
              tests = let
                virtualenv = final.mkVirtualEnv "hello-world-test-env" {
                  hello-world = [ "test" ];
                };
              in (old.tests or { }) // {
                pytest = pkgs.stdenv.mkDerivation {
                  name = "${final.hello-world.name}-pytest";
                  inherit (final.hello-world) src;
                  nativeBuildInputs = [ virtualenv ];
                  dontConfigure = true;

                  buildPhase = ''
                    runHook preBuild
                    pytest tests/
                    runHook postBuild
                  '';

                  installPhase = ''
                    runHook preInstall
                    touch $out  # Just create an empty file to mark success
                    runHook postInstall
                  '';
                };
              };
            };
          });
        };

        pythonSet = (pkgs.callPackage pyproject-nix.build.packages {
          inherit python;
        }).overrideScope (
          nixpkgs.lib.composeManyExtensions [
            pyproject-build-systems.overlays.default
            overlay
            pyprojectOverrides
          ]
        );

        pythonEnv = pythonSet.mkVirtualEnv "hello-world-env" workspace.deps.default;
      in
      {
        packages = {
          default = pythonEnv;
        };

        apps = {
          default = {
            type = "app";
            program = "${pythonEnv}/bin/hello";
          };
        };

        # Add checks for testing
        checks = {
          inherit (pythonSet.hello-world.passthru.tests) pytest;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python312
            uv
            ruff
            python312Packages.python-lsp-ruff
            pyright
            nixpkgs-fmt
          ];
        };
      });
} 