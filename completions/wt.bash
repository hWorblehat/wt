# Bash completion for the `wt` git-worktree wrapper.
#
# Install: source it from ~/.bashrc:
#   source /path/to/wt.bash
# or drop it in a bash-completion directory:
#   cp wt.bash ~/.local/share/bash-completion/completions/wt

_wt() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # First word: the subcommand.
  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=($(compgen -W "co checkout prune" -- "$cur"))
    return
  fi

  case "${COMP_WORDS[1]}" in
    co | checkout)
      if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "-p --pull --setup --no-setup --submodules --no-submodules" -- "$cur"))
        return
      fi
      # Local branches plus remote branches (remote prefix stripped), minus HEAD.
      local branches
      branches=$(
        {
          git for-each-ref --format='%(refname:short)' refs/heads
          git for-each-ref --format='%(refname:short)' refs/remotes | sed -E 's#^[^/]+/##'
        } 2>/dev/null | grep -vx HEAD | sort -u
      )
      COMPREPLY=($(compgen -W "$branches" -- "$cur"))
      ;;
  esac
}
complete -F _wt wt
