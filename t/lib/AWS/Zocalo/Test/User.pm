package AWS::Zocalo::Test::User;

use Dancer2;

post '/user' => sub {
  my $data = request->body;
  return;
};

get '/user' => sub {

};

1;
