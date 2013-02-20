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
		die " You need to INIT LOGGER\n " unless $self->{logger};
		return if $debug_level > DEBUG_LEVEL;

		foreach (keys %$display_ref){
			$self->{logger}->write(
				comment =>  ,uc "$_:\t",$display_ref->{$_},
				level => $debug_level) 
				||
				die $self->{logger}->get_error;
		}
	}

	sub write {
	
		my ($self, $str,$debug_level) = @_;
		die " You need to INIT LOGGER\n " unless $self->{logger};
		if($debug_level <= DEBUG_LEVEL){
			$self->{logger}->write(comment =>  "$str",level => $debug_level) ||  die $self->{logger}->get_error;
		}
	}

}1;

