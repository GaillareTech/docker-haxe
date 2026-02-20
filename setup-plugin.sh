set -e
HERE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
WORKING_DIR=$(pwd)

if [ -z "$HAXE_COMPILER_DIR" ]; then
	# Run in a docker container already
	echo "ERROR: setup-plugin.sh must run from within the container. You can run it from your Dockerfile."
	exit 1
fi

read_json_field() {
  JSON_PATH="$1"
  FIELD_NAME="$2"
  cat "$JSON_PATH" | grep -o "\"$FIELD_NAME\"\s*:\s*\"[^\"]*\"" | sed 's|[^:]*:\s*"\([^"]*\)"|\1|'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    ""|--help)
      echo "Setup a Haxe plugin in your Haxe container (linux only)"
      echo "Usage: setup-plugin.sh <path/to/plugin> [options...]"
      echo "Options:"
		  echo " "
      echo -e "  --plugin-post-script <cmd> \t Run a bash script inside the plugin directory after a successful build, such as 'bash -c \"<cmd>\"'"
      exit 0 ;;
    --plugin-post-script=*)
      POST_PLUGIN_SCRIPT=${1#*--plugin-post-script=}
      shift ;;
    --plugin-post-script)
      POST_PLUGIN_SCRIPT="$2"
      shift
      shift ;;
    *)
      PLUGIN_SRC="$1"
      shift ;;
  esac
done

# Arg: plugin path
PLUGIN_SRC=./libs/ecso
PLUGIN_NAME=`basename $PLUGIN_SRC`

if [ ! -d "$PLUGIN_SRC" ]; then
  echo "$PLUGIN_SRC does not exist."
  exit 1
fi

echo "HAXE_COMPILER_DIR=$HAXE_COMPILER_DIR"
echo "PLUGIN_SRC=$PLUGIN_SRC"
echo "PLUGIN_NAME=$PLUGIN_NAME"

PLUGIN_SYMLINK=$HAXE_COMPILER_DIR/plugins/$PLUGIN_NAME
rsync -avu --delete "$PLUGIN_SRC/" "$PLUGIN_SYMLINK"

# Build plugin from the Haxe directory
cd $HAXE_COMPILER_DIR

# Make dune command available
eval $(opam config env)

# Build
make PLUGIN=$PLUGIN_NAME plugin

# Run post-scripts
cd $PLUGIN_SYMLINK
if [ ! -z "$POST_PLUGIN_SCRIPT" ]; then
  bash -c "$POST_PLUGIN_SCRIPT"
fi

# MOVE BACK OUTPUT
cd $WORKING_DIR
rsync -avu --delete "$PLUGIN_SYMLINK/cmxs/" "$PLUGIN_SRC/cmxs"

# Add plugin's haxelib
PLUGIN_HAXELIB="$(find "$PLUGIN_SRC" -name 'haxelib.json')"
PLUGIN_HAXELIB_DIR="$(dirname "$PLUGIN_HAXELIB")"
if [ -z "$PLUGIN_HAXELIB" ]; then
  echo "Warning: No haxelib.json found in $PLUGIN_SRC"
else
  PLUGIN_HAXELIB_NAME=$(read_json_field "$PLUGIN_HAXELIB" "name")
  haxelib dev $PLUGIN_HAXELIB_NAME $PLUGIN_HAXELIB_DIR
fi