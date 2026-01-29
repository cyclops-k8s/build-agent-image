# Base image: GitHub Actions Runner (official ARC image)
FROM ghcr.io/actions/actions-runner:latest

# Switch to root for installations
USER root

# Set up non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install base tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    bash \
    jq \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Ansible using pipx (modern, isolated installation)
# pipx will use default ~/.local directory
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --break-system-packages pipx \
    && pipx install ansible

# Update PATH to include pipx binaries
ENV PATH="/root/.local/bin:${PATH}"

# Install .NET SDK
# Note: Installing .NET 10 SDK as requested. If .NET 10 is not yet available, the script will fail.
# In that case, change channel to 9.0 or 8.0 for the latest available LTS version.
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --channel 10.0 --install-dir /usr/share/dotnet \
    && rm dotnet-install.sh \
    && ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Install yq
RUN curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/bin/yq \
    && chmod +x /usr/bin/yq

# Verify installations
RUN echo "=== Verifying installations ===" \
    && curl --version \
    && wget --version | head -1 \
    && bash --version | head -1 \
    && ansible --version | head -1 \
    && dotnet --version \
    && kubectl version --client=true \
    && jq --version \
    && yq --version

# Reset DEBIAN_FRONTEND
ENV DEBIAN_FRONTEND=

# Switch back to runner user for security
USER runner
