# macOS Homebrew environment setup
if [[ "$(uname)" == "Darwin" ]]; then
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)"
    fi
fi

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Created by `pipx` on 2026-05-28 19:09:30
export PATH="$PATH:/Users/dim/Library/Python/3.14/bin"
