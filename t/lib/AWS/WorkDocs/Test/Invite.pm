package AWS::WorkDocs::Test::Invite;

use Dancer2;

our $temp;

post '/invite/' => sub {
  my $data = from_json(request->body);

  if ( defined $temp->{sent} ) {
    return {
      ExistingUsers => [],
      FailedInvites => [],
      NewInvites => [],
      PendingInvites => [ $data->{Emails}[0] ],
      ResentInvites => [ $data->{Emails}[0] ],
    }; 
  } else {
    $temp->{sent} = 1;
    return {
      ExistingUsers => [],
      FailedInvites => [],
      NewInvites => [ $data->{Emails}[0] ],
      PendingInvites => [],
      ResentInvites => [],
    };
  }
};

1;
