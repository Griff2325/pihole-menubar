# PiHoleBar

A tiny macOS menu bar app for [Pi-hole](https://pi-hole.net) v6. See at a glance whether blocking is on, view today's stats, pause blocking for a few minutes, and jump to the dashboard.

- A little pie (Pi, get it) in the menu bar: bright = blocking on, dimmed = blocking off, warning sign = can't reach Pi-hole.
- Click it for queries today, blocked count and percent, blocklist size, and active clients.
- **Disable blocking…** for 5 min, 30 min, or until you turn it back on.
- **Open Dashboard** opens `http://<your-pi>/admin`.
- Refreshes every 10 seconds. The admin password is kept in your macOS Keychain.

Requires macOS 13+ and Pi-hole **v6** (it uses the v6 REST API).

## Build and run

Needs Xcode or the command line tools (`xcode-select --install`).

```bash
git clone https://github.com/Griff2325/pihole-menubar.git
cd pihole-menubar
./build.sh
open PiHoleBar.app
```

Click the shield, enter your Pi-hole address (for example `pihole.local` or `192.168.1.2`) and admin password, then Save. macOS will ask to allow access to the local network the first time: click **Allow**.

To start it at login, drag `PiHoleBar.app` to Applications, then add it under System Settings > General > Login Items.

## Notes

- The app is ad-hoc signed, so it runs on the Mac that built it. To share a build, sign and notarize it with your own Apple developer ID.
- It talks to Pi-hole over plain HTTP on your local network. Use an address you trust.
- Pi-hole API sessions count against a small limit; the app reuses one session and re-logs in when it expires.

MIT licensed.
