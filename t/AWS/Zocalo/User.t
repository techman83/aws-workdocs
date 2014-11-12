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

  pass("User Testing: $message");  
  use_ok("AWS::Zocalo::User");
  

  my $user = AWS::Zocalo::User->new(
    EmailAddress => $config->{username},
    GivenName => $config->{givenname},
    Surname => $config->{surname},
    Password => $config->{password},
    auth => $auth,
  );
  
  subtest 'Instantiation' => sub {
    isa_ok($user, "AWS::Zocalo::User");
    
    can_ok($user, qw(retrieve create update update_attr activate
      deactivate delete));
  };
  
  subtest 'Create' => sub {
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
    $user->{GivenName} = 'ZocaloTest99';
    $user->{Surname} = 'Surname99';
    $user->update();
    is($user->{GivenName}, 'ZocaloTest99', "GivenName: $user->{GivenName}");
    is($user->{Surname}, 'Surname99', "Surname: $user->{Surname}");
  
    # Attribute Updated
    $user->update_attr("Surname","Test99");
    is($user->{Surname}, 'Test99', "Surname: $user->{Surname}");
  
    # Deactivate/Activate
    $user->deactivate();
    is($user->{Status}, 'INACTIVE', "Status: $user->{Status}");
    $user->activate();
    is($user->{Status}, 'ACTIVE', "Status: $user->{Status}");
  };
  
  subtest 'Delete' => sub {
    my $delete = $user->delete();
  
    is($delete, 1, "User Deleted");
  };
}

done_testing();
__END__
