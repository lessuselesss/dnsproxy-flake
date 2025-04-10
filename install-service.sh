#!/bin/bash

# Create log directory if it doesn't exist
sudo mkdir -p /var/log

# Copy the service file to the system launchd directory
sudo cp com.dnsproxy.cloudflare.plist /Library/LaunchDaemons/

# Set the correct permissions
sudo chown root:wheel /Library/LaunchDaemons/com.dnsproxy.cloudflare.plist
sudo chmod 644 /Library/LaunchDaemons/com.dnsproxy.cloudflare.plist

# Load the service
sudo launchctl load /Library/LaunchDaemons/com.dnsproxy.cloudflare.plist

echo "Service installed and started. You can check the logs at /var/log/dnsproxy-cloudflare.log" 