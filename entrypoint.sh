#!/bin/sh
set -e

CONFIG_FILE="/var/www/html/qa-config.php"

echo "Configuring Q2A database settings dynamically from K3s cluster context..."

# Robustly match and replace credentials regardless of initial spacing format
sed -i "s|define('QA_MYSQL_HOSTNAME'.*|define('QA_MYSQL_HOSTNAME', '${DB_HOST}');|g" "$CONFIG_FILE"
sed -i "s|define('QA_MYSQL_USERNAME'.*|define('QA_MYSQL_USERNAME', '${DB_USER}');|g" "$CONFIG_FILE"
sed -i "s|define('QA_MYSQL_PASSWORD'.*|define('QA_MYSQL_PASSWORD', '${DB_PASS}');|g" "$CONFIG_FILE"
sed -i "s|define('QA_MYSQL_DATABASE'.*|define('QA_MYSQL_DATABASE', '${DB_NAME}');|g" "$CONFIG_FILE"

echo "Q2A configuration updated successfully. Handing off process control to Apache."

# Execute the main container command passed by CMD ["apache2-foreground"]
exec "$@"