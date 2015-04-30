#!/usr/bin/perl -w

use lib 't/lib/';

use AWS::WorkDocs::Test;
use Test::Most;
use Test::Warnings;
use Time::Local 'timegm';

my $tester = AWS::WorkDocs::Test->new();

$tester->test_with_auth(\&user_testing, 5);
$tester->test_with_dancer(\&user_testing, 5);

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
    is($auth->_should_refresh, 0, "Token doesn't require refresh");
    
    # Set expiration in the past (our mucking about with gmtime
    # seems to be incompatible with Test::MockTime)
    $auth->_expiration(timegm(gmtime(time - 1800)));
    my $expiration = $auth->{'_expiration'};
    is($auth->_should_refresh, 1, "Token requires refresh");    
    $auth->token();
    ok($auth->_expiration =~ /^\d+.?\d+$/ , "Expiration parsed");
    ok($expiration != $auth->_expiration, "Token refreshed");
  };

  subtest 'Failures' => sub {
    # GET
    dies_ok { $auth->api_get("invalid_url") } 'Get dies on invalid url';
    dies_ok { $auth->api_get() } 'Get requires an argument';
    dies_ok { $auth->api_get("blarg","blarg") } 'Get requires a single argument';

    # POST
    dies_ok { $auth->api_post("invalid_url","blarg") } 'Post dies on invalid url';
    dies_ok { $auth->api_post("invalid_url") } 'Post requires two arguments';
    dies_ok { $auth->api_post("invalid_url","blarg","blarg") } 'Post requires two arguments';
   
    # PUT 
    dies_ok { $auth->api_put("invalid_url","blarg") } 'Put dies on invalid url';
    dies_ok { $auth->api_put("invalid_url") } 'Put requires two arguments';
    dies_ok { $auth->api_put("invalid_url","blarg","blarg") } 'Put requires two arguments';

    # DELETE
    dies_ok { $auth->api_delete("invalid_url") } 'Delete dies on invalid url';
    dies_ok { $auth->api_delete() } 'Delete requires an argument';
    dies_ok { $auth->api_delete("blarg","blarg") } 'Delete requires a single argument';
    $auth->api_uri("invalid");
    
    # token
    dies_ok { $auth->_build__token } 'Token dies correctly';
    dies_ok { $auth->_build__token('argument') } "method '_build__token' doesn't accept arguments";
    dies_ok { $auth->_should_refresh('argument') } "method '_should_refresh' doesn't accept arguments";
    dies_ok { $auth->token('argument') } "method 'token' doesn't accept arguments";
    dies_ok { $auth->_build_api_uri('argument') } "method '_build_api_uri' doesn't accept arguments";
  }
}

done_testing();
__END__
