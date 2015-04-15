package AWS::Zocalo::Test::Content;

use Dancer2;

our $temp;

#post '/user' => sub {
#  my $user->{User} = config->{testdata}{User};
#  return $user;
#};
#
get '/folder/:Id' => sub {
  {
    Folder => {
      Metadata => {
        Id => param('Id'),
        PermissionsGranted => $temp->{permissions},
      },
    },
  }
};

put '/resource/:Id/permissions' => sub {
  my $data = from_json(request->body);
  my $content;
  my @results;
  foreach my $principal ( @{$data->{Principals}} ) {
    push ( @results, {
      PrincipalId => $principal->{Id},
      Role => $principal->{Role},
      ShareId => param('Id')
    });

    my $permission;
    if ( $principal->{Role} eq 'CONTRIBUTOR' ) {
      $permission = "CONTRIBUTE";
    } elsif ( $principal->{Role} eq 'VIEWER' ) {
      $permission = "VIEW";
    } else {
      $permission = $principal->{Role};
    }

    push ( @{$temp->{permissions}}, {
      Permission => $permission,
      User => config->{testdata}{User}, 
    });
  }

  @{$content->{ShareResults}} = @results;

  return $content;
};

del '/resource/:Id/permissions/:SId' => sub {
  @{$temp->{permissions}} = grep !(defined && $_->{User}{Id} eq param('SId')),@{$temp->{permissions}};
  return;
};

1;
