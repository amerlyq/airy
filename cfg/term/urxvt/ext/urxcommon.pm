# Common: don't run as standalone!
package urxcommon;

# SEE
#   http://perldesignpatterns.com/?DispatchTable
#   http://perldoc.perl.org/perlop.html#Regexp-Quote-Like-Operators
#   http://perl101.org/arrays.html

## USAGE
# use urxcommon qw(&cmd_err &run_err);
# use urxcommon qw(:API);
# OR: urxcommon::fmt_key(@_)

# =================== Package ========================

use warnings;
use strict "vars";
# no strict 'subs';  # because 'urxvt::*' unimported
use Exporter;
use lib '/usr/lib/urxvt';
use urxvt;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = qw(on_action);  # Always
@EXPORT_OK   = qw(cmd_err run_err line_count text_metrics fmt_key);  # On demand
%EXPORT_TAGS = (API => [qw(&cmd_err &run_err &line_count &text_metrics &fmt_key)]);


# =================== Embed ========================
sub cmd_err { warn "unknown command '$_[0]'\n"; () }
sub run_err { warn "error running: '$_[0]': $!\n"; () }
# sub dbg_hash { my %all = @_;
#     foreach (sort keys %all) { print "$_ : $all{$_}\n"; } }
#     print "$_ : $all{$_}\n" for sort keys %all; }

# =================== Shorts ========================

sub line_count { scalar(split('\n', $_[0])); }
sub text_metrics { sprintf("%dL> %-d", line_count($_[0]), length($_[0])); }

# =================== Convertors ========================
# Input events
sub std_mod {
    my ($term, $event) = @_;
    my $mod = '';
    $mod .= 'A-' if ($event->{state} & $term->ModLevel3Mask);
    $mod .= 'M-' if ($event->{state} & $term->ModMetaMask);
    $mod .= 'C-' if ($event->{state} & urxvt::ControlMask);
    $mod .= 'S-' if ($event->{state} & urxvt::ShiftMask);
    return $mod;
}
sub std_key {
    my ($term, $keysym) = @_;
    my $key = $term->XKeysymToString($keysym);
    return (1 == length($key) ? lc $key : $key);
}
sub fmt_key
{
    my ($term, $event, $keysym) = @_;
    # if (0x20 <= $keysym && $keysym < 0x80) {
    return std_mod($term, $event) . std_key($term, $keysym);
}

# =================== Common urxvt api impl ========================

# EXPL for >v.9.19 (Ubuntu 14.04) used instead of on_user_command
# BUG need prepend extension name!
sub on_action { $_[0]->on_user_command($_[1]); () }
