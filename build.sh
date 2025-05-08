HERE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

echo "Build image haxe:4.3.6-gllr"
docker build --pull -t haxe:4.3.6-gllr $HERE