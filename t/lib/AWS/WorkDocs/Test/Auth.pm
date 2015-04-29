package AWS::WorkDocs::Test::Auth;

use Dancer2;
use POSIX qw(strftime);
set serializer => 'JSON';

post '/authenticate' => sub {
  my $date = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime(time + 3660));
  { AuthenticationToken => 'areallylongtokenshouldgohereandwecouldprobablyvalidateitlater', Expiration => "$date" };
};

1;
