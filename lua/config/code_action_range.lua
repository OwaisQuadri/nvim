local M = {}

function M.get(bufnr, row)
  if vim.bo[bufnr].filetype == 'swift' then
    local diagnostic = vim.diagnostic.get(bufnr, { lnum = row - 1 })[1]
    if diagnostic then
      local start = { diagnostic.lnum + 1, diagnostic.col }
      return { start = start, ['end'] = { start[1], start[2] } }
    end
  end
  local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ''
  return { start = { row, 0 }, ['end'] = { row, #line } }
end

function M.to_protocol(range, bufnr, encoding)
  return vim.lsp.util.make_given_range_params(range.start, range['end'], bufnr, encoding).range
end

return M
