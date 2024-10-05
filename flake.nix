{
  description = "A Nix Flake for Android Java app development.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

        projectVersion = "1.0.0";

        androidComposition = pkgs.androidenv.composeAndroidPackages {
          platformVersions = [ "33" ];
          buildToolsVersions = [ "33.0.1" ];
          abiVersions = [ "x86_64" ];
          includeEmulator = true;
          includeSystemImages = true;
          systemImageTypes = [ "google_apis_playstore" ];
          includeExtras = [ "extras;google;gcm" ];
        };

        androidSdk = androidComposition.androidsdk;

        # Define build dependencies to be reused
        buildDeps = [
          pkgs.gradle_7
          androidSdk
          pkgs.jdk17
        ];

        # Define reusable Android environment setup
        androidEnvSetup = ''
          export ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk"
          export ANDROID_HOME="$ANDROID_SDK_ROOT"
          echo "ANDROID_SDK_ROOT set to $ANDROID_SDK_ROOT"

          # Add android tools and emulator to PATH
          export PATH="$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
        '';

      in
      {
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.nixfmt-rfc-style
            pkgs.git
            pkgs.scrcpy
          ] ++ buildDeps;

          shellHook = androidEnvSetup;
        };

        # Run dependency resolution package seperately and disable sandboxing so gradle can fetch the required dependencies
        # nix build .#gradleDependencies --option sandbox false

        # Build the release and debug APKs
        # nix build
        # nix build .#buildDebug
        packages = rec {
          default = buildRelease;

          gradleDependencies = pkgs.stdenv.mkDerivation {
            __noChroot = true;
            pname = "gradle_dependencies";
            version = projectVersion;
            src = ./.;

            outputHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: This is a dummy hash - replace after first run with the actual hash
            buildInputs = buildDeps;

            buildPhase = ''
              ${androidEnvSetup}
              export GRADLE_USER_HOME=$out
              gradle --no-daemon --refresh-dependencies --info dependencies
            '';
          };

          buildRelease = pkgs.stdenv.mkDerivation {
            name = "extra_keyboard_layouts_release";
            version = projectVersion;
            buildInputs = buildDeps;
            src = ./.;

            buildPhase = ''
              ${androidEnvSetup}
              export GRADLE_USER_HOME=${self.packages.gradleDependencies}
              gradle --no-daemon --offline assembleRelease
              cp -r app/build/outputs/apk/release/*.apk $out
            '';
          };

          buildDebug = pkgs.stdenv.mkDerivation {
            name = "extra_keyboard_layouts_debug";
            version = projectVersion;
            buildInputs = buildDeps;
            src = ./.;

            buildPhase = ''
              ${androidEnvSetup}
              export GRADLE_USER_HOME=${self.packages.gradleDependencies}
              gradle --no-daemon --offline assembleDebug
              cp -r app/build/outputs/apk/debug/*.apk $out
            '';
          };
        };
      }
    );
}
