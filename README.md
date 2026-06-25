# frankenphp-laravel

A pre-built [FrankenPHP](https://frankenphp.dev/) + **PHP 8.4** base Docker image with every PHP extension a Laravel [Octane](https://laravel.com/docs/octane) application needs already compiled in. It exists to solve one problem: cold-boot speed. Building the required extensions at container start (the usual `install-php-extensions` step) adds **2+ minutes** to first boot. By baking the extensions, Composer, and common system tooling into the image ahead of time, downstream Laravel projects can extend this image and start almost instantly.

This repository contains **only the image definition and its CI pipeline** — it is not a runnable Laravel application. The published image is consumed as a base (`FROM`) by Laravel project scaffolds such as `RandomSynergy17/laravel-docker-template` and other internal apps.

> Published image: `ghcr.io/randomsynergy17/frankenphp-laravel:latest`

## Features

- **FrankenPHP 1.11** app server (runs Laravel Octane in worker mode via `OCTANE_SERVER=frankenphp`).
- **PHP 8.4** with extensions pre-installed: `pcntl`, `pdo_pgsql`, `pgsql`, `redis`, `zip`, `intl`, `mbstring`, `bcmath`, `opcache`, `exif`, `gd`.
- **Composer 2** copied in from the official `composer:2` image.
- Common system tooling: `curl`, `git`, `unzip`, `zip`, plus the dev libraries needed to support the bundled extensions (`libpq-dev`, `libzip-dev`, `libicu-dev`, `libonig-dev`).
- **Marker file** at `/etc/frankenphp-laravel-extensions` (contents: `image`) so a consuming project's entrypoint can detect that extensions are already baked in and skip the install step.
- **Automated multi-arch publishing** to GitHub Container Registry (GHCR) on every push to `main` and on version tags.
- Tuned build args — `PHP_VERSION` and `FRANKENPHP_VERSION` are overridable at build time.

## Tech Stack

| Layer | Choice |
|-------|--------|
| App server | FrankenPHP `1.11` (base image `dunglas/frankenphp:${FRANKENPHP_VERSION}-php${PHP_VERSION}`) |
| Language | PHP `8.4` |
| Intended runtime | Laravel Octane (worker mode) |
| Dependency manager | Composer 2 |
| Target databases / cache | PostgreSQL (`pdo_pgsql`, `pgsql`) and Redis (`redis` extension) |
| Registry | GitHub Container Registry — `ghcr.io/randomsynergy17/frankenphp-laravel` |
| CI | GitHub Actions (`docker/build-push-action`) |
| License | MIT (declared via the OCI image label) |

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (with Buildx for building locally).
- A GitHub account with access to GHCR if you intend to pull the published image or push new builds.

### Using the published image (recommended)

Most consumers do not build this repo directly — they reference the published image as a base in their own `Dockerfile`:

```dockerfile
FROM ghcr.io/randomsynergy17/frankenphp-laravel:latest

# Your Laravel app build steps here.
# Extensions, Composer, git, unzip, etc. are already present.
```

Or pull it directly:

```bash
docker pull ghcr.io/randomsynergy17/frankenphp-laravel:latest
```

### Available tags

The CI pipeline produces the following tags (see [Usage](#usage)):

- `latest` — tracks the `main` branch.
- `php8.4-YYYYMMDD` — date-stamped builds from `main` for version pinning.
- `MAJOR.MINOR.PATCH` and `MAJOR.MINOR` — produced from `v*` semver Git tags.

### Configuration / build args

The image is configured at **build time** via Docker `ARG`s (override with `--build-arg`):

| Build arg | Default | Description |
|-----------|---------|-------------|
| `PHP_VERSION` | `8.4` | PHP version of the FrankenPHP base image. |
| `FRANKENPHP_VERSION` | `1.11` | FrankenPHP base image version. |

Runtime environment baked into the image:

| Env var | Value | Purpose |
|---------|-------|---------|
| `OCTANE_SERVER` | `frankenphp` | Tells Laravel Octane to use the FrankenPHP server. |

The default working directory is `/app/data/app` (where a consuming project is expected to place its Laravel source).

> Note: This repository ships **no `.env.example`, migrations, or application code** — database setup, migrations, and runtime env vars are the responsibility of the consuming Laravel project, not this base image.

## Usage

### Build the image locally

From the repository root:

```bash
# Build with defaults (PHP 8.4, FrankenPHP 1.11)
docker build -t frankenphp-laravel:local .

# Build overriding the versions
docker build \
  --build-arg PHP_VERSION=8.4 \
  --build-arg FRANKENPHP_VERSION=1.11 \
  -t frankenphp-laravel:local .
```

### Publish via CI

`.github/workflows/build-image.yml` builds and pushes the image automatically. It triggers on:

- **Push to `main`** → tags `latest` and `php8.4-YYYYMMDD`.
- **Push of a `v*` tag** (e.g. `v1.2.0`) → semver tags (`1.2.0`, `1.2`).
- **Manual run** via the Actions tab (`workflow_dispatch`).

The workflow logs in to GHCR using the built-in `GITHUB_TOKEN`, derives tags/labels with `docker/metadata-action`, and pushes with `docker/build-push-action@v6`. No additional secrets are required.

To cut a versioned release:

```bash
git tag v1.2.0
git push origin v1.2.0
```

## Project Structure

```
frankenphp-laravel/
├── Dockerfile                      # The image definition (base image, system deps,
│                                   #   PHP extensions, Composer, marker file, env)
├── .github/
│   └── workflows/
│       └── build-image.yml         # CI: build & push to ghcr.io on main / v* tags
├── .gitignore                      # Ignores .DS_Store and *.log
└── README.md                       # This file
```

The entire project is intentionally minimal — its only deliverable is the Docker image produced from `Dockerfile`.

## Notes

- **This is a base image, not an app.** There is no Laravel codebase, `composer.json`, Caddyfile, or compose file in this repo. Application concerns (routes, migrations, env, FrankenPHP/Caddy config) live in the projects that extend this image.
- **Why it exists:** baking extensions in saves the ~2 minute `install-php-extensions` step on every cold boot. A consuming project's entrypoint can short-circuit its extension-install logic by checking for the `/etc/frankenphp-laravel-extensions` marker (or via `php -m`).
- **Known downstream consumers:** the `RandomSynergy17/laravel-docker-template` scaffold (`FROM ghcr.io/randomsynergy17/frankenphp-laravel`) and other internal Laravel apps (e.g. ECMS) build on this image. Keep extension/version changes here in sync with what those projects assume.
- **Database orientation is PostgreSQL + Redis.** Only the `pgsql`/`pdo_pgsql` and `redis` drivers are bundled — there is no MySQL/MariaDB extension. Add `pdo_mysql` to the `install-php-extensions` list if a MySQL-based project ever needs this base.
- **License:** the image is labeled MIT (`org.opencontainers.image.licenses="MIT"`), though no standalone `LICENSE` file is committed to this repo — add one if formal licensing is needed.
- **Versions are pinned in the Dockerfile** (`PHP_VERSION=8.4`, `FRANKENPHP_VERSION=1.11`). Bumping either is a one-line change plus a fresh build/publish.
