if not vim.g.neovide then
  return
end

-- Match kitty's font. The Nerd Font variant supplies the icon glyphs that
-- devicons, lualine, and oil need. Plain "Fira Code" lacks them.
vim.o.guifont = "FiraCode Nerd Font:h10"

vim.g.neovide_remember_window_size = true

vim.g.neovide_cursor_vfx_mode = "pixiedust"
vim.g.neovide_cursor_vfx_particle_lifetime = 1.2
vim.g.neovide_cursor_vfx_particle_density = 7.0
vim.g.neovide_cursor_vfx_particle_speed = 10.0
vim.g.neovide_cursor_animation_length = 0.13
vim.g.neovide_cursor_trail_size = 0.7
vim.g.neovide_cursor_animate_command_line = true
vim.g.neovide_cursor_animate_in_insert_mode = true
vim.g.neovide_cursor_short_animation_length = 0.04
vim.g.neovide_cursor_animation_length = 0.10

vim.g.neovide_scroll_animation_length = 0.1

vim.g.neovide_hide_mouse_when_typing = true

vim.g.neovide_refresh_rate = 144

vim.opt.linespace = 0
