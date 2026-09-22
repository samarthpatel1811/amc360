FROM php:8.2-cli-alpine

RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    oniguruma-dev \
    sqlite-dev \
    sqlite

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_sqlite mbstring exif pcntl bcmath gd zip opcache

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy backend files into working directory
COPY backend/ /var/www/html/

# Copy environment config
RUN cp /var/www/html/.env.production /var/www/html/.env 2>/dev/null || true

RUN composer install --no-dev --optimize-autoloader --no-interaction

# Production environment variables
ENV APP_NAME="AMC360"
ENV APP_ENV="production"
ENV APP_DEBUG="true"
ENV APP_KEY="base64:gbbYxCHr9F+vN2C9tNB2rlbjsMl6gtjC3fhADuQHyvU="
ENV DB_CONNECTION="sqlite"
ENV DB_DATABASE="/var/www/html/database/database.sqlite"
ENV SESSION_DRIVER="file"
ENV CACHE_STORE="file"
ENV LOG_CHANNEL="stderr"
ENV PORT="8000"

# Permissions
RUN chmod -R 777 /var/www/html/database /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 8000

CMD sh -c "php artisan config:clear && php artisan route:clear && php artisan serve --host=0.0.0.0 --port=\${PORT:-8000}"
