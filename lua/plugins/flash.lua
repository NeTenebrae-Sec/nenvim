local flash = require("flash")

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
