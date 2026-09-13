# 🚀 Direct-NVR: PM2 Background Setup

Use these instructions to run Direct-NVR 24/7 in the background on your server.

---

## 1. Prerequisites
*   Node.js installed on your server.
*   PM2 installed globally: `npm install -g pm2`

## 2. Initial Setup
Run these commands in the project root folder:
```bash
# Install all dependencies (including AI features)
npm install

# Start the background process
pm2 start server.js --name direct-nvr
```

## 3. Configure Gemini AI (Optional)
To enable Tactical AI Briefs and Semantic Search:
1.  Create a file named `.env` in this folder.
2.  Add your key: `GEMINI_API_KEY=your_google_ai_studio_key`
3.  Restart the process: `pm2 restart direct-nvr`

## 4. Surviving a Reboot

Starting the process with `pm2 start` only keeps it running until pm2 itself
stops (e.g. the machine reboots) — pm2 does *not* come back on its own
unless you also do this, once:

```bash
pm2 startup
```

This prints an OS-specific command (usually starting with `sudo env PATH=...`)
— copy that exact line and run it. Don't just run `pm2 startup` again
expecting it to apply itself; it only prints the command, it doesn't run it.

Then snapshot the current process list so pm2 knows what to restore on boot:

```bash
pm2 save
```

**Whenever you add, remove, or rename a pm2 process later, run `pm2 save`
again** — otherwise the next reboot restores the old, stale process list
instead of what's actually running now.

## 5. Maintenance Commands
*   **Check Status:** `pm2 status`
*   **View Live Logs:** `pm2 logs direct-nvr`
*   **Restart Server:** `pm2 restart direct-nvr`
*   **Stop Server:** `pm2 stop direct-nvr`

---
**Note:** This project runs on port **3010** by default.
