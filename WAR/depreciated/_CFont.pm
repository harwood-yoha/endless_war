package WAR::CFont; 
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION=0.1; 

use Gtk2 -init;
use Cairo;
use strict;
use lib '.';
use WAR::CCnf;



sub prep_pango_text {
	my ($self, $x, $y,$font_Ref) = @_;
	my $cr = $self->{cr};

	die "\n ERROR no Cairo context at draw_pango_text " unless $cr;
	die "\n ERROR no string at draw_pango_text " unless $font_Ref->{'string'};
	my $string = $self->prepair_markup_str($font_Ref); 
#	$cr->save;
	$cr->move_to ($x, $y);
	$self->{layout}->set_markup($string);
	print "\n\n\n CFONT $string";
 	$self->get_metrics if DEBUG; 
	if (DEBUG) {
		$self->pango_get_para_settings if DEBUG;
		print "\n PARA_SETTINGS ";
	
		my $p = $self->{'para_settings'};
		foreach(keys %$p){
			print "\n\t $_ = " . $p->{$_}; 
			#$self->update_para_settings($_ => $p->{$_}); 
		}
	}
	
}

sub show_layout {
	my $self = shift;
	
	Gtk2::Pango::Cairo::show_layout ($self->{cr}, $self->{layout});

}

sub rgb2hex {
    my $self = shift;
    my ($r,$g,$b) = @_;
    my $hex = sprintf("%02X%02X%02X", $r, $g, $b);
    return "#$hex";
}

sub get_px_extents {
	my ($self) = @_;
	
	return $self->{layout}->get_pixel_extents;

}

sub get_px_descent {
	my ($self) = @_;
	return $self->{layout}->get_descent;

}
sub prepair_markup_str {
	my ($self,$font_Ref) = @_;

	my $str = "<span ";
	$str .= " foreground 			= '".$font_Ref->{'foreground'}."'" 			if $font_Ref->{'foreground'}; 
	$str .= " background 			= '".$font_Ref->{'background'}."'" 			if $font_Ref->{'background'}; 
	$str .= " size 					= '".$font_Ref->{'font_size'}."'" 			if $font_Ref->{'font_size'};  
	$str .= " font_family 			= '".$font_Ref->{'font_family'}."'" 		if $font_Ref->{'font_family'}; 
	$str .= " weight 				= '".$font_Ref->{'font_weight'}."'" 		if $font_Ref->{'weight'};
	$str .= " style 				= '".$font_Ref->{'font_style'}."'" 			if $font_Ref->{'style'};
	$str .= " stretch 				= '".$font_Ref->{'font_stretch'}."'" 		if $font_Ref->{'stretch'};
	$str .= " variant 				= '".$font_Ref->{'font_variant'}."'" 		if $font_Ref->{'variant'};
	$str .= " underline 			= '".$font_Ref->{'underline'}."'" 			if $font_Ref->{'underline'};
	$str .= " underline_color 		= '".$font_Ref->{'underline_color'}."'" 	if $font_Ref->{'underline_color'};
	$str .= " rise 					= '".$font_Ref->{'rise'}."'" 				if $font_Ref->{'rise'};
	$str .= " strikethrough 		= '".$font_Ref->{'strikethrough'}."'" 		if $font_Ref->{'strikethrough'}; 
	$str .= " strikethrough_color 	= '".$font_Ref->{'strikethrough_color'}."'"	if $font_Ref->{'strikethrough_color'};
	$str .= " letter_spacing 		= '".$font_Ref->{'letter_spacing'}."'" 		if $font_Ref->{'letter_spacing'};
	$str .= " gravity 				= '".$font_Ref->{'gravity'}."'" 			if $font_Ref->{'gravity'};
	$str .= " gravity_hint 			= '".$font_Ref->{'gravity_hint'}."'" 		if $font_Ref->{'gravity_hint'};
	$str .= " >". $font_Ref->{'string'}."</span>";
	return $str;

}


sub get_metrics {
	my $self = shift;
	my $label = Gtk2::Label -> new("Metrics");
	my $context = $label -> create_pango_context();
	my $font = $context -> load_font($self->{'font_desc'});
	my $language = Gtk2 -> get_default_language();
	
	#print "\n Glyph";
	#foreach my $rectangle ($font -> get_glyph_extents(23)) {
  	#	foreach my $key (qw(x y width height)) {
    #		print "\n $key = " . $rectangle -> { $key };
  	#	}
	#}
	print "\n METRICS ";
	my $metrics = $font -> get_metrics($language);
	print "\n\t asent " . $metrics -> get_ascent() / FONT_PNT ;
	print "\n\t desent " . $metrics -> get_descent() / FONT_PNT ;
	print "\n\t char width " . $metrics -> get_approximate_char_width() / FONT_PNT ;
	print "\n\t width " . ($metrics -> get_approximate_digit_width() / FONT_PNT). "\n" ;


}


sub get_pnts {
	my ($self,$pnts) = @_;
	return int(FONT_PNT * $pnts);
}


sub CFont_init {	
	my ($self,$font_Ref) = @_;

	die "\n ERROR no Cairo context at init_font " unless $self->{cr};
	die "\n ERROR no font_Ref at init_font " unless $font_Ref;

	$self->{'font_desc'} = Gtk2::Pango::FontDescription->new;

	$self->{'layout'} = Gtk2::Pango::Cairo::create_layout ($self->{cr});
#	print "\n'" .(FONT_SIZE)."'"; 
	$font_Ref->{'foreground'} 			= FOREGROUND 			unless $font_Ref->{'foreground'};
	$font_Ref->{'background'} 			= BACKGROUND 			unless $font_Ref->{'background'};
	$font_Ref->{'font_size'} 			= FONT_SIZE 			unless $font_Ref->{'font_size'};
	$font_Ref->{'font_family'} 			= FONT_FAMILY 			unless $font_Ref->{'font_family'};
	$font_Ref->{'font_weight'} 			= FONT_WEIGHT			unless $font_Ref->{'font_weight'};
	$font_Ref->{'font_style'} 			= FONT_STYLE			unless $font_Ref->{'font_style'};
	$font_Ref->{'font_stretch'} 		= FONT_STRETCH			unless $font_Ref->{'font_stretch'};
	$font_Ref->{'font_variant'} 		= FONT_VARIANT			unless $font_Ref->{'font_variant'};
	$font_Ref->{'underline'} 			= UNDERLINE 			unless $font_Ref->{'underline'}; 
	$font_Ref->{'underline_color'} 		= UNDERLINE_COLOR 		unless $font_Ref->{'underline_color'}; 	
	$font_Ref->{'rise'} 				= RISE 					unless $font_Ref->{'rise'};
	$font_Ref->{'strikethrough'} 		= STRIKETHROUGH 		unless $font_Ref->{'strikethrough'};
	$font_Ref->{'strikethrough_color'} 	= STIKETHROUGH_COLOR 	unless $font_Ref->{'strikethrough_color'};
	$font_Ref->{'letter_spacing'} 		= LETTER_SPACING 		unless $font_Ref->{'letter_spacing'}; 		
	$font_Ref->{'gravity'}  			= GRAVITY 				unless $font_Ref->{'gravity'};  	
	$font_Ref->{'gravity_hint'} 		= GRAVITY_HINT 			unless $font_Ref->{'gravity_hint'};
	
	$self->{'font_desc'}-> set_family($font_Ref->{'font_family'});
	$self->{'font_desc'}-> set_family_static($font_Ref->{'font_family'});
	$self->{'font_desc'}-> set_style($font_Ref->{'font_style'});
	$self->{'font_desc'}-> set_variant($font_Ref->{'font_variant'});
	$self->{'font_desc'}-> set_weight($font_Ref->{'font_weight'});
	$self->{'font_desc'}-> set_stretch($font_Ref->{'font_stretch'});
	$self->{'font_desc'} -> set_size($font_Ref->{'font_size'});
	#$description -> unset_fields([qw(size stretch)]);
	#$description -> merge($description, 1);
	#$description -> merge_static($description, 1);
	#$description = Gtk2::Pango::FontDescription -> from_string("Sans 12");
	$self->{'font_desc'}-> set_gravity($font_Ref->{'gravity'});
	#print "\n GET SIZE '" .( $self->{'font_desc'}->get_size )."'"; 
 
}

sub pango_get_para_settings {
	
	my $self = shift;
	my %para;
    my $layout = $self->{'layout'};
	$para{alignment} = $layout->get_alignment;
    $para{attributes} = $layout->get_attributes;
    $para{auto_dir} = $layout->get_auto_dir;
   	$para{context} = $layout->get_context;
    $para{ellipsize} = $layout->get_ellipsize;
    #my ($ink_rect, $logical_rect) = $layout->get_extents;
    #my ($ink_rect, $logical_rect) = $layout->get_pixel_extents;
    $para{font_description} = $layout->get_font_description;
    $para{indent} = $layout->get_indent;
    $para{is_ellipsized} = $layout->is_ellipsized;
    $para{is_wrapped} = $layout->is_wrapped;
    $para{layoutiter} = $layout->get_iter;
    $para{justify} = $layout->get_justify;
	$para{line_cnt} = $layout->get_line_count; 
	($para{width}, $para{height}) = $layout->get_pixel_size;
	$para{single_paragraph_mode} = $layout->get_single_paragraph_mode;
    $para{spacing} = $layout->get_spacing;
    $para{tabs} = $layout->get_tabs;
    $para{text} = $layout->get_text . " lets see if it adds this";
    $para{width} = $layout->get_width;
    $para{wrap} = $layout->get_wrap;
	
	$self->{'para_settings'} = \%para;

}

sub update_para_settings {
		# take a keyword pair and update the para setting 
        my $self = shift;
		## check we can set this keyword pair
		#
		my @allowed_setting = qw( 
			alignment attributes auto_dir ellipsize font_description indent justify 
			markup markup_with_accel single_paragraph_mode spacing tabs text width wrap	
		);
		my $allowed = 0;
		my $layout = $self->{'layout'};

        my %keyPairs = @_;
        my @query = ();
        my @keys  = keys(%keyPairs);    
		
		FOUND: foreach my $s (@allowed_setting){
			foreach (@keys) {
				if($_ eq $s){$allowed = 1;last FOUND}
			}
		}
		if($allowed){
			foreach (@keys) {
               #print "\n {'$layout->set_$_(" . $keyPairs{$_}.');}';
    			my $s = sub{'$layout->set_'.$_.'( '.$keyPairs{$_}.');'};
				eval &$s;
			   # push( @query, "$_ = " . $self->{'para_set'}->quote( $keyPairs{$_} ) );
        	}
		}else{
			die "\n ERR could not make setting '$_' at update_para_settings";
		}

}



1;

