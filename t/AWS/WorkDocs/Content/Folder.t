#!/usr/bin/perl -w

use lib 't/lib/';

use AWS::WorkDocs::Test;
use AWS::WorkDocs::Test::InvalidContent;
use Test::Most;
use List::MoreUtils qw( firstidx none );
use Test::Warnings;

my $tester = AWS::WorkDocs::Test->new();

$tester->test_with_auth(\&folder_testing, 6);
$tester->test_with_dancer(\&folder_testing, 6);

sub folder_testing {
  my ($auth,$config,$message) = @_;

  SKIP: {
    skip "No folder Id for testing", 4 unless $config->{folder}; 
  
    pass("Folder Testing: $message");  
    use_ok("AWS::WorkDocs::Content::Folder");
    
    my $folder = AWS::WorkDocs::Content::Folder->new(
      Id => $config->{folder},
      auth => $auth,
    );
    
    subtest 'Instantiation' => sub {
      isa_ok($folder, "AWS::WorkDocs::Content::Folder");
      
      can_ok($folder, qw(retrieve user_share
        user_unshare shared_users shared_usernames
        create_folder));
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

    subtest 'Folder Create/Delete/Find' => sub {
      my $id = $folder->create_folder("TestFolder1");
      my $created = AWS::WorkDocs::Content::Folder->new(
        Id => $id,
        auth => $auth,
      );
      print $id."\n";
      is($folder->child_folder(Id => $id)->Id, $id, "Find folder in Array of Folders by Id");
      is($folder->child_folder(Id => "notafolder"), 0, "Return 0 when folder not found");
      $created->remove;
      $folder->retrieve;
      is($folder->child_folder(Id => $id), 0, "Folder is not present after removal");
    };

    subtest 'Sharing' => sub {

      # Share to user
      $folder->user_share( users => $config->{username}, access => "CONTRIBUTOR" );
      my @users = $folder->shared_users;
      my $index = firstidx { $_->{Username} eq $config->{username} if defined $_->{Username} } @users;
      is($users[$index]{User}{Username}, $config->{username}, "User shared successfully");
      is($users[$index]{Permission}, "CONTRIBUTE", "Permission 'CONTRIBUTE' assigned successfully");

      # Check 'shared_usersnames' returns correctly
      my @usernames = $folder->shared_usernames;
      $index = firstidx { $_ eq $config->{username} } @usernames;
      is($usernames[$index], $config->{username}, "shared_usernames returns shared user successfully");

      # Update users permission to default, including a message
      $folder->user_share( users => $config->{username}, message => "I'm letting you view" );
      @users = $folder->shared_users;
      $index = firstidx { $_->{Username} eq $config->{username} if defined $_->{Username} } @users;
      is($users[$index]{Permission}, "VIEW", "Permission 'VIEW' assigned successfully");
      
      # Too many/invalid arguments
      dies_ok { $folder->user_share( 
        users => $config->{username}, 
        message => "I'm letting you view",
        access => "VIEWER",
        "blarg" => "blarg",
        )
      } "user_share dies correctly with invalid arguments";

      dies_ok { $folder->user_share( 
        users => $config->{username}, 
        message => "I'm letting you view",
        access => "VIEWER",
        users => $config->{username}, 
        )
      } "user_share dies correctly with too many arguments";

      dies_ok { $folder->child_folder( 
        Id => "1234", 
        "blarg" => "blarg",
        )
      } "child_folder dies correctly with invalid arguments";

      # Unshare a user
      $folder->user_unshare( users => $config->{username} );
      @users = $folder->shared_usernames;
      ok(none { $_ eq $config->{username} } @users, "User removed from share");

      # As an array of users
      my @shares = $config->{username};
      $folder->user_share( users => \@shares, access => "COOWNER" );
      @users = $folder->shared_users;
      $index = firstidx { $_->{Username} eq $config->{username} if defined $_->{Username} } @users;
      is($users[$index]{Permission}, "COOWNER", "Permission 'COOWNER' via array assigned successfully");
      is($shares[0], $config->{username}, "Make sure we're not altering things unexpectedly");

      # Unshare a user as array
      $folder->user_unshare( users => \@shares );
      @users = $folder->shared_usernames;
      ok(none { $_ eq $config->{username} } @users, "User as array removed from share");
      is($shares[0], $config->{username}, "Make sure we're not altering things unexpectedly");
      
      # Too many/Invalid arguments
      dies_ok { $folder->user_unshare( users => \@shares, users => \@shares ) } "user_unshare dies correctly with too many arguments";
      dies_ok { $folder->user_unshare( blarg => \@shares ) } "user_unshare dies correctly with invalid arguments";
    };
   
    subtest 'Warnings' => sub {
      throws_ok { $folder->user_share( users => $config->{username}, access => "VIEW" ) }
        qr/VIEW not valid, only \[COOWNER, VIEWER, OWNER, CONTRIBUTOR\] are valid types/,
        "Invalid permission type 'VIEW' correctly croaks";
      throws_ok { $folder->user_share( users => $config->{username}, access => "CONTRIBUTE" ) }
        qr/CONTRIBUTE not valid, only \[COOWNER, VIEWER, OWNER, CONTRIBUTOR\] are valid types/,
        "Invalid permission type 'CONTRIBUTE' correctly croaks";

      throws_ok { my $content = AWS::WorkDocs::Test::InvalidContent->new( Id => '12345678', auth => $auth ) }
        qr/Extending class neither document or folder at/,
        "Invalid Content Type correctly croaks";

    };
    
    $user->delete();
  
    subtest 'Failures' => sub {
      dies_ok { $folder->_build_content('argument') } "method '_build_content' doesn't accept arguments";
      dies_ok { $folder->_map_keys() } "'_map_keys' requires an argument";
      dies_ok { $folder->_map_keys("blarg","blarg") } "'_map_keys' requires a single argument";
      dies_ok { $folder->retrieve('argument') } "method 'retrieve' doesn't accept arguments";
      dies_ok { $folder->_build_Type('argument') } "method '_build_Type' doesn't accept arguments";
      dies_ok { $folder->shared_usernames('argument') } "method 'shared_usernames' doesn't accept arguments";
      dies_ok { $folder->shared_users('argument') } "method 'shared_users' doesn't accept arguments";
      dies_ok { $folder->user_unshare() } "'user_unshare' requires a named argument";
      dies_ok { $folder->_push_folders() } "'_push_folders' requires an argument";
      dies_ok { $folder->_push_folders("arg","arg") } "'_push_folders' only takes one argument";
      dies_ok { $folder->_push_folder() } "'_push_folder' requires an argument";
      dies_ok { $folder->_push_folder("arg","arg") } "'_push_folder' only takes one argument";
      dies_ok { $folder->create_folder() } "'create_folder' requires an argument";
      dies_ok { $folder->create_folder("arg","arg") } "'create_folder' only takes one argument";
      dies_ok { $folder->remove("arg") } "'remove' takes no arguments";
    }
  }
}

done_testing();
__END__
