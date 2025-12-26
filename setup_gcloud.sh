#!/usr/bin/env bash
set -euo pipefail

log() { echo -e "\n[setup] $*\n"; }

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root: sudo $0"
  exit 1
fi

TARGET_USER="${SUDO_USER:-}"
OS_ID="$(. /etc/os-release && echo "${ID:-}")"
OS_CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME:-}")"

if [[ "${OS_ID}" != "debian" ]]; then
  echo "This script is intended for Debian (detected: ${OS_ID}). Exiting."
  exit 1
fi

log "Installing prerequisites..."
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg2 python3

# Stop Ops Agent if present (can block driver installs on some setups)
systemctl stop google-cloud-ops-agent >/dev/null 2>&1 || true

###############################################################################
# 1) NVIDIA Driver (Google Compute Engine installer)
###############################################################################
if ! command -v nvidia-smi >/dev/null 2>&1; then
  log "NVIDIA driver not detected (nvidia-smi missing). Installing via cuda_installer.pyz (binary + prod)..."

  mkdir -p /opt/google/cuda-installer
  cd /opt/google/cuda-installer

  if [[ ! -f cuda_installer.pyz ]]; then
    curl -fsSL -o cuda_installer.pyz \
      https://storage.googleapis.com/compute-gpu-installation-us/installer/latest/cuda_installer.pyz
  fi

  # Fix for Debian: prod branch requires binary install mode
  # This may trigger a reboot; script is safe to re-run.
  set +e
  python3 cuda_installer.pyz install_driver --installation-mode=binary --installation-branch=prod
  rc=$?
  set -e

  # If we still don't have nvidia-smi, assume reboot happened or is required.
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    log "Driver install started. If your VM rebooted (or needs reboot), reconnect and run: sudo ./setup-gpu-docker.sh"
    exit 0
  fi

  log "NVIDIA driver detected."
else
  log "NVIDIA driver already present."
fi

###############################################################################
# 2) Docker Engine (official Docker repo for Debian)
###############################################################################
if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker Engine..."

  # Remove conflicting/unofficial packages if present
  apt-get remove -y \
    docker.io docker-compose docker-doc podman-docker containerd runc >/dev/null 2>&1 || true

  install -m 0755 -d /etc/apt/keyrings

  if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  fi
  chmod a+r /etc/apt/keyrings/docker.asc

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${OS_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  systemctl enable --now docker
else
  log "Docker already installed."
  systemctl enable --now docker >/dev/null 2>&1 || true
fi

# Add the invoking user to docker group (so they can run docker without sudo)
if [[ -n "${TARGET_USER}" ]] && id "${TARGET_USER}" >/dev/null 2>&1; then
  if ! getent group docker >/dev/null; then
    groupadd docker || true
  fi
  usermod -aG docker "${TARGET_USER}" || true
fi

###############################################################################
# 3) NVIDIA Container Toolkit (nvidia-ctk + runtime config)
###############################################################################
if ! dpkg -s nvidia-container-toolkit >/dev/null 2>&1; then
  log "Installing NVIDIA Container Toolkit..."

  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    > /etc/apt/sources.list.d/nvidia-container-toolkit.list

  apt-get update
  apt-get install -y nvidia-container-toolkit
else
  log "NVIDIA Container Toolkit already installed."
fi

log "Configuring Docker to use NVIDIA runtime..."
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

###############################################################################
# 4) Test: run nvidia-smi inside a container
###############################################################################
log "Testing GPU inside Docker..."
set +e
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
rc=$?
set -e

if [[ $rc -ne 0 ]]; then
  echo
  echo "[setup] GPU container test FAILED (exit=$rc)."
  echo "[setup] Useful checks:"
  echo "  nvidia-smi"
  echo "  docker info | sed -n '1,120p'"
  echo "  cat /etc/docker/daemon.json"
  echo "  systemctl status docker --no-pager"
  exit $rc
fi

log "SUCCESS ✅ Docker can access the NVIDIA GPU."
if [[ -n "${TARGET_USER}" ]]; then
  echo "[setup] Note: if you want to run docker without sudo, log out and back in so group membership applies (user: ${TARGET_USER})."
fi
EOF

chmod +x setup-gpu-docker.sh
sudo ./setup-gpu-docker.sh
