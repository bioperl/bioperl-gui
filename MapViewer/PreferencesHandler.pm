package PreferencesHandler;

use strict;

use IO::File;

use XML::Parser::PerlSAX;
use XML::Writer;

use FeatureWidget;
use ExternalViewerLinker;

sub new {
    my $class=shift;

    my $self={};

    bless $self,$class;
}

sub start_strands {
    my $self=shift;
    my $tag=shift;

    my $attributes=$tag->{Attributes};
    ScalableFeatureWidget::collapse_strands()
	if ($attributes->{layout} eq 'collapsed');
    ScalableFeatureWidget::expand_strands()
	if ($attributes->{layout} eq 'expanded');
    
}

sub start_frames {
    my $self=shift;
    my $tag=shift;

    my $attributes=$tag->{Attributes};
    ScalableFeatureWidget::show_frames()
	if ($attributes->{visible} eq 'true');
    ScalableFeatureWidget::hide_frames()
	if ($attributes->{visible} eq 'false');
    
}


sub start_feature {
    my $self=shift;
    my $tag=shift;

    my $attributes=$tag->{Attributes};

    my $feature=$attributes->{type};
    my $visible=$attributes->{visible};

    FeatureWidgetFactory::unmask_feature($feature)
      if ($visible eq 'true');

    FeatureWidgetFactory::mask_feature($feature)
      if ($visible eq 'false');
}

sub start_browser {
    my $self=shift;
    my $tag=shift;

    my $attributes=$tag->{Attributes};

    my $command=$attributes->{command};

    $ExternalViewerLinker::browser_command=$command;
}


my %subs = (
	    strands => { start => sub {start_strands @_}},
	    frames =>  { start => sub {start_frames @_}},
	    feature => { start => sub {start_feature @_}},
	    browser => { start => sub {start_browser @_}}
	    );

sub start_element {
	my $self=shift;
	my $tag=shift;

	my $tagname=$tag->{Name};
	&{$subs{$tagname}->{start}}($self,$tag)
		if (defined $subs{$tagname});
}


sub load_preferences {
    my $prefsfile=shift;

    my $parser=new XML::Parser::PerlSAX();

    $parser->parse(Source => { SystemId => $prefsfile},
		   Handler => new PreferencesHandler);

}

sub save_preferences {
    my $prefsfile=shift;

    my $xmlfh=new IO::File(">$prefsfile");
    my $writer=new XML::Writer(OUTPUT=>$xmlfh,DATA_MODE=>1,DATA_INDENT=>1);
    $writer->xmlDecl('ISO-8859-1',1);
    
    print $xmlfh <<EODOCTYPE;

<!DOCTYPE mapviewer [
<!ELEMENT mapviewer (mapdisplay*,browser*)>
<!ELEMENT mapdisplay (strands*,feature*)+>
<!ELEMENT strands EMPTY>
<!ATTLIST strands 
        layout (collapsed|expanded) "expanded">
<!ELEMENT frames EMPTY>
<!ATTLIST frames
	visible (true|false) "false">
<!ELEMENT feature EMPTY>
<!ATTLIST feature 
          type CDATA #REQUIRED
	  visible (true|false) "true">
<!ELEMENT browser EMPTY>
<!ATTLIST browser
	  command CDATA #REQUIRED>
]>
EODOCTYPE
    $writer->startTag('mapviewer');

    $writer->startTag('mapdisplay');

    my $layout='expanded';
    $layout='collapsed'
	if (ScalableFeatureWidget::are_strands_collapsed());
    $writer->emptyTag('strands','layout'=>$layout);


    my $frames_visible='false';
    $frames_visible='true'
	if (ScalableFeatureWidget::are_frames_visible());
    $writer->emptyTag('frames','visible'=>$frames_visible);

    foreach my $featurename (FeatureWidgetFactory::get_feature_names()) {
	$writer->emptyTag('feature',
			  'type'=>$featurename,
			  'visible'=>'false')
	    if (FeatureWidgetFactory::is_masked($featurename));
    }

    $writer->endTag('mapdisplay');

    $writer->emptyTag('browser',
		    'command' => $ExternalViewerLinker::browser_command);

    $writer->endTag('mapviewer');


    $xmlfh->close();
}


