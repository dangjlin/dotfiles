# shell environment initialization {{{

case "$(uname -s)" in
  Linux)
    source /etc/os-release
    ;;
  Darwin)
    NAME=Darwin
esac

# for tool (the_silver_searcher git-extras htop); do
#   case "$NAME" in
#     Ubuntu)
#       [[ -z $(dpkg -l | grep $tool) ]] && sudo apt-get install -y $tool
#       ;;
#     Darwin)
#       [[ -z $(brew list | grep $tool) ]] && brew install $tool
#       ;;
#   esac
# done

case "$NAME" in
  Ubuntu)
    for tool (silversearcher-ag git-extras htop); do
      [[ -z $(dpkg -l | grep $tool) ]] && sudo apt-get install -y $tool
    done
    ;;
  Darwin)
    # for tool (the_silver_searcher git-extras htop); do
    #   [[ -z $(brew list | grep $tool) ]] && brew install $tool
    # done
    ;;
esac

if [[ ! -d ~/.dotfiles ]]; then
  git clone git://github.com/dangjlin/dotfiles.git ~/.dotfiles

  ln -sf ~/.dotfiles/gemrc               ~/.gemrc
  ln -sf ~/.dotfiles/inputrc             ~/.inputrc
  ln -sf ~/.dotfiles/psqlrc              ~/.psqlrc
  ln -sf ~/.dotfiles/tigrc               ~/.tigrc
  ln -sf ~/.dotfiles/pryrc               ~/.pryrc
  ln -sf ~/.dotfiles/tmux.conf           ~/.tmux.conf
  ln -sf ~/.dotfiles/vimrc.local         ~/.vimrc.local
  ln -sf ~/.dotfiles/vimrc.bundles.local ~/.vimrc.bundles.local

  ln -sf ~/.dotfiles/zshrc               ~/.zshrc

  mkdir -p ~/.psql_history
fi

if [[ ! -d ~/.asdf ]]; then
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.4.3
fi

if [[ ! -d ~/.maximum-awesome ]]; then
  git clone git://github.com/square/maximum-awesome.git ~/.maximum-awesome
  git clone https://github.com/VundleVim/Vundle.vim.git ~/.maximum-awesome/vim/bundle/Vundle.vim

  ln -sf ~/.maximum-awesome/vim ~/.vim
  ln -sf ~/.maximum-awesome/vimrc ~/.vimrc
  ln -sf ~/.maximum-awesome/vimrc.bundles ~/.vimrc.bundles

  vim +BundleInstall +qall
fi

# }}}


# zplug {{{

# install zplug, if necessary
if [[ ! -d ~/.zplug ]]; then
  export ZPLUG_HOME=~/.zplug
  git clone https://github.com/zplug/zplug $ZPLUG_HOME
fi

source ~/.zplug/init.zsh

 zplug "plugins/vi-mode", from:oh-my-zsh
 zplug "plugins/chruby",  from:oh-my-zsh
 zplug "plugins/bundler", from:oh-my-zsh
# zplug "plugins/rails",   from:oh-my-zsh

zplug "b4b4r07/enhancd", use:init.sh
zplug "junegunn/fzf", as:command, hook-build:"./install --bin", use:"bin/{fzf-tmux,fzf}"

zplug "zsh-users/zsh-autosuggestions", defer:3

# zim {{{
# zplug "zimframework/zim", as:plugin, use:"init.zsh", hook-build:"ln -sf $ZPLUG_REPOS/zimframework/zim ~/.zim"
zplug "zimfw/zimfw", as:plugin, use:"init.zsh", hook-build:"ln -sf $ZPLUG_REPOS/zimfw/zimfw ~/.zim"

zmodules=(directory environment git git-info history input spectrum ssh utility meta \
          syntax-highlighting history-substring-search prompt completion)

zhighlighters=(main brackets pattern cursor root)

if [[ "$NAME" = "Ubuntu" ]]; then
  zprompt_theme='eriner'
else
  zplug denysdovhan/spaceship-zsh-theme, use:spaceship.zsh, from:github, as:theme
  # zprompt_theme='liquidprompt'
fi
# }}}

if ! zplug check --verbose; then
  zplug install
fi

zplug load #--verbose

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'

source ~/.zplug/repos/junegunn/fzf/shell/key-bindings.zsh
source ~/.zplug/repos/junegunn/fzf/shell/completion.zsh

export FZF_COMPLETION_TRIGGER=';'
export FZF_TMUX=1

# }}}


# customization {{{

# directory shortcut {{{
p()  { cd ~/proj/$1;}
h()  { cd ~/$1;}
vm() { cd ~/vagrant/$1;}

compctl -W ~/proj -/ p
compctl -W ~ -/ h
compctl -W ~/vagrant -/ vm
# }}}

# development shortcut {{{
alias pa!='[[ -f config/puma.rb ]] && RAILS_RELATIVE_URL_ROOT=/`basename $PWD` bundle exec puma -C $PWD/config/puma.rb'
alias pa='[[ -f config/puma.rb ]] && RAILS_RELATIVE_URL_ROOT=/`basename $PWD` bundle exec puma -C $PWD/config/puma.rb -d'
alias kpa='[[ -f tmp/pids/puma.state ]] && pumactl -S tmp/pids/puma.state stop'

# alias mc='bundle exec mailcatcher --http-ip 0.0.0.0'
alias kmc='pkill -fe mailcatcher'
# alias sk='[[ -f config/sidekiq.yml ]] && bundle exec sidekiq -C $PWD/config/sidekiq.yml -d'
alias ksk='pkill -fe sidekiq'

pairg() { ssh -t $1 ssh -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' -p $2 -t vagrant@localhost 'tmux attach' }
pairh() { ssh -S none -o 'ExitOnForwardFailure=yes' -R $2\:localhost:$2 -t $1 'watch -en 10 who' }

cop() {
  local exts=('rb,thor,jbuilder')
  local excludes=':(top,exclude)db/schema.rb'
  local extra_options='--display-cop-names --rails'

  if [[ $# -gt 0 ]]; then
    local files=$(eval "git diff $@ --name-only -- *.{$exts} $excludes")
  else
    local files=$(eval "git status --porcelain -- *.{$exts} $excludes | sed -e '/^\s\?[DRC] /d' -e 's/^.\{3\}//g'")
  fi

  if [[ -n "$files" ]]; then
    echo $files | xargs bundle exec rubocop `echo $extra_options`
  else
    echo "Nothing to check. Write some *.{$exts} to check.\nYou have 20 seconds to comply."
  fi
}
# }}}

# tmux shortcut {{{
tx() {
  if ! tmux has-session -t work 2> /dev/null; then
    tmux new -s work -d;
    # tmux splitw -h -p 40 -t work;
    # tmux select-p -t 1;
  fi
  tmux attach -t work;
}
txtest() {
  if ! tmux has-session -t test 2> /dev/null; then
    tmux new -s test -d;
  fi
  tmux attach -t test;
}
txpair() {
  SOCKET=/home/share/tmux-pair/default
  if ! tmux -S $SOCKET has-session -t pair 2> /dev/null; then
    tmux -S $SOCKET new -s pair -d;
    # tmux -S $SOCKET send-keys -t pair:1.1 "chmod 1777 " $SOCKET C-m "clear" C-m;
  fi
  tmux -S $SOCKET attach -t pair;
}
fixssh() {
  if [ "$TMUX" ]; then
    export $(tmux showenv SSH_AUTH_SOCK)
  fi
}
# 重啟 puma/unicorn（非 daemon 模式，用於 pry debug）
rpy() {
  if bundle show pry-remote > /dev/null 2>&1; then
    bundle exec pry-remote
  else
    rpu pry
  fi
}
# }}}

# 啟動／停止 sidekiq
rsidekiq() {
 emulate -L zsh
   if [[ -d tmp ]]; then
     if [[ -r tmp/pids/sidekiq.pid && -n $(ps h -p `cat tmp/pids/sidekiq.pid` | tr -d ' ') ]]; then
       case "$1" in
         restart)
           bundle exec sidekiqctl restart tmp/pids/sidekiq.pid
           ;;
         *)
           bundle exec sidekiqctl stop tmp/pids/sidekiq.pid
       esac
    else
      echo "Start sidekiq process..."
      nohup bundle exec sidekiq  > ~/.nohup/sidekiq.out 2>&1&
      disown %nohup
    fi
  else
    echo 'ERROR: "tmp" directory not found.'
  fi
}


# 啟動／停止 mailcatcher
rmailcatcher() {
  rm /home/vagrant/.nohup/mailcatcher.out
  local pid=$(ps --no-headers -C mailcatcher -o pid,args | command grep '/bin/mailcatcher --http-ip' | sed 's/^ //' | cut -d' ' -f 1)
  if [[ -n $pid ]]; then
    kill $pid && echo "MailCatcher process $pid killed."
  else
    echo "Start MailCatcher process..."
    nohup mailcatcher --http-ip 0.0.0.0 > ~/.nohup/mailcatcher.out 2>&1&
    disown %nohup
  fi
}

# aliases {{{
alias px='ps aux'
alias vt='vim -c :CtrlP'
alias tm='tmux -2 attach || tmux new'

alias sa='ssh-add'
alias salock='ssh-add -x'
alias saunlock='ssh-add -X'

alias agi='ag -i'
alias agr='ag --ruby'
alias agri='ag --ruby -i'

alias -g G='| ag'
alias -g P='| $PAGER'
alias -g WC='| wc -l'
alias -g RE='RESCUE=1'

alias va=vagrant
alias vsh='va ssh'
alias vsf='va ssh -- -L 0.0.0.0:8080:localhost:80 -L 1080:localhost:1080'
alias vup='va up'
alias vsup='va suspend'
alias vhalt='va halt'
alias rc='rails c'
alias gpl='git pull'
alias gmd='git diff master...'
alias ggpull='git pull origin $(git_current_branch)'
alias gbr="git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'"
alias gba="git branch --all"
alias gst='git status'
alias gcom='git checkout master'
alias gad="git add"
alias gitlast="git for-each-ref --format='%(committerdate) %09 %(authorname) %09 %(refname)' | sort -k5n -k2M -k3n -k4n"

alias rdm='rake db:migrate'
# }}}

# environment variables {{{
export EDITOR=vim
export VISUAL=vim
#}}}

# export TEST_ENV_NUMBER='2'
# export USE_BOOTSNAP=1

# key bindings {{{
bindkey -M vicmd '^a' beginning-of-line
bindkey -M vicmd '^e' end-of-line

bindkey '^f' vi-forward-word
bindkey '^b' vi-backward-word

bindkey '^j' autosuggest-accept

bindkey '^p' history-substring-search-up
bindkey '^n' history-substring-search-down
bindkey "^[OF" end-of-line
bindkey "^[[F" end-of-line
bindkey "^[[4~" end-of-line
bindkey "^[OH" beginning-of-line
bindkey "^[[H" beginning-of-line
bindkey "^[[1~" beginning-of-line

# }}}

# }}}
case "$NAME" in
  Darwin)
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    
    export NVM_DIR=~/.nvm
    source $(brew --prefix nvm)/nvm.sh
    ;;
esac

if [[ -d ~/.asdf ]]; then
  . $HOME/.asdf/asdf.sh
  . $HOME/.asdf/completions/asdf.bash
fi

