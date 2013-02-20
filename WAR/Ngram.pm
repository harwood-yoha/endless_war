package WAR::Ngram; {

	use strict;
	use lib 'WAR';
	our $VERSION = 0.1;

	use WAR::DBD 0.1;
	use WAR::Debug;
	use WAR::CCnf;
	use WAR::X_MYSQL;
	use WAR::Client;
	#used for sorting
	use Regex::PreSuf;
	use Time::HiRes qw(usleep);
	# term stuff
	use Term::ANSIColor::Markup;
	use Term::ScreenColor;
	use Term::ReadKey;
	use Term::Size;
	#lingua libs
	use Lingua::StopWords qw( getStopWords );
	use Lingua::EN::Sentence qw( get_sentences add_acronyms );
	use Lingua::EN::Splitter qw(words);
	# ngram libs
	use Text::Ngram qw(ngram_counts add_to_counts);
	use Text::Wrap;
	use Log::Trivial;
	our @ISA = qw( WAR::DBD );	
	my ($columns, $rows) = Term::Size::chars *STDOUT{IO};	
	#use constant NUM_OF_RECORDS => 500;
	
	#setup config for ngrams
	my %config = (
		spaces 		=> 	SPACES,
		punctuation 	=>  PUNCTUATION,
		lowercase 	=>  LOWERCASE,
		flankbreaks 	=>  FLANKBREAKS
	);
	
	sub new {
    	my $class = shift;
    	my $self  = {};
        bless $self, $class;
        return $self;
    }

	sub init_mysqlx {
		my $self = shift;
		
			$self->{x_mysql} = WAR::X_MYSQL->new;
			die " NO x_mysql at Ngram init_mysql\n" unless $self->{x_mysql}  ;
			$self->{x_mysql}->init;
		
	}
	
	sub init_client {
		my $self = shift;
			$self->{client} = WAR::Client->new;
			my $err =  $self->{client}->init;
			die "Ngram init clinet - NO conection to server\n" unless $err =~ /conected/;
	}


	# link to WAR_DIARY_DB
	sub get_war_diary {
		my $self = shift; 
		$self->{dbd} = WAR::DBD->new;
		$self->{dbd}->Connect_DB;
		# get WAR_DIARY 'ids' 
		my @results = $self->{dbd}->get_war_diary_ids;
		#$self->{debug}->write_ngm( "FOUND:".$#results." RECORDS in WAR_DIARY",VITAL);
		warn "\nFOUND:".$#results." RECORDS in WAR_DIARY\n";
		return (\@results);
	}

	sub get_ngrams {
		my ($self,$results_ref,$doc_ref) = @_;
		# get all the summaries and process for ngrams
		my $cnt = 1;
		foreach my $dn (@$results_ref) {   # read each line of input
			my $ref = $self->{dbd}->get_war_diary_by_id($dn);
			if( $$ref{Summary} eq 'none'){warn "Summary eq 'none'"; next;}
			my $href = ngram_counts($$ref{Summary},NGRAM_CHARS , %config);
			#doc number - count
			$doc_ref->{$dn} = $href; 
		#	last if $cnt >= NUM_OF_RECORDS ; 
			$cnt++;
		}
	}
	
	sub get_n_gram {
		my ($self,$doc_ref,$src_doc_indx,$n_gram_ref) = @_;
		my %n_gram =  %{$doc_ref->{$src_doc_indx}};
		my ($package, $filename, $line) = caller;
		die "no ngrams get_n_gram for '$src_doc_indx' ($package, $filename, $line)" unless keys %n_gram  ;
		#return 'NO NGRAMS IN DOC'	unless keys %n_gram ;
		#if(keys %n_gram){
		if(! USE_NGRAMS_WITH_ONE_OCCURRENCE){
			%$n_gram_ref = map { $n_gram{$_} > 1 ? ($_, $n_gram{$_}) : () } keys %n_gram;
		}else{
			%$n_gram_ref = map { $_, $n_gram{$_} } keys %n_gram;
		}
		#}
		return 0;	
	}


	sub find_similiar_doc {
		my ($self,$src_doc_indx,$doc_sorted_ref,$best_match_ref,$doc_ref ) = @_;
		my ($self,$src_doc_indx,$best_match_ref,$doc_ref ) = @_;
		#print "DEBUG: docs to go through " . @$doc_sorted_ref ."\n";
		my $branch = 0;
	#	my $percent  = 0;
		my $err ='';
		my @scores;
		my $i;
		my @doc_sorted = sort {  $doc_ref->{$b}  <=> $doc_ref->{$a}  }  keys %{$doc_ref};	
		PP: foreach my $target_doc  (@doc_sorted ){
			next if $target_doc == $src_doc_indx; # compare self
			my $percent;
			$err = '';
                
			my ($prcnt_a_b,$prcnt_b_a,$err,$err_doc) =  $self->comp_lst_cmplx($doc_ref,$src_doc_indx,$target_doc);
			@{$scores[$target_doc]} = ($prcnt_a_b,$prcnt_b_a);
			# record percentage of engrams in doc

			@$best_match_ref{$target_doc} =  ($prcnt_a_b + $prcnt_b_a)/2;
		}
		
		my @sorted = sort {  $best_match_ref->{$b}  <=> $best_match_ref->{$a} }  keys %{$best_match_ref};
		my $next = shift @sorted;
		$self->{pcnt_a_b} = $scores[$next][0];
		$self->{pcnt_b_a} = $scores[$next][1];
		$self->{debug}->write_ngm("NEXT '$next' a_b = ". $scores[$next][0]." b_a =" .$scores[$next][1]); 
	#	warn "\n NEXT '$next' a_b = ". $scores[$next][0]." b_a =" .$scores[$next][1]. " \n";
	return ($next,$err,$scores[$next][0] ,$scores[$next][1] );	
	}


sub get_words_frm_summary {
	my ($self,$str) = @_;
	$str =~ 
	s{         # Substitute
     	\A      #   from the beginning of the string
     	\s\s+     #   one or more white space characters
   	}{}xms;  # with nothing

  	my $splitter = new Lingua::EN::Splitter;
	my $sentences = get_sentences($str);     ## Get the sentences.
	my $stopwords = getStopWords('en'); 
	my @all_words;
	foreach my $sentence (@$sentences) {
			my $words = $splitter->words($sentence);
			my @stem_words = map {length($_) > 1 ? $_ : () } @$words;	
			my @stopped_wrds =	grep { !$stopwords->{$_} } @stem_words;
			push(@all_words, @stopped_wrds);
        }
	return @all_words;
}

sub get_date {
	my($self) = @_;

	my ($sec, $min, $hr, $day, $mon, $year) = localtime;
	return sprintf("%02d/%02d/%04d %02d:%02d:%02d", 
    $day, $mon + 1, 1900 + $year, $hr, $min, $sec);
 
}

sub disp_summary {
	my ($self,$src_doc,$doc_ref) = @_;

	die "BAD Params('$src_doc')"  unless $src_doc;
	@{$self->{current_doc_ngram}} = keys %{$doc_ref->{$src_doc}};
#die @{$self->{current_doc_ngram}};
	my $src_ref = $self->{dbd}->get_war_diary_by_id($src_doc);
	
	my $src_summary = lc $$src_ref{Summary};
	$src_summary =~ s/</-/ig;
	$src_summary =~ s/>/-/ig;
	$src_summary =~ s{\s\s+}{\s}g;  # with nothing
	die "\nsd $src_doc" unless $src_summary;
	my @t_words = ();
	my $parser = Term::ANSIColor::Markup->new;
	my ($columns, $rows) = Term::Size::chars *STDOUT{IO};
#die "\n\n$src_summary";	
	my $nl = 0;
	($src_summary,$nl )= $self->format_summary($src_summary,\@t_words,1);

	my $line_ret = int (($rows / 2) - (($nl)/2)-4);
	#warn "\n col $rows nl $nl lr $line_ret ";
	my $c = "\n" x $line_ret ."<dark><underline>$src_summary</underline></dark>\n"; 
	$c .=  "\n" . ' ' x NGRAM_STR_TAB ."NGRAM FINGERPRINT FOR WAR_ID:$$src_ref{war_diary_id} \n\n".$self->graph_ngram($src_doc); 
	$parser->parse($c);
	if (WITH_COLOUR_TERM){
		system("clear");
		#	eval { print $parser->text }; warn $@ if $@;

			eval { print $parser->text }; warn $@ if $@;
	}
}

sub disp_diary {
	my ($self,$src_doc,$target_doc) = @_;
	die "BAD Params('$src_doc','$target_doc')"  unless $src_doc && $target_doc;
	my $src_ref = $self->{dbd}->get_war_diary_by_id($src_doc);
	my $src_summary = lc $$src_ref{Summary};
	$src_summary =~ s{\A\s\s+}{\s}xms;  # with nothing
	$src_summary =~ s/</-/ig;
	$src_summary =~ s/>/-/ig;
	my $date = $self->get_date;
	
	if($target_doc ne 'first_time'){

		my $tgt_ref = $self->{dbd}->get_war_diary_by_id($target_doc);
		my $tgt_summary = lc $$tgt_ref{Summary};
		$tgt_summary =~ s{\A\s\s+}{\s}xms;  # with nothing
		$tgt_summary =~ s/</-/ig;
		$tgt_summary =~ s/>/-/ig;
		# get the words from src and tgt
		my @s_words = $self->get_words_frm_summary($src_summary);
		my @t_words = $self->get_words_frm_summary($tgt_summary);
		#find words common to both records

		my %common;		
		$self->find_common_words(\@s_words,\@t_words,\%common);
		my $parser = Term::ANSIColor::Markup->new;
		
		my $c = "\n" . ' ' x NGRAM_STR_TAB ."WAR_DIARY_ID:<bold>[<blue>$src_doc</blue>]</bold> SHARES <bold><red>%".$self->{pcnt_a_b}."</red></bold> OF NGRAMS WITH WAR_DIARY_ID:<bold>[<blue>$target_doc</blue>]</bold>\n\n";

		$c .=  $self->graph('a',$src_doc);
		my $ln;
		($src_summary,$ln )= $self->format_summary($src_summary,\@t_words);
		$c .= "<underscore><bold>$src_summary</bold></underscore>\n"; 

		$c .= "\n" . ' ' x NGRAM_STR_TAB ."WAR_DIARY_ID:<bold>[<blue>$target_doc</blue>]</bold> SHARES <bold><red>%".$self->{pcnt_b_a}."</red></bold> OF NGRAMS WITH WAR_DIARY_ID:<bold>[<blue>$src_doc</blue>]</bold>\n\n";

		$c .=  $self->graph('b',$target_doc);
		$c .= "\n";
	
		$parser->parse($c);
		($tgt_summary,$ln )= $self->format_summary($tgt_summary,\@s_words);
		$parser->parse("<underscore><bold>$tgt_summary</bold></underscore>");
  		

		if (WITH_COLOUR_TERM){
			system("clear");
			eval { $parser->text }; die $@ if $@;

			eval {print $parser->text}; warn $@ if $@;
		}



	}
	
}
sub disp_common {
	my ($self,$src_doc,$target_doc) = @_;
	die "BAD Params('$src_doc','$target_doc')"  unless $src_doc && $target_doc;
	my $src_ref = $self->{dbd}->get_war_diary_by_id($src_doc);
	my $src_summary = lc $$src_ref{Summary};
	$src_summary =~ s{\A\s\s+}{\s}xms;  # with nothing
	my $date = $self->get_date;


	my $tgt_ref = $self->{dbd}->get_war_diary_by_id($target_doc);
	my $tgt_summary = lc $$tgt_ref{Summary};
	$tgt_summary =~ s{\A\s\s+}{\s}xms;  # with nothing

	# get the words from src and tgt
	my @s_words = $self->get_words_frm_summary($src_summary);
	my @t_words = $self->get_words_frm_summary($tgt_summary);
	#find words common to both records

	my %common;		
	$self->find_common_words(\@s_words,\@t_words,\%common);
	my $parser = Term::ANSIColor::Markup->new;
	my $line_ret = int (($rows / 2)-4);	
	#my $nude_str = "COMMON WORDS & OCCURRENCE BETWEEN CURRENT WAR_DIARY_ID:[$src_doc]& TARGET WAR_DIARY_ID:[$target_doc]";
	#my $scol = ($columns / 2) - (length( $nude_str )/ 2);  	
	#my $indent = ' ' x $scol;
	my $str = ' ' x NGRAM_STR_TAB."COMMON WORDS & OCCURRENCE BETWEEN CURRENT WAR_DIARY_ID:<bold>[<blue>$src_doc</blue>]</bold> & TARGET WAR_DIARY_ID:<bold>[<blue>$target_doc</blue>]</bold>\n";
	my $cmn = "\n" x $line_ret . $str."\n";
	$cmn .= $self->format_common(\%common);
		
		
	$parser->parse("$cmn\n");

	#	$parser->parse(' ' x NGRAM_STR_TAB . "NOW USING WAR_DIARY_ID:<bold>[<blue>$target_doc</blue>]</bold> AT <red>".$date. "</red> TO SEARCH FOR CLOSEST MATCH");

		if (WITH_COLOUR_TERM){
			system("clear");
			eval {print $parser->text}; warn $@ if $@;
		}



	
}

sub format_common {
	my ($self,$common_ref) = @_;
	my $str =  join("", map{ " $_-[$common_ref->{$_}]" } keys %$common_ref);
	my $initial_tab = ''; # Tab before first line
	my $subsequent_tab = ''; # All other lines flush left
	$Text::Wrap::columns = NGRAM_GRAPH_WIDTH;
	my @txt = split(/\n/, wrap($initial_tab, $subsequent_tab,$str));
	my $cmn_str = '';
	foreach my $t( @txt){
		my @k = split ' ', $t;
		#print "$_\n" for map {$_} @k;
		my $s = '';
		foreach(@k){
			#escape <>
			$_ =~ s/\>//g;
			$_ =~ s/\<//g;
			$_ =~ s/^(\w+)-\[(\d+)\].*/$1<bold>[<red>$2<\/red>]<\/bold>/g;
		
 
			$s .= "$_ ";
		}		
		$cmn_str .= "<clear>".' ' x NGRAM_STR_TAB."</clear>" ."$s\n"; 
	}		
	$cmn_str  = "\n$cmn_str ";
	#die; $cmn_str;
	#$summary_str =~ s{(\s)}{<on_yellow>$1</on_yellow>}g;
	return $cmn_str;

}


sub format_summary {
	my ($self,$summary,$words_ref,$opt) = @_;
	
	my %hash = map { $_ => 1 } @$words_ref;
	my $re = presuf keys %hash;

	
	my $initial_tab = ''; # Tab before first line
	my $subsequent_tab = ''; # All other lines flush left
	
	$Text::Wrap::columns = NGRAM_GRAPH_WIDTH;

	my @txt = split(/\n/, wrap($initial_tab, $subsequent_tab,$summary));
	@txt = splice(@txt,0,SHOW_SUMMARY_LINES);
	my $summary_str = '';
	foreach my $t( @txt){
#		print "'$t'";
		my $i = ($columns - length($t) )/2;
		$t =~ s{($re)}{<on_black><green>$1</green></on_black>}g;
		if($opt){
			$summary_str .= "<clear>".' ' x NGRAM_STR_TAB."</clear>" ."$t<green>".' ' x $i."\n</green>"; 
		}else{
			$summary_str .= "<clear>".' ' x NGRAM_STR_TAB."</clear>" ."$t\n"; 
	
		}
	}		
#die;
	#$summary_str  = "$summary_str ";
	$summary_str =~ s{(\s)}{<clear><on_yellow>$1</on_yellow></clear>}g;
	return ($summary_str,scalar @txt);
}

sub graph_ngram {
	# TODO if ngrams are > lne_width then only show scores > 1	
	my($self,$wid) = @_;

	my @k = @{$self->{current_doc_ngram}};	

	my @sorted = splice(@k,0,NGRAM_GRAPH_WIDTH /2);

	my ($st1,$st2,$st3);
	foreach my $c (@sorted){

		my ($st_1,$st_2,$st_3) = split(//,$c);
		$st1 .= "<red>$st_1</red><black>|</black>";
		$st2 .= "<red>$st_2</red><black>|</black>";
		$st3 .= "<red>$st_3</red><black>|</black>";
	}
	my( $i, $graph_height, $tab, $ln_wdth, $top) = ( 0, NGRAM_GRAPH_HEIGHT, NGRAM_STR_TAB  ,NGRAM_GRAPH_WIDTH, 1);

	my $str = ' ' x $tab."$st1\n".' ' x $tab."$st2\n".' ' x $tab."$st3\n";
	return $str;
}  # end sub graph

sub graph {
	# TODO if ngrams are > lne_width then only show scores > 1	
	my($self,$t,$wid) = @_;

	my @k = keys %{$self->{"n_gram_$t"}};	
	my @sorted = splice(@k,0,NGRAM_GRAPH_WIDTH /2);

	my $st0 = join("<black>|</black>", map{"<blue>". %{$self->{"n_gram_$t"}}->{$_} ."</blue>"}@sorted )."|";
	my ($st1,$st2,$st3);#	
	foreach my $c (@sorted){

		my ($st_1,$st_2,$st_3) = split(//,$c);
		$st1 .= "$st_1<black>|</black>";
		$st2 .= "$st_2<black>|</black>";
		$st3 .= "$st_3<black>|</black>";
	}
	my( $i, $graph_height, $tab, $ln_wdth, $top) = ( 0, NGRAM_GRAPH_HEIGHT, NGRAM_STR_TAB +3 ,NGRAM_GRAPH_WIDTH, 1);
	@_ = map{$self->{"n_gram_$t"}->{$_}}keys %{$self->{"n_gram_$t"}};
 	my @g = ();

	my $str = ' ' x $tab."$st1\n".' ' x $tab."$st2\n".' ' x $tab."$st3\n";
		
	for (0..$ln_wdth-1) { $top = $top > $_[$_] ? $top : $_[$_] }
	
	my $s = $top > $graph_height ? ( $top / $graph_height ) : 1;  ### calculate scale

 	for (0..$graph_height) {
	  	$g[$_] = sprintf("%".($tab-1)."d ",$_*$s) . ($_ %5 == 0 ? '__':'..') x ($ln_wdth/2);
		my $i = 0;
		for( my $ii = 0;$ii < ($ln_wdth-2);$ii+=2){
	  		substr($g[$_],$ii+$tab,2) = "*|" if $_[$i]/$s>$_;
			$i++;
		} 
	}

	join( "\n", reverse( @g ),' ' x $tab . '====' x ( $ln_wdth / 4),
 	  ' ' x $tab ."$st0\n".' ' x $tab . '====' x ( $ln_wdth / 4). "\n<bold><red>$str</red></bold>\n"
	);


	}  # end sub graph

sub graph_sorted {
	# TODO if ngrams are > lne_width then only show scores > 1	
	my($self,$t,$wid) = @_;
	my @sorted = sort { $self->{"n_gram_$t"}{$b}  <=> $self->{"n_gram_$t"}{$a}  } keys %{$self->{"n_gram_$t"}} ;
	@sorted = splice(@sorted,0,NGRAM_GRAPH_WIDTH /2);
	my $st0 = join("<black>|</black>", map{"<blue>". %{$self->{"n_gram_$t"}}->{$_} ."</blue>"}@sorted )."|";

	my ($st1,$st2,$st3);
	foreach my $c (@sorted){

		my ($st_1,$st_2,$st_3) = split(//,$c);
		$st1 .= "$st_1<black>|</black>";
		$st2 .= "$st_2<black>|</black>";
		$st3 .= "$st_3<black>|</black>";
	}
	my( $i, $graph_height, $tab, $ln_wdth, $top) = ( 0, NGRAM_GRAPH_HEIGHT, NGRAM_STR_TAB +3 ,NGRAM_GRAPH_WIDTH, 1);
	@_ = map{$self->{"n_gram_$t"}->{$_}}@sorted;
 	my @g = ();

	my $str = ' ' x $tab."$st1\n".' ' x $tab."$st2\n".' ' x $tab."$st3\n";
		
	for (0..$ln_wdth-1) { $top = $top > $_[$_] ? $top : $_[$_] }
	
	my $s = $top > $graph_height ? ( $top / $graph_height ) : 1;  ### calculate scale

 	for (0..$graph_height) {
	  	$g[$_] = sprintf("%".($tab-1)."d ",$_*$s) . ($_ %5 == 0 ? '__':'..') x ($ln_wdth/2);
		my $i = 0;
		for( my $ii = 0;$ii < ($ln_wdth-2);$ii+=2){
		#	print "\n len = ". (length $g[$_]) . " sub " . ($ii+$tab);

	  		substr($g[$_],$ii+$tab,2) = "*|" if $_[$i]/$s>$_;
			$i++;
		} 
	}
	
	join( "\n", reverse( @g ),' ' x $tab . '====' x ( $ln_wdth / 4),
 	  ' ' x $tab ."$st0\n".' ' x $tab . '====' x ( $ln_wdth / 4). "\n<bold><red>$str</red></bold>\n\n"
	);


	}  # end sub graph
	
	
	
	sub find_common_words {
		my ($self,$a_lst_ref,$b_lst_ref,$cmn_wrds_ref) = @_;
		
		my %valid_lst_a = map { $_, 1 } @$a_lst_ref;
		# find what words in list_a are also in lst_b - grep into an array
		my @wrds = grep { exists $valid_lst_a{$_} }@$b_lst_ref;
		my %c_wrds = map { $_, 1 } @wrds;
		%$cmn_wrds_ref = map{ $_, $c_wrds{$_}++} @wrds ;
	
	}

	sub comp_lst_cmplx {

		my ($self,$doc_ref,$wid_a,$wid_b) = @_;
		die "BAD Params('$wid_a','$wid_b')"  unless $wid_a && $wid_b;
		# we want to find out how many ngrams from list a are in list b
		#NEED TO FIND WHICH IS LARGEST
		my %n_gram_a;
		my %n_gram_b;
		my $err = undef;
	
		$self->get_n_gram($doc_ref,$wid_a,\%n_gram_a );
		$self->get_n_gram($doc_ref,$wid_b,\%n_gram_b );

		#create ngram finger prints

		my @doc_a =  keys %n_gram_a;
		my @doc_b =  keys %n_gram_b;
		#ngrams might be zero as we have removed all those with a count of 1 or less;
		die "no ngrams comp_lst doc_a $#doc_a wid_a '$wid_a' doc_b $#doc_b wid_b '$wid_b'" unless ($#doc_a > 0) && ($#doc_b > 0);
		#find in both
		
		my %b_hash = map { $_, 1 } @doc_b;
		my @in_both = grep {exists $b_hash{$_} }@doc_a;

		%{$self->{n_gram_a}} =  map{ $_ , $n_gram_a{$_} }@in_both;
		%{$self->{n_gram_b}} =  map{ $_ , $n_gram_b{$_} }@in_both;
		
		my $tt =0;
		#find out how many times ngrams occur doc_a
		$tt += $_ for map{ $n_gram_a{$_} } @doc_a;
		# work out the percentage of doc_a in doc_b
		my $pcnt_a = $self->find_dif($tt,\@in_both,'a','b');
		#find out how many times ngrams occur doc_b
		$tt = 0;
		$tt += $_ for map{ $n_gram_b{$_} } @doc_b;
		# work out the percentage of doc_b in doc_a
		my $pcnt_b = $self->find_dif($tt,\@in_both,'b','a');
		return ($pcnt_a,$pcnt_b); # return the percentage of doc_a ngrams in doc_b


	}

	sub find_dif {
	
		my($self,$tt,$in_both_ref,$s,$t) = @_;
		my $ngm_fract = 100 / $tt;
		#how similiar is a to b				
		my $t_score = 0;
		foreach my $i (@$in_both_ref){
			# find the weight of each word
			my $weight = (100 / $tt) *  $self->{"n_gram_$s"}{$i};
			my $n =  $self->{"n_gram_$s"}{$i} -  $self->{"n_gram_$t"}{$i};
			my $p = ($n <= 0) ? 1 : $n;
			my $similiar;
			if($p > 1){
				$similiar = ($weight /  $self->{"n_gram_$s"}{$i}) * $p;
			}else{
				$similiar = $weight; 
			}
			$t_score += $similiar;
		}

		return int($t_score)+1;

}



	sub init_log {
 		my $self = shift;
		$self->{debug} = WAR::Debug->new();
		my $welcome_str = "*" x 80;
		$welcome_str .= "\n\nENDLESS_WAR ".get_date()." $VERSION Starting up @ DEBUG level = ". DEBUG_LEVEL."\n\n";
		$welcome_str .= "*" x 80;
		$self->{debug}->write_ngm($welcome_str,VITAL);
	}
	
	sub close_log {
 		my $self = shift;
		my $goodbye_str = "ENDLESS WAR $VERSION Closing down ";
		$self->{debug}->write_ngm($goodbye_str,VITAL);
		$self->{debug} =  undef;

	}


}1;


  
