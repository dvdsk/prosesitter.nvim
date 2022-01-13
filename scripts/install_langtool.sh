#!/usr/bin/env bash
set -e 

GREEN='\033[0;32m'
NC='\033[0m' # No Color
  
tmp="/tmp/prosesitter"
mkdir -p $tmp
mkdir -p languagetool

url="https://languagetool.org/download/LanguageTool-stable.zip"
printf "${GREEN}downloading languagetool${NC}\n"
curl --location --output "$tmp/langtool.zip" $url 
unzip -q "$tmp/langtool.zip" -d languagetool

# get languagetool-server.jar and its dependencies out of the version specific
# folder into one we can depend on
mv languagetool/*/* languagetool 

printf "${GREEN}done installing languagetool, restart nvim for changes to take effect${NC}\n"
