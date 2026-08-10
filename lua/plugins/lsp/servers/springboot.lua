-- lua/plugins/lsp/servers/springboot.lua
-- Servidor para autocompletado en application.properties / application.yml

vim.lsp.config["springboot"] = {
  cmd = { "vscode-spring-boot-language-server" },
  filetypes = { "yaml", "properties" },
  root_markers = { "pom.xml", "build.gradle", ".git" },
}

vim.lsp.enable("springboot")
