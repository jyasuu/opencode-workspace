# CodeSandbox supports debian & ubuntu based images
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04


RUN curl -fsSL https://opencode.ai/install | bash
RUN curl -s "https://get.sdkman.io" | bash 
RUN bash -c 'source /root/.sdkman/bin/sdkman-init.sh && sdk install java 21.0.11-zulu && sdk install gradle 9.6.1'
RUN curl -fsSL https://raw.githubusercontent.com/mklement0/n-install/stable/bin/n-install | bash -s 24
