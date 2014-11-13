#!/usr/bin/perl
use lib './t/lib/';

use strict;
use Dancer2;
use AWS::Zocalo::Test::Auth;
use AWS::Zocalo::Test::User;

my $DEBUG = $ENV{ZOCALO_DEBUG} || 0;

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
