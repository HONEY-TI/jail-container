#FROM node:24.16.0-bookworm
FROM alexfariakof/node-base:latest AS base
USER root
ARG USERNAME=node
ENV USERNAME=${USERNAME}
ARG WORKSPACE=/workspace
ENV WORKSPACE=${WORKSPACE}

# ==========================================
# Dependências do sistema
# ==========================================
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  xterm \
  iptables \
  ipset \
  iproute2 \
  iputils-ping \
  dnsutils \
  aggregate \
  curl \
  ca-certificates \
  gh \
  openssh-client \
  jq \
  procps \
  xdg-utils \
  xauth \
  xclip \
  xsel \
  bubblewrap \
  wget \
  ca-certificates \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER ${USERNAME}
RUN wget -qO /tmp/agy-install.sh https://antigravity.google/cli/install.sh \
  && bash /tmp/agy-install.sh \
  && rm -f /tmp/agy-install.sh

USER root
RUN npm install -g @openai/codex@latest --include=optional \
  && codex --version

COPY .devcontainer/setup-codex-any-user.sh /usr/local/sbin/setup-codex.sh
COPY .devcontainer/post-start.sh /usr/local/sbin/post-start.sh
COPY .devcontainer/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# ── Permissões ─────────────────────────────────────────────────────────────
RUN chmod +x /usr/local/sbin/post-start.sh \
    /usr/local/bin/docker-entrypoint.sh \
    /usr/local/sbin/setup-codex.sh

    #----------------------------------------------------------------------------
# Permissões sudo para o usuário node (desabilitado)
# ── Sudoers (regra única para ambos via entrypoint) ────────────────────────
#----------------------------------------------------------------------------
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "${USERNAME} ALL=(root) NOPASSWD: /usr/local/sbin/post-start.sh /usr/local/bin/docker-entrypoint.sh, /usr/local/sbin/setup-codex.sh" \
  > /etc/sudoers.d/${USERNAME}-dev \
  && chmod 0440 /etc/sudoers.d/${USERNAME}-dev
ENTRYPOINT ["docker-entrypoint.sh"]
WORKDIR ${WORKSPACE}
