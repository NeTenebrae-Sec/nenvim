-- lua/plugins/lsp/servers/springboot.lua
-- Servidor para autocompletado en application.properties / application.yml

-- R0: el paquete vscode-spring-boot-tools trae un JAR, no este
-- binario → sin el guard, cada sesión que abre un yaml/properties deja
-- «invalid "springboot" config … is not executable» en lsp.log y el
-- server nunca arranca. Para activarlo de verdad: cmd = { "java",
-- "-jar", <tools/packages/vscode-spring-boot-tools/extension/
-- language-server/*-exec.jar> }.
local cmd = { "vscode-spring-boot-language-server" }
if vim.fn.executable(cmd[1]) == 0 then
  return
end

vim.lsp.config["springboot"] = {
  cmd = cmd,
  filetypes = { "yaml", "properties" },
  root_markers = { "pom.xml", "build.gradle", ".git" },
}

vim.lsp.enable("springboot")
