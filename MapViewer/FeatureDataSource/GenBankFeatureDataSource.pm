package FeatureDataSource::GenBankFeatureDataSource;

use strict;

use Bio::SeqIO;
use Bio::DB::GenBank;

use FeatureDataSource;

@FeatureDataSource::GenBankFeatureDataSource::ISA=qw(FeatureDataSource);

my $genbank=undef;

sub _init_genbank {
    $genbank=new Bio::DB::GenBank;
}

sub new {
    my $class=shift;
    my %params=();

    while (my $paramname=shift) {
	$params{lc $paramname}=shift;
    }
 
    my $self=_new FeatureDataSource;
    bless $self,$class;

    _init_genbank()
	unless (defined $genbank);

    my $seq=$genbank->get_Seq_by_acc($params{accessnumber});

    $self->FeatureDataSource::_load_features($seq);

    return $self;
    
}

1
