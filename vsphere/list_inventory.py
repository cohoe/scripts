#!/usr/bin/env python

from pysphere import VIServer
import argparse
import sys
from getpass import getpass

def main():
	parser = argparse.ArgumentParser(
		description="List a vCenter Server's inventory",
		epilog="Written by Grant Cohoe")
	parser.add_argument('hostname', 
		help="The FQDN or IP address of the vCenter Server to connect to")
	parser.add_argument('username', 
		help="The username to connect as")
	parser.add_argument('-p','--password', 
		help="The password to connect with")
	args = parser.parse_args()

	if not args.password:
		args.password = getpass("Enter the password for "+args.username+": ")
	
	server = VIServer()
	server.connect(args.hostname, args.username, args.password)
	get_inventory(server)

def get_inventory(srv):
	vmlist = srv.get_registered_vms()
	#print vmlist
	for vm in vmlist:
		print vm

if __name__ == "__main__":
	main()
