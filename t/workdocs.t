#!/usr/bin/perl -w

use strict;
use v5.010;
use Test::More;
use Test::Warnings;

use_ok('experimental', 'say');

use_ok('AWS::WorkDocs');

done_testing();
