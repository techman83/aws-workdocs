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
      require Proc::Daemon;
      require JSON;
    };

    skip 'These tests are for cached testing and require Proc::Daemon, Dancer2 + JSON.', $number_tests if ($@);

    my $auth = AWS::Zocalo::Auth->new(
      api_base => "http://localhost:3000/v1",
      region => $self->config->{auth}{region}, 
      alias => $self->config->{auth}{alias}, 
      username => $self->config->{auth}{username}, 
      password => $self->config->{auth}{password}, 
    );

    #$test->($auth,$self->config->{test}, "Testing Cached API");
  }
}

1;
