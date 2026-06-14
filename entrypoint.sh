#!/bin/sh
set -e

CONFIG_FILE="/var/www/html/qa-config.php"

echo "Configuring Q2A database settings dynamically from K3s cluster context..."

# Read the correct keys injected by your K3s deployment manifest
sed -i "s|define('QA_MYSQL_HOSTNAME'.*|define('QA_MYSQL_HOSTNAME', '${QA_MYSQL_HOST}');|g" "$CONFIG_FILE"
sed -i "s|define('QA_MYSQL_USERNAME'.*|define('QA_MYSQL_USERNAME', '${QA_MYSQL_USER}');|g" "$CONFIG_FILE"
sed -i "s|define('QA_MYSQL_PASSWORD'.*|define('QA_MYSQL_PASSWORD', '${QA_MYSQL_PASSWORD}');|g" "$CONFIG_FILE"
sed -i "s|define('QA_MYSQL_DATABASE'.*|define('QA_MYSQL_DATABASE', '${QA_MYSQL_DATABASE}');|g" "$CONFIG_FILE"

echo "Q2A configuration updated successfully. Handing off process control to Apache."

# Execute the main container command passed by CMD
exec "$@"