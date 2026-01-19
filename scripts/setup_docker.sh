#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# AlmaLinux + Docker layout bootstrap
#
# - Installs Docker Engine from Docker's official repo
# - Adds current user to docker group
# - Creates:
#     ~/docker/stacks
#     /opt/appdata/docker
# - Sets permissions so containers can read/write under /opt/appdata/docker
#
# Run as your regular user with sudo privileges:
#   chmod +x setup_docker.sh
#   ./setup_docker.sh
###############################################################################

# Detect current non-root user (if run via sudo, use SUDO_USER)
CURRENT_USER="${SUDO_USER:-$USER}"
USER_HOME="$(eval echo "~${CURRENT_USER}")"

echo "Running user: ${CURRENT_USER}"
echo "Home directory: ${USER_HOME}"
echo

###############################################################################
# 1. Install Docker Engine on AlmaLinux
###############################################################################
echo "==> Installing Docker Engine (Docker CE repo for CentOS/AlmaLinux)..."

# Remove any conflicting old Docker packages (ignore failures)
sudo dnf remove -y docker \
                 docker-client \
                 docker-client-latest \
                 docker-common \
                 docker-latest \
                 docker-latest-logrotate \
                 docker-logrotate \
                 docker-engine || true

# Docker repo tools
sudo dnf install -y dnf-plugins-core

# Add official Docker CE repo (CentOS repo works for AlmaLinux)
if ! sudo dnf repolist | grep -qi docker-ce; then
    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
fi

# Install Docker Engine + dependencies
sudo dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Enable and start Docker
sudo systemctl enable --now docker

###############################################################################
# 2. Docker group and user membership
###############################################################################
echo
echo "==> Configuring docker group..."

if ! getent group docker >/dev/null; then
    sudo groupadd docker
fi

sudo usermod -aG docker "${CURRENT_USER}"

###############################################################################
# 3. Create Docker stacks directory in home
###############################################################################
echo
echo "==> Creating Docker directory structure in home..."

DOCKER_DIR="${USER_HOME}/docker"
STACKS_DIR="${DOCKER_DIR}/stacks"

mkdir -p "${STACKS_DIR}"
sudo chown -R "${CURRENT_USER}:${CURRENT_USER}" "${DOCKER_DIR}"

echo "Created: ${STACKS_DIR}"

###############################################################################
# 4. Create /opt/appdata/docker for container data
###############################################################################
echo
echo "==> Creating /opt/appdata/docker for container data..."

APPDATA_BASE="/opt/appdata/docker"
sudo mkdir -p "${APPDATA_BASE}"

# Ownership / permissions strategy:
# - Owner: root
# - Group: docker
# - Mode : 2775
#   - 2 = setgid: new files/dirs inherit group "docker"
#   - 7 = rwx for owner (root)
#   - 7 = rwx for group (docker)  -> containers / users in group can write
#   - 5 = r-x for others
sudo chown root:docker "${APPDATA_BASE}"
sudo chmod 2775 "${APPDATA_BASE}"


###############################################################################
# 5. Summary / usage info
###############################################################################
echo
echo "============================================================"
echo "Setup complete."
echo
echo "User and groups:"
echo "  - User: ${CURRENT_USER}"
echo "  - Added to group: docker"
echo "    NOTE: You must log out and log back in (or 'su - ${CURRENT_USER}')"
echo "          for docker group membership to take effect."
echo
echo "Directories created:"
echo "  - Compose stacks:"
echo "      ${STACKS_DIR}/<app>/docker-compose.yml"
echo
echo "  - Container data root (for all Docker data):"
echo "      ${APPDATA_BASE}"
echo "    Example per-app/service paths:"
echo "      ${APPDATA_BASE}/myapp-web"
echo "      ${APPDATA_BASE}/myapp-db"
echo
echo "Permissions on ${APPDATA_BASE}:"
echo "  - Owner : root"
echo "  - Group : docker"
echo "  - Mode  : 2775 (setgid, group rwx)"
echo "  -> Any new subdir inherits group 'docker', so containers / users in"
echo "     docker group can write there (depending on user inside container)."
echo "============================================================"