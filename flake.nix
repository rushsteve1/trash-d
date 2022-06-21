{
    description = ''
        A near drop-in replacement for rm that uses the FreeDesktop trash bin.
        Written in the D programming language using only D's Phobos standard library, and can be compiled with any recent D compiler. This includes GCC, so `trash-d` should run on any *NIX platform that GCC supports.
    '';

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
            defaultPackage = pkgs.stdenv.mkDerivation {
                name = "trash-d";
                src = self;

                buildInputs = with pkgs; [
                    (dmd.overrideAttrs (old : {
                        doCheck = false;
                    }))
                    gcc
                    rake
                    dub
                ];

                buildPhase = "rake";

                installPhase = ''
                    mkdir -p $out/bin
                    install -t $out/bin build/trash
                '';
            };
        }
    );
}
