package IM::Engine::Plugin::Commands::Command::Help;
use IM::Engine::Plugin::Commands::OO;

has '+help' => (
    default => 'Displays the help text for the given command',
);

sub default {
    my $self = shift;
    my ($sender, $action) = @_;
    $self->is_active(0);
    my $prefix = $self->_ime_plugin->prefix;
    my $last_message = $self->_ime_plugin->_last_message;
    my $message = $last_message->meta->clone_object(
        $last_message,
        message => "${prefix}$action -help",
    );
    return $self->_ime_plugin->incoming($message);
}

1;
