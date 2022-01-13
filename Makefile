
test_data:
	mkdir -p test_data

test_data/vale: | test_data
	cd test_data; \
	../scripts/install_vale.sh

test_data/languagetool: | test_data
	cd test_data; \
	../scripts/install_langtool.sh

test: test_data/vale test_data/languagetool
	echo "===> Testing:"
	nvim --headless --clean \
	-u scripts/minimal.vim \
	-c "PlenaryBustedDirectory lua/prosesitter/tests/ {minimal_init = 'scripts/minimal.vim'}"

.PHONY: test
