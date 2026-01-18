# Testing visual-match-paren.nvim

## Prerequisites

You need [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) installed for testing.

```bash
# Install plenary.nvim with lazy.nvim or your package manager
# Or clone it directly:
git clone https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/lazy/plenary.nvim
```

## Running Tests

### Using Make

```bash
make test
```

### Manual Testing

```bash
nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"
```

## Test Cases

The test suite covers:

1. **Nested JSON structures**: Verifies that when selecting a line with `{`, the correct matching `}` is highlighted at the proper nesting level
   - Options object (nested 3 levels deep)
   - Set-projects-version object (nested 2 levels deep)
   - Targets object (nested 1 level deep)

2. **Simple JSON structures**: Basic nested object matching

3. **Non-matching cases**: Lines that don't end with `{` should not trigger highlighting

4. **Edge cases**: Multiple braces on the same line

## Example Test Case

When selecting the line `"options": {` in this JSON:

```json
{
  "targets": {
    "set-projects-version": {
      "options": {
        "commands": []
      }
    }
  }
}
```

The plugin should highlight the closing `}` on line 6 (for options), NOT the closing `}` on line 7 (for set-projects-version) or line 8 (for targets).
