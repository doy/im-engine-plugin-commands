package IM::Engine::Plugin::Commands::Command;
use IM::Engine::Plugin::Commands::OO;

has help => (
    is         => 'ro',
    isa        => 'Str',
    default    => 'This command has no help text!',
    command    => 1,
    needs_init => 0,
);

has is_active => (
    is         => 'rw',
    isa        => 'Bool',
    command    => 1,
    needs_init => 0,
);

has _ime_plugin => (
    is       => 'ro',
    isa      => 'IM::Engine::Plugin',
    required => 1,
    weak_ref => 1,
    handles  => ['say'],
);

sub default {
    confess "Commands must implement a default method";
}

command cmdlist => sub {
    my $self = shift;
    my @commands;
    for my $method ($self->meta->get_all_methods) {
        push @commands, $method->name
            if $method->meta->can('does_role')
            && $method->meta->does_role('IM::Engine::Plugin::Commands::Trait::Method::Command');
    }
    return \@commands;
}, needs_init => 0,
   formatter => sub {
       my $list = shift;
       return join ' ', sort map { '-' . $_ } @$list
   };

__PACKAGE__->meta->make_immutable;
no IM::Engine::Plugin::Commands::OO;

1;
