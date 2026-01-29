# Base image: GitHub Actions Runner (official ARC image)
FROM ghcr.io/actions/actions-runner:latest

# Switch to root for installations
USER root

# Set up non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install all required system packages
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
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

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

# Verify system tools installations (before switching to runner user)
RUN echo "=== Verifying system tools ===" \
    && curl --version \
    && wget --version | head -1 \
    && bash --version | head -1 \
    && dotnet --version \
    && kubectl version --client=true \
    && jq --version \
    && yq --version

# Switch back to runner user for ansible installation
USER runner

# Install pipx and ansible as runner user in ~/.local directory
RUN pip3 install --break-system-packages pipx \
    && /home/runner/.local/bin/pipx install ansible \
    && /home/runner/.local/bin/pipx ensurepath

# Update PATH to include pipx binaries for runner user
ENV PATH="/home/runner/.local/bin:${PATH}"

# Verify ansible installation
RUN ansible --version

# Reset DEBIAN_FRONTEND
ENV DEBIAN_FRONTEND=
