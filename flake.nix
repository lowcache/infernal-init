{
  description = "volinit - Graphical shell initiation banner";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.buildNimPackage {
          pname = "volinit";
          version = "0.3.0";
          src = ./.;
          buildInputs = with pkgs; [ nim ];
          
          nimFlags = [
            "--d:release"
            "--opt:speed"
          ];
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/volinit";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ nim ];
        };
      });
}
