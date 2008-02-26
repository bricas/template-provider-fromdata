use inc::Module::Install 0.67;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Template/Provider/FromDATA.pm > README' );
}

name 'Template-Provider-FromDATA';
all_from 'lib/Template/Provider/FromDATA.pm';

requires 'Template' => '2.15';
requires 'Class::Accessor';

test_requires 'Test::More';

auto_install;
WriteAll;
