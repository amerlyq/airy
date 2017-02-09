#!/usr/bin/perl
# /usr/bin/perl -w --
#   http://docstore.mik.ua/orelly/unix3/upt/ch21_09.htm

use strict;
use warnings;
use strict 'vars';

use Getopt::Std;
use Digest::SHA qw(sha256);

my %opts=();
getopts("b:f:h", \%opts);
# our ($opt_b, $opt_f, $opt_h);  # Direct access

if( $opts{'h'} || (defined $opts{'f'} and not -e $opts{'f'}) ){
print <<USAGE;
    $0 -f ./video -b /tmp/dst
USAGE
exit;
}

my $src = $opts{'-f'} || $ARGV[0] || "/bin/tempfile";
my $dst = $opts{'-b'} || "/tmp/ffbin";
my($fin, $fout);

my $fsz = (stat $src)[7];
open ($fin, "<", $src) or die "No file\n";
binmode ($fin);

open ($fout, ">", $dst) or die "Can't output\n";
binmode ($fout);

my $sz  = 1024;  # Read file in 1K blocks
my $offset = 0;
my($buf, $fhash) = ("", "");

while ($offset < $fsz) {
    $offset += read ($fin, $buf, $sz);
    my $wrote = syswrite ($fout, $buf);
    my $size  = length($buf);

    # TODO: backward!
    printf STDOUT "%8d ", $offset;
    warn "WARN: truncated write" unless $wrote == $size;

    my $fhash = sha256($buf . $fhash);
    print unpack("H*", $fhash), "\n";
}
print STDOUT "\n";

close ($fin) or die "Can't close: $src\n";
close ($fout) or die "Can't close: $dst\n";


# sub write_file {
#   my($fname, $ext, $buf) = @_;
#   if($ext = '.txt'){ ... } elsif(...){ ... }else{ die "?!"; }
#   # ...
# }
