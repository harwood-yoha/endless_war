package WAR::Debug;

{
	use Log::Trivial;
	# leave the constants here 
	use WAR::CCnf;

   	sub new {
        my $class = shift;
        my $self  = {};
	$self->{logger} = Log::Trivial->new(log_file => LOG_FILE,log_tag   => $$,  log_level => DEBUG_LEVEL);
	$self->{logger}->set_log_file(LOG_FILE) || die $This->{logger}->get_error;	

        bless $self, $class;
		
        return $self;
    }

	sub write_hash {
	
		my ($self, $display_ref,$debug_level) = @_;
		die " You need to INIT LOGGER @ write_hash\n " unless $self->{logger};	
		return if $debug_level > DEBUG_LEVEL;
		my $str =  join('', map{ " $_: ".$display_ref->{$_}." "} keys %$display_ref);
		#foreach (keys %$display_ref){
			#print "$_";
			$self->{logger}->write(
				comment =>  ,uc $str,
				level => $debug_level) 
				||
				die $self->{logger}->get_error;
		#}
	}

	sub write_ngm {
	
		my ($self, $str,$debug_level) = @_;
		my ($package, $filname,$line) = caller;
	#	print $self->{logger};
		if($debug_level <= DEBUG_LEVEL){
			$self->{logger}->write(comment =>  $str) ||  die $self->{logger}->get_error;
		}
	#print "\n\n'$str'\n\n";
	
	}

}1;

