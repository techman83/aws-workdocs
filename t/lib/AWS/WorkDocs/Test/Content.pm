package AWS::WorkDocs::Test::Content;

use Dancer2;

our $temp;

get '/folder/:Id' => sub {
  {
    Folder => {
      Metadata => {
        Id => param('Id'),
        PermissionsGranted => $temp->{permissions},
      },
      Folders => [
        {
          Id => '987654321',
        },
      ]
    },
  }
};

get '/document/:Id' => sub {
  {
    Document => {
      Metadata => {
        Id => param('Id'),
        PermissionsGranted => $temp->{permissions},
      },
    },
  }
};

post '/folder' => sub {
  {
    Folder => {
      Metadata => {
        Id => 1234,
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


del '/folder/:Id' => sub {
  return;
};

del '/resource/:Id/permissions/:SId' => sub {
  @{$temp->{permissions}} = grep !(defined && $_->{User}{Id} eq param('SId')),@{$temp->{permissions}};
  return;
};

1;
