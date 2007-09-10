use inc::Module::Install 0.67;

name 'Template-Provider-FromDATA';
all_from 'lib/Template/Provider/FromDATA.pm';

requires 'Template' => '2.15';
requires 'Class::Accessor';

requires 'Test::More';

auto_install;
WriteAll;
