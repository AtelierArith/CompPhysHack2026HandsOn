# Sandbox for Devcontainer

Claude's `bypass permissions on` mode is convenient, but there is a risk that the Agent could execute arbitrary code (such as the destructive command `rm -rf /`). To mitigate this, you can run a Docker container and mount only the necessary code and data. This section explains how to set up your environment using a Dev Container.

See the following links to learn about Dev Container.

- https://code.visualstudio.com/docs/devcontainers/containers
- https://code.visualstudio.com/docs/devcontainers/devcontainer-cli

## Install `devcontainer` command

Just run:

```sh
$ npm install -g @devcontainers/cli
```

## Running the CLI

```sh
$ cd path-to-this-directory
$ devcontainer build
$ devcontainer up --workspace-folder ./
$ devcontainer exec --workspace-folder ./ bash
```

