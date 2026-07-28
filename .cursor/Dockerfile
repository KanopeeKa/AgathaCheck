# Cursor Cloud base image for Agatha Track (Flutter web + Node API + PostgreSQL).
# Do not COPY the repo — Cursor checks out the workspace at runtime.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=22
ARG FLUTTER_VERSION=3.44.0
ARG PG_VERSION=16

# git + sudo are required for Cloud Agent clone and permission management.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates curl git sudo xz-utils unzip \
    postgresql-${PG_VERSION} postgresql-client-${PG_VERSION} \
  && curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Flutter SDK — pinned to AGENTS.md / CI (3.44.0).
RUN git clone https://github.com/flutter/flutter.git \
    -b "${FLUTTER_VERSION}" --depth 1 /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config --no-analytics \
  && flutter precache --web

# Dev database credentials (matches e2e/scripts/bootstrap-db.sh defaults).
COPY scripts/cloud-pg-init.sh /usr/local/bin/agatha-cloud-pg-init.sh
RUN chmod +x /usr/local/bin/agatha-cloud-pg-init.sh \
  && pg_ctlcluster "${PG_VERSION}" main start \
  && /usr/local/bin/agatha-cloud-pg-init.sh \
  && pg_ctlcluster "${PG_VERSION}" main stop
