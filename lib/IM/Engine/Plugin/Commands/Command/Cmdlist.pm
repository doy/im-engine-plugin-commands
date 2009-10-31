package IM::Engine::Plugin::Commands::Command::Cmdlist;
use IM::Engine::Plugin::Commands::OO;

has '+help' => (
    default => 'Displays a list of commands available to the bot',
);

sub init {
    my $self = shift;
    $self->is_active(0);
    return join ' ', map { $self->_ime_plugin->prefix . $_}
                         $self->_ime_plugin->command_list;
}

1;
