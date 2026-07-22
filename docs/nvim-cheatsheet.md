# Neovim cheatsheet

Shortcuts for the NixVim setup in this repo
([nix/nixvim/config/](../nix/nixvim/config/)). Leader is **Space**.
Press **Space and wait a moment** — which-key pops up a menu of
everything below. `Space fk` fuzzy-searches all keymaps.

Tip: practice on this file — `nvim docs/nvim-cheatsheet.md`.

## Opening files (the Finder replacement)

Two styles — fuzzy finding (fastest, use this 90% of the time) and the
file tree (for when you want to *see* the structure).

| Keys | What it does |
|---|---|
| `Space ff` | Fuzzy-find a file by name (type a few letters, Enter) |
| `Space fg` | Search file *contents* across the project (live grep) |
| `Space fw` | Search for the word under the cursor |
| `Space fr` | Recently opened files |
| `Space fb` | Currently open files (buffers) |
| `Space fd` | Telescope file browser (create/rename/delete from a picker) |
| `notes` (in terminal) | Open nvim in your notes dir, straight into the fuzzy finder |

Inside any Telescope picker: type to filter, `C-j`/`C-k` (or arrows) to
move, `Enter` to open, `C-v` open in vertical split, `C-x` horizontal
split, `Esc Esc` to close.

## File tree (Neo-tree)

| Keys | What it does |
|---|---|
| `Space e` | Toggle the file tree |
| `Space o` | Jump focus to the tree (from a file) |

With the cursor **inside the tree** (plain keys, no leader — press `?`
in the tree to see all of them):

| Keys | What it does |
|---|---|
| `j` / `k` | Move down / up |
| `Enter` | Open file, or expand/collapse folder |
| `a` | Add file (end the name with `/` to make a folder) |
| `d` | Delete |
| `r` | Rename |
| `c` / `m` | Copy / move |
| `x` / `p` | Cut / paste |
| `H` | Toggle hidden files |
| `/` | Filter the tree |
| `Backspace` | Go up one directory (change tree root) |
| `.` | Set folder under cursor as tree root |
| `s` / `S` | Open file in vertical / horizontal split |
| `R` | Refresh |
| `?` | Show all tree keybindings |

## Buffers ("tabs" at the top) and windows (splits)

| Keys | What it does |
|---|---|
| `S-h` / `S-l` | Previous / next buffer (capital H / L) |
| `Space bd` | Close current buffer |
| `C-h` `C-j` `C-k` `C-l` | Jump between splits (left/down/up/right) |
| `:vsp` / `:sp` | Vertical / horizontal split |
| `Esc` | Also clears search highlighting |

## Git

| Keys | What it does |
|---|---|
| `Space gs` | Changed files (git status) |
| `Space gc` | Commit history |
| `Space gb` | Branches |
| `Space gf` | Find among git-tracked files |

Changed lines show as colored marks in the left gutter (gitsigns).

## Code navigation (LSP)

| Keys | What it does |
|---|---|
| `gd` | Go to definition |
| `gr` | Find references |
| `gi` | Go to implementation |
| `K` | Hover docs for symbol under cursor |
| `Space rn` | Rename symbol project-wide |
| `Space ca` | Code actions (quick fixes) |
| `[d` / `]d` | Previous / next diagnostic (error/warning) |
| `Space de` | Show diagnostic under cursor in a popup |
| `Space ls` | Symbols in this file (functions, classes) |
| `Space lw` | Symbols across the workspace |
| `C-o` / `C-i` | Jump back / forward (after `gd` etc.) |

## Completion (insert mode)

| Keys | What it does |
|---|---|
| `Tab` / `S-Tab` | Next / previous suggestion |
| `Enter` | Accept |
| `C-e` | Dismiss |
| `C-Space` | Trigger manually |

## Markdown / notes

| Keys | What it does |
|---|---|
| `Space mp` | Live preview in the browser |
| `z=` | Spelling suggestions for word under cursor |
| `]s` / `[s` | Next / previous spelling mistake |

Markdown buffers automatically get soft wrap, spell check, and pretty
in-buffer rendering (headings, checkboxes, tables).

## Treesitter power moves (bonus)

| Keys | What it does |
|---|---|
| `C-Space` (normal mode) | Start/grow smart selection (function → class → …) |
| `vif` / `vaf` | Select inside / around a function |
| `vic` / `vac` | Select inside / around a class |
| `]m` / `[m` | Next / previous function |
