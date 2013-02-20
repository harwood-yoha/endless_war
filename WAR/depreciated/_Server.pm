use strict;
use lib 'WAR';
use Settings;
use CCnf;
#server stuff
use IO::Socket::INET;
#screen stuff
use Term::ScreenColor;
use Term::ReadKey;
#for timings
use Time::HiRes qw(usleep);
 
use Switch;

# flush after every write
$| = 1;


use constant TEXTONLINE => 2;
use constant NUM_OF_RECORDS => 40;
use constant WITH_PNG => 0;
use constant WITH_COLOUR_TERM => 0;
use constant WITH_TERM => 1;

# SCREEN CONT
#
use constant COL			=> 60;# <- from centre
use constant ROW			=> 4;
use constant COL_DATA			=> 30;# -> from centre
use constant STRING_LENGTH		=> 150;
use constant DESC_0_NAME 	=> 'SOURCE_ID';
use constant DESC_0_TXT 	=> 'Source document for ngrams';

use constant DESC_1_NAME 	=> 'SUMMARY';
use constant DESC_1_TXT 	=> 'Goods, works or services being paid for by BCC';
use constant DESC_2_NAME 	=> 'NGRAMS'; 
use constant DESC_2_TXT 	=> 'Overall service area, budget paying for goods, works or services';
use constant DESC_3_NAME 	=> 'COST CENTRE';
use constant DESC_3_TXT 	=> 'Individual cost centre for the record';

use constant SLEEP_SUMMARY =>  5000000;
use constant SLEEP_RECORD => 5000000;

### SEVER CONST
#
use constant PORT => 1234;


#set up screen
my $scr = new Term::ScreenColor;
$scr->colorizable(1);
$scr->raw();
unless ($scr) { die " Something's wrong w/screen \n"; }
init_screen();


my $socket;
init_server();
unless ($socket){ die " Something's wrong w/server \n"; }

#sleep 5;
# flag to pass client info to server
my $flag;

SRV: while (my $client = $socket->accept)
{
    my $server = gethostbyaddr($client->peeraddr, AF_INET);
    my $pt = $client->peerport;
   	while (<$client>) { 
		if (options($_) eq 'GOODBYE'){
			$_ = 'GOODBYE';
			$flag = 'EXIT';
			#echo back to client
			print $client "$.: $_"; 
			#end this statment
			close $client or die "Error: unable to close ($!)\n";
			last SRV;
		}
	
		my %display;
		$display{pt} = $pt;
		$display{war_diary_id} = '???';
		$display{text} = $_;
		$display{SRV} = $server; 
		record_txt_screen(\%display);
		#print "[$srv $pt] $_"; 
		print $client "$.: $_"; 
	}
    close $client or die "Error: unable to close ($!)\n";
}
close $socket;


sub options {
	
	my $opt = shift;
    
	switch ($opt) {
    	case 1 { print "number 1" }
    	case "a" { print "string a" }
    	case /quit/ { return 'GOODBYE' }

	#	case [1..10,42] { print "number in list" }
    #	case (\@array) { print "number in list" }
    #	case /\w+/ { print "pattern" }
    #	case qr/\w+/ { print "pattern" }
    #	case (\%hash) { print "entry in hash" }
    #	case (\&sub) { print "arg to subroutine" }
    else { 
		print "previous case not true";
	}
    }

}


sub init_server {

	$socket = IO::Socket::INET->new(
		'LocalPort' => PORT,
		'Proto' => 'tcp',
		'Listen' => SOMAXCONN) or die "Error: unable to create socket ($!)\n";
}



sub init_screen {
	# screen message

	use constant WELCOME_MSG	=> "Endless War - YoHa with Matthew Fuller";
	use constant STATUS_MSG		=> "Port: ".PORT;
#	use constant OUTPUTS	=> 	" WITH_PNG: ".WITH_PNG. 
#					" WITH_TERM: ". WITH_TERM;

	$scr->clrscr();
	my $msg_border = '+---------------------------------------------------------------------------+';
	$scr->at( 0, ($scr->cols()/2) - (length($msg_border)/2))->red()->puts($msg_border);
	$scr->at(3, ($scr->cols()/2) - (length(WELCOME_MSG)/2))->cyan('bold')->blue()->puts(WELCOME_MSG);
	$scr->at(6, ($scr->cols()/2) - (length(WELCOME_MSG)/2))->puts(STATUS_MSG);
#	$scr->at(9, ($scr->cols()/2) - (length(OUTPUTS)/2))->puts(OUTPUTS);
	$scr->at( 12, ($scr->cols()/2) - (length($msg_border)/2))->red()->puts($msg_border);

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

            #$title = " " * (($maxwidth - length($title))/2) . $title;
          return $spc.$title.$spc;
          
}
sub entity_to_screen {
	my ($ln,$entity,$atom) = @_;
	$scr->at(ROW+$ln,  ($scr->cols()/2) - COL)->clreol()->bold()->puts($entity);
	$scr->at(ROW+$ln,  ($scr->cols()/2) - COL_DATA)->clreol()->normal()->puts($atom);

}


sub to_screen_display {

	my ($display_ref) = @_;
##	$k = $scr->getch(); 
#	$scr->clrscr();
#	if($k eq 'q'){ exit;}	
#	usleep(500000);

	my $cnt = 0;
	my $msg_border = border();
	$scr->at(ROW+$cnt, ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	my $msg_name =  title_space('AFGAN WAR DIARY');
	$scr->at(ROW+$cnt, ($scr->cols()/2) - length($msg_name)/2 )->clreol()->bold()->reverse()->puts($msg_name);
	$scr->normal();
	$cnt++;
	$scr->at(ROW+$cnt,  ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;

	entity_to_screen($cnt++,"DATE:",$display_ref->{date});
entity_to_screen($cnt++,DESC_0_NAME.":",$display_ref->{src_doc});

	entity_to_screen($cnt++,DESC_1_NAME.":",$display_ref->{summary});
	entity_to_screen($cnt++,DESC_2_NAME.":",$display_ref->{ngrams});
	entity_to_screen($cnt++,DESC_3_NAME.":",$display_ref->{desc_3});
	entity_to_screen($cnt++,"PAYMENT:","£".$display_ref->{payment}.'.00');
	entity_to_screen($cnt++,"INDEX:",$display_ref->{id});
	$cnt++;
	return $cnt;

}

sub record_txt_screen {

	my ($display_ref) = @_;
#	$k = $scr->getch(); 
#	if($k eq 'q'){ exit;}	
	my $cnt = 0;
	$scr->clrscr();
#	usleep(500000);
	my $msg_border = border();
	$scr->at(ROW+$cnt, ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	my $msg_name =  title_space('RECORD TEXT');
	$scr->at(ROW+$cnt, ($scr->cols()/2) - length($msg_name.$display_ref->{war_diary_id} )/2 )->clreol()->bold()->reverse()->puts($msg_name. $display_ref->{war_diary_id});
	$scr->normal();
	$cnt++;
	$scr->at(ROW+$cnt,  ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;


	foreach (keys %$display_ref){
		#next if ($_ eq 'war_diary_id')||($_ eq 'Summary');
		entity_to_screen($cnt++,uc "$_:\t",$display_ref->{$_});
	}
	$cnt++;
	return $cnt;

}

sub change_record_to_screen {

	my ($display_ref) = @_;
#	$k = $scr->getch(); 
#	if($k eq 'q'){ exit;}	
	my $cnt = 0;
	$scr->clrscr();
#	usleep(500000);
	my $msg_border = border();
	$scr->at(ROW+$cnt, ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	my $msg_name =  title_space('CHANGE RECORD');
	$scr->at(ROW+$cnt, ($scr->cols()/2) - length($msg_name.$display_ref->{war_diary_id} )/2 )->clreol()->bold()->reverse()->puts($msg_name. $display_ref->{war_diary_id});
	$scr->normal();
	$cnt++;
	$scr->at(ROW+$cnt,  ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;


	foreach (keys %$display_ref){
		next if ($_ eq 'war_diary_id')||($_ eq 'Summary');
		entity_to_screen($cnt++,uc "$_:\t",$display_ref->{$_});
	}
	$cnt++;
	return $cnt;

}
	
sub display_src_ngrams {

	my ($display_ref) = @_;
#	$k = $scr->getch(); 
#	if($k eq 'q'){ exit;}	
	my $cnt = 0;
	$scr->clrscr();
#	usleep(500000);
	my $msg_border = border();
	$scr->at(ROW+$cnt, ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	my $msg_name =  title_space('NGRAMS');
	$scr->at(ROW+$cnt, ($scr->cols()/2) - length($msg_name.$display_ref->{war_diary_id} )/2 )->clreol()->bold()->reverse()->puts($msg_name. $display_ref->{war_diary_id});

	$scr->normal();
	$cnt++;
	$scr->at(ROW+$cnt,  ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	entity_to_screen($cnt++,"NGRAM_CHAR_LENGTH:",3 );

	foreach (keys %$display_ref){
		next if ($_ eq 'war_diary_id')||($_ eq 'Summary');
		entity_to_screen($cnt++,uc "$_:\t",$display_ref->{$_});
	}
	$cnt++;
	return $cnt;

}

sub record_to_screen_display {

	my ($display_ref) = @_;
#	$k = $scr->getch(); 
#	if($k eq 'q'){ exit;}	
	my $cnt = 0;
	$scr->clrscr();
#	usleep(500000);
	my $msg_border = border();
	$scr->at(ROW+$cnt, ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	my $msg_name =  title_space('WAR_DIARY_ID');
	$scr->at(ROW+$cnt, ($scr->cols()/2) 
	-
	length($msg_name.$display_ref->{war_diary_id} )/2 )->clreol()->bold()->reverse()->puts($msg_name.$display_ref->{war_diary_id});
	$scr->normal();
	$cnt++;
	$scr->at(ROW+$cnt,  ($scr->cols()/2) - length($msg_border)/2)->clreol()->bold()->puts($msg_border);
	$cnt+=2;
	foreach (keys %$display_ref){
		next if ($_ eq 'war_diary_id')||($_ eq 'Summary');
		entity_to_screen($cnt++,uc "$_:\t",$display_ref->{$_});
	}
	$cnt++;
	return $cnt;

}
