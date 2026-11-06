local sh = require("utils.sh")

return {
  command = [[git stash list --format='%gd%x09%cr%x09%gs' | jq -Rc 'split("\t") | {ref:.[0], date:.[1], message:.[2]}']],
  format = "json",
  fields = {
    { expr = function(r) return r.ref end, width = { "fixed", 12 }, color = "cyan" },
    { expr = function(r) return r.date end, width = { "fixed", 15 }, color = "blue" },
    { expr = function(r) return r.message end, color = "white" },
  },
  output = function(r) return r.ref end,
  preview = function(r)
    return (sh.run("git stash show -p " .. sh.shquote(r.ref) .. " | delta"))
  end,
  options = {
    height = "60%",
    ["preview-window"] = "bottom:50%",
  },
}
