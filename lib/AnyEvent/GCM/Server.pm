package AnyEvent::GCM::Server;
use strict;
use warnings;
our $VERSION = '0.01';

use 5.10.0;

use utf8;
use Encode;

use Mouse;
use Log::Minimal;
use Data::Validator;

use AnyEvent::MPRPC::Server;
use AnyEvent::HTTP;

use JSON qw(encode_json decode_json);

use Try::Tiny;

our $API_URL = 'https://android.googleapis.com/gcm/send';

has api_key => (
    is => 'ro',
);

has port => (
    is => 'ro',
);

has api_url => (
    is => 'ro',
    default => sub {
        return $API_URL;
    },
);

has on_fail => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {sub {};},
);

has on_success => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {sub {};},
);

has _last_send_at => (
    is => 'rw',
);

no Any::Moose;

sub run {
    my $self = shift;

    my $cv = AnyEvent->condvar;

    my $server = AnyEvent::MPRPC::Server->new(
        port => $self->port,
        on_error    => sub {},
        on_accept   => sub {
            infof "[mprpc server] on_accept";
            $self->_last_send_at(time);
        },
        on_dispatch => sub {
            infof "[mprpc server] on_dispatch";
        },
    );

    $server->reg_cb(
        send => sub {
            my ($res_cv, $params) = @_;

            state $v = Data::Validator->new(
                registration_ids => { isa => 'ArrayRef'},
                collapse_key     => { isa => 'String', optional => 1},
                data             => { isa => 'HashRef'},
            );

            my $payload = $v->validate($params->[0]);

            http_request POST => $self->api_url,
                headers => {
                    Authorization   => 'key='.$self->api_key,
                    'Content-Type'  => 'application/json; charset=UTF-8',
                },
                body => encode_json $payload,
                sub {
                    my ($body, $hdr) = @_;
                    my $res = decode_json($body);

                    if ($res->{failure}) {
                        warnf "falure message exist: %d", $res->{failure};
                        $self->on_fail()->();
                    }
                    else {
                        $self->on_success()->();
                    }
                    infof "result success:%d failue: %d",
                        $res->{success}, $res->{failure};
                };

            $res_cv->result('ok');
        },
    );

    $cv->recv;
}

1;
__END__

=head1 NAME

AnyEvent::GCM::Server - server module for sending message to Google Cloud Messaging for Android (GCM)

=head1 SYNOPSIS

  use AnyEvent::GCM::Server;

  AnyEvent::GCM::Server->new({
    api_key => 'xxxxxxxxx',
    port    => 8888,
  })->run;

=head1 AUTHOR

Shinichiro Sei E<lt>shin1rosei {at} kayac.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
