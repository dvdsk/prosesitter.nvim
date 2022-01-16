#!/usr/bin/env bash

BIN_PATH=test_data/languagetool/languagetool-server.jar
CONFIG_PATH=test_data/langtool.cfg
PORT=34287

CONFIG_SOURCE=lua/prosesitter/config/defaults.lua
CONFIG="$(sed -n '/M.langtool_cfg/,/]==]/p' $CONFIG_SOURCE | head -n -1 | tail -n -1)"
echo "${CONFIG}" > $CONFIG_PATH

cd $(dirname $BIN_PATH)
nohup java -cp $(basename $BIN_PATH) org.languagetool.server.HTTPServer $CONFIG_PATH --port $PORT &

# wait till languagetool server starts responding
while [[ true ]]; do
	resp=$(curl --no-progress-meter \
		--data-urlencode language=en-US \
		--data-urlencode disabledCategories=STYLE \
		--data-urlencode text=hi \
		http://localhost:$PORT/v2/check
	)
	
	if !$?; then
		echo hi
		continue
	fi

	if [[ $resp = "{\"software\":{\"name\":\"LanguageTool\","* ]]; then
		break
	else 
		echo "Incorrect response from languageclient"
		exit -1
	fi
done
