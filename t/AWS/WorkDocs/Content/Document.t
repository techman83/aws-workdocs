#!/usr/bin/perl -w

use lib 't/lib/';

use AWS::WorkDocs::Test;
use Test::Most;
use List::MoreUtils qw( firstidx none );
use Test::Warnings;

my $tester = AWS::WorkDocs::Test->new();

$tester->test_with_auth(\&document_testing, 4);
$tester->test_with_dancer(\&document_testing, 4);

sub document_testing {
  my ($auth,$config,$message) = @_;

  SKIP: {
    skip "No document Id for testing", 4 unless $config->{document}; 
  
    pass("Document Testing: $message");  
    use_ok("AWS::WorkDocs::Content::Document");
    
    my $document = AWS::WorkDocs::Content::Document->new(
      Id => $config->{document},
      auth => $auth,
    );
    
    subtest 'Instantiation' => sub {
      isa_ok($document, "AWS::WorkDocs::Content::Document");
      
      can_ok($document, qw(retrieve user_share
        user_unshare shared_users shared_usernames));
    };

    my $user = AWS::WorkDocs::User->new(
      EmailAddress => $config->{username},
      GivenName => $config->{givenname},
      Surname => $config->{surname},
      Password => $config->{password},
      auth => $auth,
    );
    
    # If testing fails half way through, the account that is expected to
    # be cleaned up, may not be and fail.
    eval { $user->create(); };

    if ( $@ ) {
      $user->delete();
      $user->create();
    }

    subtest 'Sharing' => sub {

      # Share to user
      $document->user_share( users => $config->{username}, access => "CONTRIBUTOR" );
      my @users = $document->shared_users;
      my $index = firstidx { $_->{Username} eq $config->{username} if defined $_->{Username} } @users;
      is($users[$index]{User}{Username}, $config->{username}, "User shared successfully");
      is($users[$index]{Permission}, "CONTRIBUTE", "Permission 'CONTRIBUTE' assigned successfully");

      # Check 'shared_usersnames' returns correctly
      my @usernames = $document->shared_usernames;
      $index = firstidx { $_ eq $config->{username} } @usernames;
      is($usernames[$index], $config->{username}, "shared_usernames returns shared user successfully");

      # Update users permission
      $document->user_share( users => $config->{username}, access => "VIEWER" );
      @users = $document->shared_users;
      $index = firstidx { $_->{Username} eq $config->{username} if defined $_->{Username} } @users;
      is($users[$index]{Permission}, "VIEW", "Permission 'VIEW' assigned successfully");
      
      # Unshare a user
      $document->user_unshare( users => $config->{username} );
      @users = $document->shared_usernames;
      ok(none { $_ eq $config->{username} } @users, "User removed from share");

      # As an array of users
      my @shares = $config->{username};
      $document->user_share( users => \@shares, access => "COOWNER" );
      @users = $document->shared_users;
      $index = firstidx { $_->{Username} eq $config->{username} if defined $_->{Username} } @users;
      is($users[$index]{Permission}, "COOWNER", "Permission 'COOWNER' via array assigned successfully");
      is($shares[0], $config->{username}, "Make sure we're not altering things unexpectedly");

      # Unshare a user as array
      $document->user_unshare( users => \@shares );
      @users = $document->shared_usernames;
      ok(none { $_ eq $config->{username} } @users, "User as array removed from share");
      is($shares[0], $config->{username}, "Make sure we're not altering things unexpectedly");
    };
   
    subtest 'Warnings' => sub {
      throws_ok { $document->user_share( users => $config->{username}, access => "VIEW" ) }
        qr/VIEW not valid, only \[COOWNER, VIEWER, OWNER, CONTRIBUTOR\] are valid types/,
        "Invalid permission type 'VIEW' correctly croaks";
      throws_ok { $document->user_share( users => $config->{username}, access => "CONTRIBUTE" ) }
        qr/CONTRIBUTE not valid, only \[COOWNER, VIEWER, OWNER, CONTRIBUTOR\] are valid types/,
        "Invalid permission type 'CONTRIBUTE' correctly croaks";
    };
    
    $user->delete();
  }
}

done_testing();
__END__
