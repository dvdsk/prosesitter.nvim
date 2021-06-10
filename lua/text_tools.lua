-- which key
require("which-key").setup {}

require("kommentary.config").configure_language("default", {
	prefer_single_line_comments = true,
})

-- should probaly use autocommand to chance settings for latex
require("spellsitter").setup()
