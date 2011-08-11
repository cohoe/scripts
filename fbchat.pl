#!/usr/bin/perl

use strict;
use warnings;

my $prev_line = "";

while(<>) {
	my $input_string = $_;
	if($input_string =~ m/.*?"msg":\{"text":/) {
		chomp $input_string;
#		$input_string =~ s/.*?"text":"(.*?)".*?"from_name":"(.*?)",".+/$1 $2/;
		my $message = $input_string;
		my $from_fbid = $input_string;
		my $to_fbid = $input_string;
		$message =~ s/.*?"text":"(.*?)".+/$1/;
		$from_fbid =~ s/.*?"from":(.*?),.+/$1/;
		$to_fbid =~ s/.*?"to":(.*?),.+/$1/;
#		$input_string =~ s/.*?"text":"(.*?)".*?"from":(.*?).+/$2: $1/;
		if($message ne $prev_line) {
			print "\"$from_fbid\" -> \"$to_fbid\":\t$message\n";
#			print "TO: \"$to_fbid\"\t";
#			print "MESSAGE: \"$message\"\n";
			$prev_line = $message;
		}
	}
}
