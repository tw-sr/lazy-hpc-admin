#!/usr/bin/env bash

# Check password expiry of all user within some threshold
# Author: taufiq.wirahman.sr@gmail.com 
# Date: 2024-12-14 23:05 GMT+7 - Johor Bahru - KLG

# Feature:
# Logging - for audit purpose
# Set threshold - specify expiration threshold
# Usage - How to use this script
# Root only

# Make executable by chmod +x
# Place the script into secure location e.g /usr/local/sbin
# Schedule log rotation using logrotate
# - create /etc/logrotate.d/password_expiry_check
# - the content is:
# /var/log/password_expiry_check.log {
#   weekly
#   rotate 12
#   compress
#   missingok
#   notifempty
# }
#
# Update logrotate configuration (as root): logrotate -f /etc/logrotate.conf

# Logging configuration
LOG_FILE=/var/log/password_expiry_check.log
LOG_DATE=$(date +"%Y-%m-%d %H:%M:%S")

# Create log file if it doesn't exist and set permissions
if [ ! -f "$LOG_FILE" ]; then
  touch "$LOG_FILE"
  chmod 644 "$LOG_FILE"
fi

# Function: Display usage
usage() {
  echo "Usage: $0 [OPTION]"
  echo "Options:"
  echo "  -h, --help      Display this help message"
  echo "  -t, --threshold Specify expiration threshold (days)"
  echo "Example: $0 -t 30"
  exit 0
}

# Check if running as root
if [ $(id -u) -ne 0 ]; then
  echo "${LOG_DATE} ERROR: Non-root access attempt by $(whoami)" >> $LOG_FILE
  echo "Error: This script must be run as root."
  exit 1
fi

# Parse command-line options
while [ $# -gt 0 ]; do
  case $1 in
    -h|--help)
      usage
      ;;
    -t|--threshold)
      EXPIRY_THRESHOLD=$2
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Default expiration threshold (days)
EXPIRY_THRESHOLD=${EXPIRY_THRESHOLD:-30}

echo "${LOG_DATE} INFO: Password expiry check started by $(whoami)" >> $LOG_FILE

echo "Users with passwords expiring within $EXPIRY_THRESHOLD days:"

for user in $(getent passwd | cut -d: -f1); do
  expiry_date=$(chage -l $user | grep "Password expires" | cut -d: -f2-)
  if [ "$expiry_date" = "never" ]; then
    continue
  fi
  days_left=$(echo $expiry_date | awk '{print ($1 - $(date +%s)) / 86400}')

  if [ $days_left -le $EXPIRY_THRESHOLD ]; then
    echo "$user: $expiry_date ($days_left days left)"
    echo "${LOG_DATE} WARNING: $user password expires in $days_left days" >> $LOG_FILE
  fi
done

echo "${LOG_DATE} INFO: Password expiry check completed" >> $LOG_FILE