# Start X at login
if status is-login
    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
        exec xinit
    end
end

if status is-interactive
    # Commands to run in interactive sessions can go here
end
set -g fish_greeting

function _ranger_cwd --on-event fish_exit
  # set --local tmp ${RANGER_TMPDIR:-${XDG_RUNTIME_DIR:-/tmp}/ranger}
  set --local tmp /run/user/1000/ranger
  builtin test -d "$tmp" || command mkdir -p "$tmp"
  # (set +C && printf "%s" "$PWD" > "$tmp/cwd")
  printf "%s" "$PWD" > $tmp/cwd
end


## git
abbr -a gA  'git annex add'
abbr -a ga  'git add --all (test -e $PWD/.git || echo .)'
abbr -a ga. 'git add --all .'
abbr -a gau 'git add --update'
abbr -a gc1 'git clone --depth=1 --single-branch'
abbr -a gc  '/@/airy/git/ctl/my-msg --index --modtime --commit (test -e .git || echo --prefix=(basename $PWD))'
abbr -a gc. '/@/airy/git/ctl/my-msg --index --modtime --commit --prefix=(basename $PWD)'
abbr -a gcn '/@/airy/git/ctl/my-msg --index --modtime --commit --prefix'
abbr -a gcf 'git commit --amend --reuse-message HEAD'
abbr -a gco 'git checkout'
abbr -a gcs 'git show'
abbr -a gcss 'git show --stat'
abbr -a gdf 'git diff -M --color-moved'
abbr -a gd. 'git diff -M --color-moved .'
abbr -a gd  'git diff -M --color-moved --cached -w'
abbr -a gds 'git diff -M --color-moved --stat'
abbr -a gf  'git fetch --verbose --progress --tags'
abbr -a gir 'git reset'
abbr -a gir1 'git reset --soft HEAD~'
abbr -a glg 'git log --date=short --format=format:"%C(bold green)%ad%C(reset) %C(yellow)%h%C(reset) %<(60)%C(white)%s%C(reset)%C(bold red)%d%C(reset) %C(bold blue)[%aN]%C(reset)" --graph'
abbr -a gla 'git log --date=short --format=format:"%C(bold green)%ad%C(reset) %C(yellow)%h%C(reset) %<(60)%C(white)%s%C(reset)%C(bold red)%d%C(reset) %C(bold blue)[%aN]%C(reset)" --graph --all'
abbr -a gl  'git pull --rebase --verbose'
abbr -a gs  'git status -sb --show-stash'
abbr -a Gd  'just world dash modified -va'
abbr -a Gd. 'just world dash -C . modified -va'
abbr -a Gr  'just world dash remotes'
abbr -a Gr. 'just world dash -C . remotes'
abbr -a Gs  'just world dash modified'
abbr -a Gs. 'just world dash -C . modified'
abbr -a Gt  'just world dash modified -v'
abbr -a Gt. 'just world dash -C . modified -v'
abbr -a Gu  'just world dash unsynced'
abbr -a Gu. 'just world dash -C . unsynced'
abbr -a gx 'set -x GIT_DISCOVERY_ACROSS_FILESYSTEM 1'
abbr -a gz1 '/@/airy/git/ctl/snapshot'


## pacman
abbr -a auri 'pikaur --sync --noedit --nodiff'
abbr -a aurq 'pikaur --query --info'
abbr -a aurs 'pikaur --sync --noedit --nodiff --search'
abbr -a aurx 'pikaur --remove --recursive'

abbr -a pacr1 'pactree --color --depth 1'
abbr -a pacR1 'pactree --color --depth 1 --reverse'
abbr -a pacr 'pactree -c'
abbr -a pacR 'pactree -cr'

abbr -a pac\? 'checkupdates'
abbr -a pacD 'sudo pacman -D --asdeps'
abbr -a paci 'sudo pacman -S'
abbr -a pacx 'sudo pacman -Rsu'

abbr -a pacg 'pacman -Sg'
abbr -a pacl 'pacman -Ql'
abbr -a pacL 'pacman -Qo'
abbr -a pacQ 'pacman -Qi'
abbr -a pacq 'pacman -Si'
abbr -a pacS 'pacman -Qs'
abbr -a pacs 'pacman -Ss'
abbr -a pacz 'pacman -Qdt'


## just.lib
abbr -a j.s 'just moni scr | v -'
abbr -a ji 'just airy install'
abbr -a wks 'just tenjo wk'
abbr -a j.j 'just tenjo cat --timefmt=h --begdate=d --enddate=0 --outputfmt=j -t'
abbr -a fs 'just miur navi'
abbr -a ij 'jupyter console'
