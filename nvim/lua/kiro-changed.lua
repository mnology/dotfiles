-- Open the files the Kiro agent changed, then clear the queue.
--
-- The PostFileSave / PostFileCreate hook (.kiro/hooks/kiro-changed.json) runs
-- bin/kiro-queue-changed.py, which appends each changed path to the queue file.
-- :KiroChanged opens those paths as buffers so the LSP, formatter, and local
-- config act on them. The queue is cleared on open, so each review starts fresh.

local M = {}

local function queue_path()
  local cache = vim.env.XDG_CACHE_HOME or (vim.env.HOME .. "/.cache")
  return cache .. "/kiro/changed-files"
end

local function read_queue(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  -- Dedupe while keeping order; drop blanks and paths that no longer exist.
  local seen, paths = {}, {}
  for line in file:lines() do
    local p = vim.trim(line)
    if p ~= "" and not seen[p] and vim.uv.fs_stat(p) then
      seen[p] = true
      paths[#paths + 1] = p
    end
  end
  file:close()
  return paths
end

function M.open_changed()
  local queue = queue_path()
  local paths = read_queue(queue)
  if not paths then
    vim.notify("No Kiro change queue yet", vim.log.levels.INFO)
    return
  end
  -- Clear on open regardless of count, so a stale queue never lingers.
  os.remove(queue)
  if #paths == 0 then
    vim.notify("Kiro change queue empty", vim.log.levels.INFO)
    return
  end
  for _, p in ipairs(paths) do
    vim.cmd.edit(vim.fn.fnameescape(p))
  end
  vim.notify(("Opened %d changed file(s)"):format(#paths), vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("KiroChanged", M.open_changed, {
  desc = "Open files the Kiro agent changed; clear the queue",
})

return M
