# Calendar App

A Flutter calendar app with a dark-themed monthly view and a screen for each day.

## Run on Android

1. Start an Android emulator or connect an Android device.
2. From this directory, run:

   ```powershell
   flutter pub get
   flutter run
   ```

The Android project configuration is in `android/`. The app source code is in
`lib/`.

If Gradle reports that it cannot delete files under `build/`, move the project
to a local folder outside OneDrive and build it there; cloud sync can lock
generated build files.
