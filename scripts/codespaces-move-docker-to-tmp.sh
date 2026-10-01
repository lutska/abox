#!/usr/bin/env bash
set -e

# Preserve the current Codespaces dockerd arguments.
DOCKERD_ARGS=$(ps -eo args | grep '^dockerd' | head -1 | sed 's/^dockerd //')

if [[ -z "$DOCKERD_ARGS" ]]; then
    echo "ERROR: dockerd is not running."
    exit 1
fi

echo "Current dockerd arguments: $DOCKERD_ARGS"

# Move Docker storage to the larger /tmp filesystem.
sudo mkdir -p /tmp/docker /etc/docker

printf '{\n  "data-root": "/tmp/docker"\n}\n' | \
    sudo tee /etc/docker/daemon.json >/dev/null

# Restart dockerd with the original Codespaces arguments.
sudo pkill -x dockerd
sleep 2

# Start dockerd
sudo nohup dockerd $DOCKERD_ARGS >/tmp/dockerd.log 2>&1 &

# Wait up to 20 seconds for Docker to become available.
echo "Waiting for Docker..."

sleep 5

if docker info >/dev/null 2>&1; then
    echo "Docker is running:"
    docker info | grep "Docker Root Dir"
else
    echo "ERROR: Docker failed to start."
    tail -50 /tmp/dockerd.log
    exit 1
fi
echo

echo "Disk space:"
df -h / /tmp

echo
echo "Done. Run: make run"