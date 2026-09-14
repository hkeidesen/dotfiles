-- C# / .NET LSP via Microsoft's official Roslyn language server.
-- The `roslyn` binary itself is installed by mason (see lsp.lua's mason-tool-installer list).
-- Note: `roslyn` only exists in the Crashdummyy/mason-registry community registry,
-- which is added in lsp.lua's `require("mason").setup({ registries = ... })`.
return {
  {
    "seblj/roslyn.nvim",
    ft = { "cs" },
    opts = {
      -- Reference: https://github.com/seblj/roslyn.nvim#settings
      config = {
        settings = {
          -- `fullSolution` surfaces errors across the whole repo, not just open
          -- files. Heavier on CPU/RAM but catches breakage in files you haven't
          -- touched yet — drop to "openFiles" if Roslyn starts feeling sluggish.
          ["csharp|background_analysis"] = {
            dotnet_analyzer_diagnostics_scope = "fullSolution",
            dotnet_compiler_diagnostics_scope = "fullSolution",
          },
          ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            dotnet_enable_inlay_hints_for_parameters = true,
          },
          ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
          },
        },
      },
    },
  },
}
