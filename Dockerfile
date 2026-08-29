# CodeSandbox supports debian & ubuntu based images
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

WORKDIR /workspace
ENV PATH="/root/.local/bin:${PATH}"

RUN curl -s "https://get.sdkman.io" | bash 
RUN bash -c 'source /root/.sdkman/bin/sdkman-init.sh && sdk install java 21.0.11-zulu && sdk install gradle 9.6.1'
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*
# RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# ENV PATH="/root/.cargo/bin:${PATH}"
# RUN bash -c 'cargo install --git https://github.com/rtk-ai/rtk && rtk init -g --opencode ' \
#     rm -rf ~/.cargo/registry && rm -rf ~/.cargo/git
RUN bash -c 'curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh && rtk init -g --opencode '

RUN curl -fsSL https://opencode.ai/install | bash
RUN bash -c '/root/.opencode/bin/opencode plugin -g superpowers@git+https://github.com/obra/superpowers.git'
RUN bash -c 'npm install -g @fission-ai/openspec@latest && openspec init --tools opencode'
RUN bash -c 'npx skills@latest add -p -y mattpocock/skills --all'

# Define the URL as an environment variable for clarity
ENV GLAB_URL="https://gitlab.com/gitlab-org/cli/-/releases/v1.107.0/downloads/glab_1.107.0_linux_amd64.tar.gz"
# Download, extract, and install the glab binary
RUN curl -sSL "${GLAB_URL}" | tar -xz -C /tmp \
    && mv /tmp/bin/glab /usr/local/bin/glab \
    && rm -rf /tmp/*

RUN bash -c 'curl -fsSL https://raw.githubusercontent.com/jyasuu/okf-mcp-server/refs/heads/main/scripts/install.sh | bash && /root/.opencode/bin/opencode mcp add okf -- okf-mcp-server'
RUN bash -c 'npx skills@latest add -p -y jyasuu/okf-mcp-server --skill okf-spec'

RUN bash -c 'npx playwright install chromium && npx playwright install-deps chromium && rm -rf /var/lib/apt/lists/*' && \
    CHROME_BIN=$(find /root/.cache/ms-playwright -maxdepth 1 -type d -name 'chromium-*')/chrome-linux64/chrome && \
    ln -sf "$CHROME_BIN" /usr/local/bin/chromium

ENV CHROME_PATH=/usr/local/bin/chromium

# --- Graphify: knowledge-graph skill for AI coding assistants ---
# Requires Python 3.10+ and uv (installed below), then registers the
# /graphify skill with opencode.
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN uv tool install graphifyy \
    && uv tool update-shell \
    && graphify install --platform opencode --project

RUN bash -c 'npx skills@latest add -p -y nextlevelbuilder/ui-ux-pro-max-skill --skill ui-ux-pro-max'
RUN bash -c 'npx skills@latest add -p -y vercel-labs/agent-skills --skill vercel-composition-patterns vercel-react-best-practices web-design-guidelines vercel-react-native-skills'
RUN bash -c 'npx skills@latest add -p -y anthropics/skills --skill frontend-design'
RUN bash -c 'npx skills@latest add -p -y jyasuu/skills --skill postgres-lock-diagnostics postgres-safe-migration'
RUN bash -c 'npx skills@latest add -p -y jyasuu/nextjs-oauth2-app --skill nextjs-oauth2'
RUN bash -c 'npx skills@latest add -p -y tt-a1i/archify'
# CHROME_PATH=~/.cache/ms-playwright/chromium-1228/chrome-linux64/chrome
RUN bash -c 'curl -fsSL https://raw.githubusercontent.com/jyasuu/chromium-mcp/refs/heads/main/scripts/install.sh | bash &&  /root/.opencode/bin/opencode mcp add chromium-mcp -- chromium-mcp'

RUN bash -c 'npm install @deepseek-ai/dsh -g'
