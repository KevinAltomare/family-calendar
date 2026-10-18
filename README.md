# Family Calendar

A Flutter family planner with calendar views, shared shopping and to-do lists,
and optional Firebase sync. Without Firebase configuration, the app continues
to use local device storage. With Firebase configured, family members sign in
with Google and changes sync through Cloud Firestore.

## Configure Firebase (one time)

This app is connected to the Firebase project `family-calendar-4850c`. The
Android and web apps are registered, the Firebase options are generated, and
the family-scoped Firestore security rules are deployed.

1. In Firebase console → **Authentication → Settings → Authorized domains**,
   make sure `family-calendar-4850c.web.app` is listed. Add it if missing.
   The authorized domain is a hostname only (no `https://` and no path).
   `localhost` is for local development.
2. Enable Google under **Authentication → Sign-in method**, if it is not
   already enabled.
3. In the Firebase console, open **Build → Firestore Database** (or
   **Databases & Storage → Firestore**) and choose **Create database**. Choose
   a location near your family; the database location cannot be changed later.
   Select **Production mode**, then **Create**. Production mode starts with
   client access denied until the app's family-only rules are deployed in a
   later step. Do not switch to open test rules.
4. For Google sign-in on Android, add the debug and release SHA-1 fingerprints
   to the Android app in Firebase. From the repository root, run
   `Set-Location android; .\gradlew signingReport; Set-Location ..` and add the
   fingerprints shown for the build variants you use. Re-run
   `flutterfire configure` after changing Firebase app registrations.

The following setup steps have already been completed for this project:

```text
Firebase project: family-calendar-4850c
Android app:      com.example.calendar_app
Web app:          registered
Firestore rules:  deployed
Web app URL:      https://family-calendar-4850c.web.app
```

The web deployment is ready. To rebuild/redeploy after code changes:

```powershell
flutter build web
firebase deploy --only hosting --project family-calendar-4850c
```

For iPhone Safari sign-in, the web Firebase options use the Hosting domain
`family-calendar-4850c.web.app` as `authDomain` so authentication stays
same-site in browsers that block third-party storage. Web sign-in uses a
popup, as recommended by Firebase for this setup. The Google OAuth web client
must also allow this redirect URI:

```text
https://family-calendar-4850c.web.app/__/auth/handler
```

In Google Cloud Console → **APIs & Services → Credentials**, edit the Web OAuth
client used by Firebase Authentication and add that value under **Authorized
redirect URIs**. If you run `flutterfire configure` again, restore
`authDomain: 'family-calendar-4850c.web.app'` in
`lib/firebase_options.g.dart` and redeploy Hosting.

For a new Firebase project, the full setup is:

1. Create a Firebase project in the [Firebase console](https://console.firebase.google.com/).
2. In **Authentication → Sign-in method**, enable **Google**. The authorized
   domain is the website address that will host the app (for example,
   `your-project-id.web.app`). You do not have to add it yet: Firebase gives
   you that address when you deploy Hosting. After deployment, open
   **Authentication → Settings → Authorized domains** and add the hostname
   only (no `https://` and no path) if it is not already listed. `localhost`
   is for local development.
3. In the Firebase console, open **Build → Firestore Database** (or
   **Databases & Storage → Firestore**) and choose **Create database**. Choose
   a location near your family; the database location cannot be changed later.
   Select **Production mode**, then **Create**. Production mode starts with
   client access denied until the app's family-only rules are deployed in a
   later step. Do not switch to open test rules.
4. Install the Firebase CLI without Node.js, then install FlutterFire CLI:

   ```powershell
   New-Item -ItemType Directory -Force "$env:LOCALAPPDATA\Firebase"
   Invoke-WebRequest -Uri https://firebase.tools/bin/win/latest -OutFile "$env:LOCALAPPDATA\Firebase\firebase.exe"
   dart pub global activate flutterfire_cli
   ```

   Use the regular `win/latest` download, not `win/instant/latest`.
   The instant bootstrap can fail while checking for updates on some Windows
   setups.

   Add `%LOCALAPPDATA%\Firebase` to your **user Path** in Windows Environment
   Variables (**Edit environment variables for your account** → select `Path`
   → **Edit** → **New**), then restart VS Code. Check that `firebase --version`
   works; then sign in and confirm your project is visible:

   ```powershell
   firebase login
   firebase projects:list
   ```

5. From the repository root (`C:\family-calendar`), configure Android and
   web. Replace `YOUR_FIREBASE_PROJECT_ID` with the **Project ID** shown in
   Firebase console → Project settings → General (it is not the display name):

   ```powershell
   dart pub global run flutterfire_cli:flutterfire configure --project YOUR_FIREBASE_PROJECT_ID --platforms android,web --out lib/firebase_options.g.dart
   ```

   When prompted, select the existing project. Register Android using the
   application ID shown in `android/app/build.gradle.kts`. FlutterFire replaces
   the placeholder Firebase options file; do not publish Firebase
   service-account credentials.
6. For Google sign-in on Android, add the debug and release SHA-1 fingerprints
   to the Android app in Firebase. From the repository root, run
   `Set-Location android; .\gradlew signingReport; Set-Location ..` and add the
   fingerprints shown for the build variants you use. Re-run
   `flutterfire configure` after changing Firebase app registrations.
7. Deploy this app's family-only Firestore rules, selecting your project ID:

   ```powershell
   firebase deploy --only firestore:rules --project YOUR_FIREBASE_PROJECT_ID
   ```

The first person to sign in creates the family and can choose to upload events
and list items already stored on that device. The app displays a 12-character
invite code in **Settings → Family Sync**. The other family member signs in
with their own Google account and joins using that code. Only authenticated
members can read or change the family's events and lists.

Joining with the same Google account that already created the family is safe;
the Firestore rules permit that membership operation to be retried without
changing the member list. If joining still fails, reload the hosted app and
note whether the message says it could not look up the invite or that Firebase
denied adding the account.

## Run on Android and web

```powershell
flutter run
flutter run -d chrome
```

The tablet can continue using the Android app. On each iPhone, open the hosted
web app in Safari, choose **Share → Add to Home Screen**, and sign in.

## Publish the web app

```powershell
flutter build web
firebase deploy --only hosting --project YOUR_FIREBASE_PROJECT_ID
```

The Hosting URL is `YOUR_FIREBASE_PROJECT_ID.web.app` (also available as
`YOUR_FIREBASE_PROJECT_ID.firebaseapp.com`). After deployment, make sure the
Hosting hostname appears under **Authentication → Settings → Authorized
domains**.
