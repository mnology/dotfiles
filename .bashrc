# scm prompt
[[ $- == ** ]] && . /usr/local/bin/git-prompt/git-prompt.sh

# ssh keychain
eval $(keychain --eval id_rsa aws_pre_prod)

# aws cli completion
complete -C aws_completer aws

# local vars
PROJ_DIR="$HOME/devel"
INFRA_PROJ="$PROJ_DIR/infrastructure"

# nike proxy stuff
source "$HOME/.dotfiles/lib/chef_aliases.sh"
source "$HOME/.dotfiles/lib/git_utils.shlib"

# gtm nike env
GTM_VAGRANT_ENV="$HOME/.dotfiles/.gtm_vagrant"
DEVHOME="/Users/Shared/Development/NikeBuild"
if [[ -d $DEVHOME && -e $GTM_VAGRANT_ENV ]]; then
  echo 'Setting GTM environment'
  source $GTM_VAGRANT_ENV
fi

# homebrew
export HOMEBREW_GITHUB_API_TOKEN=""
export BREW_PRE=$(brew --prefix)

if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

# local ruby env
eval "$(rbenv init -)"

RB_PRE=$(rbenv prefix)
export PATH=$HOME/bin:$BREW_PRE/sbin:$BREW_PRE/bin:$PATH
export PYTHONPATH=$PYTHONPATH:${HOME}/devel/infrastructure-scripts

export EDITOR='mvim -f'

# Aliases
alias svn='colorsvn'
alias foodcritic="foodcritic -I $INFRA_PROJ/foodcritic_rules/"

# color ls
if [ "$(uname)" == "Darwin" ]; then
  alias ls="ls -G"
elif [ "$(uname -s)" == "Linux" ]; then
  alias ls="ls --color"
fi

# nicer name completion
eval "$(thefuck --alias wut)"

# functions
function set_gtm(){
  export GTM_PRJ_HOME="$HOME/devel/$1"
}

function go_gtm() {
  cd $GTM_PRJ_HOME
}

function vm() {
  cd $GTM_PRJ_HOME
  if [ "$#" -ne "0" ]; then
    vagrant "$@"
    cd \-
  fi
}
