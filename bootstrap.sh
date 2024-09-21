#!/usr/bin/env bash
#
# Bootstrap script for setting up.

set -e

DOTFILES_ROOT=$(pwd -P)

echo ''

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

setup_gitconfig () {
  if ! [ -f git/gitconfig.local.symlink ]; then
    info 'setup gitconfig'

    git_credential='cache'
    if [ "$(uname -s)" == 'Darwin' ]; then
      git_credential='osxkeychain'
    fi

    if [ -n "$GIT_AUTHORNAME" ]; then
      git_authorname="$GIT_AUTHORNAME"
    else
      user ' - What is your github author name?'
      read -e git_authorname
    fi

    if [ -n "$GIT_AUTHOREMAIL" ]; then
      git_authoremail="$GIT_AUTHOREMAIL"
    else
      user ' - What is your github author email?'
      read -e git_authoremail
    fi

    sed -e "s/AUTHORNAME/$git_authorname/g" -e "s/AUTHOREMAIL/$git_authoremail/g" -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" git/gitconfig.local.symlink.example > git/gitconfig.local.symlink

    success 'gitconfig'
  fi
}


link_file () {
  local src=$1 dst=$2

  local overwrite= backup= skip=
  local action=

  if [ -f "$dst" -o -d "$dst" -o -L "$dst" ]; then
    if [ "$overwrite_all" == 'false' ] && [ "$backup_all" == 'false' ] && [ "$skip_all" == 'false' ]; then
      local current_src="$(readlink $dst)"

      if [ "$current_src" == "$src" ]; then
        skip=true;
      else
        user "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        read -n 1 action

        case "$action" in
          o )
            overwrite=true;;
          O )
            overwrite_all=true;;
          b )
            backup=true;;
          B )
            backup_all=true;;
          s )
            skip=true;;
          S )
            skip_all=true;;
          * )
            ;;
        esac
      fi
    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" == 'true' ]; then
      rm -rf "$dst"
      success "removed $dst"
    fi

    if [ "$backup" == 'true' ]; then
      mv "$dst" "${dst}.backup"
      success "moved $dst to ${dst}.backup"
    fi

    if [ "$skip" == 'true' ]; then
      success "skipped $src"
    fi
  fi

  if [ "$skip" != 'true' ]; then
    ln -s "$1" "$2"
    success "linked $1 to $2"
  fi
}

install_dotfiles () {
  info 'installing dotfiles'

  local overwrite_all=false backup_all=false skip_all=false

  for src in $(find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink' -not -path '*.git*'); do
    dst="$HOME/.$(basename "${src%.*}")"
    link_file "$src" "$dst"
  done
}

setup_gitconfig
install_dotfiles

if [ "$(uname -s)" == 'Darwin' ]; then
  info 'installing dependencies'
  if source bin/dot.sh | while read -r data; do info "$data"; done; then
    success 'dependencies installed'
  else
    fail 'error installing dependencies'
  fi
fi

echo ''
echo '  All installed!'
