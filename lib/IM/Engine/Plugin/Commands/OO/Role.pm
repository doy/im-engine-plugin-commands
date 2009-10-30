package IM::Engine::Plugin::Commands::OO::Role;
use Moose::Role ();
use Moose::Exporter;

# XXX: ick
*command = \&IM::Engine::Plugin::Commands::OO::command;
Moose::Exporter->setup_import_methods(
    with_caller => ['command'],
    also        => ['Moose::Role'],
    # XXX: roles in moose don't have an attribute metaclass yet
    #attribute_metaclass_roles =>
    #    ['IM::Engine::Plugin::Commands::Trait::Attribute::Command',
    #     'IM::Engine::Plugin::Commands::Trait::Attribute::Formatted'],
    metaclass_roles =>
        ['IM::Engine::Plugin::Commands::Trait::Class::Command',
         'IM::Engine::Plugin::Commands::Trait::Class::Formatted'],
);

1;
