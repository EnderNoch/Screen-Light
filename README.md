# ScreenLight

A tiny macOS app that turns your Mac's screen into a controllable fill light (a "softbox"
for video calls). Pick a brightness and a color, hit **Light / Światło**, and the whole
screen fills with that color at the brightness you chose. Tap **any key or the trackpad** to
go back to the options.

## Features

- **Brightness slider** 0–100 with tick notches at 0 / 25 / 50 / 75 / 100.
- **Light / Światło** button sets the Mac's real backlight and shows a fullscreen color.
- **Color** picker (white by default, or any custom color).
- **Dismiss** by pressing any key, a modifier, or clicking/tapping the trackpad — this
  returns to the options screen and **restores your previous brightness**.
- **Launch at login** toggle so the options screen is ready on startup.
## Download

Download the ScreenLight.zip file and open it and move to Applications folder

## Build

Requires the Swift toolchain (Command Line Tools or Xcode):

```bash
chmod +x build.sh   # first time only
./build.sh
```

This compiles the sources and assembles `ScreenLight.app` (ad-hoc signed).

## Run

```bash
open ScreenLight.app
```

### First launch (Gatekeeper)

Because the app is ad-hoc signed (not notarized), macOS may refuse to open it the first time.
You only need to do the steps below once.

- **macOS 14 (Sonoma) and earlier:** Control-click (right-click) `ScreenLight.app`, choose
  **Open** from the context menu, then click **Open** in the warning dialog that appears.
- **macOS 15 (Sequoia) and later:** double-click `ScreenLight.app` once (it will be blocked),
  then go to **System Settings → Privacy & Security**, scroll down to the message about
  ScreenLight and click **Open Anyway**.

## Notes

- **Hardware brightness** uses the private `DisplayServices` framework (the only way to drive
  the backlight programmatically on Apple Silicon). It targets the built-in display
  (`CGMainDisplayID`). If a future macOS removes the symbol, the on-screen light still works;
  only the backlight change is skipped.
- **External monitors** ignore the backlight call (that would need DDC/CI, out of scope), but
  the color overlay still covers every connected screen.
