=head1 NAME

Bio::Tk::HitDisplay - Frame-based widget for displaying Fasta or
Blast hits/HSPs with optional text annotation

=head1 SYNOPSIS

 use Bio::Tk::HitDisplay;
 ...
 $hds = $parent->HitDisplay(?options?);

=head1 DESCRIPTION

B<HitDisplay> is a Frame-based widget which contains a Canvas. When
provided with a list of data structures, each representing a hit of a
query sequence to a database, it draws:

=over

=item * A scale

This is marked in residues (aa for a protein query, nt for a nucleic
acid query)

=item * The query sequence

Represented as a single green line

=item * Database hits

A line for each Fasta hit, or a group of lines for each Blast hit (one
per HSP)

=back

The coordinates of the hits/HSPs on the subject sequence (i.e. the
sequence in the database) are indicated below the ends of each line.

The B<HitDisplay> delegates all standard options to the Canvas contained
within it. The non-standard options for B<HitDisplay> are:

=over

=item B<-hitdata> => \@hitdata

The structure of each element of this list is quite complex. They are
normally generated from object(s) representing Blast or Fasta hits e.g.

 Bio::PSU::IO::Blast::Hit
 Bio::PSU::IO::Fasta::Hit

by their respective adapters

 Bio::PSU::IO::Blast::HitAdapter
 Bio::PSU::IO::Fasta::HitAdapter

This is normally hidden, unless you want to go and look.

Each element is a reference to a hash containing the following keys
and values:

          { q_id     => 'query id',
	    s_id     => 'subject id',
	    expect   => 'expect value',
	    score    => 'percentage identity',
	    overlap  => 'length of hit',
	    q_len    => 'query length',
	    s_len    => 'subject length',
	    data     => \@data,
            text     => "Some text",
            callback => $callback }

@data is a list of references to lists, each of which contains the
coordinates of a single Fasta hit or Blast HSP on both the query and
subject sequences.  Each innermost list contains 4 values; the start
and end coordinates on the query sequence (indices 0 and 1) and the
start and end coordinates on the subject sequence (indices 2 and 3). A
Blast hit with 3 HSPs will look like this:

          [ [ q_start1, q_end1, s_start1, s_end1 ],
            [ q_start2, q_end2, s_start2, s_end2 ],
            [ q_start3, q_end3, s_start3, s_end3 ] ]

The text field may contain any text which should be associated with
that hit e.g. a more detailed account of the result or of the subject
sequence. The display of this text is bound to a right mouse button
click on the subject id in the canvas window. The text will appear
just below the hit with one click and a subsequent click will hide it
again.

The callback is a code reference which, if defined, will be bound to a
left mouse button click on the subject id in the canvas window.

=item B<-hitcolours> => \%colourhash

The hits or HSPs will be colour-coded according to percentage identity
according to the key->value pairs in the colourhash. The default
values are:

          { 90 => 'red',
	    80 => 'orange',
	    60 => 'gold',
	    40 => 'yellow' }

This indicates that hits where the query is >= 90% identical to the
subject will be red, >= 80% will be orange etc. The hash supplied to
B<-hitcolours> will override the defaults.

=item B<-interval> => integer >= 10

This defines the vertical spacing between hit lines on the canvas. The
minimum (and default) value is 10.

=back

Mouse bindings provided:

=over

=item * Vertical scrolling

Wheel-mouse support is provided by binding buttons 4 and 5 to vertical
scrolling (standard Z-axis mapping under XFree86 on Linux).

=item * Panning

Holding down the middle mouse button while dragging will pan the
canvas in all directions

=item * Display/hide all text annotations

Double-clicking the left mouse button within the canvas will display
all text annotations, while double-clicking with the right button will
hide them. This is slow at the moment, with more than about 20 hits.

=back

Possible improvements:

=over

=item * Speed up opening/closing all text annotations at once

=item * Items other than text between the hits

=item * Make more of the canvas configurable

Mouse bindings should be made configurable. Perhaps the canvas items
making up each hit should be given a unique tag

=back

=head1 METHODS

Interaction with this widget should generally be by means of the
standard Perl/Tk options. Internal methods are documented below.

=head1 AUTHOR

Keith James (kdj@sanger.ac.uk)

=head1 ACKNOWLEDGEMENTS

See Bio::PSU.pod

=head1 COPYRIGHT

Copyright (C) 2000 Keith James. All Rights Reserved.

=head1 DISCLAIMER

This module is provided "as is" without warranty of any kind. It
may redistributed under the same conditions as Perl itself.

=cut

package Bio::Tk::Hitdisplay;

use strict;
use Carp;
use Tk::Frame;
use Tk::Canvas;

use vars qw(@ISA);

@ISA = qw(Tk::Frame);

Tk::Widget->Construct('HitDisplay');

=head2 Populate

 Title   : Populate
 Usage   : N/A
 Function: Standard composite Frame-based widget setup.
         : See 'man Tk::composite' for details
 Returns : Nothing
 Args    : Hash reference

=cut

sub Populate
{
    my ($self, $args) = @_;

    my $hitdata    = delete $args->{-hitdata};
    my $interval   = delete $args->{-interval};
    my $hitcolours = delete $args->{-hitcolours};

    my $defaultcolours = { 90 => 'red',
			   80 => 'orange',
			   60 => 'gold',
			   40 => 'yellow' };

    # A hash for storing callbacks, passed by reference to subs
    my $callbackbox = { annotate   => [],
			deannotate => [] };

    my $hititems = [];

    # Check colour option passed in by user
    if (defined $hitcolours)
    {
	unless (ref($hitcolours) eq 'HASH')
	{
	    carp "Value passed to -hitcolours was not a hash reference; using defaults";
	    $hitcolours = $defaultcolours;
	}
    }
    else
    {
	$hitcolours = $defaultcolours
    }

    # Check interval option passed in by user; default is 10
    unless (defined $interval and $interval >= 10)
    {
	carp "Value passed to -interval was too small; using minimum (10)";
	$interval = 10;
    }

    $self->SUPER::Populate($args);

    $self->fontCreate('hv-n-tiny',  -family => 'helvetica',
		      -size => 8,   -weight => 'normal');
    $self->fontCreate('hv-n-small', -family => 'helvetica',
		      -size => 10,  -weight => 'normal');
    $self->fontCreate('hv-b-small', -family => 'helvetica',
		      -size => 10,  -weight => 'bold');
    $self->fontCreate('hv-n-med',   -family => 'helvetica',
		      -size => 12,  -weight => 'normal');

    my $cv = $self->Canvas->pack(-anchor => 'w',
				 -side   => 'top',
				 -fill   => 'both');

    # Bindings to allow dragging movement
    $cv->CanvasBind('<Button-2>',        \&scroll_mark);
    $cv->CanvasBind('<Button2-Motion>', [\&scroll_drag, 4]);

    # Open/close all
    $cv->CanvasBind('<Double-Button-1>', [\&open_all,  $callbackbox]);
    $cv->CanvasBind('<Double-Button-3>', [\&close_all, $callbackbox]);

    # Binding to allow wheel-mouse scrolling
    $cv->CanvasBind('<Button-4>', sub { $cv->yviewScroll(-1, 'units') });
    $cv->CanvasBind('<Button-5>', sub { $cv->yviewScroll( 1, 'units') });

    if (defined $hitdata)
    {
	$self->draw_scale($cv, $hitdata, 10, 100, 10);
	$self->draw_align($cv, $hitdata, 10, 100, 70, $interval, $hitcolours, $callbackbox);
    }
    $cv->configure(-scrollregion => [$cv->bbox("all")]);

    # All configuration options get passed to the canvas
    $self->Advertise('Canvas' => $cv);
    $self->ConfigSpecs(DEFAULT => [$cv]);
    $self->Delegates(DEFAULT => $cv);
}

=head2 draw_align

 Title   : draw_align
 Usage   : N/A
 Function: Draws hit text, line and coords for the hits
 Returns : Nothing
 Args    : Canvas, hitdata hash reference, left margin for text,
         : x coord for lines, y coord for lines, interval between
         : sets of lines (representing 1 Fasta hit or 1+ Blast
         : HSPs), hitcolours hash reference

=cut

sub draw_align
{
    my ($self, $cv, $hitdata, $lmargin, $x, $y, $interval, $hitcolours, $callbackbox) = @_;

    # Each element represents a hit (Fasta hit or collections of Blast HSPs)
    foreach (@$hitdata)
    {
	my $q_id     = $_->{q_id};
	my $s_id     = $_->{s_id};
	my $pc       = $_->{score};
	my $expect   = $_->{expect};
	my $overlap  = $_->{overlap};
	my $q_len    = $_->{q_len};
	my $s_len    = $_->{s_len};
	my $data     = $_->{data};
	my $text     = $_->{text};
	my $callback = $_->{callback};
	my $width    = 4;
	my $colour   = 'black';

	$q_id = "<query>"   unless defined $q_id;
	$s_id = "<subject>" unless defined $s_id;
	$text = ""          unless defined $text;

	# Set colour according to % identity
	foreach (sort keys %$hitcolours)
	{
	    if ($pc >= $_) { $colour = $hitcolours->{$_} }
	}

	# Truncate over-long subject names
	if (length($s_id) > 10)
	{
	    $s_id = substr($s_id, 0, 9) . "..."
	}

	# Create subject name labels
	my $t = $cv->createText($lmargin, $y,
				-text    => "$s_id",
				-anchor  => 'w',
				-justify => 'left',
				-font    => 'hv-n-small',
				-fill    => 'blue');

	# @$data is a list of list references to data of the form:
	# [$q_start, $q_end, $s_start, $s_end]
	# Here we sort by subject start position (index 2)
	my @sorted = sort { $a->[2] <=> $b->[2] } @$data;

	# Mark in HSP/Hit lines, alternating HSPs up & down for clarity
	my $down = 0;
	foreach (@sorted)
	{
	    h_line($cv, $_, $x, $y, $width, $colour);

	    if ($down) { $y -= 15; $down = 0}
	    else       { $y += 15; $down = 1}
	}

	# Do we need more space after HSPs?
	my $spacer = 0;
	if (scalar @$data > 1)
	{
	    $y += 20;
	    $spacer = 15;

	    # Correct HSP alternation
	    if ($down) { $y -= 15 }
	}

	$y += $interval;

	my $annotate = sub { annotate_hit($cv, $t, $text, $interval + $spacer, $callbackbox) };
	push(@{$callbackbox->{annotate}}, $annotate);

	# Bind action to subject name labels
	$cv->bind($t, '<Button-3>', $annotate);

	# Bind cursor change as a visual cue to click on the labels
	$cv->bind($t, '<Enter>', sub { $cv->configure(-cursor =>    'hand2') });
	$cv->bind($t, '<Leave>', sub { $cv->configure(-cursor => 'left_ptr') });

	# Bind user supplied callback to subject name labels
	$cv->bind($t, '<Button-1>', $callback) if defined $callback;
    }
}

=head2 h_line

 Title   : h_line
 Usage   : N/A
 Function: Draws a single hit/HSP line with the subject coords
         : below it
 Returns : Nothing
 Args    : Canvas, hit hash reference, x coord for line,
         : y coord for line, line width, line colour

=cut

sub h_line
{
    my ($cv, $ref, $x, $y, $width, $colour) = @_;

    # Text indicates subject coordinates
    $cv->createText($ref->[0] + $x, $y + 7,
		    -text    => $ref->[2],
		    -justify => 'left',
		    -font    => 'hv-n-tiny');

    $cv->createText($ref->[1] + $x, $y + 7,
		    -text    => $ref->[3],
		    -justify => 'right',
		    -font    => 'hv-n-tiny');

    $cv->createLine($ref->[0] + $x, $y,
		    $ref->[1] + $x, $y,
		    -width => $width,
		    -fill  => $colour);
}

=head2 draw_scale

 Title   : draw_scale
 Usage   : N/A
 Function: Draws scale alongside line representing query
         : sequence
 Returns : Nothing
 Args    : Canvas, hit hash reference, left margin for text
         : x coord for line, y coord for line

=cut

sub draw_scale
{
    my ($self, $cv, $hitdata, $lmargin, $x, $y) = @_;

    # Draw subject line
    my $q_id = $hitdata->[0]->{q_id};
    my $len  = $hitdata->[0]->{q_len};

    # Truncate over-long query names
    if (length($q_id) > 10)
    {
	$q_id = substr($q_id, 0, 9) . "..."
    }

    # Scale ticks are marked every $div residues
    my $div   = 50;
    my $ticks = sprintf("%d", $len / $div);
    $ticks++ if $len % $div;

    # Blank scale line
    $cv->createLine($x, $y,
		    $x + $ticks * $div, $y,
		    -width => 1,
		    -fill  => 'black');

    # Ticks and labels
    for (my $i = 0; $i <= $ticks; $i++)
    {
	$cv->createLine($x + $i * $div, $y,
			$x + $i * $div, $y + 5,
			-width => 1,
			-fill  => 'black');

	$cv->createText($x + $i * $div, $y + 10,
			-text    => $i * $div + 1,
			-anchor  => 'w',
			-justify => 'right',
			-font    => 'hv-n-small');
    }

    # Subject name
    $cv->createText($lmargin, $y + 30,
		    -text    => "$q_id",
		    -anchor  => 'w',
		    -justify => 'left',
		    -font    => 'hv-b-small');

    # Subject line
    $cv->createLine($x,        $y + 30,
		    $x + $len, $y + 30,
		    -width => 4,
		    -fill  => 'green');
}

=head2 deannotate_hit

 Title   : deannotate_hit
 Usage   : N/A
 Function: Reverses the effect of annotate_hit
 Returns : Nothing
 Args    : Canvas, text item (subject id), text to be inserted
         : in gap, interval between hits

=cut

sub deannotate_hit
{
    my ($cv, $t, $text, $interval, $td, $td_ht) = @_;

    # Do nothing if the hit is already closed
    return if ! grep /open/, $cv->gettags($t);

    # Delete the hit details and remove the 'open' tags
    $cv->delete($td);
    my ($tx, $ty) = $cv->coords($t);
    $cv->dtag($t, 'open');

    # Shuffle up canvas items below the hit title
    foreach ($cv->find('all'))
    {
	my ($x, $y) = $cv->coords($_);
	$cv->move($_, 0, - $td_ht) if $y > $ty + $interval;
    }

    # Change the binding and colour of the closed hit
    $cv->bind($t, '<Button-3>', [\&annotate_hit, $t, $text, $interval]);

    $cv->itemconfigure($t, -fill => 'blue');

    $cv->configure(-scrollregion => [$cv->bbox('all')]);
}

=head2 annotate_hit

 Title   : annotate_hit
 Usage   : N/A
 Function: Displays hit annotation below a hit line by shuffling
         : all canvas elements down the canvas and placing the
         : annotation text in the gap
 Returns : Nothing
Args    : Canvas, text item (subject id), text to be inserted
         : in gap, interval between hits

=cut

sub annotate_hit
{
    my ($cv, $t, $text, $interval, $callbackbox) = @_;

    # Do nothing if the hit is already open
    return if grep /open/, $cv->gettags($t);

    # Mark this hit title as open
    my ($tx, $ty) = $cv->coords($t);
    $cv->addtag('open', 'withtag', $t);

    # Insert hit details in the gap created
    my $td = $cv->createText($tx + 100, $ty + $interval,
			     -text    => $text,
			     -justify => 'left',
			     -anchor  => 'nw',
			     -font    => 'hv-n-small',
			     -tags    => 'working');

    # Calculate the height of the newly added text. Movement
    # is calculated with reference to the interval between hits
    # plus this height
    my @tdbox = $cv->bbox($td);
    my $td_ht = $tdbox[3] - $tdbox[1];

    # Shuffle down any canvas items below the title but
    # not the newly added text
    foreach ($cv->find('withtag', '!working'))
    {
	my ($x, $y) = $cv->coords($_);
	$cv->move($_, 0, $td_ht) if $y > ($ty + $interval);
    }

    # Finished working on the added text
    $cv->dtag($td, 'working');

    my $deannotate = sub { deannotate_hit($cv, $t, $text, $interval, $td, $td_ht) };
    push(@{$callbackbox->{deannotate}}, $deannotate);

    # Change the binding and colour of the open hit
    $cv->bind($t, '<Button-3>', $deannotate);

    $cv->itemconfigure($t, -fill => 'black');

    $cv->configure(-scrollregion => [$cv->bbox('all')]);
}

sub open_all
{
    my ($cv, $callbackbox) = @_;
    my $callbacks = $callbackbox->{annotate};

    foreach (@$callbacks) { &$_ }
}

sub close_all
{
    my ($cv, $callbackbox) = @_;
    my $callbacks = $callbackbox->{deannotate};

    foreach (@$callbacks) { &$_ }
}

sub scroll_mark
{
    my ($cv) = @_;
    my $e = $cv->XEvent;

    $cv->scanMark($e->x, $e->y);
}

sub scroll_drag
{
    my ($cv, $sensit) = @_;
    my $e = $cv->XEvent;

    $cv->scanDragto($e->x, $e->y, $sensit);
}
