use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Template/Provider/FromDATA.pm > README' );
}

perl_version '5.006';

name 'Template-Provider-FromDATA';
all_from 'lib/Template/Provider/FromDATA.pm';

requires 'Template' => '2.15';
requires 'Class::Accessor';

test_requires 'Test::More';

repository "http://github.com/bricas/template-provider-fromdata/tree/master";

WriteAll;
