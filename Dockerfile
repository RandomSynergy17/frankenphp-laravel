# RandomSynergy17/frankenphp-laravel
# Pre-built FrankenPHP + PHP 8.4 image with all extensions for Laravel Octane projects
# Eliminates the 2+ minute first-boot extension install

ARG PHP_VERSION=8.4
ARG FRANKENPHP_VERSION=1.11

FROM dunglas/frankenphp:${FRANKENPHP_VERSION}-php${PHP_VERSION}

LABEL org.opencontainers.image.source="https://github.com/RandomSynergy17/frankenphp-laravel"
LABEL org.opencontainers.image.description="FrankenPHP + PHP 8.4 with extensions for Laravel Octane"
LABEL org.opencontainers.image.licenses="MIT"

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    zip \
    libpq-dev \
    libzip-dev \
    libicu-dev \
    libonig-dev \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions for Laravel + PostgreSQL + Redis
RUN install-php-extensions \
    pcntl \
    pdo_pgsql \
    pgsql \
    redis \
    zip \
    intl \
    mbstring \
    bcmath \
    opcache \
    exif \
    gd

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Marker so entrypoint scripts can detect extensions are baked in
RUN echo "image" > /etc/frankenphp-laravel-extensions

WORKDIR /app/data/app

ENV OCTANE_SERVER=frankenphp
