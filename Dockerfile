# Base image: GitHub Actions Runner (official ARC image)
FROM ghcr.io/actions/actions-runner:latest

# Switch to root for installations
USER root

# Set up non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install all required system packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        apt-transport-https \
        bash \
        ca-certificates \
        jq \
        gnupg \
        lsb-release \
        pipx \
        python3 \
        software-properties-common \
        wget \
        yq \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# Install Kustomize
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash \
    && mv kustomize /usr/local/bin/kustomize \
    && chmod +x /usr/local/bin/kustomize

# Install Helm v3
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install OpenTofu
RUN curl -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh \
    && chmod +x install-opentofu.sh \
    && ./install-opentofu.sh --install-method standalone \
    && rm install-opentofu.sh

# Switch back to runner user for ansible installation
USER runner

# Set pipx environment variables to ensure it uses /home/runner/.local
ENV PIPX_HOME="/home/runner/.local/pipx"
ENV PIPX_BIN_DIR="/home/runner/.local/bin"
ENV PATH="/home/runner/.local/bin:${PATH}"

# Install pipx and ansible as runner user in ~/.local directory
RUN pipx install --include-deps ansible \
    && pipx inject --include-apps ansible-core dnspython \
    && pipx inject --include-apps ansible-core jmespath \
    && pipx inject --include-apps ansible-core netaddr \
    && pipx inject --include-apps --include-deps ansible-core requests

# Install ansible modules
COPY requirements.yaml .
RUN ansible-galaxy collection install -r requirements.yaml \
    && rm requirements.yaml

# Verify the runner user can execute expected tools
RUN echo "=== Verifying tools ===" \
    && sudo -n true \
    && kubectl version --client=true \
    && kustomize version \
    && helm version \
    && tofu --version \
    && ansible --version

# Reset DEBIAN_FRONTEND
ENV DEBIAN_FRONTEND=
