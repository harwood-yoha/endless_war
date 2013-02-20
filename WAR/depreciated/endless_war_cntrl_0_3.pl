use strict;
use Time::HiRes qw(usleep);

use lib '/home/harwood/Void_Gallery/endless_war_0_4';
use WAR::Ngram;
use WAR::CCnf;
use WAR::Time;

my $ngm = WAR::Ngram->new;
#start server
sleep 5;



#sanity check for server
if( WITH_SERVER){
	my $ss = SERVER_SCRIPT;
	my $s = `ps aux | grep $ss` ;
	die "\n ERR: SERVER NOT RUNNING '".SERVER_SCRIPT."'\n" unless  $s =~ 'perl '.SERVER_SCRIPT;
	$ngm->init_client;

}

if(WITH_MYSQL_WINDOW){
	$ngm->init_mysqlx;
	sleep 3;
	#die 'uninitiated';
}

my $results = $ngm->get_war_diary();
my $total_records = scalar @$results;
#get a random DOCS_PER_DAY war_id's to process

shuffle(\@$results);
my @shuffled_results = splice (@$results,1,DOCS_PER_DAY);
my $cnt = 0;
#foreach (@shuffled_results){ print "$cnt $_ \n"; $cnt++}
my $debug_id = 70844;
my %doc;
push(@shuffled_results,$debug_id);
$ngm->get_ngrams(\@shuffled_results,\%doc);
#sanity check all records have ngrams
#remove any ngrams that cannot be used to search
my $tmp_str ='';
foreach my $k ( keys %doc){
	my $ref = $doc{$k};
	if ( scalar keys %$ref < 2){
		print "removing doc $k no ngrams probably empty\n";
		 $tmp_str .= "Removing doc $k\n";
		delete $doc{$k}; 
	}
}


my $time = WAR::Time->new();
$time->init(scalar keys %doc,$total_records );
#die "	SHOW_STARTS 	=>  '$time->{start_show_date}'
#	SHOW_ENDS 	=> '$time->{end_show_date}' \n";
my %log_txt = (
	SHOW_STARTS 	=>  $time->{start_show_date},
	SHOW_ENDS 	=> $time->{end_show_date},
	DOCS_TO_PROCESS => scalar keys %doc,
);

if(WITH_LOG){
	if(NEW_LOG_DAILY){
		unlink('endless_war_log.txt') or die "COULD NOT DELETE OLD LOG FILE:".LOG_FILE."\n";
		`touch endless_war_log.txt`;	
	}
	$ngm->init_log;
	$ngm->{debug}->write_hash(\%log_txt,VITAL);
	$ngm->{debug}->write_ngm($tmp_str); 
}


# this makes it easier to follow what is hapening as hash returns unordered list
my @doc_sorted;# = sort {  $doc{$b}  <=> $doc{$a}  }  keys %doc;	
my $record = [];
my @read_doc;
my $branch_flag = 0;
#main loop
#68726
my @doc_sorted = sort {  $doc{$b}  <=> $doc{$a}  }  keys %doc;	
my $src_doc = $doc_sorted[int(rand($#doc_sorted))];
#$src_doc = $debug_id;
while ($#doc_sorted > 2) {
	$time->{benchmark}->start('whole');	

	# display current doc

	if( WITH_SERVER){
		#now using
		#$ngm->{x_mysql}->send_mesg("select * from war_diary where war_diary_id = $src_doc;");
		my %tm_disp;
		get_time_display(\%tm_disp);
		my %display = ((CNTRL_disp_record_title => $src_doc),%tm_disp);
		$ngm->{client}->send_command(\%display);
		
		wait_svr_status("ENDED_DISP_RECORD_$src_doc");
		#print "\nSTATUS /$status/ looking for $src_doc\n";
	}
	if(WITH_COLOUR_TERM){
		$ngm->disp_summary($src_doc,\%doc); 
	}

	if( WITH_SERVER){
		my %tm_disp;
		get_time_display(\%tm_disp);
		my %display = ((CNTRL_disp_summary => $src_doc),%tm_disp);
		$ngm->{client}->send_command(\%display);
		wait_svr_status("ENDED_DISP_SUMMARY_$src_doc");
		if(WITH_MYSQL_WINDOW){
		#	$ngm->{x_mysql}->send_mesg("select * from war_diary where war_diary_id < $src_doc;");
			my ($upper_rnge, $lower_rnge) = ($src_doc, $src_doc - MYSQL_LINES);
			$lower_rnge = 1 if $lower_rnge < 1;
			$upper_rnge = MYSQL_LINES if $upper_rnge < MYSQL_LINES	;	
			$ngm->{x_mysql}->send_mesg("select * from war_diary where war_diary_id < $upper_rnge and war_diary_id > $lower_rnge;");
		}	

		usleep(800000);
		
	}


	# find next document that resembles this one

	#push(@read_doc,$src_doc);

	my %best_match;
	#print "\n doc " . scalar keys %doc;
	#print "\n sored doc " . scalar @doc_sorted;
	#my ($branch,$err, $pcnt_a_b,$pcnt_b_a)= $ngm->find_similiar_doc($src_doc,\@doc_sorted,\%best_match,\%doc);
	my ($branch,$err, $pcnt_a_b,$pcnt_b_a)= $ngm->find_similiar_doc($src_doc,\%best_match,\%doc);
	die $err if $err;
	if(WITH_COLOUR_TERM){
		system('clear');	
	}

	if( WITH_SERVER){
	
		my %display = (CNTRL_match_title => $branch,src_wid => $src_doc,percent_a_b => $pcnt_a_b,percent_b_a => $pcnt_b_a);
		$ngm->{client}->send_command(\%display);
		wait_svr_status("ENDED_MATCH_TITLE_$src_doc");
	}
	if(WITH_COLOUR_TERM){
		$ngm->disp_diary($src_doc,$branch);
#		sleep 5;
			}
	if( WITH_SERVER){
		my %display = (CNTRL_match_record => $branch,src_wid => $src_doc,percent_a_b => $pcnt_a_b,percent_b_a => $pcnt_b_a);
		$ngm->{client}->send_command(\%display);
		wait_svr_status("ENDED_MATCH_RECORD_$src_doc");
				
	}
	if(WITH_COLOUR_TERM){
		system('clear');
		$ngm->disp_common($src_doc,$branch);
#		sleep 5;

	}
	delete $doc{$src_doc};
	$src_doc = $branch;
	$time->docs_to_do(scalar keys %doc);
	%best_match = undef;


	#need to resort as we delete %doc after display
	@doc_sorted = sort {  $doc{$b}  <=> $doc{$a}  }  keys %doc;	

	$time->{benchmark}->stop('whole');
	$time->current_rate_epoch($time->{benchmark}->result * 1000);
	$time->current_processing_rate($time->{benchmark}->result);

	if( WITH_LOG){
		
		my %log = (
		trgt_tm_per_rec 		=> $time->target_time_for_record,
		current_processing_rate 	=> $time->current_processing_rate,
		time_elapsed 			=> $time->time_elapsed(1),
		time_to_end 			=> $time->time_to_end(1),
		records_to_do 			=> $time->docs_to_do,
		records_total 			=> $time->{num_of_rec},
		estimate_time_end 		=> $time->estimate_time_to_end(scalar keys %doc),
		
		);
		$ngm->{debug}->write_hash(\%log,VITAL);		
	}


}

if(WITH_MYSQL_WINDOW){
	#$ngm->{debug}->write_ngm("closing MySQL window",VITAL);
	$ngm->{x_mysql}->close();
}

if( WITH_SERVER){
	my %display = (CNTRL_quit => 111);
	$ngm->{client}->send_command(\%display);
}

if(WITH_LOG){
	# goodbye message in log

	$ngm->close_log();
}

sub wait_svr_status {
	my $str = shift;
	my $s_err = 0;
	my $status = '';
	usleep(1000000);
	my ($package, $filename, $line) = caller;
	do{
		$status = $ngm->{client}->get_server_status();
		chomp $status;
		$s_err++;
	#	if ($s_err > 500){last}
		usleep(1000000);


	}while($status ne $str);
	#warn  "$package, $filename, $line ERR wait for svr $s_err \n";
	#if ($s_err > 500){ die "\nERROR $status $s_err \n"} 
}

sub get_time_display {
	
	my $hash_ref = shift;
	
	%{$hash_ref} = (
		start 		=> $time->{start_show_date},
		end 		=> $time->{end_show_date},
		time_elapsed 	=> $time->time_elapsed(1),
		time_to_end 	=> $time->time_to_end(1),
		rcrds_to_do 	=> $time->docs_to_do,
		rcrds_total 	=> $time->{num_of_total_rec}
	);

}

sub shuffle (\@) { 
    my $r=pop; 
    $a = $_ + rand @{$r} - $_ 
      and @$r[$_, $a] = @$r[$a, $_] 
        for (0..$#{$r}); 
}

# fisher_yates_shuffle( \@array ) : generate a random permutation
# of @array in place
no strict;
sub fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}


