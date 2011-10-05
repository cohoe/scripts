#!/usr/bin/perl
use warnings;
use strict;
#import javax.swing.joptionpane;
print "Running rpcinfo\n";
my $rawinput = `rpcinfo -b 100005 2`;
print "Finished rpcinfo, finally. $rawinput\n";
my %hosts;
my @shares;
my @rawhosts;
@rawhosts = split("\n", $rawinput);
foreach my $host(@rawhosts){
$host =~ s/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+.*$/$1/;
print "$host\n";
$hosts{$host}=1;
}
my $key;
my $value;
while (($key,$value)= each(%hosts)){
push(@shares, split("\n",`showmount -a $key`));
}
foreach my $share (@shares){
print "$share\n";
}
