package IM::Engine::Plugin::Commands::Command::Help;
use IM::Engine::Plugin::Commands::OO;

sub default {
    my $self = shift;
    my ($sender, $action) = @_;
    $self->is_active(0);
    my $prefix = $self->_ime_plugin->prefix;
    my $message = IM::Engine::Incoming->new(
        sender  => $self->_ime_plugin->_last_message->sender,
        message => "${prefix}$action -help",
    );
    return $self->_ime_plugin->incoming($message);
}

1;
