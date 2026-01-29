local visual_match_paren = require("visual-match-paren")

describe("visual-match-paren", function()
  before_each(function()
    visual_match_paren.setup()
    vim.cmd("enew")
  end)

  after_each(function()
    vim.cmd("bwipeout!")
  end)

  describe("nested JSON structures", function()
    it("should match the correct closing brace for nested options object", function()
      local json_content = {
        '{',
        '  "name": "workspace",',
        '  "$schema": "node_modules/nx/schemas/project-schema.json",',
        '  "targets": {',
        '    "set-projects-version": {',
        '      "executor": "nx:run-commands",',
        '      "options": {',
        '        "commands": [',
        '          "npm version {args.version} --no-git-tag-version --allow-same-version --workspaces=false",',
        '          "nx run-many --target set-version --all -- --version={args.version}",',
        '          "nx run workspace:resolve-projects-package-local-deps"',
        '        ],',
        '        "parallel": false',
        '      }',
        '    }',
        '  }',
        '},',
      }
      
      vim.api.nvim_buf_set_lines(0, 0, -1, false, json_content)
      
      -- Position cursor on line 7 (options line)
      vim.api.nvim_win_set_cursor(0, {7, 0})
      
      -- Enter visual mode and select the line
      vim.cmd("normal! V")
      
      -- Trigger the highlighting
      visual_match_paren.highlight_matching_brace()
      
      -- Get highlights
      local namespace = vim.api.nvim_create_namespace("visual-match-paren")
      local highlights = vim.api.nvim_buf_get_extmarks(0, namespace, 0, -1, {details = true})
      
      -- Should highlight line 14 (closing brace for options), not line 15 or 16
      assert.is_true(#highlights > 1, "Expected at least two highlights")
      local highlight_line = highlights[2][2] + 1
      assert.equals(14, highlight_line, "Should highlight closing brace on line 14 for options object")
      
      vim.cmd("normal! \\<ESC>")
    end)

    it("should match the correct closing brace for set-projects-version object", function()
      local json_content = {
        '{',
        '  "name": "workspace",',
        '  "$schema": "node_modules/nx/schemas/project-schema.json",',
        '  "targets": {',
        '    "set-projects-version": {',
        '      "executor": "nx:run-commands",',
        '      "options": {',
        '        "commands": [',
        '          "npm version {args.version} --no-git-tag-version --allow-same-version --workspaces=false",',
        '          "nx run-many --target set-version --all -- --version={args.version}",',
        '          "nx run workspace:resolve-projects-package-local-deps"',
        '        ],',
        '        "parallel": false',
        '      }',
        '    }',
        '  }',
        '},',
      }
      
      vim.api.nvim_buf_set_lines(0, 0, -1, false, json_content)
      
      -- Position cursor on line 5 (set-projects-version line)
      vim.api.nvim_win_set_cursor(0, {5, 0})
      
      -- Enter visual mode and select the line
      vim.cmd("normal! V")
      
      -- Trigger the highlighting
      visual_match_paren.highlight_matching_brace()
      
      -- Get highlights
      local namespace = vim.api.nvim_create_namespace("visual-match-paren")
      local highlights = vim.api.nvim_buf_get_extmarks(0, namespace, 0, -1, {details = true})
      
      -- Should highlight line 15 (closing brace for set-projects-version)
      assert.is_true(#highlights > 1, "Expected at least two highlights")
      local highlight_line = highlights[2][2] + 1
      assert.equals(15, highlight_line, "Should highlight closing brace on line 15 for set-projects-version object")
      
      vim.cmd("normal! \\<ESC>")
    end)

    it("should match the correct closing brace for targets object", function()
      local json_content = {
        '{',
        '  "name": "workspace",',
        '  "$schema": "node_modules/nx/schemas/project-schema.json",',
        '  "targets": {',
        '    "set-projects-version": {',
        '      "executor": "nx:run-commands",',
        '      "options": {',
        '        "commands": [',
        '          "npm version {args.version} --no-git-tag-version --allow-same-version --workspaces=false",',
        '          "nx run-many --target set-version --all -- --version={args.version}",',
        '          "nx run workspace:resolve-projects-package-local-deps"',
        '        ],',
        '        "parallel": false',
        '      }',
        '    }',
        '  }',
        '},',
      }
      
      vim.api.nvim_buf_set_lines(0, 0, -1, false, json_content)
      
      -- Position cursor on line 4 (targets line)
      vim.api.nvim_win_set_cursor(0, {4, 0})
      
      -- Enter visual mode and select the line
      vim.cmd("normal! V")
      
      -- Trigger the highlighting
      visual_match_paren.highlight_matching_brace()
      
      -- Get highlights
      local namespace = vim.api.nvim_create_namespace("visual-match-paren")
      local highlights = vim.api.nvim_buf_get_extmarks(0, namespace, 0, -1, {details = true})
      
      -- Should highlight line 16 (closing brace for targets)
      assert.is_true(#highlights > 1, "Expected at least two highlights")
      local highlight_line = highlights[2][2] + 1
      assert.equals(16, highlight_line, "Should highlight closing brace on line 16 for targets object")
      
      vim.cmd("normal! \\<ESC>")
    end)
  end)

  describe("simple JSON structures", function()
    it("should match closing brace for simple nested object", function()
      local json_content = {
        '{',
        '  "probando": {',
        '    "he": "ho"',
        '  }',
        '}',
      }
      
      vim.api.nvim_buf_set_lines(0, 0, -1, false, json_content)
      
      -- Position cursor on line 2 (probando line)
      vim.api.nvim_win_set_cursor(0, {2, 0})
      
      -- Enter visual mode and select the line
      vim.cmd("normal! V")
      
      -- Trigger the highlighting
      visual_match_paren.highlight_matching_brace()
      
      -- Get highlights
      local namespace = vim.api.nvim_create_namespace("visual-match-paren")
      local highlights = vim.api.nvim_buf_get_extmarks(0, namespace, 0, -1, {details = true})
      
      -- Should highlight line 4 (closing brace for probando)
      assert.is_true(#highlights > 1, "Expected at least two highlights")
      local highlight_line = highlights[2][2] + 1
      assert.equals(4, highlight_line, "Should highlight closing brace on line 4")
      
      vim.cmd("normal! \\<ESC>")
    end)
  end)

  describe("non-matching cases", function()
    it("should not highlight when line doesn't end with {", function()
      local json_content = {
        '{',
        '  "name": "value",',
        '  "number": 123',
        '}',
      }
      
      vim.api.nvim_buf_set_lines(0, 0, -1, false, json_content)
      
      -- Position cursor on line 2 (doesn't end with {)
      vim.api.nvim_win_set_cursor(0, {2, 0})
      
      -- Enter visual mode and select the line
      vim.cmd("normal! V")
      
      -- Trigger the highlighting
      visual_match_paren.highlight_matching_brace()
      
      -- Get highlights
      local namespace = vim.api.nvim_create_namespace("visual-match-paren")
      local highlights = vim.api.nvim_buf_get_extmarks(0, namespace, 0, -1, {details = true})
      
      -- Should not highlight anything
      assert.equals(0, #highlights, "Should not highlight when line doesn't end with {")
      
      vim.cmd("normal! \\<ESC>")
    end)
  end)

  describe("edge cases", function()
    it("should handle multiple braces on the same line", function()
      local json_content = {
        '{',
        '  "inline": { "nested": {',
        '    "value": "test"',
        '  } }',
        '}',
      }
      
      vim.api.nvim_buf_set_lines(0, 0, -1, false, json_content)
      
      -- Position cursor on line 2 (line with multiple opening braces)
      vim.api.nvim_win_set_cursor(0, {2, 0})
      
      -- Enter visual mode and select the line
      vim.cmd("normal! V")
      
      -- Trigger the highlighting
      visual_match_paren.highlight_matching_brace()
      
      -- Get highlights
      local namespace = vim.api.nvim_create_namespace("visual-match-paren")
      local highlights = vim.api.nvim_buf_get_extmarks(0, namespace, 0, -1, {details = true})
      
      -- Should find a matching brace (the rightmost { on line 2)
      assert.is_true(#highlights > 0, "Expected at least one highlight")
      
      vim.cmd("normal! \\<ESC>")
    end)
  end)

  describe("TypeScript function scope highlighting", function()
    before_each(function()
      vim.cmd("set filetype=typescript")
    end)

    it("should highlight only the function scope when selecting function declaration line", function()
      local ts_content = {
        'import { readFileSync } from "fs";',
        '',
        'export async function generateNxWorkspace(options: {',
        '  nxVersion: string;',
        '  outputPath: string;',
        '}) {',
        '  console.log("starting");',
        '  return true;',
        '}',
        '',
        'function checkForNpmInstallationLogErrors(message: string) {',
        '  const logFileMatch = message.match(/Log file/);',
        '  if (logFileMatch) {',
        '    const logFilePath = logFileMatch[1];',
        '    try {',
        '      const logContent = readFileSync(logFilePath, "utf-8");',
        '      console.log(logContent);',
        '    } catch (err) {',
        '      if (err instanceof Error) {',
        '        console.error(err.message);',
        '      } else {',
        '        console.error("An unknown error occurred");',
        '      }',
        '    }',
        '  }',
        '}',
      }
      
      vim.api.nvim_buf_set_lines(0, 0, -1, false, ts_content)
      vim.bo.filetype = 'typescript'
      
      -- Position cursor on line 11 (checkForNpmInstallationLogErrors function declaration)
      vim.api.nvim_win_set_cursor(0, {11, 0})
      
      -- Enter visual mode and select the line
      vim.cmd("normal! V")
      
      -- Trigger the highlighting
      visual_match_paren.highlight_matching_brace()
      
      -- Get scope highlights (different namespace)
      local scope_namespace = vim.api.nvim_create_namespace("visual-match-paren-scope")
      local scope_highlights = vim.api.nvim_buf_get_extmarks(0, scope_namespace, 0, -1, {details = true})
      
      -- Should highlight the function body (lines 12-25), not the entire file
      assert.is_true(#scope_highlights > 0, "Expected scope highlights")
      
      -- Check that the first highlighted line is line 12 (start of function body)
      local first_highlight_line = scope_highlights[1][2] + 1
      assert.is_true(first_highlight_line >= 11, "First highlight should be at or after line 11")
      
      -- Check that the last highlighted line is line 26 (end of function)
      local last_highlight_line = scope_highlights[#scope_highlights][2] + 1
      assert.equals(26, last_highlight_line, "Last highlight should be line 26 (end of function)")
      
      -- Ensure we didn't highlight the entire file (which would include line 1)
      local has_line_1 = false
      for _, mark in ipairs(scope_highlights) do
        if mark[2] + 1 == 1 then
          has_line_1 = true
          break
        end
      end
      assert.is_false(has_line_1, "Should not highlight line 1 when selecting function on line 11")
      
      vim.cmd("normal! \\<ESC>")
    end)

    it("should highlight function scope when selecting first function", function()
      local ts_content = {
        'import { readFileSync } from "fs";',
        '',
        'export async function generateNxWorkspace(options: {',
        '  nxVersion: string;',
        '  outputPath: string;',
        '}) {',
        '  console.log("starting");',
        '  return true;',
        '}',
        '',
        'function checkForNpm() {',
        '  console.log("check");',
        '}',
      }
      
      vim.api.nvim_buf_set_lines(0, 0, -1, false, ts_content)
      vim.bo.filetype = 'typescript'
      
      -- Position cursor on line 3 (generateNxWorkspace function declaration)
      vim.api.nvim_win_set_cursor(0, {3, 0})
      
      -- Enter visual mode and select the line
      vim.cmd("normal! V")
      
      -- Trigger the highlighting
      visual_match_paren.highlight_matching_brace()
      
      -- Get scope highlights
      local scope_namespace = vim.api.nvim_create_namespace("visual-match-paren-scope")
      local scope_highlights = vim.api.nvim_buf_get_extmarks(0, scope_namespace, 0, -1, {details = true})
      
      -- Should highlight the function (lines 3-9), not the entire file
      assert.is_true(#scope_highlights > 0, "Expected scope highlights")
      
      -- Check that we didn't highlight beyond line 9
      local last_highlight_line = scope_highlights[#scope_highlights][2] + 1
      assert.is_true(last_highlight_line <= 9, "Should not highlight beyond line 9")
      
      -- Ensure we didn't highlight line 11 (different function)
      local has_line_11 = false
      for _, mark in ipairs(scope_highlights) do
        if mark[2] + 1 == 11 then
          has_line_11 = true
          break
        end
      end
      assert.is_false(has_line_11, "Should not highlight line 11 when selecting function on line 3")
      
      vim.cmd("normal! \\<ESC>")
    end)
  end)
end)
