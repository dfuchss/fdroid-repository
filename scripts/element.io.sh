#!/bin/bash
mkdir -p releases

DEPLOY="$GITHUB_WORKSPACE/fdroid"
PWD=$(pwd)

LATEST=$(curl --silent "https://api.github.com/repos/vector-im/element-android/releases/latest" | jq -r .tag_name)
echo "Latest Version $LATEST"

if compgen -G "releases/element-$LATEST*.apk" > /dev/null; then
        echo "Version already present."
        exit 0
fi

if [[ ! "$LATEST" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "New RC $LATEST .. skipping as no release .."
        exit 0
fi

echo "Downloading Latest Version $LATEST"
wget -qO "releases/element-$LATEST.apk" https://github.com/vector-im/element-android/releases/download/$LATEST/vector-gplay-arm64-v8a-release-signed.apk

echo "Saving Release for Deployment to $DEPLOY"
mkdir -p $DEPLOY/repo
install releases/element-$LATEST.apk $DEPLOY/repo/
rm releases/element-$LATEST.apk

VER=$(date +%s)
echo $VER > releases/element-$LATEST.apk

cd $DEPLOY
META=$DEPLOY/metadata/im.vector.app.yml
if [ -f "$META" ]; then
        echo "Updating Meta Data"
        sed -i "s/CurrentVersionCode.*/CurrentVersionCode: $VER/g" $META
else
        echo "Meta Data not present. Please update on your own"
fi

docker run --rm -u $UID -v $DEPLOY:/repo registry.gitlab.com/fdroid/docker-executable-fdroidserver:master update

echo "Finished Deployment"
