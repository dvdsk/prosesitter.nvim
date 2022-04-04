# Adding queries

Queries are language specific strings that tell the treesitter parser how to find the prose in code. They look like this:
```
[(line_comment)+ (block_comment) (string_literal)] @capture
```

For prosesitter to be able to automatically merge string only and comment lint targets we need the outer square brackets even if there is only a single pattern cought by a query.
To see how queries match text see the [Treesitter documentation](https://tree-sitter.github.io/tree-sitter/using-parsers#pattern-matching-with-queries). around the query You can easily create new ones using [Treesitter Playground](https://github.com/nvim-treesitter/playground) with its query editor.

To add one or more queries to prosesitter make a table of extensions and the query that should be used and add that table to your config during setup under the key `extra_queries`. If a query already exists for a file extension your new query will replace it.

language tool rules: https://community.languagetool.org/rule/list?lang=en
