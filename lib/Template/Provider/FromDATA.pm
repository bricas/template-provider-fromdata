package Template::Provider::FromDATA;

use base qw( Template::Provider Class::Accessor::Fast );

use strict;
use warnings;

use Template::Constants;

=head1 NAME

Template::Provider::FromDATA - Load templates from your __DATA__ section

=head1 SYNOPSIS

    use Template;
    use Template::Provider::FromDATA;
    
    # Create the provider
    my $provider = Template::Provider::FromDATA->new( {
        CLASSES => __PACKAGE__
    } );
    
    # Add the provider to the config
    my $template = Template->new( {
        # ...
        LOAD_TEMPLATES => [ $provider ]
    } );

    # ...and now the templates
    
    __DATA__
    
    __mytemplate__
    Foo [% bar %]
    
    __myothertemplate__
    Baz, [% qux %]?

=head1 DESCRIPTION

This module allows you to store your templates inline with your
code in the C<__DATA__> section. It will search any number of classes
specified.

=head1 CAVEAT

If you have two templates with the same name, this module will not understand
the difference, it will simply return the first one found.

=head1 INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

=cut

__PACKAGE__->mk_accessors( qw( cache classes ) );

our $VERSION = '0.09';

=head1 METHODS

=head2 new( \%OPTIONS )

Create a new instance of the provider. The only option you can
specify is C<CLASSES> which will tell the provider what classes
to search for templates. By omitting this option it will search
C<main>.

    # defaults to 'main'
    $provider = Template::Provider::FromDATA->new;
    
    # look for templates in 'Foo'
    $provider = Template::Provider::FromDATA->new;( {
        CLASSES => 'Foo'
    } );

    # look for templates in 'Foo::Bar' and 'Foo::Baz'
    $provider = Template::Provider::FromDATA->new;( {
        CLASSES => [ 'Foo::Bar', 'Foo::Baz' ]
    } );

=head2 _init( \%OPTIONS )

A subclassed method to handle the options passed to C<new()>.

=cut

sub _init {
    my( $self, $args ) = @_;
    my $classes = delete $args->{ CLASSES };
    $classes ||= [ 'main' ];
    $classes   = [ $classes ] if not ref $classes;
    
    for( @$classes ) {
        eval "require $_";
    }

    $self->classes( $classes );
    $self->cache( { classes => {}, templates => {} } );

    return $self->SUPER::_init;
}

=head2 fetch( $name )

This is a subclassed method that will load a template via C<_fetch()>
if a non-reference argument is passed.

=cut

sub fetch {
    my( $self, $name  ) = @_;

    return undef, Template::Constants::STATUS_DECLINED if ref $name;

    my( $data, $error ) = $self->_fetch( $name );    
    return $data, $error;
}

=head2 _load( $name )

Loads the template via the C<get_file()> sub and sets some cache
information.

=cut

sub _load {
    my( $self, $name ) = @_;
    my $data    = {};
    my $classes = $self->classes;
    my( $content, $error );

    for my $class ( @$classes ) {
        $content = $self->get_file( $class, $name );
        last if $content;
    }

    my $time = time;
    $data->{ time } = $time;
    $data->{ load } = $time;
    $data->{ name } = $name;
    $data->{ text } = $content;

    $error = Template::Constants::STATUS_DECLINED if !$content;

    return $data, $error;
}

=head2 get_file( $class, $template )

This method searches through C<$class> for a template
named C<$template>. Returns the contents on success, undef
on failure.

This function was mostly borrowed from L<Catalyst::Helper>'s
C<get_file> function.

=cut

sub get_file {
    my( $self, $class, $template ) = @_;

    my $cache = $self->cache;

    if( !exists $cache->{ templates }->{ $template } ) {
        unless ( $cache->{ classes }->{ $class } ) {
            local $/;
            no strict 'refs';
            my $fh = \*{"${class}\::DATA"};
            my $filecache = <$fh>;
            $cache->{ classes }->{ $class }++;

            my $result;
            my @files = split /^__(.+)__\r?\n/m, $filecache;
            shift @files;
            while (@files) {
                my( $name, $content ) = splice @files, 0, 2;
                $cache->{ templates }->{ $name } = $content;
                $result = $content if $name eq $template;
            }

            return $result;
        }

        return undef;
    }
    else {
        return $cache->{ templates }->{ $template };
    }
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
