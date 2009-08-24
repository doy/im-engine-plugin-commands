package IM::Engine::Plugin::Commands::Trait::Class::Formatted;
use Moose::Role;

has default_formatters => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef[CodeRef]',
    builder => '_build_default_formatters',
    handles => {
        formatter_for   => 'get',
        has_formatter   => 'exists',
        formattable_tcs => 'keys',
    },
);

sub _build_default_formatters {
    {
        'ArrayRef' => sub { join ', ', @{ shift() } },
        'Bool'     => sub { return shift() ? 'true' : 'false' },
        'Object'   => sub { shift() . "" },
    }
}

no Moose::Role;

1;
