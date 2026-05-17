# YouTube Clipper

A self-hostable tool that lets you extract specific clips from YouTube videos by providing a URL and start/end timestamps. Clips are processed locally with `yt-dlp` + `ffmpeg` and downloaded straight to your computer — no cloud storage required.

> The repo is patched so it runs out of the box in **local-only mode**: no Supabase, no auth, no payments. Just clone, install, run.

---

## Features

- **Frontend:** Next.js 15 (Turbopack) + TailwindCSS + shadcn/ui
- **Backend:** Express on the Bun runtime
- **Video processing:** `yt-dlp` for partial YouTube downloads, `ffmpeg` for trimming/re-encoding
- **No cloud storage required** — clips download directly to your device
- **One-command launchers:** `start.sh` (macOS/Linux) and `start.ps1` (Windows)

---

## Prerequisites

You need these on your PATH regardless of OS:

| Tool | Why |
| --- | --- |
| [Bun](https://bun.sh/) (v1.2.7+) | Runtime for both backend and frontend |
| [Node.js](https://nodejs.org/) (v18+) | Some tooling still expects it |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Downloads the YouTube segment |
| [ffmpeg](https://ffmpeg.org/) | Trims and re-encodes the clip |

Verify everything is installed:

```sh
bun --version
node --version
yt-dlp --version
ffmpeg -version
```

---

## Running on Windows

### 1. Install the prerequisites

Open **PowerShell** (no admin needed for `winget`) and run:

```powershell
winget install --id Oven-sh.Bun         -e
winget install --id OpenJS.NodeJS.LTS   -e
winget install --id yt-dlp.yt-dlp       -e
winget install --id Gyan.FFmpeg         -e
winget install --id Git.Git             -e
```

> If `winget` isn't available, install [App Installer](https://apps.microsoft.com/detail/9NBLGGH4NNS1) from the Microsoft Store, or grab each tool from its official site.

**Close and reopen PowerShell** after installing so the new tools are picked up on the PATH. Then verify:

```powershell
bun --version; node --version; yt-dlp --version; ffmpeg -version
```

### 2. Clone the repo

```powershell
cd $HOME\Desktop
git clone https://github.com/retrogtx/youtube-clipper.git
cd youtube-clipper
```

### 3. One-command start

```powershell
./start.ps1
```

What `start.ps1` does:

- Verifies `bun`, `yt-dlp`, `ffmpeg` are installed
- Kills anything already listening on ports `3000` / `3001`
- Runs `bun install` in `backend/` and `frontend/` if `node_modules` is missing
- Starts the backend on `http://localhost:3001`
- Starts the frontend on `http://localhost:3000`
- Opens the app in your default browser
- Stops both servers cleanly when you press **Ctrl+C**

> If you see *"running scripts is disabled on this system"*, run this **once** in PowerShell, then re-run `./start.ps1`:
>
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
> ```

### 4. (Optional) Make a `clip` shortcut on Windows

So you can launch from anywhere by just typing `clip`, add this to your PowerShell profile:

```powershell
notepad $PROFILE   # creates the file if it doesn't exist
```

Add the line:

```powershell
function clip { & "$HOME\Desktop\youtube-clipper\start.ps1" }
```

Save, reopen PowerShell, and now `clip` launches the app the same way it does on the Mac.

---

## Running on macOS / Linux

```sh
git clone https://github.com/retrogtx/youtube-clipper.git
cd youtube-clipper

# macOS prerequisites
brew install bun yt-dlp ffmpeg

./start.sh
```

The script handles install / port-cleanup / launch / browser-open in one shot. Press **Ctrl+C** to stop.

---

## Manual start (any OS)

If you don't want to use the launchers:

```sh
# Terminal 1 — backend
cd backend
bun install
bun run src/index.ts          # http://localhost:3001

# Terminal 2 — frontend
cd frontend
bun install
bun run dev                   # http://localhost:3000
```

---

## Usage

1. Open `http://localhost:3000`.
2. Paste a YouTube URL and the desired start / end timestamps (format `HH:MM:SS`, e.g. `00:01:23`).
3. Click **Clip Video**.
4. The processed clip downloads to your machine as `clip.mp4`.

---

## Project structure

```
youtube-clipper/
  backend/          Express + Bun, calls yt-dlp & ffmpeg
    src/index.ts
    uploads/        temp clip files
    .env            PORT / NODE_ENV (Supabase vars optional)
  frontend/         Next.js 15 app (App Router)
    app/
    lib/
    .env.local      localhost URLs only
  start.sh          one-command launcher (macOS / Linux)
  start.ps1         one-command launcher (Windows)
```

---

## Environment files

The repo ships with sensible local defaults:

**`backend/.env`**

```env
PORT=3001
NODE_ENV=development
# SUPABASE_URL / SUPABASE_SERVICE_KEY left blank — backend runs in local-only mode
```

**`frontend/.env.local`**

```env
NEXT_PUBLIC_APP_URL=http://localhost:3000
BACKEND_API_URL=http://localhost:3001
NEXT_PUBLIC_BASE_URL=http://localhost:3000
# DATABASE_URL / GOOGLE_* / BETTER_AUTH_SECRET left blank — auth & paywall are bypassed in dev
```

If either file is missing on your machine, just create it with the contents above.

---

## Troubleshooting

- **`bun: command not found` after install on Windows** — close and reopen PowerShell so the updated PATH is loaded.
- **`yt-dlp` or `ffmpeg` not found** — confirm `where.exe yt-dlp` / `where.exe ffmpeg` returns a path. If not, restart your shell or reinstall via `winget`.
- **Port already in use (3000 or 3001)** — the launchers auto-kill listeners, but you can also do it manually:
  - Windows: `Get-NetTCPConnection -LocalPort 3000 | Stop-Process -Id $_.OwningProcess -Force`
  - macOS/Linux: `lsof -ti tcp:3000 | xargs kill -9`
- **`./start.ps1` blocked** — run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once.
- **Video fails / 403 from YouTube** — make sure `yt-dlp` is up to date: `yt-dlp -U` (Windows: `winget upgrade yt-dlp.yt-dlp`).

---

## License / Notes

Open source — use it for personal clipping. You're responsible for respecting YouTube's Terms of Service and the rights of the content owner.
