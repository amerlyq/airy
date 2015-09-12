# Common: don't run as standalone!
package urxcommon;

# =================== Package ========================
use warnings;
use strict;
no strict 'subs';  # because 'urxvt::*' can't be imported
use Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();  # Always export
@EXPORT_OK   = qw(cmd_err run_err line_count text_metrics
                  paired makecurry fmt_key);  # On demand
%EXPORT_TAGS = (API => [qw(&cmd_err &run_err &line_count &text_metrics
                        &paired &makecurry &fmt_key)]);


# =================== Embed ========================
sub cmd_err { warn "unknown command '$_[0]'\n"; () }
sub run_err { warn "error running: '$_[0]': $!\n"; () }

# =================== Shorts ========================

sub line_count { scalar(split('\n', $_[0])); }
sub text_metrics { sprintf("%dL> %-d", line_count($_[0]), length($_[0])); }

# =================== Convertors ========================

# Wrapper for action tuples: curry (args bind) impl by closure
sub paired { my $val = pop @_; map { $_=> $val } @_ }
sub makecurry {
    my ($hmap, @nms) = @_;
    my @funs = map { $hmap->{$_} if $_ } @nms;
    return sub { $_->(@_) foreach @funs; }
    # ALT return eval "sub {". map { "$_" . '->(@_);' } @funs ."}"; }
}

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

# Input events
sub fmt_key
{
    my ($term, $event, $keysym) = @_;
    # if (0x20 <= $keysym && $keysym < 0x80) {
    return std_mod($term, $event) . std_key($term, $keysym);
}
