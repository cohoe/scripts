#!/usr/bin/perl

use strict;
use warnings;
use Socket;

my $ipaddr = gethostbyname("ns1.grantcohoe.com");
print inet_ntoa($ipaddr);
