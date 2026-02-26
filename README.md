# dhaxe

This image ships a Haxe toolkit:

    the `haxe` compiler with its standard library
    the `haxelib` library manager
    the `neko` virtual machine

but differs from [github.com/HaxeFoundation/docker-library-haxe] in that it allows using [Haxe plugins](https://github.com/HaxeFoundation/haxe/tree/development/plugins/example) out of the box.

# Usage

Add this repository as a submodule in your project:

```sh
git submodule add git@github.com:GaillareTech/docker-haxe.git ./libs/dhaxe
```

### Usage in Dev Container

Create the files `devcontainer.json` and `Dockerfile` in your workspaces's `.devcontainer` folder or one of its subfolders in case you want several dev containers (e.g. `.devcontainer/haxe` and `.devcontainer/nodejs`):

In `devcontainer.json`:
```jsonc
{
	// [optional] Name to display for this Dev Container
	"name": "Haxe",

	// Build instructions pointing to the Dockerfile mentioned above
	"build": {
		"context": ".",
		"dockerfile": "Dockerfile",
		"options": ["--pull=false"]
	},

	// [optional] Allow debugging via USB
	"privileged": true,
    "mounts": [
        {
            "type": "bind",
            "source": "/dev/bus/usb",
            "target": "/dev/bus/usb",
        }
    ],

	// [optional] View GUI apps (Linux-only)
	"runArgs": [
		"-e", "DISPLAY=${env:DISPLAY}",
		"-v", "/tmp/.X11-unix:/tmp/.X11-unix"
	],
	"initializeCommand": {
		"Allow connections to X server": "xhost +local:docker", // run `xhost -local:docker` to close
	},

	// Include VSCode extensions
	"customizations": {
		"vscode": {
			"extensions": [
				// Haxe support
				"nadako.vshaxe",
				// Dev Container resources information
				"mutantdino.resourcemonitor",
			]
		}
	}
}
```

In `Dockerfile`:
```Dockerfile
FROM dhaxe:4.3.6 AS build-stage

# Install additional tools here to work in your workspace (e.g: specific NodeJS version, etc) 
```

Build `dhaxe:4.3.6` by running `./libs/dhaxe/make-image.sh`.

Your Dev Container is ready to be opened (`F1` > `Dev Container: Rebuild and Reopen in Container`).

#### Install Haxe compiler plugins

In `Dockerfile`, add the following:
```Dockerfile

# Compile a plugin to work with the haxe compiler
RUN ./libs/dhaxe/setup-plugin.sh ./path/to/plugin

# Compile with a post script run from the plugin directory
RUN ./libs/dhaxe/setup-plugin.sh ./path/to/plugin --plugin-post-script "./post-script.sh"
```

- `setup-plugin.sh` compiles your [compiler plugin](https://github.com/HaxeFoundation/haxe/tree/development/plugins/example) to make it ready to use with your Haxe compiler:
  - `--plugin-post-script` runs a script from the plugin's directory after its compilation is successful.