local M = {}

local ns = vim.api.nvim_create_namespace("nextvim_welcome")
local timer = nil
local state = {
  bufnr = nil,
  a = 0,
  b = 0,
}

local donut_width = 54
local donut_height = 23
local luminance = ".,-~:;=!*#$@"

local menu = {
  { key = "f", label = "Find File", hint = "Telescope files", action = function() vim.cmd("Telescope find_files") end },
  { key = "r", label = "Recent Files", hint = "Telescope oldfiles", action = function() vim.cmd("Telescope oldfiles") end },
  { key = "n", label = "New Buffer", hint = "Empty editor", action = function() vim.cmd("enew") end },
  { key = "q", label = "Quit", hint = "Close Neovim", action = function() vim.cmd("quit") end },
}

local function define_highlights()
  vim.api.nvim_set_hl(0, "NextVimWelcomeTitle", { fg = "#7aa2f7", bold = true })
  vim.api.nvim_set_hl(0, "NextVimWelcomeMuted", { fg = "#565f89" })
  vim.api.nvim_set_hl(0, "NextVimWelcomeKey", { fg = "#9ece6a", bold = true })
  vim.api.nvim_set_hl(0, "NextVimWelcomeDonut1", { fg = "#57d99a", bold = true })
  vim.api.nvim_set_hl(0, "NextVimWelcomeDonut2", { fg = "#3fc5ff", bold = true })
  vim.api.nvim_set_hl(0, "NextVimWelcomeDonut3", { fg = "#8bd5ff", bold = true })
  vim.api.nvim_set_hl(0, "NextVimWelcomeDonut4", { fg = "#b4f9f8", bold = true })
end

local function center_line(text)
  local width = vim.api.nvim_get_option_value("columns", {})
  return string.rep(" ", math.max(0, math.floor((width - #text) / 2))) .. text
end

local function render_donut()
  local chars = {}
  local zbuffer = {}
  for i = 1, donut_width * donut_height do
    chars[i] = " "
    zbuffer[i] = 0
  end

  local cos_a = math.cos(state.a)
  local sin_a = math.sin(state.a)
  local cos_b = math.cos(state.b)
  local sin_b = math.sin(state.b)

  local theta = 0
  while theta < 2 * math.pi do
    local costheta = math.cos(theta)
    local sintheta = math.sin(theta)
    local phi = 0

    while phi < 2 * math.pi do
      local cosphi = math.cos(phi)
      local sinphi = math.sin(phi)
      local circle_x = 2 + costheta
      local circle_y = sintheta

      local x = circle_x * (cos_b * cosphi + sin_a * sin_b * sinphi) - circle_y * cos_a * sin_b
      local y = circle_x * (sin_b * cosphi - sin_a * cos_b * sinphi) + circle_y * cos_a * cos_b
      local z = 5 + cos_a * circle_x * sinphi + circle_y * sin_a
      local inv_z = 1 / z

      local xp = math.floor(donut_width / 2 + 20 * inv_z * x)
      local yp = math.floor(donut_height / 2 - 10 * inv_z * y)
      local idx = xp + donut_width * yp + 1

      local light =
        cosphi * costheta * sin_b
        - cos_a * costheta * sinphi
        - sin_a * sintheta
        + cos_b * (cos_a * sintheta - costheta * sin_a * sinphi)

      if yp >= 0 and yp < donut_height and xp >= 0 and xp < donut_width and inv_z > zbuffer[idx] then
        zbuffer[idx] = inv_z
        local lum_idx = math.max(1, math.min(#luminance, math.floor(light * 8) + 1))
        chars[idx] = luminance:sub(lum_idx, lum_idx)
      end

      phi = phi + 0.16
    end

    theta = theta + 0.08
  end

  local lines = {}
  for row = 0, donut_height - 1 do
    local line = table.concat(vim.list_slice(chars, row * donut_width + 1, (row + 1) * donut_width))
    table.insert(lines, center_line(line))
  end
  return lines
end

local function command_line(item)
  local total = 46
  local left = item.label
  local right = string.format("[%s]", item.key)
  local gap = math.max(2, total - #left - #right)
  return string.rep(" ", math.max(0, math.floor((vim.o.columns - total) / 2)))
    .. left
    .. string.rep(" ", gap)
    .. right
end

local function build_lines()
  local height = vim.api.nvim_get_option_value("lines", {})
  local content = {}

  for _, line in ipairs(render_donut()) do
    table.insert(content, line)
  end
  table.insert(content, "")
  table.insert(content, center_line("NextVim"))
  table.insert(content, center_line("Fast editing. Clear tools."))
  table.insert(content, "")
  for _, item in ipairs(menu) do
    table.insert(content, command_line(item))
  end

  local top = math.max(0, math.floor((height - #content) / 2) - 1)
  local lines = {}
  for _ = 1, top do
    table.insert(lines, "")
  end
  vim.list_extend(lines, content)
  return lines, top
end

local function color_donut(bufnr, top)
  local groups = {
    "NextVimWelcomeDonut1",
    "NextVimWelcomeDonut2",
    "NextVimWelcomeDonut3",
    "NextVimWelcomeDonut4",
  }

  local first = top
  local last = top + donut_height - 1
  for row = first, last do
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    for col = 1, #line do
      if line:sub(col, col) ~= " " then
        local group = groups[((col + row + math.floor(state.a * 10)) % #groups) + 1]
        vim.api.nvim_buf_set_extmark(bufnr, ns, row, col - 1, {
          end_col = col,
          hl_group = group,
        })
      end
    end
  end
end

local function color_text(bufnr, lines)
  for lnum, line in ipairs(lines) do
    local title_start = line:find("NextVim", 1, true)
    if title_start then
      vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, title_start - 1, {
        end_col = title_start + #"NextVim" - 1,
        hl_group = "NextVimWelcomeTitle",
      })
    end

    local subtitle_start = line:find("Fast editing", 1, true)
    if subtitle_start then
      vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, subtitle_start - 1, {
        end_col = #line,
        hl_group = "NextVimWelcomeMuted",
      })
    end

    local key_start = line:find("%[.")
    if key_start then
      vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, key_start - 1, {
        end_col = key_start + 2,
        hl_group = "NextVimWelcomeKey",
      })
    end
  end
end

local function render()
  local bufnr = state.bufnr
  if not (bufnr and vim.api.nvim_buf_is_valid(bufnr)) then
    return
  end

  local lines, top = build_lines()
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  color_donut(bufnr, top)
  color_text(bufnr, lines)
  vim.bo[bufnr].modifiable = false
end

local function stop_timer()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

local function start_timer()
  stop_timer()
  timer = vim.uv.new_timer()
  timer:start(0, 120, vim.schedule_wrap(function()
    state.a = state.a + 0.09
    state.b = state.b + 0.05
    render()
  end))
end

local function set_keymaps(bufnr)
  for _, item in ipairs(menu) do
    vim.keymap.set("n", item.key, item.action, { buffer = bufnr, nowait = true, silent = true })
  end
end

function M.open()
  if vim.fn.argc(-1) ~= 0 or #vim.api.nvim_list_uis() == 0 then
    return
  end

  define_highlights()

  local bufnr = vim.api.nvim_create_buf(false, true)
  state.bufnr = bufnr

  vim.api.nvim_set_current_buf(bufnr)
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "nextvim-welcome"
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].swapfile = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.cursorline = false
  vim.wo.signcolumn = "no"
  vim.wo.foldcolumn = "0"
  vim.wo.list = false

  set_keymaps(bufnr)
  render()
  start_timer()

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufHidden" }, {
    buffer = bufnr,
    once = true,
    callback = stop_timer,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    buffer = bufnr,
    callback = render,
  })
end

return M
