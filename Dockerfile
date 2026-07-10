# CodeSandbox supports debian & ubuntu based images
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04


RUN curl -fsSL https://opencode.ai/install | bash
RUN curl -s "https://get.sdkman.io" | bash 
RUN bash -c 'source /root/.sdkman/bin/sdkman-init.sh && sdk install java 21.0.11-zulu && sdk install gradle 9.6.1'
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs
RUN bash -c '/root/.opencode/bin/opencode plugin -g superpowers@git+https://github.com/obra/superpowers.git'
RUN bash -c 'npm install -g @fission-ai/openspec@latest'
RUN bash -c 'npx skills@latest add -p -y mattpocock/skills --all'
