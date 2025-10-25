# arca

*Latin for box*

A single-container isoloated AI development environment with enhanced system integration.

## Overview

Arca provides a self-contained development environment with systemd services, browser capabilities, and AI agent functionality.

> host --> arca --> agent runtime

![DEMO](https://github.com/omne-earth/arca/blob/main/docs/demo.gif)

### Features

1. Runs in a single host container
    * clean host environment
    * works without mounting docker socket
2. Runs in a secure and isolated container
    * no root required on host
    * arca and agent can run as root
    * root inside arca and runtime is nobody on host
3. systemd integration
    * makes recoverable daemons possible
4. plug and play image (atlas)
    * runtime and agent already included
    * reduces time to first conversation
5. secure and abstract browser interface
    * supports separate vscode per conversation
6. *security_risk* score disabled by default
    * some LLM models do not support this
    * alternatives like *invariant* and *grayswan* require subscription
    * easily modify patch target if feature is desired
7. One line to get it all started. Let's go!

### Versions

It supports two deployment variants based on OpenHands:

**gaia**: Standard version
* portal available in about 1.5 minute
* runtime available in about 11 minutes, requires internet

**atlas**: Plug-N-Play version
* portal available in 3-4 minute
* runtime available in 2 minutes, no internet required

#### Containers
Containers in docker are compressed and may occupy larger size when downloaded to the file system. Additionally, the size of locally built image is larger than docker hub.

https://hub.docker.com/r/omnedock/arca

#### omnedock/arca:gaia

Compressed Size (Docker Hub): 657.92 MB

Uncompressed Size (Local): 2.19 GB

#### omnedock/arca:atlas

Compressed Size (Docker Hub): 5.04 GB

Uncompressed Size (Local): 15.5 GB

## Prerequisites

arca has been tested on an **Ubuntu 240.4** host machine with the following resources available for containers:
- 1m cpu (1 vCPU)
- 4096m ram (4GB)
- make

Other operating systems that support make, docker and sysbox should also be compatible. The install script is *Debian* based and will require modifications for other distributions.

## Quick Start

Run the command below to atomically install dependencies, pull image and run the container:

```bash
make new:atlas:arca
```

The portal will be accessible at https://localhost:8443 by default. The port may be changed in the environment file.

### Dependencies
- docker
- sysbox
- git
- vim

For convenience, an install script is provided which  will install required dependencies.

```bash
make install
```

### Running

#### gaia

```bash
make new:gaia:<container-name>
```

#### atlas

```bash
make new:atlas:<container-name>
```

### Monitoring

portal UI at https://localhost:8443 should be available when the following command reports *Uvicorn running on http://0.0.0.0:3000*

```bash
make monitor:<container-name>:arca
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
make inject:<container-name>
```

> For any edits to OpenHands configuration, it is recommended to use the bootstrap target and make required changes. Editing the settings using the UI sometimes resets the settings as OpenHands expects certain configuration items as environment variables while some in *settings.json* or *config.toml*. This can cause unexpected behaviors - like null sandbox runtime image url upon which OpenHands starts building the runtime container instead. See: https://github.com/OpenHands/OpenHands/issues/9531

## Management Commands

### Container Operations

To enter a container:

```bash
make enter:<container-name>
```

To stop a container:

```bash
make stop:<container-name>   
```

To remove a container:

```bash
make remove:<container-name>     
```

### Monitoring

*service-name* can be atlas, arca, portal, or gateway. These services are essential to the proper functioning of arca.

To monitor the systemd journal logs for these servvices running inside arca, please run: 

```bash
make monitor:<container-name>:service-name 
```

#### Services

- **arca.service** - Core OpenHands backend
- **portal.service** - Web portal and interface in firefox
- **gateway.service** - Network gateway and routing with caddy
- **atlas.service** - Loads image tarballs using skopio

## Development

### Environment
```bash
OPENHANDS_RELEASE := 0.59.0
ARCA_RELEASE := 1.0.0
ARCA_PORTAL := 8443
DOCKER_BUILD_OPTS := # --no-cache --progress=auto
DOCKER_RUN_OPTS := # --cpus=1 -m 4096m
REMOTE_DOCKER_HOST := omnedock
```

### Building from Source

Build all variants (default):

```bash
make all
```

Or build each variant independently:

```bash
make arca-atlas
make arca-gaia
```

Build core components only:

```bash
make arca-core
```

#### Patch Information

A patch target exists that makes some changes to the OpenHands code.

```bash
make source/openhands-0.59.0 
make .patch-0.59.0 
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

## Roadmap

#### Can other agent that run minimally be onboarded in arca?

* agent onboarding

    * mini-SWE-agent
    * SWE-agent
    * SWE-ReX

#### How can the host/arca boundary be isolated even more while allowing a complete system-like environment for the agent?

* true system for agents

    * arca firewall
    * systemd environment for the agent inside the runtime

#### Can the agent runtime be modular and smaller? Is a plug-and-play design possible?

* runtime extensions

    * minimal, pluggable runtimes for agents
    * include major development environments

#### Can the agents be enabled with micro-agents specialized in routine actions that emulate enterprise workloads?

* atomic micro-agents
    * ansible
    * terraform
    * docker
    * kubernetes
    * cdk8s
    * helm

#### Can the arca containers be deployed in HPC ecosystems?

* HPC support

    * Singularity
    * HTCondor

## License

MIT License - see LICENSE file for details.

## Support
we@omne.earth
