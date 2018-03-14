package MooseX::Gtk2;

=head1 NAME

MooseX::Gtk2 - Moose extension to make Gtk2 more convenient

=cut

use 5.012;
use warnings;

our $VERSION = "1";

use Carp        ();

use Moose::Exporter;
use MooseX::MethodAttributes        ();
use MooseX::MethodAttributes::Role  ();

use Moose::Util     qw/ensure_all_roles is_role/;

BEGIN { *debug = $ENV{MOOSEX_GTK2_DEBUG} ? sub { warn "GTK2: ", @_ } : sub {} }

my $Meta = "MooseX::Gtk2::Meta";

Moose::Exporter->setup_import_methods(
    class_metaroles => {
        attribute       => ["$Meta\::Attribute"],
        class           => ["$Meta\::Class"],
    },
#    role_metaroles => {
#        attribute           => ["$Meta\::Attribute"],
#        applied_attribute   => ["$Meta\::Attribute"],
#    },
    with_meta       => [qw/ gtk_default_target /],
);

sub init_meta {
    my (undef, %args) = @_;

    ensure_all_roles $args{for_class}, "MooseX::Gtk2::Role";
    if (is_role $args{for_class}) {
        MooseX::MethodAttributes::Role->init_meta(%args);
    }
    else {
        MooseX::MethodAttributes->init_meta(%args);
    }
}

sub gtk_default_target {
    my ($meta, $type, $att) = @_;

    # This should be $meta->DOES, but Moose seems to get confused about
    # whether I'm asking for class roles or metaclass roles
    Moose::Util::find_meta($meta)->does_role("$Meta\::Class")
        or Carp::confess "Not a MooseX::Gtk2 class";

    if ($type eq "signal") {
        $meta->_gtk_default_signal_target($att);
    }
    elsif ($type eq "action") {
        $meta->_gtk_default_action_target($att);
    }
    else {
        Carp::croak "Bad Gtk target type '$type'";
    }

    my $nm = $meta->name;
    debug "TARGET [$type] SET TO [$att] FOR [$nm]\n";
}

1;

=head1 BUGS

Please report bugs to <L<bug-MooseX-Gtk2@rt.cpan.org>>.

=head1 AUTHOR

Ben Morrow <ben@morrow.me.uk>.

=head1 COPYRIGHT

Copyright 2016 Ben Morrow <ben@morrow.me.uk>.

Released under the 2-clause BSD licence.

