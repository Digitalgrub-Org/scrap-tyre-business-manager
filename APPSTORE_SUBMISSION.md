# App Store submission runbook — Scrap Tyre Business Manager

How this Flutter app was set up for the Apple App Store: tools, the App Store
Connect API key, fastlane lanes, the build/signing pipeline, and every gotcha we
hit (with the fix). Written so another session can reproduce it end to end.

- **App:** Scrap Tyre Business Manager (Flutter)
- **Bundle id:** `com.digitalgrub.scrapTyreBusinessManager`
- **App Store Connect app id:** `6785265999`
- **Apple Team id:** `HYLU87Y7JM`
- **Primary language:** English (U.S.) (`en-US`)

---

## 0. Current status

Done (automated with the API key unless noted):
- App record created in App Store Connect (had to be done in the web UI — see Gotcha 1)
- Bundle id registered (via API)
- Listing text (name, subtitle, description, keywords, promo text, category, copyright, review contact)
- 5 iPhone screenshots, 6.9" (1320x2868)
- Export compliance declared in `Info.plist`
- Device family set to iPhone only
- Build 2 uploaded and `VALID` (build 1 had the touch bug; build 2 fixed it — see Gotcha 6)

Still required before "Submit for Review":
- Real app icon (the project still ships the **default Flutter icon** — Apple rejects this)
- Free pricing set
- Build attached to the 1.0 version
- Age rating questionnaire
- App Privacy ("data collection") questionnaire — this app collects nothing, stores data on device
- Replace placeholder support/privacy URLs with real ones (privacy URL is mandatory)

---

## 1. Machine prerequisites

| Tool | Version | Location |
|---|---|---|
| Homebrew | — | `/opt/homebrew` (Apple Silicon) |
| Flutter | 3.44.4 | `/Users/theone/development/flutter` |
| Xcode | 26.6 | `/Applications/Xcode.app` |
| CocoaPods | 1.16.2 | `/opt/homebrew/bin/pod` (Homebrew, uses its own Ruby) |
| fastlane | 2.236.1 | `/opt/homebrew/bin/fastlane` (Homebrew) |

PATH used for all build commands:
```bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/Users/theone/development/flutter/bin:$PATH"
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
```

**Point the toolchain at the full Xcode** (it was aimed at the Command Line Tools,
which have no iOS Simulator SDK and break native builds):
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
# verify (must print an SDK path, not an error):
xcrun --show-sdk-path --sdk iphonesimulator
```

You also need an **active Apple Developer Program membership** ($99/year) with the
agreements (License, Tax, Banking) signed in App Store Connect. Those are human only.

---

## 2. App Store Connect API key (the auth for everything)

The key is **account level** — one key works for every app under the account.

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API** (Team Keys)
2. Generate a key. Role: **Admin** (Admin is required to create apps and register identifiers; App Manager cannot).
3. Download the `.p8` (downloadable once). Note the **Key ID** and **Issuer ID**.

Store the secret **outside the repo**, in the shared location Apple tools auto detect:
```bash
mkdir -p ~/.appstoreconnect/private_keys
mv ~/Downloads/AuthKey_<KEYID>.p8 ~/.appstoreconnect/private_keys/
```

Expose the identifiers as env vars (the `.p8` is the only real secret):
```bash
export ASC_KEY_ID="<KEYID>"          # also the .p8 filename: AuthKey_<KEYID>.p8
export ASC_ISSUER_ID="<issuer-uuid>"
export ASC_TEAM_ID="HYLU87Y7JM"
```

> Never paste the `.p8` contents into chat or commit it. Only the file matters.

---

## 3. Repo layout (fastlane)

```
fastlane/
  Appfile                     # app_identifier
  Fastfile                    # lanes: create_app, upload_metadata, upload_screenshots, release
  .env.appstore.example       # env var template (no secrets)
  .gitignore                  # ignores *.p8, .env*, certs/, *.mobileprovision
  metadata/
    copyright.txt
    primary_category.txt      # value: BUSINESS
    en-US/                    # name, subtitle, description, keywords, promotional_text,
                              # release_notes, support_url, marketing_url, privacy_url
    review_information/       # first_name, last_name, phone_number, email_address, notes
  screenshots/en-US/          # PNGs; deliver maps them to device sizes by resolution
integration_test/screenshot_test.dart   # drives the app to capture screenshots
test_driver/integration_test.dart       # saves screenshots into fastlane/screenshots
```

Auth in the Fastfile is centralized in a helper that loads the API key from the env
vars + the shared `.p8`, so every lane reuses it.

---

## 4. The process, in order

### 4a. Register the bundle id (API — works)
The API **can** register a bundle id: `POST /v1/bundleIds`. We did this with a small
Ruby JWT script (ES256 signed with the `.p8`). Result: bundle id resource created.

### 4b. Create the app record (UI — required, see Gotcha 1)
In App Store Connect → **Apps** → **＋ New App**: iOS, name `Scrap Tyre Business
Manager`, primary language English (U.S.), pick the registered bundle id, SKU
`scrapTyreBusinessManager`.

### 4c. Upload listing text
```bash
fastlane upload_metadata
```
Uses `deliver` with the API key, `skip_binary_upload` + `skip_screenshots`.

### 4d. Screenshots (generated from the app)
Screenshots come from an **integration test** that drives the real app and a
**driver** that saves the PNGs — taps go through the Flutter widget tree, so no OS
level tapping is needed.
```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_test.dart \
  -d <iphone-pro-max-simulator-udid>     # 6.9" = 1320x2868 (required size)
fastlane upload_screenshots
```

### 4e. Build + sign + upload the binary
```bash
fastlane release
```
The `release` lane: `build_app` (gym) archives + exports an App Store `.ipa` with
**automatic signing** via the API key, then `upload_to_app_store` sends the binary.
Bump the build number first for each new upload (see Gotcha 7).

---

## 5. Gotchas and fixes (the important part)

**Gotcha 1 — The API cannot create an app.**
`POST /v1/apps` returns `403 FORBIDDEN_ERROR: The resource 'apps' does not allow
'CREATE'`. Apple blocks app creation via the public API for everyone. Options: the
web UI (what we used), or `fastlane produce` which uses your **Apple ID + 2FA**
(not the API key). The bundle id, metadata, screenshots, build, and submit are all
automatable; only the initial app record is not.

**Gotcha 2 — The app icon is not a separate upload.**
Apple extracts the 1024x1024 marketing icon from the **build's** asset catalog
(`ios/Runner/Assets.xcassets/AppIcon.appiconset/`). It must be 1024x1024, PNG, **no
alpha channel**, tagged `ios-marketing`. The icon appears on the app page only after
a build is processed. NOTE: this project still has the **default Flutter icon** on
both iOS and Android — it must be replaced before submission.

**Gotcha 3 — Review contact phone format.**
`deliver` failed with "The phone number must be in a valid format." Use
`+<countrycode> <number>` (e.g. `+91 9876543210`), not all zeros.

**Gotcha 4 — iPad screenshots.**
The app defaulted to `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad), which forces
an iPad screenshot set too. We set it to iPhone only (`"1"`) in
`ios/Runner.xcodeproj/project.pbxproj` to drop that requirement.

**Gotcha 5 — Signing with the API key (several traps).**
- `build_app` auto adds the API key auth flags to the **archive** step but **not**
  the **export** step. Pass them to export via `export_xcargs`:
  `-allowProvisioningUpdates -authenticationKeyPath <p8> -authenticationKeyID <id> -authenticationKeyIssuerID <iss>`.
  Passing them to archive too causes `error: option '-authenticationKeyPath' may
  only be provided once`.
- Do **not** set `CODE_SIGN_STYLE=Manual` / `PROVISIONING_PROFILE_SPECIFIER`
  globally via `xcargs` — it is applied to the Swift Package targets (share_plus,
  sqflite_darwin) which "do not support provisioning profiles" and the archive
  fails. If you must sign manually, use `export_options.provisioningProfiles`
  (per app), not global xcargs.
- "Provisioning profile doesn't include signing certificate ..." means a stale or
  revoked cert/profile is being reused. We cleaned the slate: revoked stray
  distribution certs (`DELETE /v1/certificates/{id}`), deleted the stale App Store
  profile (`DELETE /v1/profiles/{id}`), and removed the **orphaned local identity**
  from the login keychain:
  ```bash
  security find-identity -v -p codesigning           # find the SHA-1
  security delete-identity -Z <sha1> ~/Library/Keychains/login.keychain-db
  ```
  With nothing stale left, xcodebuild created a fresh cert + matching profile and
  export succeeded.

**Gotcha 6 — App opens but ignores all touch on iPhone Pro (the big one).**
On a 120Hz **ProMotion** iPhone (Pro/Pro Max) running **iOS 26**, the app rendered
but was completely unresponsive — no taps, no scrolling. Root cause: Flutter's newer
**implicit engine** has a buggy high refresh rate "touch rate correction" path that
runs **only on 120Hz displays** (so it never shows up in the 60Hz simulator or on non
Pro phones). Fix: cap the app to 60Hz so that path never starts, in
`ios/Runner/Info.plist`:
```xml
<key>CADisableMinimumFrameDurationOnPhone</key>
<false/>   <!-- was true; true = allow 120Hz, false = cap at 60Hz -->
```
60Hz is imperceptible for a business app; re enable once Flutter patches the engine.
Reference: flutter/flutter issue 183900.

**Gotcha 7 — Build numbers and the upload "false failure".**
- Each upload needs a unique build number. Bump `version:` in `pubspec.yaml`
  (e.g. `1.0.0+1` → `1.0.0+2`), then refresh the iOS config (gym reads it from
  `ios/Flutter/Generated.xcconfig`, and `flutter pub get` does **not** update it):
  ```bash
  flutter build ios --config-only --no-pub
  grep FLUTTER_BUILD_NUMBER ios/Flutter/Generated.xcconfig   # must show the new number
  ```
- altool may print `UPLOAD SUCCEEDED` and then a transient
  `-1005 network connection lost` on a final handshake, and fastlane reports a
  failure even though the binary uploaded. Verify the truth via the API:
  `GET /v1/builds?filter[app]=<appId>` — if the build shows `state=VALID`, it landed.

**Gotcha 8 — Running the app locally.**
- No macOS desktop target configured; Chrome web does not support `sqflite`
  (this app's database), so use an **iOS Simulator**.
- `flutter run` quits immediately in a non interactive shell (stdin EOF reads as
  "q"). For headless launching, use `flutter build ios --debug --simulator` then
  `xcrun simctl install <udid> <app>` + `xcrun simctl launch <udid> <bundleid>`.
- Demo data is seeded relative to the install date. To make dashboard/reports show
  "today", wipe the app's data so it reseeds:
  `xcrun simctl uninstall <udid> <bundleid>` before relaunch.

---

## 6. Quick reference

```bash
# env (every command)
export PATH="/opt/homebrew/bin:/usr/local/bin:/Users/theone/development/flutter/bin:$PATH"
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export ASC_KEY_ID=<KEYID> ASC_ISSUER_ID=<issuer-uuid> ASC_TEAM_ID=HYLU87Y7JM

cd <project-root>
fastlane upload_metadata        # listing text
fastlane upload_screenshots     # images from fastlane/screenshots
# bump pubspec version, then:
flutter build ios --config-only --no-pub
fastlane release                # build + sign + upload binary
```

Verify a build landed:
```bash
GET https://api.appstoreconnect.apple.com/v1/builds?filter[app]=6785265999
# (signed with an ES256 JWT from the .p8; look for state=VALID)
```
