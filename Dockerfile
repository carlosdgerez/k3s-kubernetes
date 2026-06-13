FROM php:8.1-apache

# Combine system updates and utilities to keep image layers clean
RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install native extensions needed by Q2A
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Install Redis PHP extension for session clustering across pods
RUN pecl install redis && docker-php-ext-enable redis

# Configure PHP session handling to offload to Redis
RUN echo "session.save_handler = redis" > /usr/local/etc/php/conf.d/redis-session.ini \
    && echo 'session.save_path = "tcp://redis:6379"' >> /usr/local/etc/php/conf.d/redis-session.ini

# Set working directory context
WORKDIR /var/www/html

# Download, extract, and clean up Question2Answer master source branch
RUN curl -L https://github.com/q2a/question2answer/archive/refs/heads/master.zip -o q2a.zip \
    && unzip q2a.zip \
    && mv question2answer-*/* . \
    && mv question2answer-*/.htaccess-example .htaccess \
    && rm -rf question2answer-* q2a.zip

# Initialize configuration base
RUN mv qa-config-example.php qa-config.php 

# Set secure permissions for Apache runtime execution
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \;

# Wire up the automated runtime entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]