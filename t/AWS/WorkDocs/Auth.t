#!/usr/bin/perl -w

use lib 't/lib/';

use AWS::WorkDocs::Test;
use Test::Most;
use Test::Warnings;
use Test::MockTime qw(set_relative_time);

my $tester = AWS::WorkDocs::Test->new();

$tester->test_with_auth(\&user_testing, 4);
$tester->test_with_dancer(\&user_testing, 4);

sub user_testing {
  my ($auth,$config,$message) = @_;

  pass("Auth Testing: $message");  
  use_ok("AWS::WorkDocs::Auth");
  
  subtest 'Instantiation' => sub {
    isa_ok($auth, "AWS::WorkDocs::Auth");
    
    can_ok($auth, qw(token api_base api_uri api_get api_post api_put api_delete));
  };

  subtest 'Token' => sub {
    isnt($auth->token, undef, "Token Request Successful");
    ok($auth->_expiration =~ /^\d+.?\d+$/ , "Expiration parsed");
    TODO:{
      local $TODO = "Refreshing of tokens not currently implemented\n";
      use POSIX qw(strftime);
      set_relative_time(86400);
      ok(time < $auth->_expiration, "Token refreshed");
    }
  };
}

done_testing();
__END__
