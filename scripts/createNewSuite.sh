#! /bin/sh
# Scaffold a new suite package from templates/.
# Portable: sed -i differs between GNU and BSD/macOS, so we use -i.bak + rm.

if [ $# -ne 1 ]; then
    echo "Usage: $0 <folder_path>   (e.g. $0 package/acme/platform)"
    exit 1
fi

FOLDER_PATH=$1;
CODE=$(basename "$FOLDER_PATH");
VENDOR=$(basename "$(dirname "$FOLDER_PATH")");
BASE_DIR=$(dirname "$0");

if [ "$VENDOR" = "package" ] || [ -z "$VENDOR" ]; then
    echo "Error: path must be package/<vendorCode>/<suiteCode>"
    exit 1
fi

mkdir -p "$FOLDER_PATH"

# templates/. (not templates/*) so dotfiles like the REQUIRED .npmrc copy too
cp -r "$BASE_DIR"/../templates/. "$BASE_DIR/../$FOLDER_PATH"

sed -i.bak -e "s/{code}/$CODE/g" -e "s/{vendor}/$VENDOR/g" "$BASE_DIR/../$FOLDER_PATH/package.json"

UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
sed -i.bak -e "s/{id}/$UUID/g" -e "s/{code}/$CODE/g" -e "s/{vendor}/$VENDOR/g" "$BASE_DIR/../$FOLDER_PATH/index.yml"
rm -f "$BASE_DIR/../$FOLDER_PATH/package.json.bak" "$BASE_DIR/../$FOLDER_PATH/index.yml.bak"

echo "Scaffolded $FOLDER_PATH (vendor: $VENDOR, code: $CODE, id: $UUID)"
echo "Next: fill in the {name}/{description}/{url} placeholders in index.yml,"
echo "      add the suite logo, and create build.gradle.kts:"
echo "      echo 'plugins { id(\"zb.content\") }' > $FOLDER_PATH/build.gradle.kts"
