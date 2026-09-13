# Direct NVR Smart Monitor & Alert Engine

> 📱 **NEW: Native iOS & Android Mobile Apps are now supported!** Check out the [Mobile App Setup & Usage Guide](MOBILE_APP_GUIDE.md) to get the app running on your phone.

A lightweight, ultra-high-performance web application designed to run seamlessly on top of your existing **Frigate** and **go2rtc** NVR stack. It delivers low-latency, non-proxied live video streams straight to your browser, enables you to draw interactive polygonal scanning windows (Regions of Interest) and exclusion zones on each feed, and integrates with **Frigate's Edge Coral TPU over MQTT** to trigger instant email notifications, save event clips, and maintain a real-time smart dashboard with **0% local CPU decoding or local AI inference load**.

---

## 🚀 Key Features

- **Edge Coral TPU Integration via MQTT:** Completely eliminates local CPU decoding and local TensorFlow.js inference. The backend hooks into your active MQTT broker, subscribes to the `frigate/events` topic, and processes high-accuracy detections streamed in real-time from your Frigate Edge TPU.
- **Interactive Scanning & Exclusion Zones:**
  - **Yellow Scan Windows (ROIs):** Draw custom polygonal regions of interest.Detections are ignored unless they cross into these active target scanning areas.
  - **Red Ignore Zones (Exclusion Masks):** Draw exclusion polygons over areas prone to false alerts (e.g., wind-blown bushes, swaying trees, public walkways). Centroids entering these zones are instantly discarded.
- **Apple Safari/macOS/iOS Compatibility Patches:** When H.265 (HEVC) streams record clips, Frigate packages them as standard `hev1` segments which Apple's native media frameworks reject. Our backend automatically intercepts downloaded event clips and binary-patches them in-memory to Apple-compatible `hvc1` containers with **zero CPU transcoding overhead**, making clips instantly playable in macOS, iOS, and Safari!
- **Multi-Server Configuration Profiles:** Manage multiple locations (e.g., "Home Server" and "Cottage Server") with ease. Swap profiles with a single dropdown in the header; the backend will hot-reload camera feeds, disconnect from the old MQTT broker, and seamlessly boot up the new MQTT client.
- **Persistent Handshake Event History:** Events and linked video playback locations are saved to disk (`alerts_history.json`). Your event log sidebar fully survives browser refreshes and server reboots, complete with WebSocket-synchronized clear features across all connected monitors.
- **Smart SMTP Global Toggle:** Turn Gmail SMTP email notifications on or off instantly with a checkbox in the header of the SMTP section—no need to delete or re-type your app password.
- **Direct low-latency WebRTC/MJPEG streaming:** Embeds direct go2rtc streams for real-time live feeds with zero video buffering latency.

---

## 🛠️ Installation & Setup

### 1. Prerequisites
- **Node.js** (v18 or higher recommended)
- **Frigate NVR** with an active Edge Coral TPU running on your network (usually auto-discovered or configured via settings).
- **An active MQTT Broker** used by Frigate (to publish events on the `frigate/events` topic).

### 2. Startup
Navigate to the directory and run:

```bash
cd /path/to/your/Direct-NVR
npm install
npm start
```

Open your browser and visit:
👉 **[http://localhost:3010](http://localhost:3010)**

To stop the server easily at any time, run:
```bash
npm stop
```

### 3. Running It 24/7 with pm2

`npm start` runs in the foreground and stops as soon as you close the
terminal or log out — fine for testing, not for a server you actually rely
on. To keep it running in the background instead:

```bash
npm install -g pm2
pm2 start server.js --name direct-nvr
```

That keeps it running after you close the terminal, but **not** after a
reboot — pm2 itself has to be told to come back on boot, which takes two
more one-time commands:

```bash
pm2 startup
```
This prints an OS-specific command (starting with something like
`sudo env PATH=...`) — copy that exact line and run it. Then:
```bash
pm2 save
```
which snapshots the current process list so pm2 knows what to restore.
Re-run `pm2 save` any time you add, remove, or rename a pm2 process later.

Common day-to-day commands: `pm2 status`, `pm2 logs direct-nvr`,
`pm2 restart direct-nvr`, `pm2 stop direct-nvr`. Full details in
[SERVER_SETUP_PM2.md](SERVER_SETUP_PM2.md).

### 4. Running It Under Docker

```bash
cp .env.example .env   # fill in your GEMINI_API_KEY / PORT
./docker-setup.sh      # one-time: creates the state files Docker needs to exist first
docker compose up -d --build
```

`docker-setup.sh` matters — `docker-compose.yml` bind-mounts `settings.json`,
`alerts_history.json`, `rois.json`, `exclusions.json`, and
`detections_state.json` individually so your settings/zones/history survive
a rebuild. If one of those doesn't already exist on the host *before* you
run `docker compose up`, Docker creates it as an empty **directory** instead
of a file, which silently breaks the app (this is standard Docker
bind-mount behavior, not a bug in this project) — the setup script just
makes sure they all exist first. Re-run it any time after a fresh clone.

Logs: `docker compose logs -f`. Stop: `docker compose down` (data isn't
deleted — it's on the host, not in the container).

---

## 📐 Dynamic Frigate Integration (MQTT & API)

This version connects directly to your Frigate server's APIs and event streams:

1. **Auto-Discovery & Fallbacks:**
   On boot, the backend probes candidate IPs to locate your active Frigate server. It dynamically fetches Frigate's parsed JSON configuration from the `/api/config` endpoint, resolving camera resolutions, restream configurations, and automatically parsing your active **MQTT broker IP, username, and password**.
2. **The MQTT Event Pipeline:**
   Instead of grabbing and processing raw JPEGs, the server subscribes to the `frigate/events` topic on your MQTT broker. 
   When Frigate's Edge Coral TPU identifies an object (like a person or car), it publishes a live event payload:
   - When an event is initiated (`type: "new"`), our server maps the bounding box centroid against your custom yellow Scan Windows and red Ignore Zones. If it crosses your criteria, it plays an audio chime, logs it in the persistent sidebar history, and dispatches a Gmail notification.
   - When the event terminates (`type: "end"`), the backend fetches the complete MP4 video segment from Frigate's HTTP event API, binary-patches the HEVC container headers to `hvc1` for iOS/macOS compatibility, saves it to disk, and updates the historical alert log with an instant "Play Clip" button.

---

## ⚙️ Configuration & Alerts

Click the **Settings & SMTP** button in the header of the web page to open the configuration panel.

### 1. Server Profile Management
* **Profile Selection:** Switch active server profiles directly from the selector dropdown in the header of the app.
* **New Server Profile:** Create a cloned baseline profile, input its distinct Frigate and MQTT coordinates, and save it under a unique name (e.g. "Cottage Server").
* **Delete Profile:** Safely remove older or inactive profiles with automatic safe fallback routing.

### 2. Live Streaming Mode & Audio (WebRTC)

Under **Detection & Streams** in Settings, the **Streaming Protocol Mode** dropdown defaults to MJPEG (video only, no audio, but "100% Reliable"). Switching it to **WebRTC Direct** streams via Frigate's embedded go2rtc instead, which is the only mode with real audio — but it usually needs one small addition to Frigate's own `config.yml` first:

```yaml
go2rtc:
  streams:
    ...(your existing camera entries)...
  webrtc:
    candidates:
      - YOUR_FRIGATE_HOST_IP:8555
```

Add `webrtc:` as a **sibling of your existing `go2rtc.streams` key** — not a second top-level `go2rtc:` block elsewhere in the file. YAML doesn't merge duplicate top-level keys; the last one silently wins, which would wipe out every camera restream you've already defined under `streams:`. Restart Frigate after saving. If you view this instance from more than one network (e.g. locally and over Tailscale/VPN), list a candidate for each — go2rtc will use whichever one the viewer can actually reach:

```yaml
    candidates:
      - 192.168.1.50:8555
      - 100.x.x.x:8555
```

**Why this is needed:** without it, go2rtc has to guess its own reachable address for WebRTC's ICE negotiation, which frequently fails on a Docker host with more than one network interface — the connection succeeds, but no media ever actually reaches the browser. This is a Frigate/go2rtc configuration detail, not something this app can work around in code.

**If you get audio but no video:** that's a separate, unrelated issue — most browsers' WebRTC stack can negotiate H.265 but never actually decode it, so a camera whose stream happens to be H.265 will play audio while video silently never renders. This app already works around it automatically by preferring an H.264 stream when one of the camera's configured ffmpeg inputs offers it — if a camera only has an H.265 source available at all, there's currently no fix short of changing that camera's stream encoding.

### 3. Gmail SMTP Setup
To send alerts via `smtp.gmail.com` with direct camera snapshots attached:
1. Go to your [Google Account Settings](https://myaccount.google.com/).
2. Enable **2-Step Verification**.
3. Search for **App passwords** in the search bar.
4. Generate a new App Password (e.g., name it "Smart NVR Monitor").
5. Copy the 16-character password (e.g., `xxxx xxxx xxxx xxxx`).
6. Paste this app password into the **Gmail App Password** field in the Settings panel (without spaces).
7. Toggle the **Enable email alerts** checkbox on or off as needed, and click **Save**.

### 4. Tracked Classes
Check the checkboxes for any objects you want to alert on (such as `person`, `car`, `cat`, `dog`, `bear`, `bird`). Only classes ticked here will trigger logs and alerts.
