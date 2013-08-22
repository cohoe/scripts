#!/usr/bin/env python

import argparse
import re
import os
import ldap
from getpass import getpass
from string import Template

# Base class for LDAP implementation object
class directoryserver(object):
    # Attributes supported by this program
    s_attrs = ['username','lastname','firstname']

    def __init__(self, i_vals, ld_type):
        # These are common to all implementations
        values = {'lastname':'sn', 'firstname':'givenName', 'mode':ld_type}
        self.set_values(dict(values, **i_vals))

    def set_values(self, values):
        for k in values:
            setattr(self, k, values[k])
            setattr(self, values[k], k)

# Active Directory instance
class ad(directoryserver):
    def __init__(self):
        values = {'username':'sAMAccountName'}
        self.bindstring = Template("ldapsearch -x -LLL -e pr=200/noprompt -h $server -D \"$binder\" -W \"$search\" $attrs")

        super(type(self), self).__init__(values, type(self).__name__)

# OpenLDAP instance
class openldap(directoryserver):
    def __init__(self):
        values = {'username':'uid'}
        self.bindstring = Template("ldapsearch -x -LLL -h $server -D \"$binder\" -W \"$search\" $attrs")

        super(type(self), self).__init__(values, type(self).__name__)

# Get the domain from the system. This needs some work...
def get_sys_domain():
    dom = re.sub(r'^(.*?)\.','',os.getenv('HOSTNAME'))
    return dom

# Get the user from the system
def get_sys_user():
    user = os.getenv('USER')
    return user

# Get the domain that was provided from the arguments
def get_domain():
    return args.domain

# Get the user that was provided from the arguments
def get_user():
    return args.user

# Prompt the user for their password
def get_user_password():
    pw = getpass("Enter password: ")
    return pw

# Set up and parse the arguments given on the CLI
def get_args():
    parser = argparse.ArgumentParser(description="Lookup basic ID information from an LDAP server", epilog="Written by Grant Cohoe (http://grantcohoe.com)")
    parser.add_argument("-m", "--mode", dest="mode", metavar="MODE", default="ad", help="set ldap mode (ad or openldap)")
    parser.add_argument("-u", "--user", dest="user", metavar="USER", default=get_sys_user(), help="User to bind as (default: current)")
    parser.add_argument("-d", "--domain", dest="domain", metavar="DOMAIN", default=get_sys_domain(), help="LDAP domain to search (ex: corp.example.com). Default is system domain.")
    parser.add_argument("-s", "--server", dest="server", metavar="SERVER", default=None, help="LDAP server to bind to (ex: ldap.example.com). Default is domain server (AD-style)")
    parser.add_argument("-i", "--input", dest="input", metavar="fields", required=True, help="specify input values (username,lastname,firstname)")
    parser.add_argument("-o", "--output", dest="output", metavar="fields", help="specify output values (username,lastname,firstname)")
    parser.add_argument("-p", "--print", dest="prnt", action="store_true", help="print an ldapsearch command rather than executing a bind")

    return parser.parse_args()

# Set the mode of the ldap object based on what the CLI said
def set_ldap_mode():
    global ld
    if args.mode == "ad":
        ld = ad()
    elif args.mode == "openldap":
        ld = openldap()
    else:
        print "error: mode can only be 'ad' or 'openldap'"
        quit(1)

# Build search filter
def get_filter():
    u_input = str(args.input).split(',')
    u_attrs = {}
    for item in u_input:
        try:
            (k,v) = item.split('=')
        except ValueError:
            print "Need to specify a value to search on (ex: username=foo)"
            quit(1)
        if k not in ld.s_attrs:
            print "error: attribute "+k+" is not supported"
            quit(1)
        u_attrs[getattr(ld,k)] = v

    filter = "(&"
    for item in u_attrs:
        filter +="("+item+"="+u_attrs[item]+")"
    filter += ")"
    return filter

# Output attrs
def get_output_attributes(raw):
    u_output = str(args.output).split(',')
    u_print = []
    for item in u_output:
        if item not in ld.s_attrs:
            print "error: attribute "+item+" is not supported"
            quit(1)
        u_print.append(item)
    o_attrs = ""
    if raw:
        raw_attrs = []
        for item in u_print:
            raw_attrs.append(getattr(ld,item))
        return raw_attrs
    else:
        for item in u_print:
            o_attrs += getattr(ld,item)+" "
        return o_attrs

# Create the bind DN string based on what mode we are in
def get_binder():
    if ld.mode == "ad":
        return args.user+"@"+args.domain
    elif ld.mode == "openldap":
        return args.user
    else:
        print "Error in processing mode."
        quit(1)

# Figure out where to bind to in the event the user never specified it
def get_server():
    if args.server is None:
        return args.domain
    return args.server

# Build the ldapsearch command
def build_search():
    ldapsearch = ld.bindstring.substitute(
        domain=get_domain(),
        server=get_server(),
        user=get_user(),
        binder=get_binder(),
        search=get_filter(),
        attrs=get_output_attributes(None)
    )
    return ldapsearch

# Calculate the base DN for a directory based on the domain name given
def get_base_dn(domain):
    dn = "dc="
    dn += re.sub(r'\.',',dc=',domain)
    return dn

# Bind to the directory server and query
def bind_search():
    o_attrs = get_output_attributes(1)
    i_filter = get_filter()
    pw = get_user_password()

    l = ldap.initialize("ldap://"+get_server())
    l.protocol_version = 3
    # This allows for binding to AD with 'user@domain' syntax rather than 'cn=user'
    if ld.mode == "ad":
        l.set_option(ldap.OPT_REFERRALS, 0)
    try:
        l.simple_bind_s(get_binder(), pw)
    except ldap.INVALID_CREDENTIALS:
        print "Invalid LDAP credentials"
        quit(1)

    # Search
    r = l.search(get_base_dn(get_domain()), ldap.SCOPE_SUBTREE, i_filter, o_attrs)
    type,results = l.result(r,60)
    # AD returns extra crap that we don't want
    if ld.mode == "ad":
        results.pop()
    return results 

# Print the results in a pretty way
def result_print(res):
    for result in res:
        print "Result:"
        for attr in get_output_attributes(1):
            if attr in result[1]:
                print getattr(ld, attr)+": "+result[1][attr][0]
            else:
                print getattr(ld, attr)+": Not specified in this directory"

# main functionality of this program
def main():
    global args
    args = get_args()
    set_ldap_mode()
    if args.prnt is True:
        print build_search()
    else:
        res = bind_search()
        result_print(res)

if __name__ == "__main__":
    main()
