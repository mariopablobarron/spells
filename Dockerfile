FROM node:22-alpine AS builder
WORKDIR /app

RUN corepack enable && corepack prepare pnpm@10.33.2 --activate

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm build

# --- runner: nginx alpine sirviendo /dist ---
FROM nginx:alpine

# nginx config sencillo: SPA-like fallback + cache static, headers seguros
COPY <<'EOF' /etc/nginx/conf.d/default.conf
server {
  listen 80;
  server_name _;
  root /usr/share/nginx/html;
  index index.html;

  # cache largo para assets versionados (Astro hashea filenames)
  location ~* \.(js|css|woff2?|ttf|otf|png|jpg|jpeg|gif|webp|svg|ico|mp4|webm)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    access_log off;
  }

  # HTML sin cache (deploys nuevos visibles al instante)
  location ~* \.html$ {
    add_header Cache-Control "public, max-age=0, must-revalidate";
  }

  # Fallback 404 → 404.html si existe, si no Astro tiene su index
  error_page 404 /404.html;

  # Security headers
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-Frame-Options "DENY" always;
  add_header Referrer-Policy "strict-origin-when-cross-origin" always;

  # try_files prueba: archivo exacto → .html → directorio/index.html → 404.
  # Esto hace que /sobre sirva /sobre/index.html sin redirect (clean URL, mejor SEO).
  location / {
    try_files $uri $uri.html $uri/index.html =404;
  }
}
EOF

COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
