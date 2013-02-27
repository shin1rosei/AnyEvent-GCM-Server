package AnyEvent::GCM::Client;

use strict;
use warnings;

use AnyEvent::MPRPC::Client;
use Log::Minimal;

use Mouse;

has host => (
    is       => 'ro',
    required => 1,
);

has port => (
    is       => 'ro',
    required => 1,
);

has client => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        AnyEvent::MPRPC::Client->new({
            host => $self->host,
            port => $self->port,
        });
    },
);

sub send {
    my $self = shift;

    my %params = @_;
    my $cv = $self->client->call('send', \%params);

    my $res;
    eval { $res = $cv->recv};
    if (my $error = $@) {
        warnf "gcm send error: %s", $error;
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

AnyEvent::GCM::Client -

=head2 SYNOPSIS

  use AnyEvent::GCM::Client;

  $client = AnyEvent::GCM::Client->new({
     host => 'server-host',
     port => 8888,
  });

  $client->send(
     registration_ids => [ $reg_id, ... ],
     collapse_key     => $collapse_key,
     data             => {
        message => $msg,
     },
  );

=head1 DESCRIPTION

AnyEvent::GCM::Client is client module for AnyEvent::GCM::Server.

