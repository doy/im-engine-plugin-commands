package IM::Engine::Plugin::Commands::OO;
use Moose ();
use Moose::Exporter;
use Moose::Util::MetaRole;
use Scalar::Util qw(blessed reftype);

sub command {
    my $caller = shift;
    my $name = shift;
    my $code;
    $code = shift if reftype($_[0]) eq 'CODE';
    my %args = @_;

    my $method_meta = $caller->meta->get_method($name);
    my $superclass = blessed($method_meta)
                  || $caller->meta->method_metaclass;
    my @method_metaclass_roles = ('IM::Engine::Plugin::Commands::Trait::Method::Command');
    push @method_metaclass_roles, 'IM::Engine::Plugin::Commands::Trait::Method::Formatted'
        if $args{formatter};
    my $method_metaclass = Moose::Meta::Class->create_anon_class(
        superclasses => [$superclass],
        roles        => \@method_metaclass_roles,
        cache        => 1,
    );
    if ($method_meta) {
        $method_metaclass->rebless_instance($method_meta);
    }
    else {
        $method_meta = $method_metaclass->name->wrap(
            $code,
            package_name => $caller,
            name         => $name,
        );
        $caller->meta->add_method($name, $method_meta);
    }
    for my $attr (map { $_->meta->get_attribute_list } @method_metaclass_roles) {
        next unless exists $args{$attr};
        my $value = $args{$attr};
        # XXX: shouldn't this just be a coercion?
        my $munge_method = "_munge_$attr";
        $value = $method_meta->$munge_method($value)
            if $method_meta->can($munge_method);
        $method_meta->$attr($value);
    }
}

Moose::Exporter->setup_import_methods(
    with_caller => ['command'],
    also        => ['Moose'],
);

sub init_meta {
    shift;
    my %options = @_;
    Moose->init_meta(%options);
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class =>
            $options{for_class},
        attribute_metaclass_roles =>
            ['IM::Engine::Plugin::Commands::Trait::Attribute::Command',
             'IM::Engine::Plugin::Commands::Trait::Attribute::Formatted'],
        metaclass_roles =>
            ['IM::Engine::Plugin::Commands::Trait::Class::Command',
             'IM::Engine::Plugin::Commands::Trait::Class::Formatted'],
    );
    my $meta = Class::MOP::class_of($options{for_class});
    my @supers = $meta->superclasses;
    $meta->superclasses('IM::Engine::Plugin::Commands::Command')
        if @supers == 1 && $supers[0] eq 'Moose::Object'
        && $options{for_class} ne 'IM::Engine::Plugin::Commands::Command';
    return $meta;
}

1;
