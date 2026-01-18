# visual-match-paren.nvim

A Neovim plugin that highlights the matching closing brace when you visually select a line ending with `{`.

## Features

- Automatically highlights the matching `}` when you visually select a line ending with `{`
- Works in visual, visual-line, and visual-block modes
- Customizable highlight group
- Lightweight and performant

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yourusername/visual-match-paren.nvim",
  config = function()
    require("visual-match-paren").setup({
      -- Optional configuration
      highlight_group = "MatchParen", -- Highlight group to use (default: "MatchParen")
      enabled = true,                 -- Enable/disable the plugin (default: true)
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "yourusername/visual-match-paren.nvim",
  config = function()
    require("visual-match-paren").setup()
  end,
}
```

## Usage

Simply enter visual mode and select a line that ends with `{`. The plugin will automatically highlight the corresponding `}`.

### Example

```json
{
  "probando": {
    "he": "ho"
  }
}
```

When you visually select the line `"probando": {`, the closing `}` on line 5 will be highlighted.

## Commands

- `:VisualMatchParenToggle` - Toggle the plugin on/off

## Configuration

The plugin can be configured with the following options:

```lua
require("visual-match-paren").setup({
  highlight_group = "MatchParen", -- The highlight group to use
  enabled = true,                 -- Enable the plugin by default
})
```

## How it works

The plugin listens for mode changes and cursor movements in visual mode. When you're in visual mode, it:

1. Detects if the last selected line ends with `{`
2. Positions the cursor on the opening brace
3. Uses Neovim's built-in `searchpairpos` to find the matching `}`
4. Highlights the matching brace using the specified highlight group

This ensures that nested structures are matched correctly, even in deeply nested JSON, JavaScript, or other brace-based languages.

## Testing

See [tests/README.md](tests/README.md) for information about running tests.

```bash
make test
```

## License

MIT
