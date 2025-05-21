# Base Debian build (latest)
FROM mcr.microsoft.com/vscode/devcontainers/base:debian

# Use bash as default shell
ENV SHELL=/bin/bash

# Use bash for all RUN commands
SHELL ["/bin/bash", "-c"]

# Update packages and install pipx
RUN apt-get update && \
    apt-get install -y pipx curl sudo python3-pip && \
    pipx ensurepath

# Set up environment for pipx
ENV PATH=/root/.local/bin:$PATH

# Dropping privileges
USER vscode

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y && \
    echo 'source $HOME/.cargo/env' >> ~/.bashrc && \
    source $HOME/.cargo/env


# Install Node (nvm, yarn, npm, pnpm)
RUN curl -o- https://raw.githubusercontent.com/devcontainers/features/main/src/node/install.sh | sudo bash

# Install solc-select via pipx
RUN pipx install solc-select

ENV PATH="/home/vscode/.foundry/bin:${PATH}"

# Install Foundry and set specific version
RUN curl -L https://foundry.paradigm.xyz | bash && \
    foundryup -i stable

# Clean up
RUN sudo apt-get autoremove -y && sudo apt-get clean -y
