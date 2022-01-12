Any file in this dir ending in _spec.lua is ran by plenary as test in a **seperate** neovim instance.
for documentation on testing see: http://olivinelabs.com/busted/
(note not all calls supported see plenary test to see which are)

This tests in this directory are run by plenary after calling nvim with -c "PlenaryBustedDirectory" lua/prosesitter/tests/ 

see the makefile in the root directory
