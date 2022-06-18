# Fully integrate!
#   https://github.com/kalkin/zsh


# The format of login / logout reports if the watch parameter is set.
# Default is `%n has %a %l from %m'.
# Recognizes the following escape sequences:
# %n = name of the user that logged in/out.
# %a = observed action, i.e. "logged on" or "logged off".
# %l = line (tty) the user is logged in on.
# %M = full hostname of the remote host.
# %m = hostname up to the first `.'.
# %t or %@ = time, in 12-hour, am/pm format.
# %w = date in `day-dd' format.
# %W = date in `mm/dd/yy' format.
# %D = date in `yy-mm-dd' format.
# WATCHFMT='%n %a %l from %m at %t.'
# WATCHFMT='*knock* *knock* Follow the white rabbit => %n %a %l from %m at %t.'
# WATCHFTM=print '\e[1;35m%B[%b\e[1;32m%B%n%b\e[1;35m%B]%b \e[1;34m%U%a%u \e[1;35mfrom terminal \e[1;31m%M \e[1;35mat \e[1;33m%U%T%u\e[0m''
#WATCHFMT="[%B%t%b] %B%n%b has %a %B%l%b from %B%M%b"
WATCHFMT="%B->%b %n has just %a %(l:tty%l:%U-Ghost-%u)%(m: from %m:)"

# format of process time reports with 'time'
# %% A `%'.
# %U CPU seconds spent in user mode.
# %S CPU seconds spent in kernel mode.
# %E Elapsed time in seconds.
# %P The CPU percentage, computed as (%U+%S)/%E.
# %J The name of this job.
# Default is:
# %E real %U user %S system %P %J
TIMEFMT="Real: %E User: %U System: %S Percent: %P Cmd: %J"

# Limit this f*ing "zsh: do you wish to see all NNN possibilities (NNN
# lines)?" downward (default is 100). Only ask before displaying
# completions if doing so would scroll.
LISTMAX=0
