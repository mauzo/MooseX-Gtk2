package MooseX::Gtk2::Role;

use Moose::Role;
use MooseX::MethodAttributes::Role;

with qw/ 
    MooseX::Role::ObjectPath
    MooseX::Role::WeakClosure 
/;
    #MooseX::Role::NoGlobalDestruction 

1;

