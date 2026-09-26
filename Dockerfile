# Base image: GitHub Actions Runner (official ARC image)
FROM ghcr.io/actions/actions-runner:latest

# Switch to root for installations
USER root

# Update package list and install all required system packages
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get dist-upgrade --auto-remove --purge --yes \
    && apt-get install --no-install-recommends --yes \
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
    && rm -rf /var/lib/apt/lists/* \
    && echo "=== Installing kubectl ===" \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl \
    && echo "=== Installing Kustomize ===" \
    && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash -s /usr/local/bin \
    && echo "=== Installing Helm ===" \
    && curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash \
    && echo "=== Installing OpenTofu ===" \
    && curl -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh \
    && chmod +x install-opentofu.sh \
    && ./install-opentofu.sh --install-method standalone \
    && rm install-opentofu.sh

# Switch back to runner user for ansible installation
USER runner

# Set pipx environment variables to ensure it uses /home/runner/.local
ENV PIPX_HOME="/home/runner/.local/pipx"
ENV PIPX_BIN_DIR="/home/runner/.local/bin"
ENV PATH="/home/runner/.local/bin:${PATH}"

COPY requirements.yaml .

# Install pipx and ansible as runner user in ~/.local directory
RUN pipx install --include-deps ansible \
    && pipx inject --include-apps --include-deps ansible ansible-dev-tools \
    && pipx inject ansible dnspython \
    && pipx inject --include-apps ansible jmespath \
    && pipx inject --include-apps ansible netaddr \
    && pipx inject --include-apps --include-deps ansible requests \
    && rm -rf /home/runner/.cache/pip \
    && echo "=== Installing ansible modules ===" \
    && ansible-galaxy collection install -r requirements.yaml \
    && rm requirements.yaml \
    && echo "=== Verifying tools ===" \
    && sudo -n true \
    && kubectl version --client=true \
    && kustomize version \
    && helm version \
    && tofu --version \
    && ansible --version
