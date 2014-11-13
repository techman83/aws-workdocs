package AWS::Zocalo::Test;

use strict;
use warnings;
use AWS::Zocalo::Auth;
use Config::Tiny;
use Moo;
use Method::Signatures;
use Test::Most;

has 'config' => (
  is => 'ro',
  lazy => 1,
  builder => 1,
);

method _build_config() {
  my $config = Config::Tiny->read( "$ENV{HOME}/.zocalotest" );
  return $config;
}

method test_with_auth($test, $number_tests) {
  SKIP: {
    skip "No auth credentials found.", $number_tests unless ( -e "$ENV{HOME}/.zocalotest" );

    my $auth = AWS::Zocalo::Auth->new(
      region => $self->config->{auth}{region}, 
      alias => $self->config->{auth}{alias}, 
      username => $self->config->{auth}{username}, 
      password => $self->config->{auth}{password}, 
    );

    $test->($auth,$self->config->{test}, "Testing Live Zocalo API");
  }
}

method test_with_dancer($test, $number_tests) {
  SKIP: {
    eval {  
      require Dancer2; 
      require JSON;
    };

    skip 'These tests are for cached testing and require Dancer2 + JSON.', $number_tests if ($@);

    my $pid;
    # If we're inside a Travis build, we'll launch before running.
    if (!$ENV{TRAVIS_BUILD}) {
      # Launch Dancer Instance - http://www.perlmonks.org/?node_id=964597
      $pid = fork();

      if (!$pid) {
        exec("t/bin/cached_api.pl");
      }

      # Allow some time for the instance to spawn. TODO: Make this smarter
      sleep 5;
    }

    my $config = {
      username => 'zocalo.test@example.com',
      password => 'mustbe8Chars^',
      givenname => 'Zocalo',
      surname => 'Test',
    };

    my $auth = AWS::Zocalo::Auth->new(
      api_base => "http://localhost:3001",
      region => 'us-west-2', 
      alias => 'example', 
      username => 'zocalo.admin@example.com', 
      password => 'aReallyGoodone..', 
    );

    $test->($auth, $config, "Testing Cached API");
  
    if (!$ENV{TRAVIS_BUILD}) {
      # Kill Dancer
      kill 9, $pid;
    }
  }
}

1;
