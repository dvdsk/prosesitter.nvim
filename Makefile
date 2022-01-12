test:
	echo "===> Testing:"
	nvim --headless --clean \
	-u scripts/minimal.vim \
	-c "PlenaryBustedDirectory lua/prosesitter/tests/ {minimal_init = 'scripts/minimal.vim'}"

.PHONY: test
