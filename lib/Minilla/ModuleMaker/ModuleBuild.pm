package Minilla::ModuleMaker::ModuleBuild;
use strict;
use warnings;
use utf8;
use Data::Section::Simple qw(get_data_section);

use Moo;

no Moo;

use Minilla::Util qw(spew_raw);

sub generate {
    my ($self, $project) = @_;

    my $content = get_data_section('Build.PL');
    $content =~ s!<%\s*\$([a-z_]+)\s*%>!
        $project->$1()
    !ge;
    spew_raw('Build.PL', $content);
}

sub prereqs {
    return +{
        configure => {
            requires => {
                'Module::Build'    => 0.40,
                'CPAN::Meta'       => 0,
            }
        }
    }
}

1;
__DATA__

@@ Build.PL
use strict;
use Module::Build;
use File::Basename;
use File::Spec;
use CPAN::Meta;
use CPAN::Meta::Prereqs;

use 5.008;

my $builder = Module::Build->new(
    license              => 'perl',
    dynamic_config       => 0,

    configure_requires => {
        'Module::Build' => 0.40,
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => '<% $dist_name %>',
    module_name => '<% $name %>',

    script_files => [glob('script/*'), glob('bin/*')],

    test_files           => ((-d '.git' || $ENV{RELEASE_TESTING}) && -d 'xt') ? 't/ xt/' : 't/',
    recursive_test_files => 1,
);
$builder->create_build_script();

my $mbmeta = CPAN::Meta->load_file('MYMETA.json');
my $meta = CPAN::Meta->load_file('META.json');
my $prereqs_hash = CPAN::Meta::Prereqs->new(
    $meta->prereqs
)->with_merged_prereqs(
    CPAN::Meta::Prereqs->new($mbmeta->prereqs)
)->as_string_hash;
my $mymeta = CPAN::Meta->new(
    {
        %{$meta->as_struct},
        prereqs => $prereqs_hash
    }
);
print "Merging cpanfile prereqs to MYMETA.yml\n";
$mymeta->save('MYMETA.yml', { version => 1.4 });
print "Merging cpanfile prereqs to MYMETA.json\n";
$mymeta->save('MYMETA.json', { version => 2 });
