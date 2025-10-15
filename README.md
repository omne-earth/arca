# Arca

A single-container isoloated AI development environment based on OpenHands with enhanced system integration.

## Overview

Arca provides a self-contained development environment with systemd services, browser capabilities, and AI agent functionality. It supports two deployment variants:

**gaia**: Standard version
* reduced filesize, about 2.19 GB
* portal available in about 1.5 minute
* runtime available in about 11 minutes, requires internet

**atlas**: Plug-N-Play version
* larger filesize, about 15.5 GB
* portal available in 3-4 minute
* runtime available in 2 minutes, no internet required

RAM usage is around 512 MB for both versions. Estimates are based on a 8 core CPU machine. The first conversation downloads the runtime image if a local image is not available. atlas images have the runtime image, and other requisite containers, cached. The cached images is loaded at boot time. Internet may still be required if the LLM is external for atlas containers.

## Prerequisites

- docker
- sysbox
- git
- make

For convenience, an install script is provided which  will install docker, sysbox, and other required dependencies.

```bash
make .installed
```

## Quick Start

### Pulling Containers

```bash
make pull
```

#### omnedock/arca:v1-gaia

Size: 2.19 GB

#### omnedock/arca:v1-atlas

Size: 15.5 GB

### Running

arca will be accessible on port 8443.

#### gaia

```bash
make new:v1-gaia:container-name
```

#### atlas

```bash
make new:v1-atlas:container-name
```

### Monitoring

portal UI at https://localhost:8443 should be available when the following command reports *Uvicorn running on http://0.0.0.0:3000*

```bash
make monitor:container-name:arca
```

### Inject Configuration

Bootstrap configuration files include:

1. .openhands/settings.json
2. .openhands/secrets.json

For evaulation, a template configuration with an LLM key is provided which works as-is without any edits.

When a new arca container is run, a prompt is provided where settings and secrets can be edited as needed. The boostrap can also be invoked at any later time using:

```bash
make bootstrap
```

This will create `.openhands/settings.json` and `.openhands/secrets.json` files, and prompt for edits. Once the file is created, it can be injected to a running container :

```bash
make inject:container-name
```

> For any edits to OpenHands configuration, it is recommended to use the bootstrap target and make required changes. Editing the settings using the UI sometimes resets the settings as OpenHands expects certain configuration items as environment variables while some in *settings.json* or *config.toml*. This can cause unexpected behaviors - like null sandbox runtime image url upon which OpenHands starts building the runtime container instead. See: https://github.com/OpenHands/OpenHands/issues/9531

## Management Commands

### Container Operations

To enter a container:

```bash
make enter:container-name
```

To stop a container:

```bash
make stop:container-name   
```

To remove a container:

```bash
make remove:container-name     
```

### Monitoring

*service-name* can be atlas, arca, portal, or gateway. These services are essential to the proper functioning of arca.

To monitor the systemd journal logs for these servvices running inside arca, please run: 

```bash
make monitor:container-name:service-name 
```


#### Services

- **arca.service** - Core OpenHands backend
- **portal.service** - Web portal and interface in firefox
- **gateway.service** - Network gateway and routing with caddy

- **atlas.service** - Loads image tarballs using skopio

## Development

### Building from Source

Build all variants (default):

```bash
make all          # Builds both Gaia and Atlas variants
make              # Also builds both (default target)
```

Build core components only:

```bash
make arca-core
```

Build specific variants:

```bash
make arca-gaia    # Base environment
make arca-atlas   # Extended environment
```

#### Patch Information

A patch target exists that makes some changes to the OpenHands code.

```bash
make source/openhands-0.59.0  # Clone source
make .patch-0.59.0            # Apply custom patches
```

The patch speficically:

1. Refactors container user from openhands to arca, the systemd user
2. Disables *security-risk* requirement

> Not all models have tool calling set up for this *security-risk* parameter. Options like *invariant* and *grayswan* exist but are external and proprietary. The patch for security risk can be skipped by commenting out lines 47-51 in the **Makefile**.

### Cleanup

Remove all build artifacts and containers:
```bash
make clean
```

## License

MIT License - see LICENSE file for details.

## Support
we@omne.earth
