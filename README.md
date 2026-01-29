# build-agent-image

Image for our build agents containing everything needed to build our software.

## Overview

This repository contains a Dockerfile based on the upstream GitHub Actions Runner Controller (ARC) image, with additional tools pre-installed for building and deploying our applications.

## Included Tools

- **Base**: GitHub Actions Runner Controller image
- **Package Managers & Scripting**: ansible, bash, python3
- **Utilities**: curl, wget, jq, yq
- **Kubernetes**: kubectl
- **.NET**: .NET SDK (latest available version)

## Automated Builds

The Docker image is automatically rebuilt weekly via GitHub Actions:
- **Schedule**: Every Sunday at 00:00 UTC
- **Registry**: `ghcr.io/cyclops-k8s/build-agent-image`
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
docker pull ghcr.io/cyclops-k8s/build-agent-image:latest
```

Use in GitHub Actions workflows:
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/cyclops-k8s/build-agent-image:latest
    steps:
      - uses: actions/checkout@v4
      # Your build steps here
```

## Manual Build

To build the image locally:
```bash
docker build -t build-agent-image .
```

## Manual Trigger

The workflow can also be triggered manually from the GitHub Actions tab.
