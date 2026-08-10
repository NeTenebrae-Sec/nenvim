local M = {}

--- Retorna la estructura del Main según la versión elegida
local function build_main_method_lines(package_name, java_version)
  local ver_num = tonumber(java_version) or 21
  local lines = {}

  if package_name and package_name ~= "" then
    table.insert(lines, "package " .. package_name .. ";")
    table.insert(lines, "")
  end

  -- Sintaxis moderna para Java 26+ (Implicitly declared classes / Unnamed main)
  if ver_num >= 26 then
    table.insert(lines, "public class Main {")
    table.insert(lines, "    void main() {")
    table.insert(lines, '        System.out.println("Running on Java: " + System.getProperty("java.version"));')
    table.insert(lines, "    }")
    table.insert(lines, "}")
  else
    table.insert(lines, "public class Main {")
    table.insert(lines, "    public static void main(String[] args) {")
    table.insert(lines, '        System.out.println("Running on Java: " + System.getProperty("java.version"));')
    table.insert(lines, "    }")
    table.insert(lines, "}")
  end

  return lines
end

--- Crea un proyecto Pure Java simplificado (fuentes en src/) con metadata explicita para JDTLS
function M.create_pure_java_project(full_path, package_name, java_version)
  local pkg_dir = full_path .. "/src/" .. package_name:gsub("%.", "/")
  vim.fn.mkdir(pkg_dir, "p")

  local main_file = pkg_dir .. "/Main.java"
  local main_code = build_main_method_lines(package_name, java_version)
  vim.fn.writefile(main_code, main_file)

  -- Guarda el archivo .java-version para detección rápida del entorno
  vim.fn.writefile({ tostring(java_version) }, full_path .. "/.java-version")

  -- FIX CRÍTICO: Especifica StandardVMType/JavaSE-XX para obligar a JDTLS a usarlo
  local classpath_content = {
    '<?xml version="1.0" encoding="UTF-8"?>',
    "<classpath>",
    '    <classpathentry kind="src" path="src"/>',
    '    <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER/org.eclipse.jdt.internal.debug.ui.launcher.StandardVMType/JavaSE-'
      .. java_version
      .. '"/>',
    '    <classpathentry kind="output" path="bin"/>',
    "</classpath>",
  }
  vim.fn.writefile(classpath_content, full_path .. "/.classpath")

  local project_name = vim.fn.fnamemodify(full_path, ":t")
  local project_content = {
    '<?xml version="1.0" encoding="UTF-8"?>',
    "<projectDescription>",
    "    <name>" .. project_name .. "</name>",
    "    <comment></comment>",
    "    <projects></projects>",
    "    <buildSpec>",
    "        <buildCommand>",
    "            <name>org.eclipse.jdt.core.javabuilder</name>",
    "            <arguments></arguments>",
    "        </buildCommand>",
    "    </buildSpec>",
    "    <natures>",
    "        <nature>org.eclipse.jdt.core.javanature</nature>",
    "    </natures>",
    "</projectDescription>",
  }
  vim.fn.writefile(project_content, full_path .. "/.project")

  return main_file
end

--- Crea la estructura estándar de Maven/Gradle (src/main/java)
function M.create_main_class(full_path, package_name, java_version)
  local pkg_dir = full_path .. "/src/main/java/" .. package_name:gsub("%.", "/")
  vim.fn.mkdir(pkg_dir, "p")

  -- Guarda el archivo .java-version también en proyectos con build tool
  vim.fn.writefile({ tostring(java_version) }, full_path .. "/.java-version")

  local main_file = pkg_dir .. "/Main.java"
  local main_code = build_main_method_lines(package_name, java_version)
  vim.fn.writefile(main_code, main_file)
  return main_file
end

--- Genera un pom.xml puro para Maven
function M.generate_pure_maven_pom(full_path, group_id, artifact_id, java_version)
  local pom_content = {
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<project xmlns="http://maven.apache.org/POM/4.0.0"',
    '         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
    '         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">',
    "    <modelVersion>4.0.0</modelVersion>",
    "",
    "    <groupId>" .. group_id .. "</groupId>",
    "    <artifactId>" .. artifact_id .. "</artifactId>",
    "    <version>1.0-SNAPSHOT</version>",
    "",
    "    <properties>",
    "        <maven.compiler.release>" .. java_version .. "</maven.compiler.release>",
    "        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>",
    "    </properties>",
    "</project>",
  }
  vim.fn.writefile(pom_content, full_path .. "/pom.xml")
end

--- Genera un script de construcción puro para Gradle
function M.generate_pure_gradle_build(full_path, group_id, artifact_id, java_version, is_kotlin_dsl)
  local gradle_content = {}
  if is_kotlin_dsl then
    gradle_content = {
      "plugins { java; application }",
      'group = "' .. group_id .. '"',
      'version = "1.0-SNAPSHOT"',
      "repositories { mavenCentral() }",
      "java { toolchain { languageVersion.set(JavaLanguageVersion.of(" .. java_version .. ")) } }",
      'application { mainClass.set("' .. group_id .. "." .. artifact_id:gsub("-", "_") .. '.Main") }',
    }
    vim.fn.writefile(gradle_content, full_path .. "/build.gradle.kts")
  else
    gradle_content = {
      "plugins {",
      '    id "java"',
      '    id "application"',
      "}",
      "",
      'group = "' .. group_id .. '"',
      'version = "1.0-SNAPSHOT"',
      "",
      "repositories {",
      "    mavenCentral()",
      "}",
      "",
      "java {",
      "    toolchain {",
      "        languageVersion = JavaLanguageVersion.of(" .. java_version .. ")",
      "    }",
      "}",
      "",
      "application {",
      '    mainClass = "' .. group_id .. "." .. artifact_id:gsub("-", "_") .. '.Main"',
      "}",
    }
    vim.fn.writefile(gradle_content, full_path .. "/build.gradle")
  end
end

return M
