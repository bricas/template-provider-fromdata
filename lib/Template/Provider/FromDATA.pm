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

=head1 INSTALLATION

To install this module via Module::Build:

	perl Build.PL
	./Build         # or `perl Build`
	./Build test    # or `perl Build test`
	./Build install # or `perl Build install`

To install this module via ExtUtils::MakeMaker:

	perl Makefile.PL
	make
	make test
	make install

=cut

__PACKAGE__->mk_accessors( qw( cache classes ) );

our $VERSION = '0.02';

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

=cut

sub new {
    my $class   = shift;
    my $options = shift || {};
    my $self    = $class->SUPER::new( $options );

    my $classes = delete $options->{ CLASSES };
    if( $classes ) {
        $self->classes( $classes );
        for( ref $classes ? @$classes : $classes ) {
            eval "require $_";
        }
    }

    $self->cache( {} );

    return $self;
}

=head2 fetch( $file )

This is a sub-classed method that will forward things to the
super-class' C<fetch> when it is passed a reference, or to
C<_fetch> if it's a plain scalar. The scalar should hold the
name of the template found in the C<__DATA__> section.

=cut

sub fetch {
    my( $self, $file ) = @_;

    return $self->SUPER::fetch( $file ) if ref $file;
    return $self->_fetch( $file );
}

=head2 _load( $file, [$alias] )

Another sub-classed method. Normally this would try to load the
template from a reference or a file on disk. Again, we forward things
to the super-class if we see a reference, otherwise we grab the 
content from the C<__DATA__> section.

=cut

sub _load {
    my ($self, $file, $alias) = @_;

    $self->SUPER::_load( $file, $alias ) if ref $file;

    $self->debug( "_load( $file, ", defined $alias ? $alias : '<no alias>', 
         ' )') if $self->{ DEBUG };

    $alias = $file unless defined $alias;

    my $content;
    my $classes = $self->classes || 'main';
    for my $class ( ref $classes ? @$classes : $classes ) {
        $content = $self->get_file( $class, $file );
        last if $content;
    }

    unless( $content ) {
        if( $self->{ TOLERANT } ) {
            return undef, Template::Constants::STATUS_DECLINED;
        }
        else {
            return "$alias: Template not found", Template::Constants::STATUS_ERROR;
        }
    }

    $content = $self->_decode_unicode( $content ) if $self->{ UNICODE };
    my $data = {
        name => $alias,
        path => $file,
        text => $content,
        time => $^T,
        load => time,
    };

    return $data, undef;
}

=head2 get_file( $class, $file )

This method searches through C<$class> for a template
named C<$file>. Returns the contents on success, undef
on failure.

This function was mostly borrowed from L<Catalyst::Helper>'s
C<get_file> function.

=cut

sub get_file {
    my( $self, $class, $file ) = @_;

    my $cache;

    unless ( $cache = $self->cache->{ $class } ) {
        local $/;
        $cache = eval "package $class; <DATA>";
        $self->cache->{ $class } = $cache;
    }

    my @files = split /^__(.+)__\r?\n/m, $cache;
    shift @files;
    while (@files) {
        my( $name, $content ) = splice @files, 0, 2;
        return $content if $name eq $file;
    }

    return undef;
}

=head1 AUTHOR

=over 4 

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;