use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Bio/Tk',
    'VERSION_FROM' => 'Bio/Tk/SeqCanvas.pm', # finds $VERSION
    'DISTNAME'  => 'bioperl-gui',
    'AUTHOR'    => 'Mark Wilkinson and David Block',
    'ABSTRACT'  => 'Tk interface to Bio::SeqI objects',
    'PMLIBDIRS' => ['t','Bio/Tk'],
);
