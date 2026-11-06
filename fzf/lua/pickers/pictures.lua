local sh = require("utils.sh")

return {
  command = [[fd --type f . ~/Pictures --exec-batch ls -t | jq -Rc '{path:.}']],
  format = "json",
  shell_quote = true,
  fields = {
    { icon = true, expr = function(r) return r.path end },
    { dir_color = "subtext0", expr = function(r)
      local prefix = os.getenv("HOME") .. "/Pictures/"
      local p = r.path or ""
      return p:sub(1, #prefix) == prefix and p:sub(#prefix + 1) or p
    end },
  },
  output = function(r) return r.path end,
  preview = function(r) return (sh.run([[$FZF_DIR/lib/preview.sh ]] .. sh.shquote(r.path))) end,
  options = {
    height = "40",
    bind = {
      [[ctrl-o:become(${EDITOR:-nvim} "$(printf '%s' {1} | jq -r '.path')" > /dev/tty)]],
      [[ctrl-x:execute(${EDITOR:-nvim} "$(printf '%s' {1} | jq -r '.path')" > /dev/tty)]],
    },
  },
}
