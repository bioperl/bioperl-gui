package FeatureDataSource::EMBLFeatureDataSource;

use strict;

use LWP::UserAgent;
use HTTP::Request;

use FindBin;

use CORBA::ORBit idl => ["$FindBin::Bin/FeatureDataSource/BioCorba-0.2.idl"];

use Bio::Seq;
use Bio::SeqFeature::Generic;

use FeatureDataSource;

@FeatureDataSource::EMBLFeatureDataSource::ISA=qw(FeatureDataSource);

my $orb=undef;
my $database=undef;
my $EMBLNAME='EMBL';
my $IORURL='http://corba.ebi.ac.uk/IOR/EmblBiocorba_v0_2.IOR';


sub _init_server {

    $orb=CORBA::ORB_init("orbit-local-orb");

    my $request=new HTTP::Request(GET => $IORURL);
    my $agent=new LWP::UserAgent;
    my $response=$agent->request($request);

    die "$0: Unable to retrieve IOR for EMBL server\n"
	unless ($response->is_success);

    my $ior=$response->content();
    chomp($ior);
    my $bioenv=$orb->string_to_object($ior);

    $database=$bioenv->get_SeqDB_by_name($EMBLNAME,0);
}

sub new {
    my $class=shift;
    my %params=();

    $params{start}=-1;
    $params{end}=-1;
    $params{qualifiers}=0;
    while (my $paramname=shift) {
	$params{lc $paramname}=shift;
    }
   
    my $self=_new FeatureDataSource;
    bless $self,$class;

    _init_server
	unless defined ($database);

    my $corbaseq=$database->get_Seq($params{accessnumber},0);
    
    my $nucleotides=$corbaseq->seq();
    my $bioseq=new Bio::Seq(-seq => $nucleotides,
			 -id => 'embl_retrieved_sequence',
			 -accession_number => $params{accessnumber});

    my $featurevector=undef;

    if ($params{start}>0 && $params{end}>$params{start}) {
	$featurevector=$corbaseq->get_SeqFeatures_in_region($params{start},$params{end},1);
    } else {
	$featurevector=$corbaseq->all_SeqFeatures(1);
    }

    my $numfeatures=$featurevector->size();
    for (my $i=0;$i<$numfeatures;$i++) {
	my $feature=$featurevector->elementAt($i);
	my $featstart=$feature->start();
	my $featend=$feature->end();
	my $strand=$feature->strand();
	my $type=$feature->type();
	my %tags=();
	
	my $qualifierset=$feature->qualifiers();
	my $qualifierset=[];
	foreach my $qualifier (@$qualifierset) {
	    my $qualifiername=$qualifier->name();
	    my $qualifiervalues=$qualifier->values();
	    $tags{$qualifiername}=$qualifiervalues->[0];
	}

#	my $locations=$feature->locations();
	my $locations=[];
	my $featlocation=undef;

	if ($#{$locations}>=0) {
	    $featlocation=new Bio::Location::Split();
	    foreach my $sublocation (@$locations) {
		my $sublocstart=$sublocation->_get_start();
		my $sublocend=$sublocation->_get_end();
		my $sublocstrand=$sublocation->_get_strand();
		$featlocation->add_sub_Location(-start => $sublocstart,
						-end => $sublocend,
						-strand => $sublocstrand);
	    }
	} else {
	    $featlocation=new Bio::Location::Simple(-start => $featstart,
						       -end => $featend,
						       -strand => $strand);
	}
	my $seqfeature=new Bio::SeqFeature::Generic(
						    -primary => $type,
						    -location => $featlocation,
						    -tag => \%tags);
	$bioseq->add_SeqFeature($seqfeature);
    }

    $self->FeatureDataSource::_load_features($bioseq);

    return $self;

}


