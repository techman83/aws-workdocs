package AWS::Zocalo;
use v5.010;
use strict;
use warnings;
use autodie;
use Moo;
use Method::Signatures 20140224;
use Scalar::Util::Reftype;
use Carp qw(croak);

# ABSTRACT: A light Wrapper around the Zocalo API

# VERSION: Generated by DZP::OurPkg:Version

=head1 SYNOPSIS

    use AWS::Zocalo;

    my $zocalo = AWS::Zocalo->new(
      region => 'us-west-1',
      alias => 'zocalo_alias',
      username => 'zocalo_admin',
      password => 'admin_password'
    );

=head1 DESCRIPTION

AWS::Zocalo is a thin abstraction layer to the Zocalo API.

=cut

has 'region'        => ( is => 'ro', default => sub { 'us-west-1' });
has 'alias'         => ( is => 'ro', required => 1);
has 'username'      => ( is => 'ro', required => 1);
has 'password'      => ( is => 'ro', required => 1);

has 'auth' => (
  is => 'ro',
  isa => sub { "AWS::Zocalo::Auth" },
  lazy => 1,
  builder => 1,
);

use AWS::Zocalo::Auth;
method _build_auth() {
    return AWS::Zocalo::Auth->new(
        region => $self->{region}, 
        alias => $self->{alias}, 
        username => $self->{username}, 
        password => $self->{password}, 
    );
}

=method user
  $zocalo->user(%parms);

This will return a L<AWS::Zocalo::User> object. Depending on if you
are creating a user or just retrieving one, will depend on which
I<%parms> are required.

To retrieve a user, 'Id' or 'EmailAddress' is required. To create a 
user all attributes are required except for 'Id'.

=over

=item EmailAddress

Email address of the Zocalo User. A user object can be retrieved
based off the email address.

=item Id

Internal Zocalo User Id. A user object can be retrieved
based off the email address.

=item GivenName

Required if creating a Zocalo User.

=item Surname

Required if creating a Zocalo User.

=item Password

Required if creating a Zocalo User. Must have a strong password
or it will be rejected. Minimum of 8 characters and at least one
each of the following: Upper case alpha, lower case alpha, numeric,
one special.

=back

See L<AWS::Zocalo::User> for more.

=cut

use AWS::Zocalo::User;

method user(
  :$EmailAddress = undef, 
  :$Id = undef, 
  :$GivenName?,
  :$Surname?,
  :$Password?) {
    return AWS::Zocalo::User->new(
      EmailAddress => $EmailAddress, 
      Id => $Id, 
      GivenName => $GivenName, 
      Surname => $Surname, 
      Password => $Password, 
      auth => $self->auth
    );
}

=method folder

  my $folder = $zocalo->folder(Id => 'folder_id');

This will return a L<AWS::Zocalo::Content::Folder> object. Currently
you can only perform retrieve/share actions. This may be expanded to
be able to create, see files etc. See the  L<AWS::Zocalo::Content> 
for more.

=cut

use AWS::Zocalo::Content::Folder;

method folder(:$Id) {
  return AWS::Zocalo::Content::Folder->new( Id => $Id, auth => $self->auth );
}

=method document

  my $document = $zocalo->document(Id => 'document_id');

This will return a L<AWS::Zocalo::Content::Document> object. Currently
you can only perform retrieve/share actions. This may be expanded to
be able to create, see files etc. See the L<AWS::Zocalo::Content> 
for more.

=cut

use AWS::Zocalo::Content::Document;

method document(:$Id) {
  return AWS::Zocalo::Content::Document->new( Id => $Id, auth => $self->auth );
}

=method invite
  $zocalo->invite(%parms);

This is a shortcut method to invite users to zocalo, rather than
creating them. I<%parms> are required.

=over

=item users

This is required, takes an array or a single user.


=item resend

Defaults to 0, set to 1 to allow invites to be resent to
already invited users.

=item subject

Optionally set a custom subject.

=item message

Optionally set a custom welcome message.

=back

=cut

method invite(:$users,:$resend = 0,:$subject?,:$message?) {
  my $body;
  
  # Invites always an array
  if ( reftype( $users )->array ) {
     @{$body->{Emails}} = @{$users};
  } else {
     $body->{Emails}[0] = $users;
  }

  # Set Subject/Message if they exist
  $body->{Subject} = $subject if $subject;
  $body->{Message} = $message if $message;
  $body->{ResendInvites} = "true" if $resend;

  my $response = $self->auth->api_post("/invite/", $body);
  return $response;
}

1;
