local M = {}

function M.build_cmd(params)
  local java_bin = params.java_bin
  local lombok_jar = params.lombok_jar
  local path_to_jar = params.path_to_jar
  local path_to_config = params.path_to_config
  local workspace_dir = params.workspace_dir

  local cmd_args = {
    java_bin,
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.level=ERROR",
    "-Xms256m",
    "-Xmx1g",
  }

  if lombok_jar ~= "" and vim.fn.filereadable(lombok_jar) == 1 then
    table.insert(cmd_args, "-javaagent:" .. lombok_jar)
  end

  vim.list_extend(cmd_args, {
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",
    "-jar",
    path_to_jar,
    "-configuration",
    path_to_config,
    "-data",
    workspace_dir,
  })

  return cmd_args
end

return M
