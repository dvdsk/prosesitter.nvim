# Adding queries

Queries are language specific strings that tell the treesitter parser how to find the prose in code. They look like this: 
```
[(line_comment)+ (block_comment) (string_literal)] @capture
```

To see how queries match text see the [Treesitter documentation](https://tree-sitter.github.io/tree-sitter/using-parsers#pattern-matching-with-queries). You can easily create new ones using [Treesitter Playground](https://github.com/nvim-treesitter/playground) with its query editor. 

To add one or more queries to prosesitter make a table of extensions and the query that should be used and add that table to your config during setup under the key `extra_queries`. If a query already exists for a file extension your new query will replace it.
