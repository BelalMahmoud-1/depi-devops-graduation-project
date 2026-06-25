# =============================================================================
# Amazona Backend — Multi-Stage Dockerfile
# Author : Mohamed Abdelkader <muhammadabdelkader@github>
# Project: DEPI DevOps Graduation Project — Deliverable #1 (Dockerize)
# =============================================================================
#
# STAGE OVERVIEW
# ──────────────
#   Stage 1 (builder)    — Installs ALL dependencies (including devDeps) and
#                          compiles the ES6+ source with Babel into dist/.
#   Stage 2 (production) — Copies only the compiled dist/ output and installs
#                          production-only dependencies, keeping the image lean.
#
# WHY TWO STAGES?
#   Babel, nodemon, and the Babel CLI are devDependencies. They are only needed
#   during the build step. Excluding them from the final image:
#     - Reduces image size (smaller attack surface, faster pulls / deployments).
#     - Avoids shipping build tooling into production.
# =============================================================================


# -----------------------------------------------------------------------------
# Stage 1: Builder
# Installs all dependencies and compiles ES6+ source to CommonJS (dist/).
# -----------------------------------------------------------------------------
FROM node:18-alpine AS builder

LABEL maintainer="Mohamed Abdelkader"
LABEL org.opencontainers.image.authors="muhammadabdelkader@github"
LABEL org.opencontainers.image.title="Amazona Backend Builder"
LABEL org.opencontainers.image.description="Build stage: compiles ES6 source with Babel"

# Set the working directory inside the container.
# All subsequent commands run relative to this path.
WORKDIR /app

# Copy package manifests BEFORE the source code to exploit Docker layer caching.
# If package.json and package-lock.json are unchanged, Docker reuses the cached
# npm install layer and skips the expensive install on every build.
COPY package*.json ./

# Install ALL dependencies including devDependencies (@babel/cli, @babel/core,
# @babel/node, @babel/preset-env, nodemon, eslint) which are required to compile.
# `npm ci` is preferred over `npm install` in CI/Docker because it:
#   - Uses package-lock.json for deterministic, reproducible installs.
#   - Fails if lock file is out of sync with package.json.
#   - Does not write to package-lock.json (read-only).
RUN npm ci

# Copy the rest of the backend source code.
# .dockerignore prevents node_modules, dist/, uploads/, and .env* from being
# sent to the Docker build context, keeping builds fast and secrets safe.
COPY . .

# Compile ES6+ source files to CommonJS JavaScript into the dist/ directory.
# This runs: `rm -rf dist && babel . -d dist --ignore node_modules,uploads`
# After this step, dist/ contains plain Node.js-compatible JavaScript.
RUN npm run build


# -----------------------------------------------------------------------------
# Stage 2: Production
# Lean runtime image — no Babel toolchain, no devDependencies, no raw source.
# -----------------------------------------------------------------------------
FROM node:18-alpine AS production

LABEL maintainer="Mohamed Abdelkader"
LABEL org.opencontainers.image.authors="muhammadabdelkader@github"
LABEL org.opencontainers.image.title="Amazona Backend"
LABEL org.opencontainers.image.description="Production-ready Amazona API server (Node.js + Express + MongoDB)"
LABEL org.opencontainers.image.version="1.0.7"

# NODE_ENV=production tells Express to enable production optimisations (view
# caching, shorter error messages) and signals npm to skip devDependencies.
ENV NODE_ENV=production

WORKDIR /app

# Copy package manifests into the production stage.
COPY package*.json ./

# Install ONLY production runtime dependencies (--omit=dev is the npm v7+ flag
# equivalent to the older --only=production). This excludes Babel, nodemon,
# eslint, and all other build-time tools, keeping the final image small.
RUN npm ci --omit=dev

# Copy only the compiled output from the builder stage.
# Raw source code is intentionally NOT copied — dist/ is all we need at runtime.
COPY --from=builder /app/dist ./dist

# Create the uploads directory so Multer can write product images at runtime.
# In docker-compose, this path is overlaid by the named volume "backend-uploads",
# meaning uploaded files survive container restarts and recreations.
RUN mkdir -p uploads

# Expose the port the API server listens on (documentation only;
# actual port binding is defined in docker-compose.yml).
EXPOSE 5000

# ---------------------------------------------------------------------------
# Health Check
# Docker uses this to determine container health. docker-compose uses it for
# the `depends_on: condition: service_healthy` dependency chain, so the frontend
# and other services only start once the backend API is truly ready.
#
# Flag explanation:
#   --interval=30s    — run the check every 30 seconds
#   --timeout=10s     — fail if the check takes longer than 10 seconds
#   --start-period=15s— give the app 15 s to initialise before checks begin
#   --retries=3       — mark "unhealthy" only after 3 consecutive failures
#
# wget is used (instead of curl) because it is pre-installed in alpine images.
# ---------------------------------------------------------------------------
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5000/api/health || exit 1

# Start the compiled server using plain Node.js (no Babel at runtime).
CMD ["node", "dist/server.js"]
