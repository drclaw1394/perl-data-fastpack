use 5.024000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::FastPack',
    VERSION_FROM      => 'lib/Data/FastPack.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
      "Export::These"=>0,
      "constant::more"=>0,
      "Cpanel::JSON::XS"=>0,
      "Data::MessagePack"=>0,
    },
    ABSTRACT_FROM     => 'lib/Data/FastPack.pod', # retrieve abstract from module
    AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
    LICENSE           => 'mit',
);
