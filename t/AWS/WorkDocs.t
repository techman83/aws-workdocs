#!/usr/bin/perl -w

use lib 't/lib/';

use AWS::WorkDocs::Test;
use Test::Most;
use Test::Warnings;

my $tester = AWS::WorkDocs::Test->new();

$tester->test_with_auth(\&user_testing, 8);
$tester->test_with_dancer(\&user_testing, 8);

sub user_testing {
  my ($auth,$config,$message) = @_;

  pass("WorkDocs Testing: $message");  
  use_ok("AWS::WorkDocs");
 
  my $workdocs = AWS::WorkDocs->new(   
      region => $auth->{region}, 
      alias => $auth->{alias}, 
      username => $auth->{username}, 
      password => $auth->{password},
  );

  subtest 'Instantiation' => sub {
    isa_ok($workdocs, "AWS::WorkDocs");
    
    can_ok($workdocs, qw(user folder invite));

    is($workdocs->region, $auth->{region}, "Region OK");
    is($workdocs->alias, $auth->{alias}, "Alias OK");
    is($workdocs->username, $auth->{username}, "Username OK");
    is($workdocs->password, $auth->{password}, "Password OK");
    dies_ok { $workdocs->_build_auth('argument') } "method '_build_auth' doesn't accept arguments";
    my $auth_test = $workdocs->_build_auth;
    isa_ok($workdocs, "AWS::WorkDocs");
  };
 
  $workdocs->auth($auth);
  
  my $user = $workdocs->user(
    EmailAddress => $config->{username},
    GivenName => $config->{givenname},
    Surname => $config->{surname},
    Password => $config->{password},
  );
  
  subtest 'User' => sub {
    # If testing fails half way through, the account that is expected to
    # be cleaned up, may not be and fail.
    eval { $user->create(); };

    if ( $@ ) {
      $user->delete();
      $user->create();
    }
    $user->retrieve();
    
    isnt($user->{Id}, ''||undef, "Id: $user->{Id}");
    is($user->{GivenName}, $config->{givenname}, "GivenName: $config->{givenname}");
    is($user->{Surname}, $config->{surname}, "Surname: $config->{surname}");
    is($user->{EmailAddress}, $config->{username}, "EmailAddress: $config->{username}");
    is($user->{Username}, $config->{username}, "Username: $config->{username}");
    is($user->{Password}, $config->{password}, "Password: not displayed");

    my $via_email = $workdocs->user(
      EmailAddress => $config->{username},
    );
    $via_email->retrieve();
    is($via_email->{Id}, $user->{Id}, "User retrieved via email address");
    
    my $via_id = $workdocs->user(
      Id => $user->{Id},
    );
    $via_id->retrieve();
    is($via_id->{EmailAddress}, $user->{EmailAddress}, "User retrieved via Id");
    
    subtest 'search_users' => sub {
      my @users = $workdocs->search_users;
      isnt($users[0]->Id, undef, "A user was found");
      @users = $workdocs->search_users( page_size => 1 );
      is($users[1], undef, "Page size not bigger than 1");
      @users = $workdocs->search_users( page_size => 1, page => 1 );
      isnt($users[0]->Id, undef, "A user was found on the second page");
      @users = $workdocs->search_users( query => "$config->{givenname} $config->{surname}" );
      is($users[0]->GivenName, $config->{givenname}, "User found via search query");
    };

    my $delete = $user->delete();
    is($delete, 1, "User Deleted");
  };
  
  SKIP: {
    skip "No folder Id for testing", 1 unless $config->{folder}; 
    subtest 'Folder' => sub {

      my $folder = $workdocs->folder( Id => $config->{folder} );
      isa_ok($folder, "AWS::WorkDocs::Content::Folder");
      $folder->retrieve; 

      ok($folder->{Metadata}{Id} , "Metadata Id defined");
    }
  }

  SKIP: {
    skip "No Document Id for testing", 1 unless $config->{document}; 
    subtest 'Document' => sub {

      my $document = $workdocs->document( Id => $config->{document} );
      isa_ok($document, "AWS::WorkDocs::Content::Document");
      $document->retrieve; 

      ok($document->{Metadata}{Id} , "Metadata Id defined");
    }
  }

  subtest 'Invites' => sub {
    my $response = $workdocs->invite( users=> $config->{username} );
   
    is($response->{NewInvites}[0], $config->{username}, "Invite Sent");
    
    $response = $workdocs->invite( 
      users => [ $config->{username} ], 
      resend => 1,  
      subject => "test invite",
      message => "test message",
    );

    is($response->{PendingInvites}[0], $config->{username}, "Invite Pending");
    is($response->{ResentInvites}[0], $config->{username}, "Invite Resent");

    my $invite = $workdocs->user(
      EmailAddress => $config->{username},
    );
    $invite->retrieve();
    my $delete = $invite->delete();
    is($delete, 1, "User Deleted");
  };

  subtest 'Failures' => sub {
    dies_ok { $workdocs->folder(Cows => 1) } "method 'folder' requires a named argument of 'Id'";
    dies_ok { $workdocs->folder(Id => 1, Id => 2) } "method 'folder' requires a single named argument";
    dies_ok { $workdocs->document(Cows => 1) } "method 'document' requires a named argument of 'Id'";
    dies_ok { $workdocs->document(Id => 1, Id => 2) } "method 'document' requires a single named argument";
  
    dies_ok { $workdocs->user(
      Id => '12345678',
      EmailAddress => $config->{username},
      GivenName => $config->{givenname},
      Surname => $config->{surname},
      Password => $config->{password},
      EmailAddress => $config->{username},
    ) } "user dies correctly with too many arguments";

    dies_ok { $workdocs->user(
      EmailAddress => $config->{username},
      GivenName => $config->{givenname},
      Surname => $config->{surname},
      Password => $config->{password},
      Cats => $config->{password},
    ) } "user dies correctly with invalid arguments";

    dies_ok { $workdocs->invite( 
      users => [ $config->{username} ], 
      resend => 1,  
      subject => "test invite",
      Cows => "test message",
    ) } "invite dies correctly with invalid arguments";
    
    dies_ok { $workdocs->invite( 
      users => [ $config->{username} ], 
      resend => 1,  
      subject => "test invite",
      message => "test message",
      resend => 1,  
    ) } "invite dies correctly with too many arguments";

    dies_ok { $workdocs->search_users( 
      query => "users",
      page => "0",
      page_size => "50",
      page_size => "5",
    ) } "search_users dies correctly with too many arguments";

    dies_ok { $workdocs->search_users( 
      query => "users",
      page => "0",
      nyan => "50",
    ) } "search_users dies correctly with invalid arguments";
  };
}

done_testing();
__END__
