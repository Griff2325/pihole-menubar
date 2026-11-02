#!/bin/zsh
# Builds PiHoleBar.app (menu bar only, no Dock icon). Needs Xcode command line tools.
set -euo pipefail
cd "$(dirname "$0")"
ARCHS=(--arch arm64 --arch x86_64)
swift build -c release ${ARCHS[@]}
APP=PiHoleBar.app
rm -rf $APP && mkdir -p $APP/Contents/MacOS
cp "$(swift build -c release ${ARCHS[@]} --show-bin-path)/PiHoleBar" $APP/Contents/MacOS/
cat > $APP/Contents/Info.plist <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>PiHoleBar</string>
<key>CFBundleIdentifier</key><string>io.github.pihole-menubar</string>
<key>CFBundleExecutable</key><string>PiHoleBar</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSAppTransportSecurity</key><dict><key>NSAllowsLocalNetworking</key><true/></dict>
<key>NSLocalNetworkUsageDescription</key><string>Talks to your Pi-hole on the local network.</string>
</dict></plist>
PL
codesign --force --sign - $APP
echo "Built $APP"
