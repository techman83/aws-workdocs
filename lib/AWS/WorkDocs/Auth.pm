package AWS::WorkDocs::Auth;

use v5.010;
use strict;
use warnings;
use experimental 0.010 'say';
use Method::Signatures;
use JSON qw(decode_json encode_json);
use JSON::Parse 'valid_json';
use HTTP::Request;
use LWP::UserAgent;
use Carp qw(croak);
use Date::Parse;
use Time::Local 'timegm';
use Data::Dumper;
use Moo;
use namespace::clean;

our $DEBUG = $ENV{WORKDOCS_DEBUG} || 0;

# ABSTRACT: AWS::WorkDocs Auth

# VERSION: Generated by DZP::OurPkg:Version

=head1 SYNOPSIS

  my $auth = AWS::WorkDocs::Auth->new(
    ['config_file' => '/path/to/file'], 
    ['region' => 'us-east-1']
    ['region' => 'us-east-1']
    ['token' => '784592307523980hjkgfdsl']
    ['alias' => 'example']
    ['username' => 'user']
    ['password' => 'password']
  );

=head1 DESCRIPTION

  A thin auth wrapper as a helper for the rest of AWS::WorkDocs.

=cut

has 'api_base'      => ( is => 'ro', default => sub { 'https://zocalo.{region}.amazonaws.com/gb/api/v1' });
has 'region'        => ( is => 'ro', default => sub { 'us-west-1' });
has 'api_uri'       => ( is => 'rw', lazy => 1, builder => 1 );
has '_token'         => ( is => 'rw', lazy => 1, builder => 1, clearer => 1 );
has '_expiration'    => ( is => 'rw', default => sub { undef } );
has 'alias'         => ( is => 'ro', required => 1);
has 'username'      => ( is => 'ro');
has 'password'      => ( is => 'ro');

method _build_api_uri() {
  my $uri = $self->{api_base};
  $uri =~ s/\{region\}/$self->{region}/x;
  return $uri;
}

#TODO: Auth Method may change in the future, this will work for initial development, 
# but will need more work to handle tokin refresh. Looks similar to OAuth2,
# will likely be moved to IAM + AWS Sig4, so this will do for now.

method _build__token() {
  # Request object
  my $request = HTTP::Request->new('POST' => $self->api_uri . "/authenticate");
  $request->header('Content-Type' => 'application/json');
  
  # Build authentication
  my $body = { 
      OrganizationId => $self->{alias},
      Username => $self->{username},
      Password => $self->{password}
  };
  
  $request->content(encode_json($body));

  # uncoverable branch true
  if ($DEBUG) {
    say "Get Request:"; # uncoverable statement
    say Dumper($request); # uncoverable statement
  }

  my $user_agent = LWP::UserAgent->new;
  my $response = $user_agent->request($request);

  if (!$response->is_success) {
    croak($response->as_string);
  }

  # uncoverable branch true
  if ($DEBUG) {
    say "Get Response:"; # uncoverable statement
    say Dumper($response->decoded_content); # uncoverable statement
  }

  my $content = decode_json($response->decoded_content);
  $self->_expiration( str2time($content->{Expiration}) );
  return $content->{AuthenticationToken};
}

method _should_refresh() {
  my $time_gmt = timegm(gmtime(time + 1800));
  if ( defined $self->_expiration && ( $self->_expiration < $time_gmt ) ) {
    return 1;
  } else {
    return 0;
  }
}

=method token

 $auth->token();

Returns a current authentication token, refreshing if
necessary.

=cut

method token() {
  if ( $self->_should_refresh ) {
    $self->_clear_token;
  }

  return $self->_token;
}

=method api_get
  
  $auth->api_get('/user/userid');

Performs a GET on the path specified. Complete url will not work,
only the path after the api url.

=cut

method api_get($url) {
  my $request = HTTP::Request->new(GET => $self->api_uri . $url);
  $request->header(Authentication => "Bearer " . $self->token);

  # uncoverable branch true
  if ($DEBUG) {
    say "Get Request:"; # uncoverable statement
    say Dumper($request); # uncoverable statement
  }

  my $user_agent = LWP::UserAgent->new;
  my $response = $user_agent->request($request);

  if (!$response->is_success) {
    croak($response->as_string);
  }

  # uncoverable branch true
  if ($DEBUG) {
    say "Get Response:"; # uncoverable statement
    say Dumper($response->decoded_content); # uncoverable statement
  }

  return decode_json($response->decoded_content);
}

=method api_post
  
  $auth->api_post('/user/userid', $body);

Performs a POST on the path specified. Complete url will not work,
only the path after the api url.

'$body' is expected to be a standard perl data structure.

=cut

method api_post($url,$body) {
  my $request = HTTP::Request->new(POST => $self->api_uri . $url);
  $request->header(Authentication => "Bearer " . $self->token);
  $request->content(encode_json($body));

  # uncoverable branch true
  if ($DEBUG) {
    say "Post Request:"; # uncoverable statement
    say Dumper($request); # uncoverable statement
  }

  my $user_agent = LWP::UserAgent->new;
  my $response = $user_agent->request($request);

  if (!$response->is_success) {
    croak($response->as_string);
  }

  # uncoverable branch true
  if ($DEBUG) {
    say "Post Response:"; # uncoverable statement
    say Dumper($response->decoded_content); # uncoverable statement
  }

  return decode_json($response->decoded_content);
}

=method api_put
  
  $auth->api_put('/user/userid', $body);

Performs a PUT on the path specified. Complete url will not work,
only the path after the api url.

'$body' is expected to be a standard perl data structure.

=cut

method api_put($url,$body) {
  my $request = HTTP::Request->new(PUT => $self->api_uri . $url);
  $request->header(Authentication => "Bearer " . $self->token);
  $request->content(encode_json($body));

  # uncoverable branch true
  if ($DEBUG) {
    say "Put Request:"; # uncoverable statement
    say Dumper($request); # uncoverable statement
  }

  my $user_agent = LWP::UserAgent->new;
  my $response = $user_agent->request($request);

  if (!$response->is_success) {
    croak($response->as_string);
  }

  # uncoverable branch true
  if ($DEBUG) {
    say "Put Response:"; # uncoverable statement
    say Dumper($response->decoded_content); # uncoverable statement
  }

  return decode_json($response->decoded_content);
}

=method api_delete
  
  $auth->api_delete('/user/userid');

Performs a DELETE on the path specified. Complete url will not work,
only the path after the api url.

=cut

method api_delete($url) {
  my $request = HTTP::Request->new(DELETE => $self->api_uri . $url);
  $request->header(Authentication => "Bearer " . $self->token);

  # uncoverable branch true
  if ($DEBUG) {
    say "Delete Request:"; # uncoverable statement
    say Dumper($request); # uncoverable statement
  }

  my $user_agent = LWP::UserAgent->new;
  my $response = $user_agent->request($request);

  if (!$response->is_success) {
    croak($response->as_string);
  }
  
  # uncoverable branch true
  if ($DEBUG) {
    say "Delete Response:"; # uncoverable statement
    say Dumper($response->decoded_content); # uncoverable statement
  }

  return 1;
}

1;
