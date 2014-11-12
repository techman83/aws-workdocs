#!/usr/bin/perl

use lib 't/lib/';

use strict;
use Dancer2;

set serializer => 'JSON';
set logger => 'console';
set log => 'core';

use AWS::Zocalo::Test::Auth;
use AWS::Zocalo::Test::User;

dance;
