# CarRadioEbook

CarRadioEbook is a touch-first web radio player that combines live internet radio stations with locally hosted audiobook/ebook MP3 files.

The UI is optimized for in-car or kiosk-style use:
- full-screen single-tap play/pause
- swipe-based station navigation
- minimal overlays for status and buffering state

## What the application is

The app provides a single-page listening experience with two content sources:

1. **Built-in radio stations** (music, news, talk, and classical streams).
2. **Scanned local MP3 content** exposed as additional “stations” via `/api/ebooks`.

When deployed with the included `deploy.sh` flow, a lightweight Node server is generated to:
- serve the static app
- expose ebook metadata from mounted media folders
- stream MP3 files (including range request support)
- store and serve ebook playback position via `/api/ebook-progress` for cross-device resume

## Basic controls

### Touch controls
- **Tap anywhere**: Play/Pause the current station.
- **Swipe left**: Next station.
- **Swipe right**: Previous station.

### Keyboard controls
- **Space**: Play/Pause.
- **Arrow Right / Arrow Up**: Next station.
- **Arrow Left / Arrow Down**: Previous station.

### Media session controls
On supported devices/browsers, lock-screen and hardware media controls are wired for:
- Play
- Pause
- Previous track (previous station)
- Next track (next station)

## Build / run instructions

This project is designed around the provided deployment script.

### Prerequisites
- Docker
- Bash shell environment
- A local audiobook folder at `~/my_audiobooks` (or edit `EBOOK_DIR_HOST` in `deploy.sh`)
- A writable progress file path (defaults to `~/.carradio_ebook_progress.json`)

### Deploy
```bash
./deploy.sh
```

Optional custom port:
```bash
./deploy.sh 3012
```

The script will generate runtime files (`server.js`, `Dockerfile`, `.dockerignore`), build an image, and run the container with your audiobook folder mounted read-only plus a writable progress JSON file mounted for server-side resume state.

## Roadmap

- Add station persistence (remember last station and play state).
- Add search/filter for large ebook libraries.
- Add category grouping UI for radio vs audiobook sources.
- Add optional dark/light visual themes.
- Add simple health/status endpoint for container monitoring.
