# Settings
typeset -agr EMOJI_FZF_FZF_DEFAULT_ARGS=(--header "Emoji selection" --no-hscroll)
# Path to the emoji-fzf executable
typeset -g EMOJI_FZF_BIN_PATH="${EMOJI_FZF_BIN_PATH:-"emoji-fzf"}"
# Bind to Ctrl-K by default. Unset to disable.
typeset -g EMOJI_FZF_BINDKEY="${EMOJI_FZF_BINDKEY:-"^k"}"
# Fuzzy matching tool to use for the emoji selection
typeset -g EMOJI_FZF_FUZZY_FINDER="${EMOJI_FZF_FUZZY_FINDER:-"fzf"}"
# Optional arguments to pass to the fuzzy finder tool
if [[ -n "$EMOJI_FZF_FUZZY_FINDER_ARGS" ]]
then
  typeset -ag EMOJI_FZF_FUZZY_FINDER_ARGS=("$EMOJI_FZF_FUZZY_FINDER_ARGS[@]")
else
  typeset -ag EMOJI_FZF_FUZZY_FINDER_ARGS
fi
# Path to an optional custom alias JSON file
typeset -g EMOJI_FZF_CUSTOM_ALIASES="${EMOJI_FZF_CUSTOM_ALIASES}"
# Set to non-empty value to prepend the emoji before the emoji aliases
typeset -g EMOJI_FZF_PREPEND_EMOJIS="${EMOJI_FZF_PREPEND_EMOJIS}"
# Set to non-empty value to skip the creation of shell aliases
typeset -g EMOJI_FZF_NO_ALIAS="${EMOJI_FZF_NO_ALIAS}"
# Set clipboard management tool
typeset -g EMOJI_FZF_CLIPBOARD="${EMOJI_FZF_CLIPBOARD}"

if (( ! $+commands[emoji-fzf] )) && [[ ! -x ${EMOJI_FZF_BIN_PATH%% *} ]]
then
  echo "emoji-fzf is not installed. You can fix that by issuing:" >&2
  echo "pipx install emoji-fzf" >&2
  echo "or: pip install -U --user emoji-fzf" >&2
  return 1
fi

__emoji-fzf-preview() {
  local -a efzf_args
  local -a fz_args=("$EMOJI_FZF_FUZZY_FINDER_ARGS[@]")
  local -a fz_cmd
  local is_fzf

  read -rA fz_cmd <<< "$EMOJI_FZF_FUZZY_FINDER"

  case "$fz_cmd[1]" in
    fzf*)  # matches fzf but also fzf-tmux
      is_fzf=1
      ;;
  esac

  if [[ -n "$EMOJI_FZF_CUSTOM_ALIASES" ]]
  then
    efzf_args+=(-c "$EMOJI_FZF_CUSTOM_ALIASES")
  fi

  efzf_args+=(preview)

  if [[ -n "$is_fzf" ]]
  then
    # Use default FZF args if not overridden by user
    if [[ -z "$fz_args" ]]
    then
      fz_args+=("$EMOJI_FZF_FZF_DEFAULT_ARGS[@]")
    fi

    # Set start query
    if [[ -n "$*" ]]
    then
      fz_args+=(-q "$*")
    fi
  fi

  if [[ -n "$EMOJI_FZF_PREPEND_EMOJIS" ]] || [[ ! -n "$is_fzf" ]]
  then
    efzf_args+=(--prepend)

    "$EMOJI_FZF_BIN_PATH" "$efzf_args[@]" | \
      "$fz_cmd[@]" $fz_args | \
      awk '{ print $1 }'
  else
    "$EMOJI_FZF_BIN_PATH" "$efzf_args[@]" | \
      "$fz_cmd[@]" $fz_args \
        --preview "${EMOJI_FZF_BIN_PATH} get --name {1}" | \
      cut -d \" \" -f 1 | \
      "${EMOJI_FZF_BIN_PATH}" get
  fi
}

emoji-fzf-zle() {
  # Based on https://github.com/b4b4r07/emoji-cli/blob/master/emoji-cli.zsh
  local emoji
  local _BUFFER _RBUFFER _LBUFFER

  _RBUFFER="$RBUFFER"

  if [[ -n "$LBUFFER" ]]
  then
    _LBUFFER=${LBUFFER##* }
    if [[ "$_LBUFFER" =~ [a-zA-Z0-9+_-]$ ]]
    then
      local comp
      comp="$(grep -E -o ":?[a-zA-Z0-9+_-]+" <<< "$_LBUFFER")"
      emoji="$(__emoji-fzf-preview "${(L)comp#:}")"
      _BUFFER="${LBUFFER%$comp}${emoji:-$comp}"
    else
      emoji="$(__emoji-fzf-preview)"
      _BUFFER="${LBUFFER}${emoji}"
    fi
  else
    emoji="$(__emoji-fzf-preview)"
    _BUFFER="${emoji}"
  fi

  if [[ -n "$_RBUFFER" ]]
  then
    BUFFER="${_BUFFER}${_RBUFFER}"
  else
    BUFFER="$_BUFFER"
  fi

  CURSOR="$#_BUFFER"
  zle reset-prompt
}

__emoji_fzf_alias_emojicopy() {
  local -a clipboard_cmd

  if [[ -n "$EMOJI_FZF_CLIPBOARD" ]]
  then
    clipboard_cmd=("$EMOJI_FZF_CLIPBOARD[@]")
  else
    # Try to guess the clipboard manager
    if (( $+commands[xsel] ))
    then
      clipboard_cmd=(xsel -b)
    elif (( $+commands[xclip] ))
    then
      clipboard_cmd=(xclip -selection clipboard -i)
    elif (( $+commands[pbcopy] ))
    then
      clipboard_cmd=(pbcopy)
    fi
  fi

  if [[ -z "$clipboard_cmd" ]]
  then
    echo "Unable to determine command to clipboard helper command" >&2
    return 3
  fi

  __emoji-fzf-preview "$@" | "$clipboard_cmd[@]"
}

# Setup ZLE
if [[ -n "$EMOJI_FZF_BINDKEY" ]]
then
  zle -N emoji-fzf-zle
  bindkey -- "$EMOJI_FZF_BINDKEY" emoji-fzf-zle
fi

# Setup aliases
if [[ -z "$EMOJI_FZF_NO_ALIAS" ]]
then
  alias emoji=__emoji-fzf-preview
  alias emojicopy=__emoji_fzf_alias_emojicopy
fi

# vim: set ft=zsh et ts=2 sw=2 :