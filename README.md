# docker-haxe

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
FROM haxe:4.3.6-gllr AS build-stage

# Install additional tools here to work in your workspace (e.g: specific NodeJS version, etc) 
```

Build `haxe:4.3.6-gllr` by running `./make-image.sh`.

Your Dev Container is ready to be opened (`F1` > `Dev Container: Rebuild and Reopen in Container`).
