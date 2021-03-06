#!/bin/sh

# Verifies that you have the proper Perl modules installed to
# compile and run Stanford Webauth 4
#
# Grant Cohoe 2011 (www.grantcohoe.com)

perl -mCGI::Application -e 1
perl -mCGI::Application::Plugin::AutoRunmode -e 1
perl -mCGI::Application::Plugin::Forward -e 1
perl -mCGI::Application::Plugin::Redirect -e 1
perl -mCGI::Application::Plugin::TT -e 1
perl -mLWP -e 1
perl -mCrypt::SSLeay -e 1
perl -mTemplate -e 1
perl -mURI -e 1
perl -mXML::Parser -e 1
