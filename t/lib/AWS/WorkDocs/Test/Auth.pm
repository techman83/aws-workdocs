package AWS::WorkDocs::Test::Auth;

use Dancer2;
set serializer => 'JSON';

post '/authenticate' => sub {
  { AuthenticationToken => 'areallylongtokenshouldgohereandwecouldprobablyvalidateitlater' };
};

1;