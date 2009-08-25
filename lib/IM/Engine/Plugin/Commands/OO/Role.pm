package IM::Engine::Plugin::Commands::OO::Role;
use Moose::Role ();
use Moose::Exporter;
use Moose::Util::MetaRole;

# XXX: ick
*command = \&IM::Engine::Plugin::Commands::OO::command;
Moose::Exporter->setup_import_methods(
    with_caller => ['command'],
    also        => ['Moose::Role'],
);

sub init_meta {
    shift;
    my %options = @_;
    Moose::Role->init_meta(%options);
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class =>
            $options{for_class},
        # XXX: roles in moose don't have an attribute metaclass yet
        #attribute_metaclass_roles =>
            #['IM::Engine::Plugin::Commands::Trait::Attribute::Command',
             #'IM::Engine::Plugin::Commands::Trait::Attribute::Formatted'],
        metaclass_roles =>
            ['IM::Engine::Plugin::Commands::Trait::Class::Command',
             'IM::Engine::Plugin::Commands::Trait::Class::Formatted'],
    );
    return Class::MOP::class_of($options{for_class});
}

1;
