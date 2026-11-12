# Recovered from the installed nvim-system-tools derivation.
# Keep its package order and link scope so the original tool environment is reproduced.
{ pkgs }:
pkgs.buildEnv {
  name = "nvim-system-tools";
  paths = with pkgs; [
    gcc
    clang-tools
    ty
    ripgrep
    fd
    fzf
    lazygit
    tree-sitter
    cmake
    ninja
    gnumake
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
    go
    jdk
    (python3.withPackages (ps: [ ps.pip ps.pynvim ]))
    lua-language-server
    bash-language-server
    (neocmakelsp.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.pkg-config ];
      buildInputs = (old.buildInputs or []) ++ [ pkgs.oniguruma ];
    }))
    taplo
    stylua
    shfmt
    shellcheck
    cmake-format
    cmake-lint
    vscode-extensions.vadimcn.vscode-lldb.adapter
    nerd-fonts.fira-code
  ];
  pathsToLink = [ "/bin" "/share/fonts" "/share/lldb" ];
}
