package Template::Provider::FromDATA;

use base qw( Template::Provider Class::Accessor::Fast );

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

our $VERSION = '0.01';

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

    $self->classes( $options->{ CLASSES } ) if $options->{ CLASSES };
    $self->cache( {} );

    return $self;
}

=head2 fetch( $file )

This is a sub-classes method that tries to load the template. If C<$file>
is a reference, then we assume it holds the content of the template.

=cut

sub fetch {
    my( $self, $file ) = @_;

    my $content;
    if( ref $file ) {
        $content = $$file;
    }
    else {
        my $classes = $self->classes || 'main';
        for my $class ( ref $classes ? @$classes : $classes ) {
            $content = $self->get_file( $class, $file );
            last if $content
        }
    }

    my( $data, $error ) = $self->_load( \$content );
    ( $data, $error )   = $self->_compile( $data ) unless $error;

    $data = $data->{ data } unless $error;

    return $data, $error;
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