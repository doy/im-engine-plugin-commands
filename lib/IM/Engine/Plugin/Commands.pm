package IM::Engine::Plugin::Commands;
use Moose;
use Module::Pluggable sub_name => 'commands';
Sub::Name::subname('commands', \&commands);
use List::Util qw(first);
use Try::Tiny;
extends 'IM::Engine::Plugin';

=head1 NAME

IM::Engine::Plugin::Commands -

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut

has namespace => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    trigger  => sub {
        my $self = shift;
        my ($path) = @_;
        $self->search_path(new => $path);
    },
);

has exclude_commands => (
    is      => 'ro',
    isa     => 'Str|RegexpRef|ArrayRef[Str|RegexpRef]',
    trigger => sub {
        my $self = shift;
        my ($except) = @_;
        $self->except($except);
    },
);

has only_commands => (
    is  => 'ro',
    isa => 'Str|RegexpRef|ArrayRef[Str|RegexpRef]',
    trigger => sub {
        my $self = shift;
        my ($only) = @_;
        $self->only($only);
    },
);

has prefix => (
    is      => 'ro',
    isa     => 'Str',
    default => '!',
);

has alias => (
    traits  => [qw(Hash)],
    is      => 'ro',
    isa     => 'HashRef[Str]',
    default => sub { {} },
    handles => {
        alias_for => 'get',
        has_alias => 'exists',
    },
);

has _active_commands => (
    traits   => [qw(Hash)],
    is       => 'ro',
    isa      => 'HashRef[IM::Engine::Plugin::Commands::Command]',
    init_arg => undef,
    default  => sub { {} },
    handles  => {
        _get_active_command    => 'get',
        _set_active_command    => 'set',
        _remove_active_command => 'delete',
    },
);

has _last_message => (
    is       => 'rw',
    isa      => 'IM::Engine::Incoming',
    init_arg => undef,
);

sub BUILD {
    my $self = shift;
    confess "Don't specify an incoming_callback when using " . __PACKAGE__
        if $self->engine->interface->has_incoming_callback;
    $self->engine->interface->incoming_callback(
        sub { $self->incoming(@_) }
    );
}

sub incoming {
    my $self = shift;
    my ($message) = @_;
    $self->_last_message($message);
    my $text = $message->plaintext;
    my $sender = $message->sender->name;
    my $prefix = $self->prefix;

    # XXX: rewrite this in terms of Path::Dispatcher
    return unless $text =~ /^\Q$prefix\E(\w+)(?:\s+(.*))?/;
    my ($command_name, $action) = (lc($1), $2);

    $command_name = $self->_find_command($command_name);
    return unless $command_name;

    my $command = $self->_get_active_command($command_name);
    if (!defined $command) {
        my $command_package = $self->_command_package($command_name);
        return unless try {
            Class::MOP::load_class($command_package)
        }
        catch {
            warn $_;
            $self->say((split /\n/)[0]);
            return;
        };
        $command = $command_package->new(_ime_plugin => $self);
        $self->_set_active_command($command_name, $command);
    }

    if (!$command->is_active && (!defined($action) || $action !~ /^-/)) {
        $command->is_active(1);
        $self->say($command->init($sender)) if $command->can('init');
    }

    return unless defined $action;

    if ($action =~ /^-(\w+)\s*(.*)/) {
        my ($action, $arg) = ($1, $2);
        if (my $method_meta = $command->meta->get_command($action)) {
            if ($method_meta->needs_init && !$command->is_active) {
                $self->say("$command_name isn't active yet!");
                return;
            }
            my $body = $method_meta->execute($command, $arg,
                                             {sender => $sender});
            my @extra_args = $method_meta->meta->does_role('IM::Engine::Plugin::Commands::Trait::Method::Formatted') ? (formatter => $method_meta->formatter) : ();
            $self->say($body, @extra_args);
        }
        else {
            $self->say("Unknown command $action for command $command_name");
            return;
        }
    }
    else {
        my $output = $command->default($sender, $action);
        $self->say($output) if defined $output;
    }

    $self->_remove_active_command($command_name) if !$command->is_active;

    return;
}

sub say {
    my $self = shift;
    my ($message, %args) = @_;
    $message = $args{formatter}->($message) if exists $args{formatter};
    $self->engine->send_message($self->_last_message->reply($message));
}

around commands => sub {
    my $orig = shift;
    my $self = shift;
    return (
        $self->$orig(@_),
        'IM::Engine::Plugin::Commands::Command::Cmdlist',
        'IM::Engine::Plugin::Commands::Command::Help',
    );
};

sub command_list {
    my $self = shift;
    return sort map { s/.*:://; lc } $self->commands;
}

sub is_command {
    my $self = shift;
    my ($name) = @_;
    return (grep { $name eq $_ } $self->command_list) ? 1 : 0;
}

sub _command_package {
    my $self = shift;
    my ($name) = @_;
    return first { /\Q::$name\E$/i } $self->commands;
}

sub _find_command {
    my $self = shift;
    my ($abbrev) = @_;
    return $abbrev if $self->is_command($abbrev);
    return $self->alias_for($abbrev)
        if $self->has_alias($abbrev)
        && $self->is_command($self->alias_for($abbrev));
    my @possibilities = grep { /^\Q$abbrev/ } $self->command_list;
    return $possibilities[0] if @possibilities == 1;
    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-im-engine-plugin-commands at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IM-Engine-Plugin-Commands>.

=head1 SEE ALSO


=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc IM::Engine::Plugin::Commands

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IM-Engine-Plugin-Commands>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IM-Engine-Plugin-Commands>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IM-Engine-Plugin-Commands>

=item * Search CPAN

L<http://search.cpan.org/dist/IM-Engine-Plugin-Commands>

=back

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
