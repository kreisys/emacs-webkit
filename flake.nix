{
  description = "Webkit Browser in Emacs";

  inputs.utils.url = "github:kreisys/flake-utils";

  outputs = { self, utils, nixpkgs }: utils.lib.simpleFlake {
    inherit nixpkgs;
    name = "emacs-webkit";
    overlay = final: prev: {
      emacsPackagesFor = emacs: (prev.emacsPackagesFor emacs).overrideScope'
        (final: prev: {
          emacs-webkit = final.callPackage ./package.nix {};
      });
    };

    packages = { emacsPackages }: rec {
      inherit (emacsPackages) emacs-webkit;
      defaultPackage = emacs-webkit;
    };
  };
}
