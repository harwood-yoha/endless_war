use strict;
use lib '/home/harwood/Void_Gallery/endless_war_0_5';
use WAR::Settings;
use WAR::CCnf;
use WAR::DBD 0.1;
#server stuff
use IO::Socket;
#screen stuff
use Text::Wrap;
use Term::Size;
use Term::ReadKey;
#for timings
use Time::HiRes qw(usleep);
# flush after every write
$| = 1; 
use Switch;
use Term::ScreenColor;
#ansicolor  $scr->putcolored('1;36;44', 'Altair');
# 	clear       => 0    black       => 30    on_black    => 40
#  	reset       => 0    red         => 31    on_red      => 41
# 	ansibold    => 1    green       => 32    on_green    => 42
#	underline   => 4    yellow      => 33    on_yellow   => 43
#	underscore  => 4    blue        => 34    on_blue     => 44
#	blink       => 5    magenta     => 35    on_magenta  => 45
#	inverse     => 7    cyan        => 36    on_cyan     => 46
#	concealed   => 8    white       => 37    on_white    => 47

use constant REC_TITLE_CLR 	=> "1;31;47";
use constant TITLE_CLR 		=> "1;31;47";
use constant BORDER_CLR 	=> "1;32;47";
use constant REC_CLR 		=> "0;30;47";
use constant BLACK_WHITE 	=> "1;30;47";
use constant STARTEND		=> "0;34;47";
use constant REC_COMP		=> "1;31;47";


# used in endless_war_server and endless_war_cntrl to keep an eye on timimg
use constant TITLE_SLEEP 	=> 2000000;
use constant MATCH_SLEEP 	=> 9300000;
use constant BLANK_SLEEP 	=> 950000;
use constant SUMMARY_SLEEP 	=> 9000000;
use constant RECORD_SLEEP 	=> 9000000;
use constant STATS_SLEEP 	=> 1200000;
use constant PROCESS_SLEEP 	=> 2000000;

#use constant TEXTONLINE 	=> 2;
#use constant NUM_OF_RECORDS 	=> 40;
#use constant WITH_PNG 		=> 0;
#use constant WITH_COLOUR_TERM 	=> 0;
#use constant WITH_TERM 		=> 1;

# SCREEN CONT 180 62
my ($columns, $rows) = Term::Size::chars *STDOUT{IO};
warn "\n($columns, $rows)  ";
use constant FOOTER			=>  57;#start footer
use constant COL			=>  28;# <- from centre
use constant HEADER			=> 3;
use constant ROW			=> 7;
use constant ROW_CENTRE 		=> 30;
use constant COL_DATA			=> 30;# -> from centre
use constant REC_ENTITY			=> 20;# <- from centre
use constant REC_DATA			=> 5;# -> from centre

use constant STRING_LENGTH		=> 170;
use constant DESC_0_NAME 	=> 'SOURCE_ID';
use constant DESC_0_TXT 	=> 'Source document for ngrams';

use constant DESC_1_NAME 	=> 'SUMMARY';
use constant DESC_1_TXT 	=> 'Goods, works or services being paid for by BCC';
use constant DESC_2_NAME 	=> 'NGRAMS'; 
use constant DESC_2_TXT 	=> 'Overall service area, budget paying for goods, works or services';
use constant DESC_3_NAME 	=> 'COST CENTRE';
use constant DESC_3_TXT 	=> 'Individual cost centre for the record';



### SEVER CONST
#
#use constant PORT => 1234;
my %stats;



#set up screen
my $scr = new Term::ScreenColor;
$scr->colorizable(1);
$scr->raw();
#$scr->cols(COL + COL_DATA);
unless ($scr) { die " Something's wrong w/screen \n"; }
init_screen();

my $dbd = 0; 
my $socket;
init_server();
unless ($socket){ die " Something's wrong w/server \n"; }

#sleep 5;
# flag to pass client info to server
my $flag;
#my $socket;
my $new_socket;
my $c_addr;
my $status = 'IDLE';
SRV: while (($new_socket,$c_addr) = $socket->accept()) {
	my ($client_port, $client_ip) = sockaddr_in($c_addr); 
	my $client_ipnum = inet_ntoa($client_ip); 
	my $client_host =gethostbyaddr($client_ip, AF_INET); 
	while ($new_socket){
	my $nonblocking = 1;
	ioctl($new_socket, 0x8004667e, \$nonblocking);
	my $buf;
	sysread($new_socket, $buf, BUFFER_SIZE);
	$new_socket->flush;

	my $return_code = options($buf); 
	syswrite($new_socket, "$return_code\n", BUFFER_SIZE);
		if ($return_code eq 'GOODBYE'){
			$status = 'SHUTING DOWN';
			sleep 3;# wait for client to close
			last SRV;
	}	
		#print $client "$status\n";
		#$client->flush; 
	#}
	$new_socket->flush;
	}
    close $new_socket or die "Error: unable to close ($!)\n";
}

$scr->clrscr();
close $socket or die "Error: unable to close ($!)\n";


sub options {
	
	my ($opt_str) = shift;
	#find cntrl string
	my @cntl = map { $_ =~ q/CNTRL/ ? $_ : () } split(/\&/,$opt_str);
	
	my ($cntrl,$cmd) = split(/\*/, shift @cntl);
	# no contrl no can do
	die "ERR: $opt_str no control string '$cntrl'\n" unless $cntrl;
	#die "ERR: no command string $cmd\n" unless $cmd;

	my $display;
	switch ($cntrl) {
    		case /CNTRL_quit/ {
			#print "cmnd $cmd"; 
			$status = 'GOODBYE';
			return 'GOODBYE';
		}
    		case /CNTRL_disp_record_title/ { 

				my $display = $dbd->get_war_diary_by_id($cmd);
				process_to_screen('TITLE OF WAR_ID:'.$display->{war_diary_id}); 
				disp_title_of_record($display);
				usleep(TITLE_SLEEP);
				blank_to_screen(); 
				$status = "ENDED_DISP_RECORD_".$display->{war_diary_id};
				my @params = split(/\&/,$opt_str);
				foreach (@params){ 
					my ($cmd,$val) = split(/\*/,$_); 
					$stats{$cmd} = $val unless $cmd =~ /CNTRL_/;
				#	print "\n$val $cmd\n";
				}

				return $status;
			}
		case /CNTRL_disp_summary/ { 

				my $display = $dbd->get_war_diary_by_id($cmd);
				process_to_screen('GENERATED NGRAM FINGER PRINT FOR WAR_ID:'.$display->{war_diary_id}); 
				process_to_screen('DISPLAY SUMMARY OF WAR_ID:'.$display->{war_diary_id});
				disp_summary_of_record($display);
				$status = "ENDED_DISP_SUMMARY_".$display->{war_diary_id};
				my @params = split(/\&/,$opt_str);

				foreach (@params){ 
					my ($cmd,$val) = split(/\*/,$_); 
					$stats{$cmd} = $val unless $cmd =~ /CNTRL_/;
				#	print "\n$val $cmd\n";
				}

				return $status;

			}
		case /CNTRL_match_title/ { 
				my @params = split(/\&/,$opt_str);
				my %p;
				foreach (@params){ 
					my ($cmd,$val) = split(/\*/,$_); 
					$p{$cmd} = $val;
				}				
				#sanity check
				if (! $p{src_wid} ) {die "ERRR: NO Source WID"};
				if ( $p{percent_b_a} == undef) {die "ERRR: NO percent WID"};
				if ( $p{percent_a_b} == undef) {die "ERRR: NO percent WID"};

				my $display_src = $dbd->get_war_diary_by_id($p{src_wid});
				$display_src->{percent_a_b} = $p{percent_a_b};
				my $display_nxt = $dbd->get_war_diary_by_id($cmd);
				$display_nxt->{percent_b_a} = $p{percent_b_a};
				blank_to_screen();

				process_to_screen('FOUND MATCH'); 
				my $str = "WAR ID ".$display_src->{war_diary_id}." IS %".$display_src->{percent_a_b}. " SIMILAR TO WAR_ID ".$display_nxt->{war_diary_id}." WHICH IS %".$display_nxt->{percent_b_a}. " SIMILAR TO WAR_ID ".$display_src->{war_diary_id};
				process_to_screen($str);
				usleep(7000000); 
				disp_title_of_src_nxt($display_src,$display_nxt);
				process_to_screen('RETRIEVING HEADERS FROM NGRAM MATCH'); 
				blank_to_screen(); 
				$status = "ENDED_MATCH_TITLE_".$display_src->{war_diary_id};

				
				return $status;

				
				#return 'MATCH';
		}
		case /CNTRL_match_record/ { 
				my @params = split(/\&/,$opt_str);
						#	shift @params;# get rid of cntrl string
				my %p;
				foreach (@params){ 
					my ($cmd,$val) = split(/\*/,$_); 
					$p{$cmd} = $val;
				}				
				#sanity check
				if (! $p{src_wid} ) {die "ERRR: NO Source WID"};
				if ( $p{percent_b_a} == undef) {die "ERRR: NO percent WID"};
				if ( $p{percent_a_b} == undef) {die "ERRR: NO percent WID"};

				my $display_src = $dbd->get_war_diary_by_id($p{src_wid});
				$display_src->{percent_a_b} = $p{percent_a_b};
				my $display_nxt = $dbd->get_war_diary_by_id($cmd);
				$display_nxt->{percent_b_a} = $p{percent_b_a};
				process_to_screen('RECORD HEADERS FROM NGRAM ANALYSIS');
				disp_match_record($display_src,$display_nxt); 
				blank_to_screen();
				#disp_summary_of_record($display);
				#blank_to_screen();
				$status = "ENDED_MATCH_RECORD_".$display_src->{war_diary_id};

				return $status;

				#return 'MATCH';
			}
			case /CNTRL_current_timing/ { 
								#$stats{currrent_time_taken} = $cmd;
				my @params = split(/\&/,$opt_str);
			#	shift @params;# get rid of cntrl string
				foreach (@params){ 
					my ($cmd,$val) = split(/\*/,$_); 
					$stats{$cmd} = $val unless $cmd =~ /CNTRL_/;
				}
				$status = "CURRENT_TIMING_START";
				
				disp_timmings(\%stats);
				blank_to_screen(); 
				$status = "CURRENT_TIMING_END";
				return $status;

				#return 'TIMING';
			}
			case /CNTRL_status/ {return $status;}
			case /CNTRL_init/ { return 'INIT'}


    		case /quit/ { return 'GOODBYE' }

    else { 
		print "previous case not true";
	}
    }

}


sub init_server {

	$socket = IO::Socket::INET->new(
		'LocalPort' => PORT,
		'Proto' => 'tcp',
		'Listen' => SOMAXCONN,
		Reuse       => 1,
    	#	Timeout     => 20
) or die sprintf "ERRRR:(%d)(%s)(%d)(%s)\n", $!,$!,$^E,$^E;
	$dbd = WAR::DBD->new;
	die "ERR: Could not connect to MySQL Server" unless $dbd;
	my $err = $dbd->Connect_DB;
	die if $err;
}



sub init_screen {
	# screen message

	use constant WELCOME_MSG	=> "Endless War - YoHa with Matthew Fuller (Work in Progresss, April 2012) " ;
	use constant STATUS_MSG		=> "Port: ".PORT;
	my $outputs = 	'WITH_MYSQL WINDOW' 		if WITH_MYSQL_WINDOW;
	$outputs .= 	' WITH_COLOUR_TERM' 		if WITH_COLOUR_TERM;
	$outputs .= 	' WITH_SERVER' 			if WITH_SERVER; 	
	$outputs .= 	' WITH_LOG' 			if WITH_LOG;		
	$outputs .= 	' NEW_LOG_DAILY' 		if 	NEW_LOG_DAILY;		
	$outputs .= 	' DOCS_PER_DAY:'.DOCS_PER_DAY 	if 	DOCS_PER_DAY;
	my $cnt = disp_header(undef); 
	$cnt += 10;
	my $msg_border = '+---------------------------------------------------------------------------+';
	$scr->at($cnt+=2,  ($scr->cols()/2) - (length($msg_border)/2))->putcolored(BORDER_CLR,$msg_border);
	$scr->at($cnt+=2,  ($scr->cols()/2) - (length(WELCOME_MSG)/2))->putcolored(TITLE_CLR ,WELCOME_MSG.$scr->cols());
	$scr->at($cnt+=2,  ($scr->cols()/2) - (length(WELCOME_MSG)/2))->puts(STATUS_MSG);
	$scr->at($cnt+=2,  ($scr->cols()/2) - (length($outputs)/2))->puts($outputs);
	$scr->at($cnt+=2, ($scr->cols()/2) - (length($msg_border)/2))->putcolored(BORDER_CLR,$msg_border);
	disp_footer();
	$scr->at(0,0);
	#### end init screen
}
sub border {
	my $str = '';
	my $l = (STRING_LENGTH + COL_DATA)- COL;
	foreach(0..$l){$str .= '_'};
	return $str;
}
sub title_space {
	my $title = shift;          
	my $maxwidth = (STRING_LENGTH + COL_DATA)- COL;
        $maxwidth = length($title) if length($title) > $maxwidth;
        my $spc = '';  
        foreach( 0..($maxwidth - length($title))/2){
		$spc .= ' ';
	}

       return $spc.$title.$spc;
          
}

sub clear_rec {
	my ($header,$footer) = @_;
	
	for(my $cnt = $header;$cnt <= $footer;$cnt++){
	$scr->at($cnt,1)->clreol();

	}

}


sub entity_to_screen {
	my ($ln,$entity,$atom) = @_;
	$scr->at(ROW+$ln,  ( $scr->cols() / 2 ) - COL )->clreol()->bold()->puts($entity);
	$scr->at(ROW+$ln,  ($scr->cols()/2) - COL_DATA)->clreol()->normal()->puts($atom);
	$scr->at(0,0);
}

sub color_entity_to_screen {
	my ($ln,$entity,$atom) = @_;
	$scr->at(ROW+$ln,  ( $scr->cols() / 2 ) - REC_ENTITY)->clreol()->putcolored(REC_CLR,$entity);
	$scr->at(ROW+$ln,  ( $scr->cols() / 2 ) + REC_DATA)->clreol()->putcolored(REC_CLR,$atom);
i	$scr->at(0,0);
}
sub blank_to_screen {
	clear_rec(HEADER +10,FOOTER);
	usleep(BLANK_SLEEP);
	$scr->at(0,0);

}

sub process_to_screen {
	my ($process) = @_;
	clear_rec(HEADER+10,FOOTER);
	my $cnt =  ROW_CENTRE;
	$scr->at($cnt, ( ($scr->cols()/2) - length( $process) / 2 ))->clreol()->putcolored(BLACK_WHITE , $process);
	usleep(PROCESS_SLEEP);
	$scr->at(0,0);

}


sub disp_footer {

	my $cnt = FOOTER;
	my $msg_border = border();
	$scr->at($cnt, ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	my $msg_name =  title_space('ENDLESS WAR');
	$scr->at($cnt, ($scr->cols()/2) - length($msg_name)/2 )->clreol()->bold()->reverse()->puts($msg_name);
	$scr->normal();
	$cnt++;
	$scr->at($cnt,  ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	$scr->at($cnt,  ( $scr->cols() / 2 ) - length($msg_border) / 2 )->clreol()->putcolored(BLACK_WHITE,"TOTAL RECORDS: ");
	$scr->at($cnt,  ((( $scr->cols() / 2 ) - length($msg_border) / 2 ))+length("TOTAL RECORDS: "))->clreol()->putcolored(STARTEND,$stats{rcrds_total});
	$scr->at($cnt,  ( $scr->cols() / 2 ) - length("TIME REMAINING: " )  )->clreol()->putcolored(BLACK_WHITE,"TIME REMAINING: ");
	$scr->at($cnt,  ( $scr->cols() / 2 ) )->clreol()->putcolored(STARTEND,$stats{time_to_end});

	$scr->at($cnt,    ( ( ( $scr->cols() /2 ) - length($msg_border)/2 ) + length($msg_border)) - length("RECORDS REMAINING: ".$stats{rcrds_to_do})  )->clreol()->putcolored(BLACK_WHITE,"RECORDS REMAINING: ");
	
$scr->at($cnt,    ( ( ( $scr->cols() /2 ) - length($msg_border)/2 ) + length($msg_border)) - length($stats{rcrds_to_do})  )->clreol()->putcolored(STARTEND,$stats{rcrds_to_do});
	$cnt++;
	$scr->at($cnt, ( $scr->cols() / 2 ) - length($msg_border) / 2 )->clreol()->bold()->puts($msg_border);
	$scr->at(0,0);

	return $cnt;

}

sub to_screen_display {

	my ($display_ref) = @_;
#	usleep(500000);

	my $cnt = ROW;
	my $msg_border = border();
	$scr->at($cnt, ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	my $msg_name =  title_space('AFGHAN WAR DIARY');
	$scr->at($cnt, ($scr->cols()/2) - length($msg_name)/2 )->clreol()->bold()->reverse()->puts($msg_name);
	$scr->normal();
	$cnt++;
	$scr->at($cnt,  ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;

	entity_to_screen($cnt++,"DATE:",$display_ref->{date});
entity_to_screen($cnt++,DESC_0_NAME.":",$display_ref->{src_doc});

	entity_to_screen($cnt++,DESC_1_NAME.":",$display_ref->{summary});
	entity_to_screen($cnt++,DESC_2_NAME.":",$display_ref->{ngrams});
	entity_to_screen($cnt++,DESC_3_NAME.":",$display_ref->{desc_3});
	entity_to_screen($cnt++,"PAYMENT:","£".$display_ref->{payment}.'.00');
	entity_to_screen($cnt++,"INDEX:",$display_ref->{id});
	$cnt++;
	$scr->at(0,0);

	return $cnt;

}


sub disp_title_of_src_nxt {

	my ($display_src_ref,$display_nxt_ref) = @_;
#	my $cnt = ROW;
	#$scr->clrscr();
	my $cnt = disp_header($display_src_ref,$display_nxt_ref); 
	clear_rec($cnt,FOOTER);
	my $cnt  = ROW_CENTRE - 3;

#	$scr->at($cnt++, ($scr->cols()/2) - length($str  ) / 2 )->clreol()->putcolored(BLACK_WHITE ,$str );

	my $str1 = "WAR ID ".$display_src_ref->{war_diary_id}." TITLE:";
	$scr->at($cnt, ( $scr->cols()/2) - length( $str1.$display_src_ref->{Title}) / 2 )->clreol()->putcolored(BLACK_WHITE ,$str1 );
	
	$scr->at($cnt++, (($scr->cols()/2) - length( $str1.$display_src_ref->{Title}) / 2)+ length($str1)  )->clreol()->putcolored(REC_TITLE_CLR ,$display_src_ref->{Title});
	$cnt++;
	my $str2 = "WAR ID ".$display_nxt_ref->{war_diary_id}." TITLE:";

	$scr->at($cnt, ( $scr->cols()/2) - length( $str2.$display_nxt_ref->{Title}) / 2 )->clreol()->putcolored(BLACK_WHITE ,$str2 );
	$scr->at($cnt++, (($scr->cols()/2) - length($str2.$display_nxt_ref->{Title}) / 2)+length($str2)  )->clreol()->putcolored(REC_TITLE_CLR ,$display_nxt_ref->{Title});

	disp_footer();
	$scr->at(0,0);

	usleep(MATCH_SLEEP);

}

sub disp_title_of_record {

	my ($display_ref) = @_;
#	my $cnt = ROW;
	#$scr->clrscr();
	my $cnt = disp_header($display_ref); 
	clear_rec($cnt,FOOTER);
	my $cnt =  ROW_CENTRE;
#	$scr->at($cnt, ( ($scr->cols()/2) - length( "WAR_ID:".$display_ref->{war_diary_id}." TITLE:") / 2 ) - 40)->clreol()->putcolored(BLACK_WHITE , "WAR_ID:".$display_ref->{war_diary_id}." TITLE:");

	$scr->at($cnt,  ($scr->cols()/2) - length($display_ref->{Title})/2)->clreol()->putcolored(REC_TITLE_CLR ,$display_ref->{Title});
	disp_footer();
	$scr->at(0,0);


}


sub disp_summary_of_record {

	my ($display_ref) = @_;
	my $cnt = disp_header($display_ref); 
	my $initial_tab = ''; # Tab before first line
	my $subsequent_tab = ''; # All other lines flush left
	#"$_ <bold>[<red>$common{$_}</red>]</bold> " 
	my $SUMMARY_COLOUMNS = 120;
	$Text::Wrap::columns = $SUMMARY_COLOUMNS ;
	my @txt = split(/\n/, wrap($initial_tab, $subsequent_tab,$display_ref->{Summary}));
	@txt = splice(@txt,0,SHOW_SUMMARY_LINES);
	my $start_pnt = (ROW + ((FOOTER - ROW) / 2)) - ( int (scalar @txt / 2) );
	$cnt = $start_pnt;
	foreach my $t( @txt){

	$scr->at($cnt++,  ($scr->cols()/2) - ($SUMMARY_COLOUMNS / 2) )->clreol()->putcolored(REC_TITLE_CLR ,$t);
	}
	disp_footer();
	$scr->at(0,0);

	usleep(SUMMARY_SLEEP);

}

sub disp_header {
	my ($display_ref,$tgt_ref) = @_;
	my $cnt = HEADER;
	
	$scr->clrscr();
#	usleep(500000);
	my $msg_border = border();
	$scr->at($cnt,  ( $scr->cols() / 2 ) - length($msg_border) / 2 )->clreol()->bold()->puts($msg_border);
	$cnt+=2;

	$stats{start} =~ s/^(\d\d\d\d)-(\d\d)-(\d\d)T\d\d:\d\d:\d\d/$3\/$2\/$1/;
	$scr->at($cnt,  ( $scr->cols() / 2 ) - length($msg_border) / 2 )->clreol()->putcolored(BLACK_WHITE,"STARTED: ");
	$scr->at($cnt,  ((( $scr->cols() / 2 ) - length($msg_border) / 2 ))+length("STARTED: "))->clreol()->putcolored(STARTEND,$stats{start});

	$scr->at($cnt,  ( $scr->cols() / 2 ) - length("BATCH COMPLETION: " )  )->clreol()->putcolored(BLACK_WHITE,"BATCH COMPLETION: ");
	$scr->at($cnt,  ( $scr->cols() / 2 ) )->clreol()->putcolored(STARTEND,$stats{time_to_end});


	$stats{end}  =~ s/^(\d\d\d\d)-(\d\d)-(\d\d).+/$3\/$2\/$1/;
	my $dif = ($scr->cols() - length($msg_border))/2;
	$scr->at($cnt, $scr->cols()  - (length("ENDING: ".$stats{end})+$dif) )->clreol()->putcolored(BLACK_WHITE,"ENDING: ");
	$scr->at($cnt, $scr->cols() - (length("$stats{end}") + $dif) )->clreol()->putcolored(STARTEND,$stats{end});

	$cnt++;
	$scr->at($cnt,  ( $scr->cols() / 2 ) - length($msg_border) / 2 )->clreol()->bold()->puts($msg_border);
	$scr->at($cnt, ( $scr->cols() / 2 ) - length($msg_border) / 2 )->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	my $msg_name;
	if(! $tgt_ref){
	$msg_name =  title_space('WAR_ID:'.$display_ref->{war_diary_id});	
	$scr->at($cnt, ( $scr->cols() / 2 ) - length($msg_name ) / 2 )->clreol()->bold()->reverse()->puts($msg_name);
	}else{
	$msg_name =  title_space('WAR_ID '. $tgt_ref->{war_diary_id}.'<- MATCH -> WAR_ID '.$display_ref->{war_diary_id});	$scr->at($cnt, ( $scr->cols() / 2 ) - length($msg_name ) / 2 )->clreol()->bold()->reverse()->puts($msg_name);

	}
	
	
	$scr->normal();
	$cnt++;
	$scr->at($cnt,  ( $scr->cols() / 2 ) - length($msg_border) / 2 )->clreol()->bold()->puts($msg_border);
	$scr->at(0,0);

	#$cnt+=2;

return ++$cnt;

}
sub disp_timmings {

	my ($display_ref) = @_;
	
#	$scr->clrscr();
	my $cnt = disp_header($display_ref);
#	my $cnt = 20;
	clear_rec($cnt,FOOTER);
	foreach (keys %$display_ref){
	#	next if ($_ eq 'war_diary_id')||($_ eq 'Summary');
		color_entity_to_screen($cnt++,uc "$_:\t",$display_ref->{$_});
	}
	$cnt++;
	disp_footer();
	$scr->at(0,0);

	usleep(STATS_SLEEP);

	return $cnt;

}

sub disp_record {

	my ($display_ref) = @_;
	
#	$scr->clrscr();
	my $cnt = disp_header($display_ref); 
	clear_rec($cnt,FOOTER);
	foreach (keys %$display_ref){
		next if ($_ eq 'war_diary_id')||($_ eq 'Summary');
		color_entity_to_screen($cnt++,uc "$_:\t",$display_ref->{$_});
	}
	$cnt++;
	disp_footer();
	$scr->at(0,0);

	usleep(RECORD_SLEEP);

	return $cnt;

}

sub disp_match_record {

	my ($src_ref,$tgt_ref) = @_;
	
#	$scr->clrscr();
	my $cnt = disp_header($src_ref,$tgt_ref); 
	clear_rec($cnt,FOOTER);
	#$cnt;
	foreach (keys %$src_ref){
		next if (($_ eq 'war_diary_id')||($_ eq 'Summary')||($_ eq 'Title'));
		my $str1 =  $src_ref->{$_};
		$str1 =~ s/^\s+//; #remove leading spaces
		$str1 =~ s/\s+$//; #remove trailing spaces
		my $str2 =   uc " <- $_ -> ";
		my $str3 =  $tgt_ref->{$_};
		$str3 =~ s/^\s+//; #remove leading spaces
		$str3 =~ s/\s+$//; #remove trailing spaces

				#$cnt++;
		$scr->at(ROW+$cnt,  ( $scr->cols() / 2 ) - length($str1.$str2.$str3)/2 )->clreol()->putcolored(REC_CLR,$str1);
		$scr->at(ROW+$cnt,  ( $scr->cols() / 2 ) - length($str2)/2 )->clreol()->putcolored(REC_COMP,$str2);
		$scr->at(ROW+$cnt,  ( ($scr->cols() / 2 ) - length($str1.$str2.$str3)/2)+length($str1.$str2) )->clreol()->putcolored(REC_CLR,$str3);
	$cnt++;
	}
		disp_footer();
	$scr->at(0,0);

	usleep(RECORD_SLEEP);

	return $cnt;

}

sub change_record_to_screen {

	my ($display_ref) = @_;
	my $cnt = ROW;
#	$scr->clrscr();
	clear_rec($cnt,FOOTER);
#	usleep(500000);
	my $msg_border = border();
	$scr->at($cnt, ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	my $msg_name =  title_space('CHANGE RECORD');
	$scr->at($cnt, ($scr->cols()/2) - length($msg_name.$display_ref->{war_diary_id} )/2 )->clreol()->bold()->reverse()->puts($msg_name. $display_ref->{war_diary_id});
	$scr->normal();
	$cnt++;
	$scr->at($cnt,  ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;


	foreach (keys %$display_ref){
		next if ($_ eq 'war_diary_id')||($_ eq 'Summary');
		entity_to_screen($cnt++,uc "$_:\t",$display_ref->{$_});
	}
	$cnt++;
	$scr->at(0,0);

	return $cnt;

}
	
