= Trust Dalyx Aluminium 10-in-1 USB-C Multi-port Dock (23417_TRUST)

## Ethernet & Link Speed Bottlenecks

* The Symptom: ethtool reports a 1000Mb/s physical link, but iperf throughput stalls around 350–382 Mbps.
* The Root Cause: The USB network adapter is falling back to a USB 2.0 connection (480M) instead of USB 3.0 SuperSpeed (5000M).
* The Check: Run lsusb -t to view the connection speed. 480M means a USB 2.0 bottleneck; 5000M means full SuperSpeed.
* The Linux Driver: The r8152 driver handles multiple chip generations. Keep linux-firmware-realtek installed to ensure stable SuperSpeed microcode injection during boot.

## The HP BIOS USB-C Conflict

* The Cause: HP Spectre laptops default to allocating all high-speed USB-C lanes to video data. This leaves zero high-speed lanes for data, forcing docks to route Ethernet over internal USB 2.0 paths.
* The Fix: Disable "High Resolution Mode" (or set preference to "Dock/Data Speed") in the BIOS. This splits the cable lines: 2 lanes for data and 2 lanes for video.
* The Fix Result: Your Ethernet adapter migrates to Bus 002/004 running at 5000M, instantly unlocking full ~950 Mbps iperf speeds.

## Display Bandwidth & Dock Limitations

* The 30Hz Ceiling: The Trust Dalyx 10-in-1 dock (23417) uses an older internal chip limited to HDMI 1.4.
* The Bandwidth Math: Driving 3840x1600 @ 60Hz (8-bit color) requires 10.13 Gbps of raw pixel clock data.
* The Protocol Wall: HDMI 1.4 has a 10.2 Gbps wire rate, but mandatory 8b/10b encoding overhead drops usable data bandwidth to a max of 8.16 Gbps. Because 10.13 Gbps > 8.16 Gbps, the dock cannot physical handle 60Hz and drops to 30Hz.
* The Split Penalty: Enabling the BIOS data-split cuts the dock's incoming video lanes in half, further starving any monitor connected directly to the dock.

## The Ideal Dual-Port Layout

* Port 1 (Direct to Monitor): Use a pure USB-C to USB-C connection. It bypasses dock multi-function throttling, utilizes full lanes, and outputs an unrestricted 3840x1600 @ 60Hz.
* Port 2 (Direct to Dock): Use exclusively for 950 Mbps Gigabit Ethernet, power delivery, and low-bandwidth USB peripherals.

Would you like me to compile this into a neat, downloadable Markdown (.md) text file so you can easily save it straight into your personal knowledge base or notes folder?
