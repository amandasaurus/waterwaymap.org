#! /bin/sh
set -o errexit
if [ "${1:-}" = "-v" ] ; then
	set -x
	shift
fi

if [ "$(hostname)" != "wwm-render1" ] ; then
	echo 1>&2 "Wrong host"
	exit 1
fi


apt update -qq
apt full-upgrade -qq --yes --auto-remove
apt install --yes -qq git build-essential btop aria2 osmium-tool neovim jo jq moreutils rclone screen units pyosmium
mkdir -p /srv/

if [ ! -d /srv/waterwaymap.org/ ] ; then
	cd /srv/
	./ssh.sh git clone https://github.com/amandasaurus/waterwaymap.org.git
fi

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
cargo install osm-lump-ways

apt install --yes -qq build-essential libsqlite3-dev zlib1g-dev checkinstall
if [ ! -d /srv/tippecanoe/ ] ; then
	cd /srv/
	git clone https://github.com/felt/tippecanoe.git
fi
cd /srv/tippecanoe
make -j
checkinstall --default

mkdir -p /root/.terminfo/x/
