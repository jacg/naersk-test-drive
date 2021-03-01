{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
    mozillapkgs = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, naersk, mozillapkgs }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages."${system}";

      mozilla = pkgs.callPackage (mozillapkgs + "/package-set.nix") {};

      rust-stable = (mozilla.rustChannelOf {
        date = "2021-02-26"; # get the current date with `date -I`
        channel = "1.50.0";
        sha256 = "sha256-PkX/nhR3RAi+c7W6bbphN3QbFcStg49hPEOYfvG51l1=";
      }).rust;

      # Naersk requires nightly cargo
      rust-nightly = (mozilla.rustChannelOf {
        date = "2021-02-26"; # get the current date with `date -I`
        channel = "nightly";
        sha256 = "sha256-hTj47PwUeP276uF6+HLDzsHYoDvfJa+y9o+vmxZqV0g=";
      }).rust;

      # Override the version used in naersk
      naersk-lib = naersk.lib."${system}".override {
        cargo = rust-nightly;
        rustc = rust-stable;
      };
    in rec {
      # `nix build`
      packages.my-project = naersk-lib.buildPackage {
        pname = "my-project";
        root = ./.;
      };
      defaultPackage = packages.my-project;

      # `nix run`
      apps.my-project = utils.lib.mkApp {
        drv = packages.my-project;
      };
      defaultApp = apps.my-project;

      # `nix develop`
      devShell = pkgs.mkShell {
        # supply the specific rust version
        nativeBuildInputs = [ rust-stable ];
      };
    });
}
