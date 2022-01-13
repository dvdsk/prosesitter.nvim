#!/usr/bin/env bash
set -e 

GREEN='\033[0;32m'
NC='\033[0m' # No Color

function latest_version() {
	local release=$(curl -L -s -H 'Accept: application/json' $1/releases/latest)
	local version=$(echo $release | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
	echo $version
}

function os_str() {
	local os_str
	if [[ "$OSTYPE" == "linux-gnu"* ]]; then
		echo Linux
	elif [[ "$OSTYPE" == "darwin"* ]]; then
		echo macOS
	else 
		echo "Error: Os other then linux and macOS not supported by install script"
		exit -1
	fi
}

# setup vale binary
latest_version=$(latest_version https://github.com/errata-ai/vale)
fname="vale_${latest_version:1}_$(os_str)_64-bit.tar.gz"
url="https://github.com/errata-ai/vale/releases/download/$latest_version/$fname"
printf "${GREEN}downloading vale${NC}\n"
curl --location $url | tar --gzip --extract --directory . vale

# setup styles
tmp="/tmp/prosesitter"
mkdir -p $tmp
mkdir -p styles

styles="Microsoft Google write-good proselint Joblint alex"
printf "${GREEN}setting up vale styles${NC}\n"

for style in $styles; do
	release=$(latest_version https://github.com/errata-ai/$style)
	version=$(echo $release | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
	url="https://github.com/errata-ai/$style/releases/download/$version/$style.zip"
	curl --location --output "$tmp/$style.zip" $url 
	unzip -q "$tmp/$style.zip" -d styles
done

printf "${GREEN}done installing vale, restart nvim for changes to take effect${NC}\n"
