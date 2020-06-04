# emoji-fzf.zsh

This is a configurable ZSH plugin for the excellent 
[emoji-fzf](https://github.com/noahp/emoji-fzf). It is heavily inspired by 
[emoji-cli](https://github.com/b4b4r07/emoji-cli).

## Requirements

- [emoji-fzf](https://github.com/noahp/emoji-fzf)

## Installation

### With zinit (recommended)

```zsh
zinit light-mode wait lucid for pschmitt/emoji-fzf.zsh
```

## Configuration

All the configuration is done via env vars.

```
# Path to the emoji-fzf executable
EMOJI_FZF_BIN_PATH="emoji-fzf"

# Bind to Ctrl-K by default. Unset to disable.
EMOJI_FZF_BINDKEY="^k"

# Fuzzy matching tool to use for the emoji selection
EMOJI_FZF_FUZZY_FINDER=fzf

# Optional arguments to pass to the fuzzy finder tool
EMOJI_FZF_FUZZY_FINDER_ARGS=

# Path to an optional custom alias JSON file
EMOJI_FZF_CUSTOM_ALIASES=

# Set to non-empty value to prepend the emoji before the emoji aliases
EMOJI_FZF_PREPEND_EMOJIS=1

# Set to non-empty value to skip the creation of shell aliases
EMOJI_FZF_NO_ALIAS=

# Set clipboard management tool
EMOJI_FZF_CLIPBOARD="xsel -b"
```
