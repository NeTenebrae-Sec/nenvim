-- =========================================================
-- Ficha Java — jdtls + spring boot + google-java-format
-- =========================================================
-- jdtls no usa vim.lsp.config: el aux core.lua arranca el servidor
-- con su propio ciclo de vida (detector de proyecto, Lombok, JDKs).
-- springboot.lua añade el LSP de properties/YAML para proyectos Spring.

local M = {
  name = "java",
  filetypes = { "java" },

  format = { java = { "google-java-format" } },

  parsers = { "java" },

  tools = { "jdtls", "java-debug-adapter", "java-test", "vscode-spring-boot-tools", "google-java-format" },

  -- run(): menú de ejecución Maven/Gradle en Kitty; setup(): DAP de jdtls
  dap = require("languages.java.dap"),
}

-- Side effects: :checkhealth del server de Spring Boot
pcall(require, "languages.java.springboot")

-- Side effects: arranque jdtls por FileType + comandos JavaInit, etc.
local ok_core, java_core = pcall(require, "languages.java.core")
if ok_core and java_core then
  java_core.setup()
end

return M
