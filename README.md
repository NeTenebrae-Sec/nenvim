# nenvim

![Dashboard](https://raw.githubusercontent.com/NeTenebraes/nenvim/refs/heads/main/docs/images/Dashboard.webp)

nenvim is a personal Neovim configuration, designed to be modular, efficient,
and maintainable. It focuses on a clean development workflow with curated
plugins for modern coding tasks.

## Features

- **Modular Architecture:** Organized directory structure separating
  configuration, plugins, LSP settings, and UI components.
- **LSP & Tooling:** Pre-configured support for Language Servers, linting, and
  formatting via Mason.
- **UI Enhancements:** Carefully selected aesthetic and functional plugins to
  improve visibility and interaction.
- **Productivity:** Optimized keymaps and tools for faster navigation and
  editing.

## Structure

The configuration is structured as follows:

- config/ # Core settings: keymaps, options, and plugin loading
- plugins/ # Plugins separated by functionality (CMP, LSP, UI)
- theme00/01.lua # Theme configurations

## Installation

1. Ensure you have Neovim 0.12 or higher installed.
1. Clone this repository into your Neovim configuration directory (make a
   backup)
