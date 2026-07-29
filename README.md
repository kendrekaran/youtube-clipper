# YouTube Clipper

A self-hostable tool that lets you extract specific clips from YouTube videos by providing a URL and start/end timestamps. Clips are processed locally with `yt-dlp` + `ffmpeg` and downloaded straight to your computer — no cloud storage required.

> Runs out of the box in **local-only mode**: no Supabase, no auth, no payments. Clone, install, run.

---

## Quick start (local)

### Prerequisites

| Tool | Why |
| --- | --- |
| [Bun](https://bun.sh/) (v1.2.7+) | Runtime for backend and frontend |
| [Node.js](https://nodejs.org/) (v18+) | Some tooling still expects it |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Downloads the YouTube segment |
| [ffmpeg](https://ffmpeg.org/) | Trims and re-encodes the clip |

### macOS / Linux

```sh
# 1. Install tools (macOS via Homebrew)
brew install bun yt-dlp ffmpeg node

# 2. Clone
git clone https://github.com/kendrekaran/youtube-clipper.git
cd youtube-clipper

# 3. Start (installs deps, starts both servers, opens the browser)
./start.sh
```

- Frontend: [http://localhost:3000](http://localhost:3000)
- Backend: [http://localhost:3001](http://localhost:3001)
- Press **Ctrl+C** to stop both servers

Optional: add a `clip` shortcut so you can launch from anywhere:

```sh
# add to ~/.zshrc (or ~/.bashrc)
alias clip="/path/to/youtube-clipper/start.sh"
```

### Windows (PowerShell)

```powershell
# 1. Install tools
winget install --id Oven-sh.Bun         -e
winget install --id OpenJS.NodeJS.LTS   -e
winget install --id yt-dlp.yt-dlp       -e
winget install --id Gyan.FFmpeg         -e
winget install --id Git.Git             -e

# Close and reopen PowerShell so PATH updates, then verify:
bun --version; node --version; yt-dlp --version; ffmpeg -version

# 2. Clone
git clone https://github.com/kendrekaran/youtube-clipper.git
cd youtube-clipper

# 3. Start
./start.ps1
```

If you see *"running scripts is disabled on this system"*, run this once, then re-run `./start.ps1`:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Optional `clip` shortcut — add to your PowerShell profile (`notepad $PROFILE`):

```powershell
function clip { & "$HOME\path\to\youtube-clipper\start.ps1" }
```

### What the launchers do

- Verify `bun`, `yt-dlp`, and `ffmpeg` are installed
- Free ports `3000` / `3001` if something is already listening
- Run `bun install` in `backend/` and `frontend/` when `node_modules` is missing
- Start backend on `http://localhost:3001` and frontend on `http://localhost:3000`
- Open the app in your default browser
- Shut down cleanly on **Ctrl+C**

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
2. Paste a YouTube URL and the desired start / end timestamps (`HH:MM:SS`, e.g. `00:01:23`).
3. Click **Clip Video**.
4. The processed clip downloads to your machine as `clip.mp4`.

---

## Features

- **Frontend:** Next.js 15 (Turbopack) + TailwindCSS + shadcn/ui
- **Backend:** Express on the Bun runtime
- **Video processing:** `yt-dlp` for partial YouTube downloads, `ffmpeg` for trimming/re-encoding
- **No cloud storage** — clips download directly to your device
- **One-command launchers:** `start.sh` (macOS/Linux) and `start.ps1` (Windows)

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

If either file is missing, create it with the contents above.

---

## Troubleshooting

- **`bun: command not found` after install** — close and reopen your terminal so PATH updates.
- **`yt-dlp` or `ffmpeg` not found** — confirm they are on PATH (`which yt-dlp` / `where.exe yt-dlp`), then restart the shell or reinstall.
- **Port already in use (3000 or 3001)** — launchers auto-kill listeners; or manually:
  - macOS/Linux: `lsof -ti tcp:3000 | xargs kill -9`
  - Windows: `Get-NetTCPConnection -LocalPort 3000 | Stop-Process -Id $_.OwningProcess -Force`
- **`./start.ps1` blocked** — run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once.
- **Video fails / 403 from YouTube** — update yt-dlp: `yt-dlp -U` (Windows: `winget upgrade yt-dlp.yt-dlp`).

---

## License / Notes

Open source — use it for personal clipping. You're responsible for respecting YouTube's Terms of Service and the rights of the content owner.
