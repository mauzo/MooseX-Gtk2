package MooseX::Gtk2;

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
