# Settings
typeset -ag EMOJI_FZF_FZF_DEFAULT_ARGS=(--header "Emoji selection" --no-hscroll)
# Path to the emoji-fzf executable
typeset -g EMOJI_FZF_BIN_PATH="${EMOJI_FZF_BIN_PATH:-"emoji-fzf"}"
# Bind to Ctrl-K by default. Unset to disable.
typeset -g EMOJI_FZF_BINDKEY="${EMOJI_FZF_BINDKEY-"^k"}"
# Fuzzy matching tool to use for the emoji selection
typeset -g EMOJI_FZF_FUZZY_FINDER="${EMOJI_FZF_FUZZY_FINDER:-"fzf"}"
# Optional arguments to pass to the fuzzy finder tool
if [[ -n "$EMOJI_FZF_FUZZY_FINDER_ARGS" ]]
then
  typeset -ag EMOJI_FZF_FUZZY_FINDER_ARGS=("$EMOJI_FZF_FUZZY_FINDER_ARGS[@]")
else
  typeset -ag EMOJI_FZF_FUZZY_FINDER_ARGS
fi
# Color to display the aliases
typeset -g EMOJI_FZF_ALIAS_COLOR="${EMOJI_FZF_ALIAS_COLOR}"
# Path to an optional custom alias JSON file
typeset -g EMOJI_FZF_CUSTOM_ALIASES="${EMOJI_FZF_CUSTOM_ALIASES}"
# Set to non-empty value to prepend the emoji before the emoji aliases
typeset -g EMOJI_FZF_PREPEND_EMOJIS="${EMOJI_FZF_PREPEND_EMOJIS}"
# Set to non-empty value to ignore all multichar emojis (eg: 🇩🇪)
# Requires EMOJI_FZF_PREPEND_EMOJIS=1
typeset -g EMOJI_FZF_SKIP_MULTICHAR="${EMOJI_FZF_SKIP_MULTICHAR}"
# Set to non-empty value to skip the creation of shell aliases
typeset -g EMOJI_FZF_NO_ALIAS="${EMOJI_FZF_NO_ALIAS}"
# Set clipboard management tool
typeset -g EMOJI_FZF_CLIPBOARD="${EMOJI_FZF_CLIPBOARD}"

if (( ! $+commands[emoji-fzf] )) && [[ ! -x ${EMOJI_FZF_BIN_PATH%% *} ]]
then
  {
    echo "emoji-fzf is not installed. You can fix that by issuing:"
    echo "pipx install emoji-fzf"
    echo "or: pip install -U --user emoji-fzf"
  } >&2
  return 1
fi

__emoji-fzf-preview() {
  setopt localoptions
  setopt errreturn
  setopt pipefail

  local show_all

  zparseopts -D -E \
    a=show_all -all=show_all -show-all=show_all

  if [[ -n "$show_all" ]]
  then
    # If invoked with -a|--all: Show *all* emojis, regardless of the current
    # value of EMOJI_FZF_SKIP_MULTICHAR
    local EMOJI_FZF_SKIP_MULTICHAR
  fi

  local -a efzf_args
  local -a filter=(tee)  # do not filter by default
  local -a filter2=(tee)  # do not filter by default
  local -a fz_args=("$EMOJI_FZF_FUZZY_FINDER_ARGS[@]")
  local -a fz_cmd
  local -a selector=(awk '{ print $1 }')
  local -a selector2=(tee)
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
      # Update default header when not all emojis are shown
      if [[ -n "$EMOJI_FZF_SKIP_MULTICHAR" ]]
      then
        fz_args[2]="$fz_args[2] single char emoji only"
      fi
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

    if [[ -n "$EMOJI_FZF_SKIP_MULTICHAR" ]]
    then
      efzf_args+=(--skip-multichar)
    fi
  else
    fz_args+=(-d' ' --preview "${EMOJI_FZF_BIN_PATH} get --name {1}")
    selector2=(${EMOJI_FZF_BIN_PATH} get)
  fi

  if [[ "$EMOJI_FZF_ALIAS_COLOR" ]]
  then
    local col=$(tput setaf "$EMOJI_FZF_ALIAS_COLOR")
    local colreset=$(tput sgr0)
    filter2=(sed -r "s/(.) (.+)/${col}\1 \2${colreset}/")
  fi

  # DEBUG
  # local logfile=${TMPDIR:-/tmp}/emoji.log
  # {
  #   touch $logfile
  #   echo $EMOJI_FZF_BIN_PATH $efzf_args[@]
  #   typeset filter
  #   typeset filter2
  #   typeset fz_cmd
  #   typeset selector
  #   typeset selector2
  # } >> $logfile

  $EMOJI_FZF_BIN_PATH $efzf_args[@] | $filter[@] | $filter2[@] | \
    $fz_cmd[@] $fz_args[@] | $selector[@] | $selector2[@]
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
      comp="$(grep -E -o ":?[a-zA-Z0-9+_-]+" <<< "$_LBUFFER" | tail -1)"
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

__emoji_fzf_clipboard_cmd() {
  local -a clipboard_cmd

  if [[ -n "$EMOJI_FZF_CLIPBOARD" ]]
  then
    # Split EMOJI_FZF_CLIPBOARD
    clipboard_cmd=(${=EMOJI_FZF_CLIPBOARD})
  else
    # Try to guess the clipboard manager
    if (( $+commands[xsel] ))
    then
      clipboard_cmd=(xsel -b -i)
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

  echo "$clipboard_cmd[@]"
}

__emoji_fzf_alias_emojicopy() {
  setopt localoptions
  setopt errreturn
  setopt pipefail

  local clipboard_cmd=($(__emoji_fzf_clipboard_cmd))
  __emoji-fzf-preview "$@" | tr -d '\n' | "$clipboard_cmd[@]"
}

__emoji_fzf_alias_emojilucky() {
  local usage="Usage: $0 SEARCH_TERM"

  if [[ -z "$*" ]]
  then
    echo "$usage" >&2
    return 2
  fi

  case "$1" in
    --help|-h)
      echo "$usage"
      return
      ;;
  esac

  local e
  e=$(emoji-fzf preview --prepend | \
      fzf -d' ' --filter "$*" | awk '{ print $1; exit }')

  local clipboard_cmd=($(__emoji_fzf_clipboard_cmd))
  if [[ -n "$e" ]]
  then
    echo "Putting $e into your X selection" >&2
    echo -n "$e" | "$clipboard_cmd[@]"
  fi
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
  alias emojilucky=__emoji_fzf_alias_emojilucky
fi

# vim: set ft=zsh et ts=2 sw=2 :
