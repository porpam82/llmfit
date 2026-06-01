# ---------- Frontend ----------
FROM node:22 AS frontend

WORKDIR /build

COPY . .

WORKDIR /build/llmfit-web

RUN npm ci
RUN npm run build

# ---------- Rust Builder ----------
FROM rust:1.88-slim AS builder

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY . .

# copiar frontend compilado
COPY --from=frontend /build/llmfit-web/dist ./llmfit-web/dist

RUN cargo build --release -p llmfit

# ---------- Runtime ----------
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    pciutils \
    lshw \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# binário
COPY --from=builder /build/target/release/llmfit /usr/local/bin/llmfit

# assets do dashboard
COPY --from=builder /build/llmfit-web/dist /llmfit-web/dist

EXPOSE 8787

ENTRYPOINT ["/usr/local/bin/llmfit"]

CMD ["serve","--host","0.0.0.0","--port","8787"]
