package WAR::CText;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION = 0.1;
#uise warnings;
# changes text_para_prep
use Glib qw/TRUE FALSE/;
use Cairo;
use Math::Trig;
use Lingua::EN::Sentence qw( get_sentences add_acronyms );
use Time::HiRes qw( usleep  );
use Switch;
use lib '.';
use WAR::CCnf;
use WAR::CFont;

@ISA = qw(CFont); 

use strict;
	
	sub new {
		my ($self) = @_;
		bless {
		},$self;
	
	}

sub get_data {
	my $data_file= shift;
	open(DAT, $data_file) || die("Could not open file!");
	my @raw_data;
	foreach (<DAT>){
		chomp $_;
		next if m/^\s+/;
		$_ =~ tr/\x20-\x7f//cd;

		push(@raw_data, $_) if $_;
	}
	close(DAT);
	return @raw_data;
}

sub create_png_surface {
	my $filename = shift;
	if ( -e $filename ){
		my $surface = Cairo::ImageSurface->create_from_png($filename);
	}else{
	print STDERR "Cannot open $filename";
	}
}


sub draw_flat_rec {
	my ($cr, $x, $y, $width, $height) = @_;
	#print "\n $width $height";
	$cr->rectangle ($x, $y, $width, $height/2);
	$cr->fill;
}


sub draw_flat
{
	my ($cr,$x,$y,$width, $height) = @_;
	#need to sort this
	$cr->move_to     ( $x, $y);
	$cr->rel_line_to ( $width, $y);
	$cr->rel_line_to ( $x, $height/2);
	$cr->close_path;
	$cr->fill;
}


my %font = {
		'fill_color' 	=> (0,0,0),
		'stoke_color'	=> (0,0,0),
		'file'	=> '/usr/share/fonts/truetype/ttf-bitstream-vera/VeraBd.ttf',
};

sub min { return ($_[0] < $_[1] ? $_[0] : $_[1]); }

sub create_gradient
{
	my ($cr,$x,$y,$width, $height) = @_;
#	print "\n $width $height";
	my $gradient = Cairo::LinearGradient->create ($x, $y, $width, $height);
	$gradient->add_color_stop_rgba (0.0, 0., 0., 0. , 1);
	$gradient->add_color_stop_rgba (0.5, 0.7, 0.7, 0.7, 0.3);
#	$gradient->add_color_stop_rgba (1.0, 1.0, 1.0, 1.0, 0.0);
	return $gradient;
}



sub add_background {
	
	my ($self,$filename,$x,$y,$ang) = @_;
	my $cr = $self->{cr};
	#print "\n" . $self->{png_surface};
	$self->{png_surface} = create_png_surface($filename);
	my $image_width = $self->{png_surface}->get_width();
	my $image_height = $self->{png_surface}->get_height();

	$cr->save();
	my $radians  = deg2rad($ang);
	$cr->translate ($x, $y);
	$cr->rotate($radians);
	$cr->set_source_surface ($self->{png_surface}, $x, $y);
	$cr->rectangle ($x, $y, $image_width, $image_height);
	#$cr->set_source_rgba(0.0, 0.0, 0.0,0.5);

	$cr->clip();
	$cr->paint_with_alpha(0.5);
	$cr->restore();

}


sub draw_init
{
	my $self = shift;
	my $cr = $self->{cr};
	#my $surf = Cairo::ImageSurface->create ('argb32', PAGE_WIDTH, PAGE_HEIGHT);
	#my $ccr = Cairo::Context->create ($surf);

	#return FALSE unless $cr;
	#my $str = rand(10000) . 'The furthest distance' . rand(1234000000);
	my $width  = $self->allocation->width;
	my $height = $self->allocation->height;
	#$self->zoom($self->{zmfct},$self->{trnx},$self->{trny});	
	my $txt_num = 0;
	my $ang = 0;
	
#	print "\n" . $self->{zmfct};
#	$self->add_background;

	my ($cntrx,$cntry) = (PAGE_WIDTH/2,PAGE_HEIGHT/2);
	my @lines;
	for (my $ny = 0; $ny < CELLS_Y; $ny++){
		for (my $nx = 0; $nx < CELLS_X; $nx++){
			my $str = $self->{texts}->[int(rand($#{$self->{texts}}))];
			push(@lines,$str);
		}
	}

	my $cnt;
	for (my $ny = 0; $ny < CELLS_Y; $ny++){
		for (my $nx = 0; $nx < CELLS_X; $nx++){
			my $x1 = BORDER_X + ($nx * CELL_WIDTH) + ($nx * GUTTER);
			my $y1 = BORDER_Y + ($ny * CELL_HEIGHT) +($ny * GUTTER);
	 		my ($x2,$y2) = ( $x1+ (CELL_WIDTH/2),$y1+(CELL_HEIGHT/2));
			my $str = $lines[$cnt++];
			my $sentences = get_sentences($str); 	


			$cr->rectangle($x1,$y1,CELL_WIDTH,CELL_HEIGHT);
			$cr->set_source_rgb (0, 0, 0);
			$cr->set_line_width(1);
			$cr->stroke;
			$cr->save;

			$ang += 30;
#		  	switch (scalar @$sentences ) {
#				case 1		{ 
#					$self->{rndrtype} = FNL;
#					$self->TextShadeFunnel(\%font,$str,$x2,$y2,CENTERX,CENTERY); 
#					}
#				case 2		{ 	
#					$self->{rndrtype} = ANG;
#					$self->angletext_arnd_arb_pnt(CENTERX,CENTERY,$x2,$y2,$str,\%font); 
#			}else{ 	
#					$self->{rndrtype} = LNG;
#					$self->longText($str,$nx,$ny,\%font);
# 				}
#    		}
		
		}
	}
	#print "\n__END__";
	#return TRUE;


}

sub make_backround_groups {
	my $self = shift;
 	#   cairo_t *cr_pixmap = gdk_cairo_create(pixmap);
  	#  cairo_set_source_surface (cr_pixmap, cst, 0, 0);
   	# cairo_paint(cr_pixmap);
    #`:w
	#cairo_destroy(cr_pixmap);

	my $cr = $self->{cr};
	my @files = <png/*>;
	my @img;
	foreach my $file (@files) {
 	 	#print $file . "\n";
		push(@img,$file);
		
	} 
my @bkgnd;
	for (my $ny = 0; $ny < CELLS_Y; $ny++){
		for (my $nx = 0; $nx < CELLS_X; $nx++){
			$cr->push_group;	
			$self->add_background(shift @img);
			$bkgnd[$nx][$ny] = $cr->pop_group;
		}
	}
	$self->{backgrounds} = \@bkgnd;


}

#sub draw1 {
#	my $self = shift;
#	my $cr = $self->{cr};
##	$self->zoom($self->{zmfct},$self->{trnx},$self->{trny});	
##	print STDERR '.';
#	$cr->save;
#	my $txt_num = 0;
#	my $ang = 0;
#	
#	
#	my $bkgnd_Ref = $self->{backgrounds};
#	for (my $ny = 0; $ny < CELLS_Y; $ny++){
#		for (my $nx = 0; $nx < CELLS_X; $nx++){
#			my $x1 = BORDER_X + ($nx * CELL_WIDTH) + ($nx * GUTTER);
#			my $y1 = BORDER_Y + ($ny * CELL_HEIGHT) +($ny * GUTTER);
#
#			$cr->save();
#			$cr->translate($x1,$y1);		
#			$cr->set_source($bkgnd_Ref->[$nx]->[$ny]);
#			$cr->paint;
#			$cr->restore;
#			print "\n $nx,$ny ".$bkgnd_Ref->[$nx]->[$ny] ;
#
#		$ang += 30;
#		  	switch (scalar @$sentences ) {
#				case 1		{ 
#					$self->{rndrtype} = FNL;
#					$self->TextShadeFunnel(\%font,$str,$x2,$y2,CENTERX,CENTERY); 
#					}
#				case 2		{ 	
#					$self->{rndrtype} = ANG;
#					$self->angletext_arnd_arb_pnt(CENTERX,CENTERY,$x2,$y2,$str,\%font); 
#			}else{ 	
#					$self->{rndrtype} = LNG;
#					$self->longText($str,$nx,$ny,\%font);
# 				}
#    		}
#
#
#		}
#	}
#	
#
#}

sub draw
{
	my $self = shift;
	my $cr = $self->{cr};

	return FALSE unless $cr;
	#my $str = rand(10000) . 'The furthest distance' . rand(1234000000);
	#my $width  = $self->allocation->width;
	#my $height = $self->allocation->height;
	#$self->zoom($self->{zmfct},$self->{trnx},$self->{trny});	
	my $txt_num = 0;
	my $ang = 0;
		
	my $bkgnd_Ref = $self->{backgrounds};

	#print "\n" . $self->{zmfct};
#	$self->add_background;

	my ($cntrx,$cntry) = (PAGE_WIDTH/2,PAGE_HEIGHT/2);
	my @lines;
	for (my $ny = 0; $ny < CELLS_Y; $ny++){
		for (my $nx = 0; $nx < CELLS_X; $nx++){
			my $str = $self->{texts}->[int(rand($#{$self->{texts}}))];
			push(@lines,$str);
	my $x1 = BORDER_X + ($nx * CELL_WIDTH) + ($nx * GUTTER);
			my $y1 = BORDER_Y + ($ny * CELL_HEIGHT) +($ny * GUTTER);
#			$cr->rectangle($x1,$y1,CELL_WIDTH,CELL_HEIGHT);
#			$cr->clip;
#			$cr->save();
#			$cr->translate($x1,$y1);		
#			$cr->set_source($bkgnd_Ref->[$nx]->[$ny]);
#			$cr->paint;
#			$cr->restore;
#			print "\n $nx,$ny ";
			$cr->save();
			$cr->rectangle($x1,$y1,CELL_WIDTH,CELL_HEIGHT);
			$cr->set_source_rgb (0, 0, 0);
			$cr->set_line_width(1);
			$cr->stroke;
			$cr->save;
		}
	}

	my $cnt;
	for (my $ny = 0; $ny < CELLS_Y; $ny++){
		for (my $nx = 0; $nx < CELLS_X; $nx++){
			my $x1 = BORDER_X + ($nx * CELL_WIDTH) + ($nx * GUTTER);
			my $y1 = BORDER_Y + ($ny * CELL_HEIGHT) +($ny * GUTTER);
	 		my ($x2,$y2) = ( $x1+ (CELL_WIDTH/2),$y1+(CELL_HEIGHT/2));
			my $str = $lines[$cnt++];
			my $sentences = get_sentences($str); 	

	

			$ang += 30;
		  	switch (scalar @$sentences ) {
				case 1		{ 
					$self->{rndrtype} = FNL;
					$self->{'fntsz'} = FNL_FNT_SZ;
					$self->TextShadeFunnel(\%font,$str,$x2,$y2,CENTERX,CENTERY); 
					}
				case 2		{ 	
					$self->{rndrtype} = ANG;
					$self->{'fnsz'} = ANG_FNT_SZ;

					$self->angletext_arnd_arb_pnt(CENTERX,CENTERY,$x2,$y2,$str,\%font); 
			}else{ 	
					$self->{rndrtype} = LNG;
					$self->{'fnsz'} = LNG_FNT_SZ;
					$self->longText($str,$nx,$ny,\%font);
 				}
    		}
		
		}
	}
	#print "\n__END__";
	return TRUE;
}



sub AngleCircle{
	# given a radius and a angle in dgrees return the x and y
	# 0 degrees is 
	# origin is top left
	my ($radius,$angle_dgre) = @_;
	my $ang = &deg2rad($angle_dgre);

	return (int(sin($ang)* $radius),int(cos($ang)* $radius));
}
	
sub longText {

	my ($self,$text,$cellx,$celly,$font_Ref) = @_;
	my $cr = $self->{cr};
	my $sentences = get_sentences($text);     ## Get the sentences.
	$sentences = ($text) unless $sentences;	
	my $ang_inc = 360  / scalar @$sentences;
	my $ang_dgre = 0;#rand(15);
	#my ($xx,$yy) = (RADIUS,0);
	foreach my $sentence (@$sentences){

		my ($cntrx,$cntry) = 
			( 
			BORDER_X + ($cellx * CELL_WIDTH ) + ( (CELL_WIDTH/2) ),
			BORDER_Y + ($celly * CELL_HEIGHT) + ( (CELL_HEIGHT/2) )
		);
			my ($x,$y) = AngleCircle(RADIUS,$ang_dgre);
			my ($xx,$yy) =	(( $cntrx - (CELL_WIDTH/2))+($x + RADIUS),($cntry-(CELL_HEIGHT/2))+ ($y+RADIUS));

		$self->angletext_arnd_arb_pnt(
			$cntrx,$cntry,
			($cntrx - (CELL_WIDTH/2))+($x + RADIUS),
			($cntry- (CELL_HEIGHT/2))+ ($y+RADIUS),$sentence,
		);
		
	#	$self->TextShadeFunnel(\%font,$sentence,$xx,$yy,$cntrx,$cntry); 

		$ang_dgre += $ang_inc;
		#$cr->arc ( ($cntrx - CELL_WIDTH/2)+($x + RADIUS),
		#($cntry-CELL_HEIGHT/2)+ ($y+RADIUS), 3, 0, 2 * Math::Trig::pi);

	#dot($cntrx+$x,$cntry+$y);
	}
}
sub dot {
	my ($self,$x,$y) = @_;
	my $cr = $self->{cr};
	#$cr->set_source_rgba (0.337, 0.612, 0.117, 0.9);
	#$cr->paint;
	#$cr->restore;
	$cr->arc ($x, $y, 3, 0, 2 * Math::Trig::pi);
	#$cr->save;

}

sub text_para_prep {
	my ($self,$txt,$font_Ref,$r,$g,$b,$br,$bg,$bb,$size_pnts) = @_;

	# pango font stuff

	$font_Ref->{'string'} = $txt;
	$font_Ref->{'foreground'} = $self->rgb2hex($r,$g,$b);
	$font_Ref->{'font_size'} = $size_pnts * FONT_PNT;
	#$font_Ref->{'background'} = $self->rgb2hex($br,$bg,$bb);
$self->CFont_init($font_Ref);	
}

sub text_para_bacground 
{
	my ($self,$x,$y,$ang,$font_Ref) = @_;
	my $cr = $self->{cr};
	$self->prep_pango_text(0,0,$font_Ref); 
	my ($ink_ext,$font_ext) = $self->get_px_extents;
	
	draw_flat_rec($cr,$x,$y, %$font_ext->{width},%$font_ext->{height}*2);
	#	print "\n ";# . $self->get_px_descent;
	#foreach (keys %$ink_ext ){print " ink $_ ".%$ink_ext->{$_} }
	#print "\n";
	#foreach (keys %$font_ext ){print " font $_ ".%$font_ext->{$_} }
	#	$self->prep_pango_text(0,-(%$font_ext->{height}*0.785),$font_Ref); 
#die;
	#$cr->set_source_rgb (1, 1, 1);
	#$cr->rectangle ($x1+5, $y1+5, 280, 50);
	#$cr->fill;
}


sub text_para {
		my ($self,$x,$y,$ang,$font_Ref) = @_;
		my $cr = $self->{cr};

		#print $self->{rndrtype};
		my $radians  = deg2rad($ang);

		$cr->save;
		$cr->translate ($x, $y);
		$cr->rotate($radians);
	
		$self->prep_pango_text(0,0,$font_Ref);
		#print $font_ref->text
		$self->show_layout;
		$cr->restore;
	}

sub text_shade {
		my ($self,$x,$y,$txt,$ang,$font_Ref) = @_;
		my $cr = $self->{cr};

		#print $self->{rndrtype};
		my $radians  = deg2rad($ang);

		$cr->save;
		$cr->translate ($x, $y);
		#$cr->move_to($x, $y);
		#print "-> $x $y";
		$cr->rotate($radians);
		# pango font stuff
		$self->CFont_init($font_Ref);
		$font_Ref->{'background'} = '';
		$font_Ref->{'string'} = $txt;
		#$font_Ref->{'foreground'} = $self->rgb2hex(0,0,255);
		#print "\n".$font_Ref->{'foreground'};
		$self->prep_pango_text(0,0,$font_Ref); 
		my ($ink_ext,$font_ext) = $self->get_px_extents;
		# find the bottom of the decsender
		my $yoff = $font_Ref->{'font_size'} / FONT_PNT;
	
	#this is to draw gradiant taken off for tracy
	#	my $gradient = create_gradient($cr,0,0,0,%$ink_ext->{height});
	#	$cr->set_source($gradient);
	#	draw_flat_rec($cr,0,0, %$font_ext->{width},%$font_ext->{height});
	
	
	#	print "\n ";# . $self->get_px_descent;
	#foreach (keys %$ink_ext ){print " ink $_ ".%$ink_ext->{$_} }
	#print "\n";
	#foreach (keys %$font_ext ){print " font $_ ".%$font_ext->{$_} }
		$self->prep_pango_text(0,-(%$font_ext->{height}*0.785),$font_Ref); 
		$self->show_layout;
		$cr->restore;
	}

sub angletext_arnd_arb_pnt {
	my ($self,$cntrx,$cntry,$x,$y,$txt,$font_Ref) = @_;
	my $cr = $self->{cr};
		if($self->{rndrtype} eq ANG){
			if((length $txt) > MAX_CHAR_LENGTH_ANG){ 
				$txt = (substr $txt, 0, MAX_CHAR_LENGTH_ANG).'...';
			}
		}else{
			if((length $txt) > MAX_CHAR_LENGTH_LNG){ 
				$txt = (substr $txt, 0, MAX_CHAR_LENGTH_LNG).'...';
			}

		}
		my $ang = correct_angle($cntrx,$cntry,$x,$y);  
		$self->text_shade($x,$y,$txt,$ang,$font_Ref);

}


sub AngleOfText{
		my ($cx,$cy,$cntx ,$cnty ) = @_; 
		# work out angle of text from from centre of image given a 
	
		if (($cx == $cntx)&&($cy == $cnty)){return}
		my $rang;
		my $h = sqrt( ( $cnty-$cy)*($cnty-$cy) + ($cntx-$cx)*($cntx-$cx) );
		
								
		if($h < 0.000001) {
			$rang = 0;
		}else {
			$rang = asin(($cntx-$cx)/$h);
		}

		if(($cntx < $cx)&&($cnty < $cy)){
			# third quad			
			$rang =  (PI-$rang);
		}elsif(($cntx > $cx)&&($cnty < $cy)){
			# second quad
			$rang =  (PI/2)+((PI/2-$rang));		
		}elsif(($cntx < $cx)&&($cnty > $cy)){
			#$rang = PI+(PI/2)+((PI+(PI/2))+$rang);
		}elsif(($cntx > $cx)&&($cnty > $cy)){
				#first quad
		}
		
	return $rang;

	}


sub correct_angle {
	my ($cntrx,$cntry,$x,$y) = @_;
	my $ang;
	my $angle = &rad2deg( &AngleOfText(
			$cntrx,
			$cntry,
			$x,
			$y
		));

		if ($angle == 0){
			#print "\n here $angle";
			if($y < $cntry){	
				$ang = -90;
			}else{
				$ang = 90;
			}
		}else{
			$ang = CORRECTION_ANGLE - $angle;
			#print "\n$ang $angle";
		}
	return $ang;
}



sub TextShadeFunnel {
	my ($self,$font_Ref,$sentence,$x,$y,$cntrX,$cntrY,$scale_char) = @_;
	my $cr = $self->{cr};
	$self->{type} = 'funneltext';
print "SC $scale_char\n";
	#make mask for funnel text to get rid of 
#	# we need to go through each letter at a time
	
	my @chars = split(//, $sentence);
	if(scalar @chars > MAX_CHAR_LENGTH_FNL ){@chars = splice(@chars,0,MAX_CHAR_LENGTH_FNL ) }

	$self->CFont_init($font_Ref);
	die 'ERR NO FONT SIZE at TextShadeFunnel ' unless $font_Ref->{'font_size'};	
	my $tmp_fsize = $font_Ref->{'font_size'} / FONT_PNT ;
#	print "fsize $tmp_fsize \n";
	$font_Ref->{'background'} = '';
	my $ts_inc = $scale_char;# FNL_INC;
	#my $ts_inc = FNL_INC;
	print "INC $scale_char $ts_inc \n";
	my $ang = correct_angle($cntrX,$cntrY,$x,$y); 
	my $radians  = deg2rad(rand($ang));
	$cr->save;
	$cr->translate ($x, $y);
	my ($ink_ext,$font_ext);	
	for (my $cnt =0; $cnt <= $#chars;$cnt++){
		my $ch = $chars[$cnt];
		#if ($ch eq ' '){$chars[$cnt] = '-'}
		$font_Ref->{'font_size'} = $self->get_pnts($tmp_fsize);
		die "FONT SIZE ".$font_Ref->{'font_size'} ." over at TextFunnel 2097153 " if $font_Ref->{'font_size'} > 2097153;
		#$font_Ref->{'string'} .= "$ch";
		$font_Ref->{'string'} .= "<span size='".$font_Ref->{'font_size'}."'>$ch</span>";
		$tmp_fsize += $ts_inc;
	}
	$self->prep_pango_text(0,0,$font_Ref); 
	($ink_ext,$font_ext) = $self->get_px_extents;
	#foreach (keys %$ink_ext ){print " ink $_ ".%$ink_ext->{$_} }
	#foreach (keys %$font_ext ){print " font $_ ".%$font_ext->{$_} }
	$cr->rotate($radians);
	my $gradient = create_gradient($cr,0,0,0,%$ink_ext->{height} );
	$cr->set_source($gradient);
	draw_flat($cr,0,0,  %$ink_ext->{width},%$ink_ext->{height});
	$self->prep_pango_text(0,-(%$font_ext->{height}*0.785),$font_Ref); 
	$self->show_layout;
	$cr->restore;
}



sub init
{
	my $self = shift;
	$self->{line_width} = 0.05;
	$self->{radius}     = 0.42;
	$self->{page_width} = PAGE_WIDTH;
	$self->{page_height} = PAGE_HEIGHT;
	$self->{zmfct} = 1.0;	
	$self->{current_y} = 0;
	$self->{current_x} = 0;
	$self->{trny} = 0;
	$self->{trnx} = 0;
	@{$self->{texts}} = get_data("NaturalMedia.txt");
	$self->{init} = 0;


}

1;
