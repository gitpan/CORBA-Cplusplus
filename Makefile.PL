use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::Cplusplus',
    'VERSION_FROM'  => 'lib/CORBA/Cplusplus.pm',
    'ABSTRACT'      => 'IDL compiler to C++',
    'PREREQ_PM'     => {
                        'CORBA::IDL'    => 2.47,
                        'CORBA::C'      => 2.46
    },
    'INSTALLDIRS'   => 'site',
    'EXE_FILES'     => [ 'bin/idl2cpp' ],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);

