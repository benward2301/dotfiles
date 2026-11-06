local expr = require("utils.expr")
local sh = require("utils.sh")

local function unquote(p)
  if p:sub(1, 1) ~= '"' or p:sub(-1) ~= '"' then return p end
  local s = p:sub(2, -2)
  local out, i = {}, 1
  while i <= #s do
    local c = s:sub(i, i)
    if c == "\\" then
      local nxt = s:sub(i + 1, i + 1)
      if nxt == "\\" or nxt == '"' then
        out[#out + 1] = nxt; i = i + 2
      elseif s:sub(i + 1, i + 3):match("^[0-7][0-7][0-7]$") then
        out[#out + 1] = string.char(tonumber(s:sub(i + 1, i + 3), 8)); i = i + 4
      else
        out[#out + 1] = c; i = i + 1
      end
    else
      out[#out + 1] = c; i = i + 1
    end
  end
  return table.concat(out)
end

local function op_symbol(op)
  if op == "A" then return "+" end
  if op == "D" then return "-" end
  if op == "R" then return "»" end
  return "~"
end

local function parse_numstat(out)
  local map = {}
  for line in out:gmatch("[^\n]+") do
    local adds, dels, file = line:match("^([^\t]*)\t([^\t]*)\t(.*)$")
    if adds then
      if file:find(" => ", 1, true) then
        file = file:gsub(".*=> ", ""):gsub("}$", "")
      end
      map[file] = {
        adds = adds == "-" and 0 or (tonumber(adds) or 0),
        dels = dels == "-" and 0 or (tonumber(dels) or 0),
      }
    end
  end
  return map
end

local function count_lines(path)
  local fh = io.open(path, "rb")
  if not fh then return 0 end
  local content = fh:read("a") or ""
  fh:close()
  local _, n = content:gsub("\n", "")
  return n
end

local function relpath(from, to)
  local function split(p)
    local t = {}
    for s in p:gmatch("[^/]+") do t[#t + 1] = s end
    return t
  end
  local f, t = split(from), split(to)
  local i = 1
  while f[i] and t[i] and f[i] == t[i] do i = i + 1 end
  local parts = {}
  for _ = i, #f do parts[#parts + 1] = ".." end
  for j = i, #t do parts[#parts + 1] = t[j] end
  return table.concat(parts, "/")
end

return {
  format = "json",
  shell_quote = true,
  input = function()
    local git_root = sh.trim(sh.run("git rev-parse --show-toplevel 2>/dev/null"))
    if git_root == "" then return {} end

    local cwd = sh.trim(sh.run("pwd -P"))
    local function git(args)
      return sh.run("git -C " .. sh.shquote(git_root) .. " " .. args .. " 2>/dev/null")
    end

    local staged = parse_numstat(git("diff --cached --numstat"))
    local unstaged = parse_numstat(git("diff --numstat"))

    local results = {}
    for line in git("status --porcelain -uall"):gmatch("[^\n]+") do
      local x, y, file = line:sub(1, 1), line:sub(2, 2), line:sub(4)
      if x == "R" or y == "R" then
        local _, new = file:match("^(.*) %-> (.*)$")
        if new then file = new end
      end
      file = unquote(file)
      local abs = git_root .. "/" .. file
      local rel = relpath(cwd, abs)

      if x == "?" and y == "?" then
        results[#results + 1] = { status = "?", op = "?", diff_type = "untracked",
          file = rel, absFile = abs, adds = count_lines(abs), dels = 0 }
      else
        if x ~= " " and x ~= "?" then
          local ns = staged[file] or {}
          results[#results + 1] = { status = "S", op = op_symbol(x), diff_type = "staged",
            file = rel, absFile = abs, adds = ns.adds or 0, dels = ns.dels or 0 }
        end
        if y ~= " " and y ~= "?" then
          local ns = unstaged[file] or {}
          results[#results + 1] = { status = "U", op = op_symbol(y), diff_type = "unstaged",
            file = rel, absFile = abs, adds = ns.adds or 0, dels = ns.dels or 0 }
        end
      end
    end

    local status_order = { S = 0, C = 1, U = 2, ["?"] = 3 }
    local op_order = { ["+"] = 0, ["~"] = 1, ["-"] = 2, ["»"] = 3, ["?"] = 4 }
    table.sort(results, function(a, b)
      local sa, sb = status_order[a.status] or 9, status_order[b.status] or 9
      if sa ~= sb then return sa < sb end
      local oa, ob = op_order[a.op] or 9, op_order[b.op] or 9
      if oa ~= ob then return oa < ob end
      return a.file < b.file
    end)
    return results
  end,
  fields = {
    {
      expr = function(r) return r.op end,
      width = { "fixed", 2 },
      colors = {
        { color = "green", values = { "+" } },
        { color = "red", values = { "-" } },
        { color = "cyan", values = { "»" } },
        { color = "magenta", values = { "?" } },
        { color = "blue", values = { "~" } },
      },
    },
    {
      expr = function(r) return (r.adds and r.adds > 0) and tostring(r.adds) or "" end,
      color = "green",
    },
    {
      expr = function(r) return (r.dels and r.dels > 0) and tostring(r.dels) or "" end,
      color = "red",
    },
    {
      expr = function(r) return r.status == "S" and "*" or "" end,
      color = "green"
    },
    { icon = true, expr = function(r) return r.file end },
    {
      expr = function(r)
        local c = ({ ["+"] = "\27[32m", ["-"] = "\27[31m", ["?"] = "\27[35m" })[r.op] or "\27[37m"
        local i = expr.last_index(r.file, "/")
        if i < 0 then
          return c .. r.file .. "\27[0m"
        end
        return "\27[90m" .. expr.slice(r.file, 0, i + 1) .. c .. expr.slice(r.file, i + 1) .. "\27[0m"
      end,
      width = "none",
    },
  },
  output = function(r) return r.file end,
  copy = function(r) return r.absFile end,
  preview = function(r)
    local f = sh.shquote(r.file)
    local cmd
    if r.diff_type == "staged" then
      cmd = "git diff --cached --color=always -- " .. f .. [[ | delta --width="$FZF_PREVIEW_COLUMNS"]]
    elseif r.diff_type == "unstaged" then
      cmd = "git diff --color=always -- " .. f .. [[ | delta --width="$FZF_PREVIEW_COLUMNS"]]
    elseif r.diff_type == "head" then
      cmd = "git diff HEAD --color=always -- " .. f .. [[ | delta --side-by-side --width="$FZF_PREVIEW_COLUMNS"]]
    elseif r.diff_type == "untracked" then
      cmd = "bat --color=always --style=numbers " .. f .. " 2>/dev/null || cat " .. f
    else
      return "Unknown diff type: " .. tostring(r.diff_type)
    end
    return (sh.run(cmd))
  end,
  options = {
    height = "95%",
    ["preview-window"] = "right:60%,border-left,nohidden,<120(down,50%,border-top,nohidden)",
    bind = {
      [[ctrl-o:become(${EDITOR:-nvim} +$(git diff -U0 "$(printf '%s' {1} | jq -r '.file')" | rg -m1 '^@@' | rg -o '\+\d+' | rg -o '\d+') "$(printf '%s' {1} | jq -r '.file')" > /dev/tty)]],
      [[ctrl-x:execute(${EDITOR:-nvim} +$(git diff -U0 "$(printf '%s' {1} | jq -r '.file')" | rg -m1 '^@@' | rg -o '\+\d+' | rg -o '\d+') "$(printf '%s' {1} | jq -r '.file')" > /dev/tty)]],
    },
  },
}
