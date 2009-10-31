package IM::Engine::Plugin::Commands::Trait::Method::Formatted;
use Moose::Role;
use Scalar::Util qw(reftype);

has formatter => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub { sub {
        Carp::cluck "no formatter specified!";
        return @_;
    } },
);

sub _munge_formatter {
    my $self = shift;
    my ($format) = @_;
    return $format if defined(reftype($format)) && reftype($format) eq 'CODE';
    return $self->associated_metaclass->formatter_for($format);
}

no Moose::Role;

1;
