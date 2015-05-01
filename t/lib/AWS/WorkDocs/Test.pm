package AWS::WorkDocs::Test;

use strict;
use warnings;
use AWS::WorkDocs::Auth;
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
  my $config = Config::Tiny->read( "$ENV{HOME}/.workdocstest" );
  return $config;
}

method test_with_auth($test, $number_tests) {
  SKIP: {
    skip "No auth credentials found.", $number_tests unless ( -e "$ENV{HOME}/.workdocstest" );

    my $auth = AWS::WorkDocs::Auth->new(
      region => $self->config->{auth}{region}, 
      alias => $self->config->{auth}{alias}, 
      username => $self->config->{auth}{username}, 
      password => $self->config->{auth}{password}, 
    );

    $test->($auth,$self->config->{test}, "Testing Live WorkDocs API");
  }
}

method test_with_dancer($test, $number_tests) {
  SKIP: {
    eval {  
      require Dancer2; 
      require JSON;
    };

    skip 'These tests are for cached testing and require Dancer2 + JSON.', $number_tests if ($@);

    my $pid = fork();

    if (!$pid) {
      exec("t/bin/cached_api.pl");
    }

    # Allow some time for the instance to spawn. TODO: Make this smarter
    sleep 5;

    my $config = {
      username => 'workdocs.test@example.com',
      password => 'mustbe8Chars^',
      givenname => 'WorkDocs',
      surname => 'Test',
      folder => '12345678',
      document => '12345678',
    };

    my $auth = AWS::WorkDocs::Auth->new(
      api_base => "http://localhost:3001",
      region => 'us-west-2', 
      alias => 'example', 
      username => 'workdocs.admin@example.com', 
      password => 'aReallyGoodone..', 
    );

    $test->($auth, $config, "Testing Cached API");
  
    # Kill Dancer
    kill 9, $pid;
  }
}

1;
