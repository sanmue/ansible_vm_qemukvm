#!/usr/bin/env bash

#set -x # enable debug mode

### --------------------
### delete storage pools
### --------------------

echo "pool-list:"
sudo sudo virsh pool-list --all

# want to keep pools "default" and "nvram"
sudo sudo virsh pool-list --all --name | grep -vE "default|nvram" | xargs -I % sh -c "sudo virsh pool-destroy % 2>/dev/null || true"
sudo sudo virsh pool-list --all --name | grep -vE "default|nvram" | xargs -I % sh -c "sudo virsh pool-undefine % 2>/dev/null || true"

echo "pool-list:"
sudo sudo virsh pool-list --all
