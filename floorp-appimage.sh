#!/bin/sh

set -ex

export ARCH=$(uname -m)
REPO="https://api.github.com/repos/Floorp-Projects/Floorp/releases"
APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
DESKTOP="https://github.com/flathub/one.ablaze.floorp/raw/refs/heads/master/src/share/applications/one.ablaze.floorp.desktop"
export URUNTIME_PRELOAD=1 # really needed here

# ruffle uses amd64 instead of x86_64
tarball_url=$(wget "$REPO" -O - | sed 's/[()",{} ]/\n/g' \
	| grep -oi "https.*linux-$ARCH.tar.bz2$" | head -1)

export VERSION=$(echo "$tarball_url" | awk -F'/' '{print $(NF-1); exit}')
echo "$VERSION" > ~/version

wget "$tarball_url" -O ./package.tar.bz2
tar xvf ./package.tar.bz2
rm -f ./package.tar.bz2

mv -v ./floorp ./AppDir && (
	cd ./AppDir
	cp -v ./browser/chrome/icons/default/default128.png ./one.ablaze.floorp.png
	cp -v ./browser/chrome/icons/default/default128.png ./.DirIcon
	wget "$DESKTOP" -O ./floorp.desktop

	cat > ./AppRun <<- 'KEK'
	#!/bin/sh
	CURRENTDIR="$(dirname "$(readlink -f "$0")")"
	export PATH="${CURRENTDIR}:${PATH}"
	export MOZ_LEGACY_PROFILES=1          # Prevent per installation profiles
	export MOZ_APP_LAUNCHER="${APPIMAGE}" # Allows setting as default browser
	exec "${CURRENTDIR}/floorp" "$@"
	KEK
	chmod +x ./AppRun

	# disable automatic updates
	mkdir -p ./distribution
	cat >> ./distribution/policies.json <<- 'KEK'
	{
	  "policies": {
	    "DisableAppUpdate": true,
	    "AppAutoUpdate": false,
	    "BackgroundAppUpdate": false
	  }
	}
	KEK
)

wget "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool
./appimagetool -n -u "$UPINFO" ./AppDir
