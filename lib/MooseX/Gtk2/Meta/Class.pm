package MooseX::Gtk2::Meta::Class;

use Moose::Role;

Moose::Util::meta_class_alias "Gtk2";

has _gtk_default_signal_target => (
    is      => "rw",
    default => "",
);
has _gtk_default_action_target => (
    is      => "rw",
    default => "actions",
);

BEGIN { *debug = \&MooseX::Gtk2::debug }

sub _gtk_signal_connect {
    my ($self, $on, $sig, $obj, $method) = @_;

    debug "CONNECTING [$sig] ON [$on] TO [$obj]->[$method]";
    Scalar::Util::weaken $on;

    $on->signal_connect($sig,
        $obj->weak_method($method, sub { 
            debug "DISCONNECTING [$sig] ON [$on] FROM [$_[0]]";
            $on->signal_handlers_disconnect_by_func($_[0]);
        }));
}

sub _gtk_process_attribute {
    my ($self, $obj, $key, $default, $map) = @_;

    for ($self->_gtk_methods_by_attribute($key)) {
        my ($method, $val) = @$_;
        $method = $method->name;

        $val //= "";
        my ($att, $name) = $val =~ /^(?:(.*)\.)?([-\w:]*)$/
            or Carp::croak("Bad Gtk2 attribute :$key($val)");
        $att //= $default;

        my $on = $obj->_resolve_object_path($att)
            or Carp::croak("Can't resolve '$att'");

        $map and ($on, $name) = $map->($on, $name, $method);
        $on or next;
        $self->_gtk_signal_connect($on, $name, $obj, $method);
    }
}

sub _gtk_methods_by_attribute {
    my ($self, $att) = @_;
    
    my @meth;
    for my $m ($self->get_nearest_methods_with_attributes) {
        for (@{$m->attributes}) {
            my ($n, $v) = /^(\w+)(?:\((.*)\))?$/x
                or next;
            $n eq $att or next;
            push @meth, [$m, $v];
        }
    }
    @meth;
}

# XXX
push @Data::Dump::FILTERS, sub {
    my ($ctx, $obj) = @_;

    Scalar::Util::blessed $obj && $obj->isa("Moose::Meta::Method") 
        or return;

    return {
        dump => sprintf "METAMETHOD[%s]", $obj->fully_qualified_name,
    };
};

sub _gtk_extra_init {
    my ($self, $obj) = @_;

    debug "PROCESSING SIGNALS FOR [$obj]";
    my $targ = $self->_gtk_default_signal_target;
    $self->_gtk_process_attribute($obj, "Signal", $targ, sub {
        my ($att, $name, $method) = @_;
        unless ($name) {
            $name = $method;
            $name =~ s/^_//;
            $name =~ s/_/-/g;
        }
        ($att, $name);
    });

    $targ = $self->_gtk_default_action_target;
    $self->_gtk_process_attribute($obj, "Action", $targ, sub {
        my ($att, $name, $method) = @_;
    
        unless ($name) {
            $name = $method;
            $name =~ s/^_//;
            $name = join "", map ucfirst, split /_/, $name;
        }

        my $act = $att->get_action($name);
        unless ($act) {
            Carp::carp "Can't find action '$name' on '$att'";
            return;
        }
        ($act, "activate");
    });

    my @props =
        grep $_->gtk_prop,
        grep $_->does("MooseX::Gtk2::Meta::Attribute"),
        $self->get_all_attributes;
    debug "PROPS FOR [$obj]: " . join "; ", map $_->name, @props;
    $self->_gtk_setup_prop($obj, $_) for @props;
}

around new_object => sub {
    my ($super, $self, @args) = @_;

    my $obj = $self->$super(@args);
    $self->_gtk_extra_init($obj);
    
    $obj;
};

around _inline_extra_init => sub {
    my ($super, $self) = @_;

    return (
        $self->$super,
        q{Moose::Util::find_meta($instance)->_gtk_extra_init($instance);},
    );
};

sub _gtk_setup_prop {
    my ($self, $obj, $att) = @_;

    my $name    = $att->name;
    my ($reader, $writer)       = map $att->$_, 
        qw/get_read_method get_write_method/;
    my ($targs, $path, $prop)   = $att->_gtk_prop_args;

    my $class = Scalar::Util::blessed $obj;
    my $sobj  = "$obj";
    debug "PROP BUILD CALLED FOR [$sobj][$name] -> [$path][$prop]";

    my $targ = $$targs{$obj} = $obj->_resolve_object_path($path);
    Scalar::Util::weaken $$targs{$obj};

    $targ->signal_connect("notify::$prop", 
        $obj->weak_closure(sub {
            my ($self) = @_;
            debug "GET PROP [$prop] FOR [$sobj][$name]";
            my $value = $targ->get_property($prop);
            $value eq $self->$reader and return;
            $self->$writer($value);
        }, my $dtor = sub {
            debug "DISCONNECT PROP [$prop] FOR [$sobj][$name]";
            $targ->signal_handlers_disconnect_by_func($_[0]);
        }));
    debug "SET PROP [$prop] FOR [$sobj][$name]";
    $targ->set_property($prop, $obj->$reader);
    Scalar::Util::weaken($targ);
}

1;
