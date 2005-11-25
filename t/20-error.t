use Test::More tests => 5;

use strict;
use warnings;

use_ok( 'Template' );
use_ok( 'Template::Provider::FromDATA' );

my $provider = Template::Provider::FromDATA->new;
isa_ok( $provider, 'Template::Provider::FromDATA' );

my $template = Template->new( {
    LOAD_TEMPLATES => [ $provider ],
} );
isa_ok( $template, 'Template' );

{
    my $output;
    $template->process( 'testDNE', {}, \$output );
    is( $template->error, 'file error - testDNE: Template not found' );
}

__DATA__

__test__
template data