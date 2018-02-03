package MooseX::Role::Signal;

use Moose::Role;

use Carp            qw/croak/;
use Scalar::Util    qw/refaddr reftype blessed/;

use namespace::autoclean;

has _signal_handlers => (
    is          => "ro",
    lazy        => 1,
    init_arg    => undef,
    default     => sub { +{} },
);

require MooseX::Gtk2;
my $debug = \&MooseX::Gtk2::debug;

sub signal_connect {
    my ($self, $sig, $cb) = @_;

    my $hand = ($self->_signal_handlers->{$sig} ||= []);
    push @$hand, $cb;

    return refaddr $cb;
}

sub signal_handler_disconnect {
    my ($self, $id) = @_;

    if (ref $id) {
        reftype $id eq "CODE" && !blessed $id
            or croak "A signal handler is a coderef";
        $id = refaddr $id;
    }

    my $hand = $self->_signal_handlers;
    for my $h (values %$hand) {
        @$h = grep $_ != $id, @$h;
    }
}

*signal_handlers_disconnect_by_func = \&signal_handler_disconnect;

sub signal_emit {
    my ($self, $sig, @args) = @_;

    $sig =~ s/_/-/g;

    $debug->("EMIT SIGNAL [$sig] ON [$self] [@args]\n");

    # Copy the list in case we connect or disconnect while invoking
    # callbacks.
    my @hand = @{ $self->_signal_handlers->{$sig} }
        or return;

    $_->(@args) for @hand;
}

1;
