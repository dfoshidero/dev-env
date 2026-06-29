# Powerlevel10k config — minimal defaults
# Run `p10k configure` after first install to customize your prompt.

# Left prompt segments
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  dir
  vcs
  newline
  prompt_char
)

# Right prompt segments
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status
  command_execution_time
  background_jobs
  time
)

typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true
typeset -g POWERLEVEL9K_RPROMPT_ON_NEWLINE=true
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
typeset -g POWERLEVEL9K_TIME_FORMAT='%H:%M'

# Mise/python version in prompt (optional)
typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYTHON=false
