#!/usr/bin/env bash

# Display a number of last login attempt of an user
# Author: taufiq.wirahman.sr@gmail.com 
# Date: 2024-12-15 11:45 GMT+7 - Johor Bahru - UTM

# Feature:
# For any users, not only root
# Ordinary user only can check their own username
# "last" command parameters:
# -a all logins, including failed attempts
# -F show full date and time
# -n <number> number of outputs

# Function: Display usage
usage() {
  echo "Usage: $0 [OPTIONS] USERNAME"
  echo "Options:"
  echo "  -n, --num        Number of entries (default: 10)"
  echo "  -r, --reboot     Include reboot entries (default: exclude)"
  echo "  -h, --help       Display this help message"
  echo "Example: $0 -n 20 -r john"
  exit 0
}

# Initialize variables
NUM_ENTRIES=10
INCLUDE_REBOOT=0

# Parse command-line options
while [ $# -gt 0 ]; do
  case $1 in
    -n|--num)
      NUM_ENTRIES=$2
      shift 2
      ;;
    -r|--reboot)
      INCLUDE_REBOOT=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      break
      ;;
  esac
done

# Check if running as root
if [ $(id -u) -eq 0 ]; then
  # Root user, allow checking any user
  USERNAME=$1
  if [ -z "$USERNAME" ]; then
    usage
  fi
else
  # Non-root user, only allow checking self
  USERNAME=$(whoami)
  if [ $# -gt 0 ]; then
    echo "Error: Non-root users can only check their own login history."
    usage
  fi
fi

# Check if user exists (only applicable for root)
if [ $(id -u) -eq 0 ] && ! id -u $USERNAME > /dev/null 2>&1; then
  echo "User '$USERNAME' not found."
  exit 1
fi

# Display login attempts
if [ $INCLUDE_REBOOT -eq 1 ]; then
  echo "Last $NUM_ENTRIES login attempts for $USERNAME (including reboots):"
  last -a -F -n $NUM_ENTRIES $USERNAME
else
  echo "Last $NUM_ENTRIES login attempts for $USERNAME (excluding reboots):"
  last -a -F -n $NUM_ENTRIES $USERNAME | grep -v "reboot"
fi
