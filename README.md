## Swiss German Keyboard Layout for Android (Quest 3)

This repository is a fork of `extra_keyboard_layouts`, modified to contain only the **Swiss German keyboard layout**. The purpose of this fork is to enable the use of a physical Swiss German keyboard over Bluetooth on devices like the Meta Quest 3.

### Features

-   **Swiss German Keyboard Layout**: Includes the official Android Swiss German `.kcm` file.
-   **Compatibility**: Allows you to connect a physical Swiss German keyboard via Bluetooth and use it on Android devices.
-   **Built-in Nix Flake for Reproducible Development**: This project includes a Nix flake that provides all the dependencies required to develop and build the APK.

### Installation Guide

#### Prerequisites

-   **Nix**: Make sure Nix is installed on your development machine. The flake setup is intended for a reproducible build environment.

#### Build Instructions

1. Clone this repository:

    ```sh
    git clone https://github.com/your-username/extra_keyboard_layouts.git
    cd extra_keyboard_layouts
    ```

2. Enter the development environment using Nix:

    ```sh
    nix develop
    ```

3. Build the APK:

    ```sh
    gradle build
    ```

    Alternatively, you can build the release version:

    ```sh
    gradle assembleRelease
    ```

4. Align the APK:

    ```sh
    zipalign -v 4 app/build/outputs/apk/release/app-release-unsigned.apk swiss_keyboard_unsigned.apk
    ```

5. Sign the APK:
    ```sh
    apksigner sign --ks ~/.android/debug.keystore --ks-pass pass:android --key-pass pass:android --out swiss_keyboard.apk swiss_keyboard_unsigned.apk
    ```

#### Install the APK

Use `adb` to install the signed APK to your Android device:

```sh
adb install swiss_keyboard.apk
```

### Connecting Your Physical Keyboard

After installing the app, connect your **physical Swiss German keyboard** to your device via Bluetooth. The installed layout will allow you to type in Swiss German without compatibility issues, even on a Meta Quest 3.

### Nix Flake Details

The Nix flake (`flake.nix`) provides:

-   **All Build Dependencies**: Includes Gradle, Android SDK, JDK 17, and tools like `zipalign` and `apksigner`.
-   **Simple Development Environment**: Use `nix develop` to enter a shell with everything you need to build and sign the APK.

### License

This project is licensed under the MIT License. See the original repository for more details.

### Credits

-   Forked from [`calin-darie/extra-keyboard-layouts`](https://github.com/calin-darie/extra-keyboard-layouts).
-   Updated to include the official Android Swiss German keyboard layout.
