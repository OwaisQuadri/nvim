-- hackerman.lua
-- Translucent-black terminal glass, neon green everything else.
-- Normal has no background on purpose: Ghostty's translucency shows through
-- (see the clear_bg autocmd in init.lua, which enforces this on every theme).
--
-- Iterate with `:Inspect` (what group is under the cursor) and
-- `:so $VIMRUNTIME/syntax/hitest.vim` (every group at once).

vim.cmd 'highlight clear'
if vim.fn.exists 'syntax_on' == 1 then vim.cmd 'syntax reset' end
vim.g.colors_name = 'hackerman'
vim.o.background = 'dark'

-- [[ Palette ]]
-- Everything bright and high-contrast, including the greys.
local p = {
  -- greens (the stars)
  neon = '#39ff14', -- keywords, accents, borders
  spring = '#00ff9f', -- functions
  mint = '#8affc1', -- strings
  lime = '#b7ff5c', -- numbers, constants, preproc
  fg = '#d7ffe0', -- normal text: pale minty white

  -- teals
  teal = '#17f5d3', -- diagnostics info/hint, specials
  aqua = '#5fffd7', -- types

  -- supporting cast (can't be green: errors/warns must read as errors/warns)
  red = '#ff4d4d',
  yellow = '#ffe75c',
  orange = '#ffab5c',
  purple = '#c46bff', -- booleans, builtins, macros/decorators: the "magic" stuff

  -- greys, kept bright and green-tinted
  grey1 = '#a5c9b8', -- comments
  grey2 = '#86ab97', -- line numbers, delimiters, UI chrome
  grey3 = '#628270', -- whitespace chars, folds' gutter

  -- backgrounds (near-black, used sparingly so the glass stays visible)
  black = '#071009', -- fg for text sitting on a neon background
  bg_float = '#0c1710', -- popups, statusline
  bg_line = '#13241a', -- cursorline, reference highlights
  bg_visual = '#1c4a2e', -- visual selection

  -- diff backgrounds
  bg_add = '#0f3320',
  bg_del = '#33100f',
  bg_change = '#2e2a0e',
  bg_text = '#4d460f',
}

-- stylua: ignore
local groups = {
  -- [[ Editor UI ]]
  Normal = { fg = p.fg }, -- no bg: terminal glass
  Cursor = { fg = p.black, bg = p.neon },
  CursorLine = { bg = p.bg_line },
  CursorColumn = { link = 'CursorLine' },
  ColorColumn = { bg = p.bg_line },
  CursorLineNr = { fg = p.neon, bold = true },
  LineNr = { fg = p.grey2 },
  SignColumn = { fg = p.grey2 },
  FoldColumn = { fg = p.grey3 },
  Folded = { fg = p.grey1, bg = p.bg_line },
  Conceal = { fg = p.grey2 },
  EndOfBuffer = { fg = p.grey3 },
  NonText = { fg = p.grey3 },
  Whitespace = { fg = p.grey3 },
  SpecialKey = { fg = p.grey3 },
  WinSeparator = { fg = p.grey2 },
  StatusLine = { fg = p.fg, bg = p.bg_float },
  StatusLineNC = { fg = p.grey2, bg = p.bg_float },
  TabLine = { fg = p.grey1, bg = p.bg_float },
  TabLineFill = { bg = p.bg_float },
  TabLineSel = { fg = p.neon, bold = true },
  Title = { fg = p.neon, bold = true },
  Directory = { fg = p.spring },
  Visual = { bg = p.bg_visual },
  VisualNOS = { link = 'Visual' },
  Search = { fg = p.black, bg = p.yellow },
  IncSearch = { fg = p.black, bg = p.orange },
  CurSearch = { link = 'IncSearch' },
  Substitute = { link = 'IncSearch' },
  MatchParen = { fg = p.neon, bold = true, underline = true },
  Pmenu = { fg = p.fg, bg = p.bg_float },
  PmenuSel = { fg = p.black, bg = p.neon, bold = true },
  PmenuSbar = { bg = p.bg_line },
  PmenuThumb = { bg = p.grey2 },
  WildMenu = { link = 'PmenuSel' },
  NormalFloat = { fg = p.fg, bg = p.bg_float },
  FloatBorder = { fg = p.neon, bg = p.bg_float },
  FloatTitle = { fg = p.neon, bold = true },
  MsgArea = { fg = p.fg },
  ErrorMsg = { fg = p.red, bold = true },
  WarningMsg = { fg = p.yellow },
  ModeMsg = { fg = p.spring, bold = true },
  MoreMsg = { fg = p.spring },
  Question = { fg = p.teal },
  QuickFixLine = { bg = p.bg_visual },
  SpellBad = { undercurl = true, sp = p.red },
  SpellCap = { undercurl = true, sp = p.yellow },
  SpellLocal = { undercurl = true, sp = p.teal },
  SpellRare = { undercurl = true, sp = p.aqua },

  -- [[ Syntax ]]
  -- Treesitter @groups and most plugins link here by default,
  -- so these ~20 groups do the bulk of the work.
  Comment = { fg = p.grey1, italic = true },
  Constant = { fg = p.lime },
  String = { fg = p.mint },
  Character = { link = 'String' },
  Number = { fg = p.lime },
  Boolean = { fg = p.purple },
  Float = { link = 'Number' },
  Identifier = { fg = p.fg },
  Function = { fg = p.spring },
  Statement = { fg = p.neon, bold = true },
  Conditional = { link = 'Statement' },
  Repeat = { link = 'Statement' },
  Label = { link = 'Statement' },
  Operator = { fg = p.teal },
  Keyword = { link = 'Statement' },
  Exception = { link = 'Statement' },
  PreProc = { fg = p.purple },
  Include = { link = 'PreProc' },
  Define = { link = 'PreProc' },
  Macro = { link = 'PreProc' },
  PreCondit = { link = 'PreProc' },
  Type = { fg = p.aqua },
  StorageClass = { link = 'Type' },
  Structure = { link = 'Type' },
  Typedef = { link = 'Type' },
  Special = { fg = p.teal },
  SpecialChar = { link = 'Special' },
  Tag = { fg = p.neon },
  Delimiter = { fg = p.grey2 },
  SpecialComment = { fg = p.grey1, bold = true },
  Debug = { link = 'Special' },
  Underlined = { fg = p.teal, underline = true },
  Error = { fg = p.red, bold = true },
  Todo = { fg = p.black, bg = p.neon, bold = true },

  -- [[ Treesitter ]] (only where the default links need overriding)
  ['@variable'] = { fg = p.fg },
  ['@variable.builtin'] = { fg = p.purple, italic = true },
  ['@variable.parameter'] = { fg = p.fg, italic = true },
  ['@variable.member'] = { fg = p.fg },
  ['@property'] = { fg = p.fg },
  ['@module'] = { fg = p.aqua },
  ['@constructor'] = { fg = p.aqua },
  ['@constant.builtin'] = { fg = p.purple, italic = true },
  ['@string.escape'] = { fg = p.teal },
  ['@punctuation'] = { link = 'Delimiter' },
  ['@tag'] = { fg = p.neon },
  ['@tag.attribute'] = { fg = p.spring },
  ['@tag.delimiter'] = { link = 'Delimiter' },
  ['@markup.heading'] = { link = 'Title' },
  ['@markup.strong'] = { bold = true },
  ['@markup.italic'] = { italic = true },
  ['@markup.strikethrough'] = { strikethrough = true },
  ['@markup.link'] = { fg = p.spring },
  ['@markup.link.url'] = { fg = p.teal, underline = true },
  ['@markup.raw'] = { fg = p.mint },
  ['@markup.list'] = { fg = p.neon },

  -- [[ Diagnostics ]]
  DiagnosticError = { fg = p.red },
  DiagnosticWarn = { fg = p.yellow },
  DiagnosticInfo = { fg = p.teal },
  DiagnosticHint = { fg = p.teal },
  DiagnosticOk = { fg = p.spring },
  DiagnosticUnderlineError = { undercurl = true, sp = p.red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = p.yellow },
  DiagnosticUnderlineInfo = { undercurl = true, sp = p.teal },
  DiagnosticUnderlineHint = { undercurl = true, sp = p.teal },
  LspReferenceText = { bg = p.bg_line },
  LspReferenceRead = { bg = p.bg_line },
  LspReferenceWrite = { bg = p.bg_line, underline = true },
  LspInlayHint = { fg = p.grey3, italic = true },
  LspSignatureActiveParameter = { fg = p.neon, bold = true },

  -- [[ Diff / git ]]
  DiffAdd = { bg = p.bg_add },
  DiffChange = { bg = p.bg_change },
  DiffDelete = { fg = p.red, bg = p.bg_del },
  DiffText = { bg = p.bg_text, bold = true },
  Added = { fg = p.spring },
  Changed = { fg = p.yellow },
  Removed = { fg = p.red },
  diffAdded = { link = 'Added' }, -- fugitive/patch syntax
  diffRemoved = { link = 'Removed' },
  diffChanged = { link = 'Changed' },
  GitSignsAdd = { link = 'Added' },
  GitSignsChange = { link = 'Changed' },
  GitSignsDelete = { link = 'Removed' },

  -- [[ Plugins ]] (most link to the groups above on their own)
  TelescopeBorder = { fg = p.neon },
  TelescopeTitle = { fg = p.neon, bold = true },
  TelescopePromptPrefix = { fg = p.neon },
  TelescopeSelection = { bg = p.bg_visual, bold = true },
  TelescopeSelectionCaret = { fg = p.neon, bg = p.bg_visual },
  TelescopeMatching = { fg = p.neon, bold = true },
  WhichKey = { fg = p.neon },
  WhichKeyGroup = { fg = p.teal },
  WhichKeyDesc = { fg = p.fg },
  WhichKeySeparator = { fg = p.grey2 },
  FidgetTitle = { fg = p.neon, bold = true },
  FidgetTask = { fg = p.grey1 },
}

for group, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, group, spec)
end

-- [[ :terminal ANSI colors ]]
-- Blue/magenta stay recognizable (CLI tools rely on them) but lean cool/bright.
local term = {
  '#233a2e', p.red, p.spring, p.yellow, '#33c7ff', p.purple, p.teal, p.fg, -- 0-7
  '#3a5a48', p.red, p.neon, p.lime, '#33c7ff', p.purple, p.aqua, '#ffffff', -- 8-15
}
for i, color in ipairs(term) do
  vim.g['terminal_color_' .. (i - 1)] = color
end
