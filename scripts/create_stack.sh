#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Komodo stack bootstrap
#
# Usage:
#   create_stack.sh <app_name>
#
# Creates:
#   ~/komodo/stacks/<app_name>/
#     - docker-compose.yml (empty)
#     - .env (empty)
#     - config/
#     - logs/
#
#   /opt/appdata/<app_name>/
#     - data/
#
# And sets:
#   - ~/komodo and subdirs owned by current user, group docker, mode 775
#   - ~/komodo/stacks/<app_name> owned by current user:docker
#   - /opt/appdata/<app_name> owned by root:docker, mode 2775 (recursively)
###############################################################################

#----- 0. Check args -----------------------------------------------------------
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <app_name>"
    exit 1
fi

APP_NAME="$1"

# Basic validation (letters, numbers, dots, underscores, dashes)
if [[ ! "$APP_NAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "Error: app_name can only contain letters, numbers, dots, underscores and dashes."
    exit 1
fi

#----- 1. Figure out user and paths -------------------------------------------
CURRENT_USER="${SUDO_USER:-$USER}"
USER_HOME="$(eval echo "~${CURRENT_USER}")"

KOMODO_DIR="${USER_HOME}/komodo"
STACKS_DIR="${KOMODO_DIR}/stacks"
STACK_APP_DIR="${STACKS_DIR}/${APP_NAME}"

STACK_CONFIG_DIR="${STACK_APP_DIR}/config"
STACK_LOGS_DIR="${STACK_APP_DIR}/logs"

APPDATA_BASE="/opt/appdata"
APP_ROOT_DIR="${APPDATA_BASE}/${APP_NAME}"
APP_DATA_DIR="${APP_ROOT_DIR}/data"

echo "Using user: ${CURRENT_USER}"
echo "App name : ${APP_NAME}"
echo

# Ensure docker group exists
if ! getent group docker >/dev/null 2>&1; then
    echo "Error: group 'docker' does not exist. Create it first (e.g. 'sudo groupadd docker')."
    exit 1
fi

#----- 2. Ensure ~/komodo base permissions for docker group -------------------
echo "==> Ensuring ~/komodo base directory and permissions"

mkdir -p "${KOMODO_DIR}" "${STACKS_DIR}"

# Owner = current user, group = docker, permissions = 775
sudo chown -R "${CURRENT_USER}:docker" "${KOMODO_DIR}"
sudo chmod -R 775 "${KOMODO_DIR}"

#----- 3. Create stack directory structure ------------------------------------
echo "==> Creating stack directory tree: ${STACK_APP_DIR}"

mkdir -p "${STACK_CONFIG_DIR}" "${STACK_LOGS_DIR}"

# Ensure ownership of the whole stack dir (user:docker)
sudo chown -R "${CURRENT_USER}:docker" "${STACK_APP_DIR}"

# Create empty docker-compose.yml if it doesn't exist
COMPOSE_FILE="${STACK_APP_DIR}/docker-compose.yml"
if [[ ! -f "${COMPOSE_FILE}" ]]; then
    touch "${COMPOSE_FILE}"
    chown "${CURRENT_USER}:docker" "${COMPOSE_FILE}"
    echo "Created empty docker-compose.yml at: ${COMPOSE_FILE}"
else
    echo "docker-compose.yml already exists at: ${COMPOSE_FILE} (left unchanged)"
fi

# Create empty .env if it doesn't exist
ENV_FILE="${STACK_APP_DIR}/.env"
if [[ ! -f "${ENV_FILE}" ]]; then
    touch "${ENV_FILE}"
    chown "${CURRENT_USER}:docker" "${ENV_FILE}"
    echo "Created empty .env at: ${ENV_FILE}"
else
    echo ".env already exists at: ${ENV_FILE} (left unchanged)"
fi

#----- 4. Create app data directory under /opt/appdata ------------------------
echo
echo "==> Creating app data directory under ${APPDATA_BASE}"

sudo mkdir -p "${APP_DATA_DIR}"
sudo chown -R root:docker "${APP_ROOT_DIR}"
sudo chmod -R 2775 "${APP_ROOT_DIR}"

echo
echo "Created/verified app data tree:"
echo "  - ${APP_DATA_DIR}"

#----- 5. Summary -------------------------------------------------------------
echo
echo "============================================================"
echo "Stack '${APP_NAME}' initialized."
echo
echo "Komodo base directory (user + docker group access):"
echo "  ${KOMODO_DIR}"
echo
echo "Stack directory:"
echo "  ${STACK_APP_DIR}"
echo
echo "Files:"
echo "  ${COMPOSE_FILE}"
echo "  ${ENV_FILE}"
echo
echo "Config & Logs (under ~/komodo, group docker):"
echo "  Config dir: ${STACK_CONFIG_DIR}"
echo "  Logs dir  : ${STACK_LOGS_DIR}"
echo
echo "Data directory (under /opt/appdata, root:docker):"
echo "  ${APP_DATA_DIR}"
echo
echo "Next steps:"
echo "  1) Edit ${COMPOSE_FILE} to define your services and volumes."
echo "  2) Optionally add environment variables in ${ENV_FILE}."
echo "  3) Then run:"
echo "       cd ${STACK_APP_DIR}"
echo "       docker compose --env-file .env up -d"
echo "============================================================"
