#!/bin/bash

# Exit on error
set -e

# Detect the Linux distribution
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO=$ID
else
  echo "Unable to detect Linux distribution. Exiting."
  exit 1
fi

# Run the appropriate bootstrap script based on the distribution
case $DISTRO in
  arch)
    bash "$HOME/mydotfiles/bootstrap/arch.sh"
    ;;
  *)
    echo "Unsupported distribution: $DISTRO"
    exit 1
    ;;
esac

# Done
echo "Bootstrap process complete!"
