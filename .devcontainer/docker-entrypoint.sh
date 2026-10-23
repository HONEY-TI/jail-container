#!/usr/bin/env bash

set -e

# ==========================================================
# Usuário atual (qualquer usuário, sem valor fixo)
# ==========================================================
USER="${TARGET_USER:-node}"
if id "$USER" >/dev/null 2>&1; then
    TARGET_USER="$USER"
else
    TARGET_USER="$(id -un)"
fi
readonly TARGET_USER
readonly WORKSPACE="${WORKSPACE:-/workspace}"

# ── Realinhar UID/GID do node com o dono do $WORKSPACE ───────────────

HOST_UID=$(stat -c '%u' "$WORKSPACE")
HOST_GID=$(stat -c '%g' "$WORKSPACE")

CURRENT_UID=$(id -u "$USER")
CURRENT_GID=$(id -g "$USER")

echo "[entrypoint] $WORKSPACE pertence a UID:GID ${HOST_UID}:${HOST_GID}"
echo "[entrypoint] usuário '$USER' atualmente é UID:GID ${CURRENT_UID}:${CURRENT_GID}"

if [ "$HOST_GID" != "$CURRENT_GID" ]; then
    echo "[entrypoint] ajustando GID de '$USER' para $HOST_GID"
    groupmod -o -g "$HOST_GID" "$USER"
fi

if [ "$HOST_UID" != "$CURRENT_UID" ]; then
    echo "[entrypoint] ajustando UID de '$USER' para $HOST_UID"
    usermod -o -u "$HOST_UID" "$USER"
fi

chown -R "$USER:$USER" "/home/$USER" 2>/dev/null || true
chown -R "$USER:$USER" "/home/$USER/.vscode-server" 2>/dev/null || true

if [ "$(stat -c '%u:%g' "$WORKSPACE")" != "$HOST_UID:$HOST_GID" ]; then
    chown "$USER:$USER" "$WORKSPACE" 2>/dev/null || true
fi

# ==========================================
# GIT CONFIG
# ==========================================
git config --global user.name "Alex Ribeiro de Faria"
git config --global user.email "135660435+alexribeirofaria@users.noreply.github.com"

# ==========================================
# AUTENTICAÇÃO AUTOMÁTICA DO GITHUB CLI
# ==========================================
export GITHUB_TOKEN="$GITHUB_TOKEN"
if ! gh auth status >/dev/null 2>&1; then
    printf '%s' "$GITHUB_TOKEN" | gh auth login --with-token
fi

# =============================================================================
# 🔄 AUTO SWITCH — ROOT ➜ ${TARGET_USER}
# =============================================================================
if [ "$ENABLE_SWITCH_USER" = "true" ]; then \
        echo "🔄 Configurando auto switch: root ➜ ${TARGET_USER}"; \
        printf '%s\n' \
            'if [ "${AUTO_SWITCHED}" != "1" ]; then' \
            '    export AUTO_SWITCHED=1' \
            '    exec su - ${TARGET_USER}' \
            'fi' \
            > /root/.switch_user; \
        echo "source /root/.switch_user" >> /root/.bashrc; \
        echo "source /root/.switch_user" >> /root/.bash_profile; \
        echo ". /root/.switch_user" >> /root/.profile; \
    else \
        echo "⏭️  Auto switch root ➜ ${TARGET_USER}: DESATIVADO"; \
    fi

# ── Processo original do container ───────────────────────────────────
exec "$@"
