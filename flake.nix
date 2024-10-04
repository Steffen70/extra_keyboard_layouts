{
  description = "A Nix Flake for Android Java app development.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils}:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

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

      in {
        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.git
            pkgs.scrcpy
          ] ++ buildDeps;

          shellHook = ''
            export ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk"
            export ANDROID_HOME="$ANDROID_SDK_ROOT"
            echo "ANDROID_SDK_ROOT set to $ANDROID_SDK_ROOT"

            # Add android tools and emulator to PATH
            export PATH="$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
          '';
        };

        packages = rec {
          default = buildRelease;

          buildRelease = pkgs.stdenv.mkDerivation {
            name = "extra_keyboard_layouts_release";
            buildInputs = buildDeps;
            src = ./.;

            buildPhase = ''
              gradle assembleRelease
              cp -r app/build/outputs/apk/release/*.apk $out
            '';
          };

          buildDebug = pkgs.stdenv.mkDerivation {
            name = "extra_keyboard_layouts_debug";
            buildInputs = buildDeps;
            src = ./.;

            buildPhase = ''
              gradle assembleDebug
              cp -r app/build/outputs/apk/debug/*.apk $out
            '';
          };
        };
      }
    );
}
