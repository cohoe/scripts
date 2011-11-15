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

my $realm = `cat /etc/krb5.conf | grep default_realm | awk '{print \$3}'`;
chomp $realm;
my $principal = `find /var/* -name principal 2>/dev/null`;
chomp $principal;
my $stash = `find /var/* -name .k5.$realm 2>/dev/null`;
chomp $stash;

print "# KCRAP configuration file. \n# WARNING: This must be done on your KDC!\n";

print "[kcrap_server]\n\tport = 89\n\trealm = $realm\n\n";

print "[realms]\n\t$realm = {\n\t\tdatabase_name = $principal\n\t\tkey_stash_file = $stash\n\t}\n";
