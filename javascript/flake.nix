{
  description = "A basic flake.nix for a Node.js project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs
            git
            nodePackages.npm

            # Add browser dependencies for Playwright
            webkitgtk
            gtk3
            glib
            xorg.libX11
            xorg.libXcomposite
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXrandr
            xorg.libxkbcommon
            xorg.libxcb
            xorg.libxshmfence
            nss
            alsa-lib
            at-spi2-atk
            cups
            expat
            libepoxy
            libdrm
            libgbm
            libudev0-shim
            libpulseaudio
            libnotify
            pango
          ];
          shellHook = ''
            if [ ! -d "node_modules" ]; then
              echo "node_modules not found. Running npm install..."
              npm install
            fi
            echo "Nix development shell is ready."
          '';
        };
      }
    );
}
