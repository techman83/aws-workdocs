#!/usr/bin/perl -w

use lib 't/lib/';

use AWS::WorkDocs::Test;
use Test::Most;
use Test::Warnings;

my $tester = AWS::WorkDocs::Test->new();

$tester->test_with_auth(\&user_testing, 7);
$tester->test_with_dancer(\&user_testing, 7);

sub user_testing {
  my ($auth,$config,$message) = @_;

  pass("User Testing: $message");  
  use_ok("AWS::WorkDocs::User");
  

  my $user = AWS::WorkDocs::User->new(
    auth => $auth,
  );
  
  subtest 'Instantiation' => sub {
    isa_ok($user, "AWS::WorkDocs::User");
    
    can_ok($user, qw(retrieve create update update_attr activate
      deactivate delete));
  };
  
  subtest 'Create' => sub {
    throws_ok { $user->update }
      qr/Id required for update, call retrieve method first/,
      "croaks on attempting update before retrieving";
    
    throws_ok { $user->create } 
      qr/EmailAddress is required for User creation/,
      "croaks on create missing 'EmailAddress'";
    $user->EmailAddress($config->{username});
    throws_ok { $user->create } 
      qr/Password is required for User creation/,
      "croaks on create missing 'Password'";
    $user->Password($config->{password});
    throws_ok { $user->create } 
      qr/GivenName is required for User creation/,
      "croaks on create missing 'GivenName'";
    $user->GivenName($config->{givenname});
    throws_ok { $user->create } 
      qr/Surname is required for User creation/,
      "croaks on create missing 'Surname'";
    $user->Surname($config->{surname});
    $user->create();
    $user->retrieve();
    
    isnt($user->{Id}, ''||undef, "Id: $user->{Id}");
    is($user->{GivenName}, $config->{givenname}, "GivenName: $config->{givenname}");
    is($user->{Surname}, $config->{surname}, "Surname: $config->{surname}");
    is($user->{EmailAddress}, $config->{username}, "EmailAddress: $config->{username}");
    is($user->{Username}, $config->{username}, "Username: $config->{username}");
    is($user->{Password}, $config->{password}, "Password: not displayed");
    #TODO: We should test passwords that fail too
  };
  
  subtest 'Update' => sub {
    # Full User Update
    $user->{GivenName} = 'WorkDocsTest99';
    $user->{Surname} = 'Surname99';
    $user->update();
    is($user->{GivenName}, 'WorkDocsTest99', "GivenName: $user->{GivenName}");
    is($user->{Surname}, 'Surname99', "Surname: $user->{Surname}");
  
    # Attribute Updated
    $user->update_attr("Surname","Test99");
    is($user->{Surname}, 'Test99', "Surname: $user->{Surname}");
    my $userUA = AWS::WorkDocs::User->new(
      EmailAddress => $config->{username},
      auth => $auth,
    );
    $userUA->update_attr("Surname","Test");
    is($userUA->{Surname}, 'Test', "Surname: $user->{Surname}");

    # Deactivate/Activate
    my $userD = AWS::WorkDocs::User->new(
      EmailAddress => $config->{username},
      auth => $auth,
    );
    $userD->deactivate();
    is($userD->active, 0, "Status: $userD->{Status}");
  
    my $userA = AWS::WorkDocs::User->new(
      EmailAddress => $config->{username},
      auth => $auth,
    );
    $userA->activate();
    is($userA->active, 1, "Status: $userA->{Status}");
    
    $user->deactivate();
    is($user->active, 0, "Status: $user->{Status}");
    $user->activate();
    is($user->active, 1, "Status: $user->{Status}");
  };
  
  subtest 'Delete' => sub {
    my $delete = $user->delete();
  
    is($delete, 1, "User Deleted");
    $user->create();

    my $userDel = AWS::WorkDocs::User->new(
      EmailAddress => $config->{username},
      auth => $auth,
    );
    my $deleteDel = $userDel->delete();
  
    is($deleteDel, 1, "User Deleted");
  };
  
  subtest 'Failures' => sub {
    dies_ok { $user->_build_user('argument') } "method '_build_user' doesn't accept arguments";
    dies_ok { $user->_map_keys() } "method '_map_keys' requires an argument";
    dies_ok { $user->_map_keys('argument','argument') } "method '_map_keys' doesn't accept multiple arguments";
    dies_ok { $user->retrieve('argument') } "method 'retrieve' doesn't accept arguments";
    dies_ok { $user->create('argument') } "method 'create' doesn't accept arguments";
    dies_ok { $user->active('argument') } "method 'active' doesn't accept arguments";
    dies_ok { $user->update('argument') } "method 'update' doesn't accept arguments";
    dies_ok { $user->update_attr() } "method 'update_attr' requires two arguments";
    dies_ok { $user->update_attr(1) } "method 'update_attr' requires two arguments";
    dies_ok { $user->update_attr(1,2,3) } "method 'update_attr' requires two arguments";
    dies_ok { $user->activate('argument') } "method 'activate' doesn't accept arguments";
    dies_ok { $user->deactivate('argument') } "method 'deactivate' doesn't accept arguments";
    dies_ok { $user->delete('argument') } "method 'delete' doesn't accept arguments";
  }
}

done_testing();
__END__
