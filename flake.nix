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
          export PATH="$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/build-tools/33.0.1:$ANDROID_SDK_ROOT/platform-tools:$PATH"
        '';

      in
      {
        # Build apk via `gradle build` or `gradle assembleRelease`
        # - then zipalign the signed apk `zipalign -v 4 app-release-unsigned.apk swiss_keyboard_unsigned.apk`
        # - and finally sign the apk `apksigner sign --ks ~/.android/debug.keystore --ks-pass pass:android --key-pass pass:android --out swiss_keyboard.apk swiss_keyboard_unsigned.apk`

        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.nixfmt-rfc-style
            pkgs.git
            pkgs.scrcpy
          ] ++ buildDeps;

          shellHook = androidEnvSetup;
        };

        # TODO: Add package outputs for debug and release builds
      }
    );
}
