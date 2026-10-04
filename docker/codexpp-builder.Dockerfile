FROM public.ecr.aws/ubuntu/ubuntu@sha256:cd11a24d38f395f018457869ea3dab0c21546450787e63d60b52e680de159bb7

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cargo \
    curl \
    libayatana-appindicator3-dev \
    libdbus-1-dev \
    libglib2.0-dev \
    libgtk-3-dev \
    libjavascriptcoregtk-4.1-dev \
    libsqlite3-dev \
    libssl-dev \
    libsoup-3.0-dev \
    libwebkit2gtk-4.1-dev \
    nodejs \
    npm \
    pkg-config \
    rustc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /source
