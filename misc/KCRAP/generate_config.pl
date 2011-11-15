#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  generate_config.pl
#
#        USAGE:  ./generate_config.pl  
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
#      CREATED:  11/15/2011 12:32:50 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

my $realm = `cat /etc/resolv.conf | egrep -e "^search" | awk '{print \$2}' | tr '[:lower:]' '[:upper:]'`;
chomp $realm;
my $principal = `find /var/* -name principal`;
chomp $principal;
my $stash = `find /var/* -name .k5.$realm`;
chomp $stash;

print "[kcrap_server]\n\tport = 1999\n\trealm = $realm\n\n";

print "[realms]\n\t$realm = {\n\t\tdatabase_name = $principal\n\t\tkey_stash_file = $stash\n\t}\n";
