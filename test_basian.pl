use Algorithm::NaiveBayes;
use strict;

use lib '/home/harwood/Void_Gallery/endless_war_0_5';
use WAR::Ngram;
use WAR::CCnf;

my $ngm = WAR::Ngram->new;
#start server
sleep 5;


my $results = $ngm->get_war_diary();
my $total_records = scalar @$results;
#get a random DOCS_PER_DAY war_id's to process

#shuffle(\@$results);
my @shuffled_results = splice (@$results,1,DOCS_PER_DAY);
my $cnt = 0;
#foreach (@shuffled_results){ print "$cnt $_ \n"; $cnt++}
my $debug_id = 64813;
my %doc;
push(@shuffled_results,$debug_id);
$ngm->get_ngrams(\@shuffled_results,\%doc);
#sanity check all records have ngrams
#remove any ngrams that cannot be used to search
my $nb = Algorithm::NaiveBayes->new;

my $str_ind = 5000;
my $cnt = 0;
foreach my $k ( keys %doc){
	my $ref = $doc{$k};
	  $nb->add_instance(attributes => $ref,label => $k);

#	if ( scalar keys %$ref < 2){
#		print "removing doc $k no ngrams probably empty\n";
#		 $tmp_str .= "Removing doc $k\n";
#		delete $doc{$k}; 
#	}
last if $cnt++ > $str_ind;
}
 $nb->train;
for( my $k =$str_ind;$k <= 5050; $k++){
	my $ref = $doc{$k};
	 # $nb->add_instance(attributes => $ref,label => $k);
	my $result = $nb->predict(attributes => $ref);
	#print keys %{$result};
	foreach (keys %{$result}){
	print "$_ ". $result->{$_} ."\n";

	}

}


#  $nb->add_instance
 #   (attributes => {foo => 1, bar => 1, baz => 3},
  #   label => 'sports');
  
  #$nb->add_instance
   # (attributes => {foo => 2, blurp => 1},
    # label => ['sports', 'finance']);

  #... repeat for several more instances, then:
   
  # Find results for unseen instances
  #my $result = $nb->predict
  #  (attributes => {bar => 3, blurp => 2});
