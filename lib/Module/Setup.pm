package Module::Setup;

use strict;
use warnings;
use 5.008001;
our $VERSION = '0.06';

use Carp ();
use Class::Trigger;
use Cwd ();
use ExtUtils::MakeMaker qw(prompt);
use File::HomeDir;
use File::Path;
use File::Temp;
use Getopt::Long;
use Path::Class;
use Pod::Usage;

use Module::Setup::Distribute;
use Module::Setup::Path;
use Module::Setup::Path::Template;

our $HAS_TERM;

sub argv       { shift->{argv} }
sub config     { shift->{config} }
sub options    { shift->{options} }
sub base_dir   { shift->{base_dir} }
sub distribute { shift->{distribute} }
sub plugins_stash { shift->{plugins_stash} }

sub new {
    my($class, %args) = @_;

    $args{options} ||= +{};
    $args{argv}    ||= +[];
    $args{_current_dir} = Cwd::getcwd;

    my $self = bless { %args }, $class;
    $self->{_current_dir}  = Cwd::getcwd;
    $self->{plugins_stash} = +{};

    $self;
}

sub DESTROY {
    my $self = shift;
    chdir $self->{_current_dir} unless $self->{_current_dir} eq Cwd::getcwd;
}

sub _setup_options_pod2usage {
    pod2usage(1);
}
sub _setup_options_version {
    print "module-setup v$VERSION\n";
    exit 1;
}

sub setup_options {
    my($self, %args) = @_;
    $Module::Setup::HAS_TERM = 1;

    _setup_options_pod2usage unless @ARGV;

    my $options = {};
    GetOptions(
        'init'                         => \($options->{init}),
        'pack'                         => \($options->{pack}),
        'direct'                       => \($options->{direct}),
        'flavor|flavour=s'             => \($options->{flavor}),
        'flavor-class|flavour-class=s' => \($options->{flavor_class}),
        'additional=s'                 => \($options->{additional}),
        'without-additional'           => \($options->{without_additional}),
        'plugin=s@'                    => \($options->{plugins}),
        'target'                       => \($options->{target}),
        'module-setup-dir'             => \($options->{module_setup_dir}),
        version                        => \&_setup_options_version,
        help                           => \&_setup_options_pod2usage,
    ) or _setup_options_pod2usage;

    $self->{options} = $options;
    $self->{argv}    = \@ARGV;
    $self;
}


sub _clear_triggers {
    my $self = shift;
    # reset triggers # this is bad hack
    delete $self->{__triggers};
    delete $self->{_class_trigger_results};
}

sub _load_argv {
    my($self, $name, $default) = @_;

    $self->options->{$name} = @{ $self->argv } ? shift @{ $self->argv } : undef;
    if (!$self->options->{$name} && defined $default) {
        $self->options->{$name} = ref($default) eq 'CODE' ? $default->() : $default;
    }
    $self->options->{$name};
}

sub setup_base_dir {
    my $self = shift;

    my $path;
    if ($self->options->{direct}) {
        $path = File::Temp->newdir;
    } else {
        $path = $self->options->{module_setup_dir} || $ENV{MODULE_SETUP_DIR} || Path::Class::Dir->new(File::HomeDir->my_home, '.module-setup');
    }
    die 'module_setup directory was not able to be discovered.' unless $path;

    $self->{base_dir} = Module::Setup::Path->new($path);
    $self->base_dir->init_directories unless $self->base_dir->is_initialized;
}

sub run {
    my $self    = shift;
    my $options = $self->options;
    $self->_clear_triggers;

    $options->{flavor_class} ||= 'Default';
    $self->setup_base_dir;

    if ($options->{init} || (!$options->{pack} && $options->{additional})) {
        $self->_load_argv( flavor => 'default' );
        return $self->create_flavor;
    }

    $self->_load_argv( module => '' );
    $self->_load_argv( flavor => sub { $self->select_flavor } );

    Carp::croak "flavor name is required" unless $options->{flavor};
    Carp::croak "module name is required" unless $options->{module};
    $self->base_dir->set_flavor($options->{flavor});

    if ($options->{additional} && !-d $self->base_dir->flavor->additional->path_to($options->{additional})) {
        Carp::croak "additional template is no exist: $options->{additional}";
    }

    return $self->pack_flavor if $options->{pack};

    unless ($self->base_dir->flavor->is_dir) {
        return unless $self->create_flavor;
    }

    $self->load_config;
    $self->load_plugins;

    # create skeleton
    $self->create_skeleton;
    $self->call_trigger( 'after_create_skeleton' );

    # test
    chdir $self->distribute->dist_path;
    $self->call_trigger( 'check_skeleton_directory' );
    $self->call_trigger( 'finalize_create_skeleton' );
    chdir $self->{_current_dir};

    $self->call_trigger( 'finish_of_run' );
    $self;
}


sub load_config {
    my $self = shift;
    my $options = $self->options;

    my $option_plugins = delete $options->{plugins} || [];
    my $config = $self->base_dir->flavor->config->load;
    $config = +{
        plugins => [],
        %{ $config },
        %{ $options },
    };
    push @{ $config->{plugins} }, @{ $option_plugins };

    $self->{config} = $config;
}

sub plugin_collect {
    my $self = shift;

    my %loaded_local_plugin;
    for my $local_plugin ( $self->base_dir->global_plugins->collect, $self->base_dir->flavor->plugins->collect ) {
        $local_plugin->require;
        if ($local_plugin->package->isa('Module::Setup::Plugin')) {
            $loaded_local_plugin{$local_plugin->package} = $local_plugin;
        }
    }
    %loaded_local_plugin;
}

sub load_plugins {
    my $self = shift;

    my %loaded_local_plugin = $self->plugin_collect;

    $self->{loaded_plugin} ||= +{};
    for my $plugin (@{ $self->config->{plugins} }) {
        my $pkg;
        my $config = +{};
        if (ref($plugin)) {
            if (ref($plugin) eq 'HASH') {
                $pkg    = $plugin->{module};
                $config = $plugin->{config};
            } else {
                next;
            }
        } else {
            $pkg = $plugin;
        }
        $pkg = "Module::Setup::Plugin::$pkg" unless $pkg =~ s/^\+//;

        unless ($loaded_local_plugin{$pkg}) {
            eval "require $pkg"; ## no critic
            Carp::croak $@ if $@;
        }
        $self->{loaded_plugin}->{$pkg} = $pkg->new( context => $self, config => $config );
    }
}

sub write_file {
    my($self, $opts) = @_;
    my $path = $opts->{dist_path};

    if (-e $path) {
        my $ans = $self->dialog("$path exists. Override? [yN] ", 'n');
        return if $ans !~ /[Yy]/;
    } else {
        $path->dir->mkpath;
    }

    my $template;
    if ($opts->{is_binary}) {
        $template = pack 'H*', $opts->{template};
    } else {
        $template = $opts->{template};
    }

    $self->log("Creating $path");
    my $out = $path->openw;
    $out->print($template);
    $out->close;

    chmod oct($opts->{chmod}), $path if $opts->{chmod};
}

sub install_flavor {
    my($self, $tmpl) = @_;

    my $flavor = $self->base_dir->flavor;
    my $template_path = $flavor->template;
    if (exists $tmpl->{additional}) {
        $template_path = Module::Setup::Path::Template->new($flavor->additional->path, $tmpl->{additional});
        $template_path->path->mkpath;
    }

    my $path;
    if (exists $tmpl->{file} && $tmpl->{file}) {
        $path = $template_path->path_to(split '/', $tmpl->{file});
    } elsif (exists $tmpl->{dir} && $tmpl->{dir}) {
        return Module::Setup::Path::Dir->new( $template_path->path, split('/', $tmpl->{dir}) )->mkpath;
    } elsif (exists $tmpl->{plugin} && $tmpl->{plugin} && !exists $tmpl->{additional}) {
        $path = $flavor->plugins->path_to(split '/', $tmpl->{plugin});
    } else {
        return;
    }

    $self->write_file(+{
        dist_path => $path,
        %{ $tmpl },
    });
}

sub _load_flavor_class {
    my($self, $class) = @_;
    $class = "Module::Setup::Flavor::$class" unless $class =~ s/^\+//;
    eval " require $class "; Carp::croak $@ if $@; ## no critic
    $class;
}

sub create_flavor {
    my $self = shift;

    my $options = $self->options;
    my $name    = $options->{flavor};
    my $flavor_class = $self->_load_flavor_class($options->{flavor_class});

    $self->base_dir->set_flavor($name);
    Carp::croak "create flavor: $name exists " if $self->base_dir->flavor->is_exists && !exists $options->{additional};
    my $flavor = $flavor_class->new;
    return unless $flavor->setup_flavor($self);

    my @template = $flavor->loader;
    my $config = +{};
    my $additional_config = +{};
    if ($options->{additional}) {
        $additional_config = $self->base_dir->flavor->additional->config->load;
    }
    for my $tmpl (@template) {
        if (exists $tmpl->{config} && ref($tmpl->{config}) eq 'HASH') {
            $config = $tmpl->{config};
        } else {
            my $additional;
            if (exists $tmpl->{additional}) {
                $additional = $tmpl->{additional};
            } elsif ($options->{additional}) {
                $additional = $options->{additional};
            }
            local $tmpl->{additional} = $additional if $additional; ## no critic;
            if ($additional) {
                $additional_config->{$additional} = +{
                    class => $flavor_class,
                };
            }
            $self->install_flavor($tmpl);
        }
    }

    $self->base_dir->flavor->additional->path->mkpath;
    $self->base_dir->flavor->additional->config->dump($additional_config);

    if ($options->{additional}) {
        $flavor->setup_additional($self, $config);
        return 1;
    }

    $self->base_dir->flavor->plugins->path->mkpath;
    $self->base_dir->flavor->template->path->mkpath;

    if (exists $options->{plugins} && $options->{plugins} && @{ $options->{plugins} }) {
        $config->{plugins} ||= [];
        push @{ $config->{plugins} }, @{ delete $options->{plugins} };
    }
    $config->{plugins} ||= [];

    $flavor->setup_config($self, $config);

    # load plugins
    local $self->{config} = +{
        %{ $config },
        %{ $options },
        plugins => $config->{plugins},
    };
    $self->load_plugins;

    $self->call_trigger( befor_dump_config => $config );

    $self->_clear_triggers;

    $self->base_dir->flavor->config->dump($config);
}

sub create_skeleton {
    my $self   = shift;
    my $config = $self->config;

    $self->{distribute} = Module::Setup::Distribute->new(
        $config->{module},
        target => $config->{target},
    );
    $self->call_trigger( 'after_setup_module_attribute' );
    $self->distribute->dist_path->mkpath;

    my $template_vars = {
        module      => $self->distribute->module,
        dist        => $self->distribute->dist_name,
        module_path => $self->distribute->module_path,
        config      => $config,
        distribute  => $self->distribute,
        localtime   => scalar localtime,
    };
    $self->call_trigger( after_setup_template_vars => $template_vars);
    $self->{distribute}->set_template_vars($template_vars);

    for my $path ($self->base_dir->flavor->template->find_files) {
        $self->{distribute}->install_template($self, $path);
    }
    $self->call_trigger( 'append_template_file' );

    return $template_vars;
}

sub _collect_flavor_files {
    my($self, $template, $path_name, $type) = @_;

    my $base_path = $type->path;
    for my $file ($type->find_files) {
        my @path = $file->is_dir ? $file->dir_list : ($file->dir->dir_list, $file->basename);
        while ($path[0] eq '.') { shift @path };

        if ($file->is_dir) {
            push @{ $template }, +{
                dir => join('/', @path),
            };
        } else {
            my $body = $type->path_to($file)->slurp;
            my $tmpl = +{
                $path_name => join('/', @path),
                template   => $body,
            };
            if (-B $type->path_to($file)) {
                $tmpl->{template}  = unpack 'H*', $body;
                $tmpl->{is_binary} = 1;
            }
            push @{ $template }, $tmpl;
        }
    }
}

sub pack_flavor {
    my $self = shift;
    my $config = $self->options;
    my $module = $config->{module};
    my $flavor = $config->{flavor};

    my $template = [];
    $self->_collect_flavor_files($template, file   => $self->base_dir->flavor->template);
    $self->_collect_flavor_files($template, plugin => $self->base_dir->flavor->plugins);
    push @{ $template }, +{
        config => YAML::LoadFile($self->base_dir->flavor->config->path),
    };

    unless ($config->{without_additional}) {
        $template = [] if $config->{additional};
        for my $additional ( $self->base_dir->flavor->additional->path->children ) {
            next unless $additional->is_dir;
            my $name = $additional->dir_list(-1);
            next if $config->{additional} && $name ne $config->{additional};
            my $base_path = Module::Setup::Path::Template->new($self->base_dir->flavor->additional->path, $name);

            my $templates = [];
            $self->_collect_flavor_files($templates, file => $base_path);
            if ($config->{additional}) {
                push @{ $template }, @{ $templates };
            } else {
                push @{ $template }, map { $_->{additional} = $name; $_ } @{ $templates };
            }
        }
    }

    my $eq = '=';
    my $yaml = YAML::Dump(@{ $template });
    $self->stdout(<<FLAVOR__);
package $module;
use strict;
use warnings;
use base 'Module::Setup::Flavor';
1;

${eq}head1

$module - pack from $flavor

${eq}head1 SYNOPSIS

  $ module-setup --init --flavor-class=+$module new_flavor

${eq}cut

\__DATA__

$yaml
FLAVOR__
}

sub select_flavor {
    my $self = shift;
    return 'default' if $self->options->{direct};
    return 'default' if $self->base_dir->flavors->path->children == 0;

    my @flavors;
    for my $flavor ( $self->base_dir->flavors->path->children ) {
        next unless $flavor->is_dir;
        my $name = $flavor->dir_list(-1);
        ($name eq 'default') ? unshift @flavors, $name :  push @flavors, $name;
    }
    return $flavors[0] if @flavors == 1;

    my $num = 1;
    my $message;
    for my $flavor (@flavors) {
        $message .= sprintf "[%d]: %s\n", $num++, $flavor;
    }

    my $selected;
    $self->dialog( "${message}Select flavor:", 1, sub {
        my($self, $ret) = @_;
        return unless $ret =~ /^[0-9]+$/;
        $selected = $flavors[ $ret - 1 ];
    } );
    $self->log("You chose flavor: $selected");
    return $selected;
}

sub stdout {
    my($self, $msg) = @_;
    print STDOUT "$msg\n" if $HAS_TERM;
}
sub log {
    my($self, $msg) = @_;
    print STDERR "$msg\n" if $HAS_TERM;
}
sub dialog {
    my($self, $msg, $default, $validator_callback) = @_;
    return $default unless $HAS_TERM;
    while (1) {
        my $ret = prompt($msg, $default);
        return $ret unless $validator_callback && ref($validator_callback) eq 'CODE';
        return $ret if $validator_callback->($self, $ret);
    }
}

sub system {
    my($self, @args) = @_;
    CORE::system(@args);
}

1;
__END__

=head1 NAME

Module::Setup - a simple module maker "yet another Module::Start(?:er)?"

=head1 SYNOPSIS

simply use

  $ module-setup Foo::Bar

make flavor

  $ module-setup --init catalyst-action # create a "catalyst actions" flavor

edit for flavor

  $ cd ~/.module-setup/flavor/catalyst-action/template && some files edit for catalyst action templates

use flavor

  $ module-setup Foo catalyst-action # create to Catalyst::Action::Foo module

redistribute pack for flavor

  $ module-setup --pack MyFlavorCatalystAction catalyst-action > MyFlavorCatalystAction.pm

using redistributed flavor

  $ module-setup --direct --flavor-class=+MyFlavorCatalystAction New::Class

importing redistributed flavor

  $ module-setup --init --flavor-class=+MyFlavorCatalystAction new_flavor

install additional template

  $ module-setup --flavor-class=+MyFlavorCatalystDBIC --additional=DBIC catalyst

redistribute pack for additional template

  $ module-setup --pack --additional=DBIC MyFlavorCatalystDBIC catalyst > MyFlavorCatalystDBIC.pm

redistribute pack without additional template

  $ module-setup --pack --without-additional MyFlavorCatalyst catalyst > MyFlavorCatalyst.pm

for git

  $ module-setup --plugin=VC::Git Foo::Bar # or edit your ~/.module-setup/flavor/foo/config.yaml

=head1 DESCRIPTION

Module::Setup is very simply module start kit.

When the module-setup command is executed first, a necessary template for ~/.module-setup directory is copied.

=head1 What's difference Module::Setup and Module::Starter?

L<Module::Starter> is very useful module. However customize of module template is complex.

If L<Module::Starter::PBP> is used, do you solve it?

Yes, but switch of two or more templates is complex.

If Module::Setup is used, switch of template flavor is easy.

flavor customized uniquely becomes the form which can be redistributed by "module-setup --pack".

if incorporating Module::Setup in your application, you can make Helper which is well alike of Catalyst::Helper.

=head1 Example For Incorporating

  use Module::Setup;
  my $pmsetup = Module::Setup->new;
  local $ENV{MODULE_SETUP_DIR} = '/tmp/module-setup'; # dont use  ~/.module-setup directory
  my $options = {
      # see setup_options method
  };
  $pmsetup->run($options, [qw/ New::Module foo_flavor /]); # create New::Module module with foo_flavor flavor

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

walf443

hidek

tokuhirom

=head1 SEE ALSO

L<Module::Setup::Plugin>, L<module-setup>

this module's base code is pmsetup written by Tatsuhiko Miyagawa.

some pmsetup scripts are in a L<http://svn.coderepos.org/share/lang/perl/misc/pmsetup>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Module-Setup/trunk Module-Setup

Module::Setup is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
