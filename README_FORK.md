# Diia Fork: no login + custom profile

This is a fork of [diia-open-source/ios-diia](https://github.com/diia-open-source/ios-diia)
modified for personal / educational use.

## What changed

1. **No login / no pincode / no biometry challenge.**
   The app boots straight into the main tab bar (Documents / Services / Feed / Menu).
   - `AppRouter.routeStart()` was simplified to open `MainTabBarModule` directly.
   - `AppDelegate.applicationWillEnterForeground` no longer re-presents the pincode screen.
   - `SettingsPresenter` no longer shows "Change pincode" / "Biometry" entries.

2. **A new "Profile" screen** accessible from `Menu → Settings → Профіль`.
   The Profile screen lets the user enter:
   - first name, last name, middle name
   - birth date (date picker)
   - city, phone, email
   - free-form "about me" text
   - avatar photo — picked from the camera or the photo library, cropped to a square,
     and stored as a JPEG inside the app's `Documents` directory.

   All profile data is stored locally (`UserDefaults` for text fields,
   `Documents/profile_avatar.jpg` for the photo). Nothing is uploaded anywhere.
   A "Clear all data" button wipes the local profile.

3. **Info.plist** has the required `NSCameraUsageDescription` and
   `NSPhotoLibraryUsageDescription` strings (in Ukrainian).

4. **A GitHub Actions workflow** at `.github/workflows/build-ipa.yml` builds
   an **unsigned `.ipa`** on every push. You download the artifact and sideload
   it locally (see below).

## How to get an installable `.ipa`

You do **not** need a Mac yourself — that's the whole point of the workflow.

1. Push this branch (`feature/no-auth-profile`) to your own GitHub fork.
2. Open the **Actions** tab → **"Build unsigned IPA"** workflow → pick the latest run.
3. Download the artifact called `DiiaOpenSource-unsigned-ipa`. Inside the ZIP you
   will find `DiiaOpenSource-unsigned.ipa`.
4. Sideload it onto your iPhone using one of:
   - **[Sideloadly](https://sideloadly.io/)** (Mac/Windows, free Apple ID, 7-day cert)
   - **[AltStore](https://altstore.io/)** (Mac/Windows, free Apple ID, 7-day cert, auto-refresh)
   - **TrollStore** (iOS 14–16.x with TrollStore-compatible core, no cert limit)
   - A paid Apple Developer account + iOS App Signer / `codesign` (1-year cert)

## If you want to build locally on a Mac

1. `git clone <your-fork>`
2. `open DiiaOpenSource.xcodeproj`
3. Wait for Swift Package Manager to resolve.
4. Select the `DiiaOpenSource` scheme + your iOS device.
5. Set a signing team in **Signing & Capabilities** (or use the same unsigned
   build trick the workflow uses).
6. Run.

## Project structure additions

```
DiiaOpenSource/
└── Modules/
    └── Profile/
        ├── ProfileModule.swift
        ├── ProfilePresenter.swift
        ├── ProfileStorage.swift
        ├── ProfileViewController.swift
        └── ProfileViewController.storyboard
```

All new files are referenced from `DiiaOpenSource.xcodeproj/project.pbxproj`
(see `scripts/add_profile_to_xcodeproj.py` if you ever need to re-add them).

## Files modified from upstream

| File | Change |
|---|---|
| `DiiaOpenSource/AppDelegate.swift` | Removed pincode-on-foreground and pincode-date bookkeeping |
| `DiiaOpenSource/AppRouter.swift` | `routeStart()` always opens `MainTabBarModule`, no auth check |
| `DiiaOpenSource/Modules/Menu/Settings/SettingsPresenter.swift` | Added "Профіль" row, removed pincode/biometry rows |
| `DiiaOpenSource/Info.plist` | Added `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` |
| `DiiaOpenSource/Modules/Profile/*` | New module |
| `DiiaOpenSource.xcodeproj/project.pbxproj` | References the new files |
| `.github/workflows/build-ipa.yml` | New CI build |

## Disclaimer

This fork is **not affiliated** with the Ministry of Digital Transformation of Ukraine.
It exists only for personal experimentation. Do not attempt to use any modified build
to interact with real Diia backend services — the official Diia backend will reject
requests that don't originate from a properly signed official client, and using
modified clients against state services may be illegal in your jurisdiction.
