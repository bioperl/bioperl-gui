package FeatureDataSource::FileFeatureDataSource;

use strict;

use Bio::SeqIO;

use FeatureDataSource;

@FeatureDataSource::FileFeatureDataSource::ISA=qw(FeatureDataSource);

sub _load_features {
    my $self=shift;
    my $filename=shift;
    my $format=shift;

    my $in=new Bio::SeqIO('-file'=>"$filename",'-format'=>"$format");

    my $seq = $in->next_seq;
    $self->FeatureDataSource::_load_features($seq);
}

sub new {
    my $class=shift;
    my $filename=shift;
    my $format=shift;

    my $self=_new FeatureDataSource;

    bless $self,$class;

    $self->{filename}=$filename;
    $self->{format}=$format;

    $self->_load_features($filename,$format);

    return $self;
}


sub get_filename {
    my $self=shift;

    return $self->{filename};
}

1
