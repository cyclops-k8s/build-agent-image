[![Build and Keepalive](https://github.com/cyclops-k8s/build-agent-image/actions/workflows/weekly-build.yml/badge.svg)](https://github.com/cyclops-k8s/build-agent-image/actions/workflows/weekly-build.yml)

# build-agent-image

Image for our build agents containing everything needed to build our software.

## Overview

This repository contains a Dockerfile based on the upstream GitHub Actions Runner Controller (ARC) image, with additional tools pre-installed for building and deploying our applications.

## Included Tools

- **Base**: GitHub Actions Runner Controller image
- **Package Managers & Scripting**: ansible (via pipx), bash, python3
- **Utilities**: curl, wget, jq, yq
- **Kubernetes**: kubectl

## Automated Builds

The Docker image is automatically rebuilt weekly via GitHub Actions:
- **Schedule**: Every Sunday at 00:00 UTC
- **Registry**: `quay.io/cyclops-k8s/build-agent-image`
- **Tags**: 
  - `latest` - most recent build
  - `YYYY-MM-DD` - date-tagged builds
  - `YYYY-MM-DD-{sha}` - date and commit SHA tagged builds

### Keepalive Mechanism

The workflow includes an automatic keepalive mechanism:
- If no commits have been made in the last 30 days, the workflow automatically creates a keepalive commit
- This ensures the weekly cron job remains active and the image stays up-to-date

## Usage

Pull the latest image:
```bash
docker pull quay.io/cyclops-k8s/build-agent-image:latest
```

Use in GitHub Actions workflows:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: quay.io/cyclops-k8s/build-agent-image:latest
    steps:
      - uses: actions/checkout@v4
      # Your build steps here
```

## Development Container

This repository includes a devcontainer configuration for local development with VS Code.

### Requirements

- **Docker**: Docker must be installed and running on your host machine
- **Docker Socket**: The devcontainer requires access to `/var/run/docker.sock` on the host
  - **Linux**: Default location is `/var/run/docker.sock`
  - **macOS**: Default location is `/var/run/docker.sock` (created by Docker Desktop)
  - **Windows**: If using WSL2, Docker Desktop creates the socket at `/var/run/docker.sock` in WSL2
- **VS Code**: Visual Studio Code with the Dev Containers extension

### Included VS Code Extensions

The devcontainer automatically installs:
- Docker (Microsoft)
- GitHub Pull Requests and Issues
- GitHub Copilot
- GitHub Copilot Chat
- GitHub Actions

### Usage

1. Open the repository in VS Code
2. When prompted, click "Reopen in Container" (or use Command Palette: "Dev Containers: Reopen in Container")
3. The devcontainer will build and start with access to your host's Docker daemon
4. You can now build and run Docker images from within the container using the host's Docker

**Note**: The devcontainer uses Docker-outside-of-Docker (DooD), meaning it shares the host's Docker daemon rather than running Docker-in-Docker. This is more efficient and allows you to build images that persist on your host system.

## Manual Build

To build the image locally:
```bash
docker build -t build-agent-image .
```

## Manual Trigger

The workflow can also be triggered manually from the GitHub Actions tab.
