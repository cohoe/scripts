#!/usr/bin/env python

import argparse
import re
import os
import ldap
from getpass import getpass
from string import Template

attributes = ['username','lastname','firstname']

class directoryserver:
	lastname = "sn"
	firstname = "givenName"
	givenName = "firstname"
	sn = "lastname"

class ad(directoryserver):
	bindstring = Template("ldapsearch -x -LLL -e pr=200/noprompt -h $server -D \"$binder\" -W \"$search\" $attrs")
	username = "sAMAccountName"
	sAMAccountName = "username"
	mode = "ad"

class openldap(directoryserver):
	bindstring = Template("ldapsearch -x -LLL -h $server -D \"$binder\" -W \"$search\" $attrs")
	username = "uid"
	uid = "username"
	mode = "openldap"

def get_sys_domain():
	dom = re.sub(r'^(.*?)\.','',os.getenv('HOSTNAME'))
	return dom

def get_domain():
	return args.domain

def get_user():
	return args.user

def get_sys_user():
	user = os.getenv('USER')
	return user

def get_user_password():
	pw = getpass("Enter password: ")
	return pw

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

# Mode
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
		if k not in attributes:
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
		if item not in attributes:
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

def get_binder():
	if ld.mode == "ad":
		return args.user+"@"+args.domain
	elif ld.mode == "openldap":
		return args.user
	else:
		print "Error in processing mode."
		quit(1)

def get_server():
	if args.server is None:
		return args.domain
	return args.server

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

def get_base_dn(domain):
	dn = "dc="
	dn += re.sub(r'\.',',dc=',domain)
	return dn

def bind_search():
	o_attrs = get_output_attributes(1)
	i_filter = get_filter()
	pw = get_user_password()

	l = ldap.initialize("ldap://"+get_server())
	if ld.mode == "ad":
		l.set_option(ldap.OPT_REFERRALS, 0)
	l.protocol_version = 3
	try:
		l.simple_bind_s(get_binder(), pw)
	except ldap.INVALID_CREDENTIALS:
		print "Invalid LDAP credentials"
		quit(1)

	r = l.search(get_base_dn(get_domain()), ldap.SCOPE_SUBTREE, i_filter, o_attrs)
	type,results = l.result(r,60)
	if ld.mode == "ad":
		results.pop()
	return results 

def result_print(res):
	for result in res:
		print "Result:"
		for attr in get_output_attributes(1):
			if attr in result[1]:
				print getattr(ld, attr)+": "+result[1][attr][0]
			else:
				print getattr(ld, attr)+": Not specified in this directory"

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
