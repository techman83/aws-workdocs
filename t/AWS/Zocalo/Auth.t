#!/usr/bin/perl -w

use lib 't/lib/';

use AWS::Zocalo::Test;
use Test::Most;
use Test::Warnings;

my $tester = AWS::Zocalo::Test->new();

$tester->test_with_auth(\&user_testing, 6);
$tester->test_with_dancer(\&user_testing, 6);

sub user_testing {
  my ($auth,$config,$message) = @_;

  pass("Auth Testing: $message");  
  use_ok("AWS::Zocalo::Auth");
  
  subtest 'Instantiation' => sub {
    isa_ok($auth, "AWS::Zocalo::Auth");
    
    can_ok($auth, qw(token api_base api_uri api_get api_post api_put api_delete));
  };

  subtest 'Token' => sub {
    isnt($auth->token, undef, "Token Request Successful");
  };
}

done_testing();
__END__
