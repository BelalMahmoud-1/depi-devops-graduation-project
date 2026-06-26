# =============================================================================
# Amazona Frontend — Multi-Stage Dockerfile
# Author : Mohamed Abdelkader <muhammadabdelkader@github>
# Project: DEPI DevOps Graduation Project — Deliverable #1 (Dockerize)
# =============================================================================
#
# STAGE OVERVIEW
# ──────────────
#   Stage 1 (builder)    — Installs npm dependencies and runs `npm run build`
#                          (react-scripts build → CRA) to produce the static
#                          bundle in /app/build.
#   Stage 2 (production) — Copies the static bundle into an Nginx image and
#                          serves it on port 80. No Node.js at runtime.
#
# ARG vs ENV — KEY CONCEPT
# ─────────────────────────
# React (CRA) bakes environment variables into the JavaScript bundle AT BUILD
# TIME. Variables prefixed with REACT_APP_ are read by react-scripts during
# `npm run build` and hardcoded into the JS chunks. This means:
#
#   ✅ Use ARG (build-time) for React environment variables like REACT_APP_API_URL.
#   ❌ ENV (runtime) alone does NOT work for CRA apps because once the bundle
#      is built, the compiled JS cannot read runtime environment variables.
#
# Contrast with the backend (Node.js): Node.js reads process.env at runtime, so
# ENV (or docker-compose environment:) is the right mechanism there.
#
# Practical consequence for docker-compose:
#   docker-compose passes REACT_APP_API_URL via `build.args` (not `environment`).
# =============================================================================


# -----------------------------------------------------------------------------
# Stage 1: Builder
# Installs npm deps, accepts the API URL build arg, and produces the static
# React bundle in /app/build using react-scripts.
# -----------------------------------------------------------------------------
FROM node:18-alpine AS builder

LABEL maintainer="Mohamed Abdelkader"
LABEL org.opencontainers.image.authors="muhammadabdelkader@github"
LABEL org.opencontainers.image.title="Amazona Frontend Builder"
LABEL org.opencontainers.image.description="Build stage: compiles React app to static assets"

# Declare the build argument.
# `ARG` variables exist only during the Docker build process (they are not
# present in the final image layers or the running container).
# Pass this value with: `docker build --build-arg REACT_APP_API_URL=http://...`
ARG REACT_APP_API_URL

# Promote the ARG to an ENV so that react-scripts can read it as a process
# environment variable during `npm run build`. Without this line, CRA would
# not pick up the ARG value.
ENV REACT_APP_API_URL=$REACT_APP_API_URL

WORKDIR /app

# Copy package manifests first for Docker layer caching optimisation.
COPY package*.json ./

# Install ALL frontend dependencies (react-scripts is a devDependency needed
# to run the build). `npm ci` ensures reproducible, lock-file-based installs.
RUN npm ci --legacy-peer-deps && npm install ajv@^8 --legacy-peer-deps

# Copy the rest of the frontend source code.
COPY . .

# Run the CRA production build.
# Outputs optimised, minified, fingerprinted static assets to /app/build.
# The REACT_APP_API_URL value is baked into the JS bundle here.
RUN npm run build


# -----------------------------------------------------------------------------
# Stage 2: Production
# Minimal Nginx image that serves the pre-built static assets.
# Node.js is NOT present in this stage — only Nginx.
# -----------------------------------------------------------------------------
FROM nginx:1.25-alpine AS production

LABEL maintainer="Mohamed Abdelkader"
LABEL org.opencontainers.image.authors="muhammadabdelkader@github"
LABEL org.opencontainers.image.title="Amazona Frontend"
LABEL org.opencontainers.image.description="Production Nginx server for Amazona React SPA"
LABEL org.opencontainers.image.version="0.1.4"

# Remove the default Nginx virtual host configuration.
# We replace it with our own SPA-aware config (nginx.conf) that handles:
#   - React Router (try_files fallback to index.html)
#   - Gzip compression
#   - Long-lived caching for hashed static assets
#   - Security: deny access to hidden files
RUN rm /etc/nginx/conf.d/default.conf

# Copy the custom Nginx configuration from the build context.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the compiled React bundle from the builder stage into Nginx's webroot.
COPY --from=builder /app/build /usr/share/nginx/html

# Expose port 80 (documentation; actual binding is in docker-compose.yml).
EXPOSE 80

# Start Nginx in the foreground (required for Docker containers — the main
# process must not daemonise, or the container will exit immediately).
CMD ["nginx", "-g", "daemon off;"]
