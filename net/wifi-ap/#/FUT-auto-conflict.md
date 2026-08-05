Good — this needs proper mutual exclusion, not just ordering. Use systemd `Conflicts=` (bidirectional, stops the other unit automatically) plus target units to group each mode.

**1. Group units — one target per mode:**

`/etc/systemd/system/wifi-ap.target`
```ini
[Unit]
Description=WiFi AP mode (hostapd+dnsmasq)
Conflicts=netctl-auto@wlan0.service
After=netctl-auto@wlan0.service
```

**2. Static IP unit** — same as before, but wire it into the target:

`/etc/systemd/system/wlan0-ap.service`
```ini
[Unit]
Description=Static IP for wlan0 AP mode
BindsTo=sys-subsystem-net-devices-wlan0.device
After=sys-subsystem-net-devices-wlan0.device
PartOf=wifi-ap.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/ip addr add 192.168.4.1/24 dev wlan0
ExecStart=/usr/bin/ip link set wlan0 up
ExecStop=/usr/bin/ip addr flush dev wlan0
ExecStop=/usr/bin/ip link set wlan0 down

[Install]
WantedBy=wifi-ap.target
```

**3. hostapd/dnsmasq — depend on the IP unit, join the target:**

Drop-in for hostapd (`systemctl edit hostapd.service`):
```ini
[Unit]
Requires=wlan0-ap.service
After=wlan0-ap.service
PartOf=wifi-ap.target

[Install]
WantedBy=wifi-ap.target
```

Same drop-in pattern for dnsmasq (`systemctl edit dnsmasq.service`), just change `Requires=`/`After=` to also list `hostapd.service` if you want strict ordering (dnsmasq after hostapd binds the interface):
```ini
[Unit]
Requires=wlan0-ap.service hostapd.service
After=wlan0-ap.service hostapd.service
PartOf=wifi-ap.target

[Install]
WantedBy=wifi-ap.target
```

**4. Make netctl-auto conflict back** (bidirectional isn't automatic from one side only unless you also declare it there):

```bash
sudo mkdir -p /etc/systemd/system/netctl-auto@wlan0.service.d
sudo tee /etc/systemd/system/netctl-auto@wlan0.service.d/override.conf <<'EOF'
[Unit]
Conflicts=wifi-ap.target
EOF
```

**5. Enable:**
```bash
systemctl daemon-reload
systemctl enable wlan0-ap.service hostapd.service dnsmasq.service
systemctl enable wifi-ap.target
```

**Usage — now it's one command each way:**
```bash
systemctl start wifi-ap.target        # brings up IP, hostapd, dnsmasq; kills netctl-auto@wlan0
systemctl start netctl-auto@wlan0.service   # brings up client wifi; kills wifi-ap.target (and its deps)
```

`Conflicts=` is symmetric in effect (starting A stops B) but must be declared on whichever unit you're *starting* to guarantee the other side stops — hence declaring it both directions above. `PartOf=` makes hostapd/dnsmasq/wlan0-ap stop together when the target stops, without needing them to also declare `Conflicts=` individually.

**Related topics you may want expanded:** verifying `netctl-auto@wlan0.service` is the actual unit name on your system (`systemctl list-units | grep netctl`), replacing the two `Requires=`/`After=` duplication in dnsmasq's drop-in with `BindsTo=` if you want hostapd crash → dnsmasq auto-stop, testing conflict resolution order (does it wait for full stop before starting?).
