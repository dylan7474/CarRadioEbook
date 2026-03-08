#!/usr/bin/env bash

set -euo pipefail

# --- Configuration ---
PORT_ARG=${1:-3012}
PROJECT_NAME="CarRadio"
IMAGE_NAME="carradio"
CONTAINER_NAME="carradio"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The host directory containing your Fiction/NonFiction folders
EBOOK_DIR_HOST="$HOME/my_audiobooks"

echo "=== Deploying ${PROJECT_NAME} with Ebook Support ==="

# 1. Environment setup
cd "$SCRIPT_DIR"

# 2. Generate .dockerignore
echo "Generating .dockerignore..."
cat <<'IGNORE_EOF' > .dockerignore
.git
.gitignore
node_modules
deploy.sh
README.md
LICENSE
AGENTS.md
Dockerfile
.dockerignore
IGNORE_EOF

# 3. Generate static server.js with API endpoint
echo "Generating server.js..."
cat <<'SERVER_EOF' > server.js
const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const PORT = Number(process.env.PORT) || 3011;
const STATIC_ROOT = process.env.STATIC_ROOT || __dirname;

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.ico': 'image/x-icon',
  '.mp3': 'audio/mpeg',
  '.m3u8': 'application/vnd.apple.mpegurl',
};

const getEbooks = (dir, baseDir) => {
  let results = [];
  if (!fs.existsSync(dir)) return results;
  const list = fs.readdirSync(dir);
  list.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      results = results.concat(getEbooks(filePath, baseDir));
    } else if (file.toLowerCase().endsWith('.mp3')) {
      const relativePath = path.relative(baseDir, filePath);
      results.push({
        name: path.basename(file, path.extname(file)).replace(/_/g, ' '),
        category: path.dirname(relativePath).split(path.sep).pop() || 'Ebook',
        url: `/ebooks/${relativePath}`
      });
    }
  });
  return results;
};

const serveStatic = (req, res, url) => {
  // 1. Handle API requests
  if (url.pathname === '/api/ebooks') {
    const ebookPath = path.join(STATIC_ROOT, 'ebooks');
    const ebooks = getEbooks(ebookPath, ebookPath);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(ebooks));
    return;
  }

  // 2. Handle File Serving
  const pathname = decodeURIComponent(url.pathname === '/' ? '/index.html' : url.pathname);
  const safePath = path.normalize(pathname).replace(/^([.][./\\])+/, '');
  const filePath = path.join(STATIC_ROOT, safePath);

  fs.stat(filePath, (err, stats) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Not found');
      return;
    }

    if (stats.isDirectory()) {
      const indexPath = path.join(filePath, 'index.html');
      fs.stat(indexPath, (iErr, iStats) => {
        if (iErr) {
          res.writeHead(403, { 'Content-Type': 'text/plain' });
          res.end('Forbidden');
          return;
        }
        res.writeHead(200, { 'Content-Type': 'text/html' });
        fs.createReadStream(indexPath).pipe(res);
      });
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const range = req.headers.range;

    if (range) {
      const parts = range.replace(/bytes=/, '').split('-');
      const start = parseInt(parts[0], 10);
      const end = parts[1] ? parseInt(parts[1], 10) : stats.size - 1;
      
      res.writeHead(206, {
        'Content-Range': `bytes ${start}-${end}/${stats.size}`,
        'Accept-Ranges': 'bytes',
        'Content-Length': (end - start) + 1,
        'Content-Type': MIME_TYPES[ext] || 'application/octet-stream',
      });
      fs.createReadStream(filePath, { start, end }).pipe(res);
    } else {
      res.writeHead(200, {
        'Content-Length': stats.size,
        'Content-Type': MIME_TYPES[ext] || 'application/octet-stream',
        'Accept-Ranges': 'bytes',
      });
      fs.createReadStream(filePath).pipe(res);
    }
  });
};

http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  serveStatic(req, res, url);
}).listen(PORT, () => {
  console.log(`CarRadio Server running on port ${PORT}`);
});
SERVER_EOF

# 4. Create Dockerfile
echo "Generating Dockerfile..."
cat <<DOCKER_EOF > Dockerfile
FROM node:20-slim
WORKDIR /app
COPY index.html server.js ./
RUN mkdir -p /app/ebooks
EXPOSE ${PORT_ARG}
ENV PORT=${PORT_ARG}
ENV STATIC_ROOT=/app
CMD ["node", "server.js"]
DOCKER_EOF

# 5. Build and launch
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "Stopping existing container..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

echo "Starting new container with volume mapping..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "$PORT_ARG:$PORT_ARG" \
  -v "${EBOOK_DIR_HOST}:/app/ebooks:ro" \
  --restart unless-stopped \
  "$IMAGE_NAME"

# IP detection
IP_ADDR=$(python3 -c "import socket; s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.connect(('8.8.8.8', 80)); print(s.getsockname()[0]); s.close()" 2>/dev/null || echo "localhost")

echo "========================================="
echo "Deployed at http://${IP_ADDR}:${PORT_ARG}"
echo "Ebooks mapped from: ${EBOOK_DIR_HOST}"
echo "========================================="
