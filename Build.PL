use strict;

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'Template::Provider::FromDATA',
	dist_author        => 'Brian Cassidy <bricas@cpan.org>',
	license            => 'perl',
	create_readme      => 1,
	create_makefile_pl => 'traditional',
	requires           => {
		'Template' => 0,
	},
	build_requres      => {
		'Test::More' => 0,
	}
);

$build->create_build_script;