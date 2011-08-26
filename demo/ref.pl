#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  ref.pl
#
#        USAGE:  ./ref.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  04/27/11 16:59:27
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

my $a = 'foo';
my $b = 'bar';
my $c = 'baz';

# Initial variable setting
print "$a $b $c\n";

# Assign variables by internal referencing
&ref_vars($a, $b, $c);
print "$a $b $c\n";

# Assign new variable values via return (the preferred way)
($a,$b,$c) = &ret_vars($a,$b,$c);
print "$a $b $c\n";

# Assign via renamed references inside subroutine
&ren_vars(\$a,\$b,\$c);
print "$a $b $c\n";

# Subroutines
sub ref_vars {
	$_[0] = 'lorem';
	$_[1] = 'ipsum';
	$_[2] = 'dottor';
}

sub ret_vars {
	my ($d,$e,$f) = @_;
	$d = 'oof';
	$e = 'rab';
	$f = 'zab';
	return ($d,$e,$f);
}

sub ren_vars {
	my ($g,$h,$i) = @_;
	$$g = 'merol';
	$$h = 'muspi';
	$$i = 'rottod';
}
