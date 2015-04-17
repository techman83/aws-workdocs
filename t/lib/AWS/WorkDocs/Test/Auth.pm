package AWS::WorkDocs::Test::Auth;

use Dancer2;
use POSIX qw(strftime);
set serializer => 'JSON';

post '/authenticate' => sub {
  my $date = strftime("%Y-%m-%dT%H:%M:%SZ", localtime(time + 43200));
  { AuthenticationToken => 'areallylongtokenshouldgohereandwecouldprobablyvalidateitlater', Expiration => "$date" };
};

1;
