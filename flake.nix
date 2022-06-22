{
    description = "A near drop-in replacement for rm that uses the FreeDesktop trash bin.";

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
                    ronn
                ];

                buildPhase = "rake build:release";

                installPhase = ''
                    install -D -t $out/bin build/trash
                    mkdir -p $out/man/man1
                    ronn --roff --pipe MANUAL.md > $out/man/man1/trash.1
                '';
            };
        }
    );
}
