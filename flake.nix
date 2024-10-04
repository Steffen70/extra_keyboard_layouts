{
  description = "A Nix Flake for Android Java app development.";

  inputs = {
    # Use the unstable channel for the latest packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        unstable = import inputs.nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

        androidComposition = unstable.androidenv.composeAndroidPackages {
          platformVersions = [ "33" ];
          buildToolsVersions = [ "33.0.1" ];
          abiVersions = [ "x86_64" ];
          includeEmulator = true;
          includeSystemImages = true;
          systemImageTypes = [ "google_apis_playstore" ];
          includeExtras = [ "extras;google;gcm" ];
        };

        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell = unstable.mkShell {
          buildInputs = [
            unstable.git
            androidSdk
            unstable.jdk17
            unstable.gradle_7
            unstable.powershell
            unstable.scrcpy
          ];

          shellHook = ''
            export ANDROID_SDK_ROOT="${androidSdk}/libexec/android-sdk"
            export ANDROID_HOME="$ANDROID_SDK_ROOT"
            echo "ANDROID_SDK_ROOT set to $ANDROID_SDK_ROOT"

            # Add android tools and emulator to PATH
            export PATH="$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
          '';
        };
      }
    );
}
