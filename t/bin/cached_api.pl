#!/usr/bin/env perl
use lib './t/lib/';

use strict;
use Dancer2;
use AWS::WorkDocs::Test::Auth;
use AWS::WorkDocs::Test::User;
use AWS::WorkDocs::Test::Content;
use AWS::WorkDocs::Test::Invite;

my $DEBUG = $ENV{WORKDOCS_DEBUG} || 0;

# Debug/Dev
if ($DEBUG) {
  set logger => 'console';
  set log => 'core';
}

# Setting it in the config file didn't appear to work.
# Not sure why, normally would use plackup, but unnecessary
# here.
set port => 3001;

dance;
