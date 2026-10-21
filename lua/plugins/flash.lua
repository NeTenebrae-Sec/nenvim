local ok, flash = pcall(require, "flash")
if not ok then
  return
end

flash.setup({
  prompt = {
    enabled = true,
    prefix = { { "▶", "FlashPromptIcon" } },
  },
  highlight = {
    backdrop = true,
    groups = {
      match = "FlashMatch",
      current = "FlashCurrent",
      backdrop = "FlashBackdrop",
      label = "FlashLabel",
    },
  },
  modes = {
    search = {
      enabled = true,
    },
    char = {
      enabled = false,
    },
  },
})
