use Module::Build;

Module::Build->new(
    module_name		=> "MooseX::Gtk2",
    license		=> "bsd",
    configure_requires	=> {
	"Module::Build"	    => "0.38",
    },
    build_requires	=> {
	"Test::More"	    => "0.96",
    },
    meta_merge		=> {
	resources   => {
	    repository => "http://github.com/mauzo/MooseX-Gtk2",
	    bugtracker => "https://rt.cpan.org/Public/Dist/" .
		"Display.html?Name=MooseX-Gtk2",
	},
    },
)->create_build_script;
