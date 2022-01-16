
test_data:
	mkdir -p test_data

test_data/vale: | test_data
	cd test_data; \
	../scripts/install_vale.sh

# if the download fails or is incomplete this will 
# not run again on its own, instead strange class warnings will appear
# do make clean and re-run
test_data/languagetool: | test_data
	cd test_data; \
	../scripts/install_langtool.sh

test: test_data/vale test_data/languagetool
	echo "===> Testing:"
	echo "starting langtool"
	scripts/start_langtool.sh
	echo "starting tests"
	nvim --headless --clean \
	-u scripts/minimal.vim \
	-c "PlenaryBustedDirectory lua/prosesitter/tests/ {minimal_init = 'scripts/minimal.vim'}"

.PHONY: test clean

clean:
	rm -rf test_data/
