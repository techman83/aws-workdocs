package AWS::Zocalo::Test::User;

use Dancer2;

post '/user' => sub {
  my $user->{User} = config->{testdata}{User};
  return $user;
};

get '/user/:Id' => sub {
  my $user->{User} = config->{testdata}{User};
  return $user;
};

put '/user/:Id' => sub {
  my $data = from_json(request->body);
  my $user->{User} = config->{testdata}{User};

  # Details Change
  $user->{User}{GivenName} = $data->{GivenName} if $data->{GivenName};
  $user->{User}{Surname} = $data->{Surname} if $data->{Surname};
  $user->{User}{Status} = $data->{Status} if $data->{Status};
  $user->{User}{EmailAddress} = $data->{EmailAddress} if $data->{EmailAddress};

  # Activate/Deactivate
  $user->{User}{Status} = "INACTIVE" if $data->{Deactivate};
  $user->{User}{Status} = "ACTIVE" if $data->{Activate};

  return $user;
};

del '/user/:Id' => sub {
  return 1;
};

get '/organization/user/search' => sub {
  { blah => "blah" }
};

1;
