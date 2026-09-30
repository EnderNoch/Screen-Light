#!/bin/bash
# Builds "Screen Light.app" from Sources/ and installs it in /Applications.
# Also refreshes Screen-Light.zip, the download linked from the README.
set -euo pipefail
cd "$(dirname "$0")"

APP="Screen Light.app"
ID="com.local.screenlight"
# The About window's signature, like the system's own "Copyright © … Apple Inc. All rights
# reserved.", with the author in place of Apple.
AUTHOR="EnderNoch (Atypical Maker)"
SINCE=2026
YEARS="$SINCE"; [ "$(date +%Y)" != "$SINCE" ] && YEARS="$SINCE–$(date +%Y)"
COPYRIGHT="Copyright © $YEARS $AUTHOR. All rights reserved."

echo "› compiling"
rm -rf "$APP" Screen-Light.zip
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -swift-version 5 -default-isolation MainActor \
	-target arm64-apple-macos26.0 \
	Sources/*.swift -o "$APP/Contents/MacOS/ScreenLight"

# The icon is layered like the system's own (ScreenLight.icon, from Icon Composer): macOS
# lays its glass over it and follows the icon style set in System Settings → Appearance.
# actool builds Assets.car from it, plus ScreenLight.icns for older places. It remembers
# icons by file path and misses edited layers at the same path, so it gets a fresh copy.
echo "› icon"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cp -R ScreenLight.icon "$TMP/ScreenLight.icon"
xcrun actool "$TMP/ScreenLight.icon" --compile "$PWD/$APP/Contents/Resources" \
	--platform macosx --minimum-deployment-target 26.0 --app-icon ScreenLight \
	--output-partial-info-plist "$TMP/icon.plist" >/dev/null

echo "› Info.plist"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>Screen Light</string>
	<key>CFBundleDisplayName</key><string>Screen Light</string>
	<key>LSHasLocalizedDisplayName</key><true/>
	<key>CFBundleDevelopmentRegion</key><string>en</string>
	<key>CFBundleExecutable</key><string>ScreenLight</string>
	<key>CFBundleIconFile</key><string>ScreenLight</string>
	<key>CFBundleIconName</key><string>ScreenLight</string>
	<key>CFBundleIdentifier</key><string>$ID</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>2.0</string>
	<key>CFBundleVersion</key><string>2</string>
	<key>LSMinimumSystemVersion</key><string>26.0</string>
	<key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
	<key>NSHighResolutionCapable</key><true/>
	<key>NSHumanReadableCopyright</key><string>$COPYRIGHT</string>
</dict>
</plist>
PLIST

# The app's name in each language, like the system's own apps: Finder, the Dock, the menu
# bar and the window title all follow the system language. The app reads its name back from
# here, so this list is the only place it is spelled out.
# The copyright line in each language comes from Photo Booth, with the author and years
# swapped in; languages macOS doesn't ship keep the English one.
BOOTH="/System/Applications/Photo Booth.app/Contents/Resources/InfoPlist.loctable"
echo "› localized names and copyright"
while IFS='|' read -r code name; do
	mkdir -p "$APP/Contents/Resources/$code.lproj"
	case "$code" in nb) sys=no;; pt) sys=pt_PT;; zh-Hans) sys=zh_CN;; zh-Hant) sys=zh_TW;; *) sys="$code";; esac
	line="$(plutil -extract "$sys.NSHumanReadableCopyright" raw -o - "$BOOTH" 2>/dev/null)" || line="$COPYRIGHT"
	# Apple writes "Apple Inc." with a no-break space in some languages and wraps it in
	# direction marks in Hebrew; perl understands both, the marks stay where they are.
	line="$(printf '%s' "$line" | YEARS="$YEARS" AUTHOR="$AUTHOR" perl -CSDA -pe \
		's/\d{4}(?:\x{2013}\d{4})?([\s\x{200F}\x{2068}]*)Apple[\s\x{00A0}]Inc\./$ENV{YEARS}$1$ENV{AUTHOR}./; s/\.(\x{2069})\./$1./')"
	line="${line//\"/\\\"}"
	printf '"CFBundleName" = "%s";\n"CFBundleDisplayName" = "%s";\n"NSHumanReadableCopyright" = "%s";\n' \
		"$name" "$name" "$line" > "$APP/Contents/Resources/$code.lproj/InfoPlist.strings"
done <<'NAMES'
en|Screen Light
pl|Światło ekranu
de|Bildschirmlicht
fr|Lumière d’écran
es|Luz de pantalla
pt|Luz do ecrã
it|Luce dello schermo
nl|Schermlicht
sv|Skärmljus
da|Skærmlys
nb|Skjermlys
fi|Näyttövalo
is|Skjáljós
cs|Světlo obrazovky
sk|Svetlo obrazovky
sl|Zaslonska luč
hr|Svjetlo zaslona
sr|Светло екрана
bg|Светлина от екрана
ro|Lumină de ecran
hu|Képernyőfény
el|Φως οθόνης
tr|Ekran Işığı
uk|Світло екрана
ru|Свет экрана
be|Святло экрана
lt|Ekrano šviesa
lv|Ekrāna gaisma
et|Ekraanivalgus
ca|Llum de pantalla
ar|ضوء الشاشة
he|אור מסך
fa|نور صفحه
hi|स्क्रीन लाइट
bn|স্ক্রিন লাইট
th|แสงหน้าจอ
vi|Đèn màn hình
id|Lampu Layar
ms|Lampu Skrin
zh-Hans|屏幕光
zh-Hant|螢幕光
ja|スクリーンライト
ko|화면 조명
NAMES

echo "› signing ad-hoc"
codesign --force --sign - "$APP"
ditto -c -k --keepParent "$APP" Screen-Light.zip

RUNNING=0
if pgrep -x ScreenLight >/dev/null; then
	RUNNING=1
	echo "› quitting the running copy"
	osascript -e "tell application id \"$ID\" to quit" 2>/dev/null || true
	sleep 1
fi

echo "› installing in /Applications"
# the app used to be called ScreenLight.app
rm -rf "/Applications/ScreenLight.app" "/Applications/$APP"
ditto "$APP" "/Applications/$APP"
# refresh the icon cache, otherwise Finder keeps the old one
touch "/Applications/$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/$APP" || true
# a copy that was running comes back as the new version, like a restart
if [ "$RUNNING" = 1 ]; then
	echo "› reopening"
	open "/Applications/$APP"
fi
echo "› done: /Applications/$APP"
