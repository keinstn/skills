---
name: flutter-ios-screenshots
description: Capture App Store screenshots of a Flutter app on an iOS simulator at the exact size App Store Connect requires. Use when asked to produce store/marketing screenshots for an iOS Flutter app (e.g. "App Store のスクリーンショットを撮って", "capture store screenshots on the simulator").
---

# Flutter iOS App Store Screenshots

Capture App Store screenshots of a Flutter app on an iOS simulator.

The 6.9" iPhone display App Store Connect asks for is **1320 × 2868** — an
iPhone 16/17 Pro Max class simulator. Capture with `xcrun simctl io <udid>
screenshot <path>`, which grabs the **full device screen including the status
bar**. A driver-side or in-app capture (Flutter's own screenshot,
`integration_test`'s `takeScreenshot`, marionette's screenshot) grabs only the
Flutter render surface and omits the status bar, so it can **never** produce the
required size. That is the most likely way to ship wrong-size assets. Check
every file with `sips -g pixelWidth -g pixelHeight <path>`.

Follow the steps in order — the locale change reboots the simulator, and a
reboot clears the status bar override.

## Step 1: Boot the simulator

Pick an iPhone 16/17 Pro Max class device (`xcrun simctl list devices
available`) and note its `<udid>`. Boot it.

## Step 2: Set the locale (if capturing a non-default language)

```sh
xcrun simctl spawn <udid> defaults write -g AppleLanguages -array <lang>
xcrun simctl spawn <udid> defaults write -g AppleLocale -string <locale>
xcrun simctl shutdown <udid> && xcrun simctl boot <udid>
```

The reboot is required to propagate the change.

## Step 3: Override the status bar

```sh
xcrun simctl status_bar <udid> override --time "9:41" \
  --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularBars 4 --dataNetwork wifi
```

`9:41` is Apple's marketing time. **Any shutdown/boot clears the override** —
re-apply it after every reboot, or the real clock lands in the asset.

## Step 4: Build and launch a debug build

Driving the app needs a VM service, which release builds don't expose — and if
the app only initialises its driver under `kDebugMode`, a profile build can't
be driven either. So capture from a debug build, and make sure the debug
artifacts are suppressed:

- `debugShowCheckedModeBanner: false` is **per `MaterialApp`, i.e. per
  entrypoint**. An app with a second entrypoint (a dev/preview harness beside
  `main.dart`) has its own `MaterialApp`; setting the flag in one leaves the
  DEBUG ribbon on captures from the other. The flag is a no-op in release
  builds, so setting it in all of them is safe.
- Capture from the **shipping entrypoint**, not a dev/preview harness. Harness
  fixture data — placeholder project names, hardcoded titles — otherwise ends
  up in the store listing.

Launch it the way your driver needs — `flutter run` prints the VM service URI;
`simctl launch <udid> <bundle-id>` starts an already-installed build.

**`terminate` before `launch`.** `simctl launch` on an already-running app just
refocuses the existing process, so you screenshot the **old binary** and
conclude your change didn't apply. Confirm the new build is live by looking for
a known token in the capture.

## Step 5: Drive the app

You need *some* driver to tap and scroll the running app. On Claude Code, use
`marionette_mcp` against the `ws://.../ws` Dart VM service URI that `flutter
run` prints; on other agents, use the equivalent. These gesture facts are
Flutter-level and apply to any driver:

- A drag that **starts inside a selectable text widget** is consumed by text
  selection and never reaches the enclosing scroll view. Start from a margin
  outside it.
- **Short drags are ignored**, below Flutter's gesture-recognizer threshold.
  Observed: ~150 logical px did nothing, ~430 px moved reliably. Treat these as
  observations, not parameters to copy — the threshold in practice depends on
  layout and screen size.
- A "scroll to this element" helper may work on message/body text but **fail on
  section headers** (surfaces as a driver error). Scroll to a body element near
  the target instead.
- **Verify by capturing and looking.** Never assume a scroll landed.

## Step 6: Compose the frame

A screen that auto-scrolls on open (e.g. to the newest content) can push what
you want to show out of frame. Set the scroll position deliberately before
capturing, then check the capture.

## Step 7: Capture

```sh
xcrun simctl io <udid> screenshot <repo>/<versioned-dir>/<name>.png
sips -g pixelWidth -g pixelHeight <repo>/<versioned-dir>/<name>.png
```

**Do not stage captures in a temp/scratch directory** — system temp gets
cleaned, and finished work goes with it (eight completed captures, in one real
case). Write straight into a versioned directory in the repo.

## Troubleshooting: no VM service URI / the device looks stuck

**A stray `flutter run` holds the device.** One started inside a git worktree
survives `git worktree prune` — the directory goes, the process doesn't — and
keeps holding the device, so a new session never prints a VM service URI and
looks like a hang.

```sh
pgrep -fl "flutter run"   # kill the strays
xcrun simctl terminate <udid> <bundle-id>
```

Then relaunch. The general lesson: **when removing a worktree, kill what you
started inside it first.**

## Note: automating this in CI

XCUITest-based capture (fastlane `snapshot`) *does* get the full device screen
including the status bar, but driving a Flutter app from XCUITest requires
semantics/accessibility identifiers wired through, and that navigation layer is
the expensive part — for a handful of captures a few times a year it rarely
pays.
