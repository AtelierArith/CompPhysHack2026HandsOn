# Sandbox for Devcontainer

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

