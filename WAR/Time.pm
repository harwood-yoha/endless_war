package WAR::Time;

{
# we could do with way of controlling the timeing
# #this will vary deppending on how many summaries we need to read.
# 
# if we new how long it took to do a match we could set the server timings

	use lib 'WAR';
	use WAR::CCnf;
	use Benchmark qw(:all) ;
   	use Benchmark::Timer;
	use DateTime;
	use DateTime::Duration;




	sub new {
        my $class = shift;
        my $self  = {};		
        bless $self, $class;
        return $self;
    }


sub init {
	my ($self,$todays_rec,$total_rec) = @_;
	
	$self->init_show_start;
	$self->init_show_end;

	$self->init_start_date(USE_TODAY);
	$self->init_end_date(USE_TODAY);
	$self->{benchmark} = Benchmark::Timer->new(skip => 0);
	$self->{num_of_rec} = $todays_rec;
	$self->{num_of_total_rec} = $total_rec;

	$self->docs_to_do($self->{num_of_rec} );
	$self->{total_time} = $self->end_date_epoch  - $self->start_date_epoch;
	$self->{trgt_tm_per_rec} = 	$self->{total_time} / $self->{num_of_rec};
	$self->current_rate_epoch(-1);
}


sub time_elapsed {
	my ($self,$hum_read) = @_;
	my $time_now = DateTime->now(time_zone=>TIME_ZONE);
	my $time_elapsed = $time_now->epoch - $self->start_date_epoch;

	if(! $hum_read){
		return $time_elapsed;
	}else{
		my ($sec, $min, $hr, $day, $mon, $year) = (localtime($time_elapsed));
		return sprintf("%02d:%02d:%02d:%02d", $day - 1, $hr -1, $min, $sec);
	}
}
sub target_time_for_record {
	my ($self) = @_;
	my ($sec, $min, $hr, $day, $mon, $year) = (localtime($self->{trgt_tm_per_rec} * 1000));
	return sprintf("%02d:%02d", $min, $sec);
}
sub estimate_time_to_end_epoch {
	my ($self,$curr_num_of_rec) = @_;
	return $self->current_rate_epoch * $curr_num_of_rec;
}
sub estimate_time_to_end {
	my ($self,$curr_num_of_rec) = @_;
	my $t = $self->current_rate_epoch * $curr_num_of_rec;
	my ($sec, $min, $hr, $day, $mon, $year) = (localtime($t));
		return sprintf("%02d:%02d:%02d:%02d", $day - 1, $hr, $min, $sec);

}


sub time_to_end {
	my ($self,$hum_read) = @_;
	my $time_now = DateTime->now(time_zone=>TIME_ZONE);

	my $time_to_end =  $self->end_date_epoch - $time_now->epoch;
	if(! $hum_read){
		return $time_to_end;
	}else{
		my ($sec, $min, $hr, $day, $mon, $year) = (localtime($time_to_end));
		return sprintf("%02d:%02d:%02d:%02d", $day - 1, $hr, $min, $sec);
	}

}


sub init_start_date {

	my ($self,$opt) = @_;
	if($opt){
	#	$self->{start_date} = DateTime->new( localtime(time));
		$self->{start_date} = DateTime->now(time_zone=>'local');
	}else{
		$self->{start_date} = DateTime->new( 
		year       => START_YEAR,
      		month      => START_MONTH,
      		day        => START_DAY, 
      		hour       => START_HOUR,
      		minute     => START_MIN,
      		second     => START_SEC,
      		nanosecond => START_NANO,
      		time_zone  => TIME_ZONE,
		);
	}
	
	$self->start_date_epoch($self->{start_date}->epoch);

}
sub init_show_start {

	my ($self) = @_;
	
	$self->{start_show_date} = DateTime->new( 
		year       => START_YEAR,
      		month      => START_MONTH,
      		day        => START_DAY, 
      		hour       => START_HOUR,
      		minute     => START_MIN,
      		second     => START_SEC,
      		nanosecond => START_NANO,
      		time_zone  => TIME_ZONE,
	);
	
	
	$self->start_show_date_epoch($self->{start_show_date}->epoch);

}

sub  docs_to_do{
	my ( $self, $docs_to_do) = @_;
    
	$self->{docs_to_do} = $docs_to_do, if defined($docs_to_do);
	return $self->{docs_to_do};
}
sub  start_show_date_epoch{
	my ( $self, $start_show_date_epoch) = @_;
    
	$self->{start_show_date_epoch} = $start_show_date_epoch, if defined($start_show_date_epoch);
	return $self->{start_show_date_epoch};
}

sub  start_date_epoch{
	my ( $self, $start_date_epoch) = @_;
    
	$self->{start_date_epoch} = $start_date_epoch, if defined($start_date_epoch);
	return $self->{start_date_epoch};
}

sub current_rate_epoch  {
	my ( $self, $current_rate_epoch) = @_;
    
	$self->{current_rate_epoch} = $current_rate_epoch , if defined($current_rate_epoch);
	return $self->{current_rate_epoch};
}

sub current_rate  {
	my ( $self,) = @_;
    
	my ($sec, $min, $hr, $day, $mon, $year) = (localtime($self->current_rate_epoch));
	
	return sprintf("%02d:%02d", $min, $sec);

}

sub init_show_end {

	my ($self) = @_;


	$self->{end_show_date} = DateTime->new( 
	year       => START_YEAR,
      	month      => START_MONTH,
      	day        => START_DAY, 
      	hour       => START_HOUR,
      	minute     => START_MIN,
      	second     => START_SEC,
      	nanosecond => START_NANO,
      	time_zone  => TIME_ZONE,
	);

	my $show_duration = DateTime::Duration->new( 
	years       => 0,
      	months      => 0,
      	days        => NUMBER_OF_DAYS_TO_COMPLETE, 
      	hours       => 0,
      	minutes     => 0,
      	seconds     => 0,
      	nanoseconds => 0

	);

	$self->{end_show_date}->add_duration($show_duration);
#warn "\nend date $self->{end_date} = start date	$self->{start_date}\n";
	$self->end_show_date_epoch($self->{end_show_date}->epoch);

}

sub init_end_date {

	my ($self,$opt) = @_;


	if($opt){
	#	$self->{start_date} = DateTime->new( localtime(time));
		$self->{end_date} = DateTime->now(time_zone=>'local');
	}else{

		$self->{end_date} = DateTime->new( 
		year       => START_YEAR,
      		month      => START_MONTH,
      		day        => START_DAY, 
      		hour       => START_HOUR,
      		minute     => START_MIN,
      		second     => START_SEC,
      		nanosecond => START_NANO,
      		time_zone  => TIME_ZONE,
		);
	}
	my $show_duration = DateTime::Duration->new( 
		years       => 0,
      	months      => 0,
      	days        => 0, 
      	hours       => 12,
      	minutes     => 0,
      	seconds     => 0,
      	nanoseconds => 0
	);

	$self->{end_date}->add_duration($show_duration);
#warn "\nend date $self->{end_date} = start date	$self->{start_date}\n";
	$self->end_date_epoch($self->{end_date}->epoch);

}
sub  end_date_epoch{
	my ( $self, $end_date_epoch) = @_;
    
	$self->{end_date_epoch} = $end_date_epoch, if defined($end_date_epoch);
	return $self->{end_date_epoch};
}
sub  current_processing_rate{
	my ( $self, $current_processing_rate) = @_;
    
	$self->{current_processing_rate} = $current_processing_rate, if defined($current_processing_rate);
	return $self->{current_processing_rate};
}
sub  end_show_date_epoch{
	my ( $self, $end_show_date_epoch) = @_;
    
	$self->{end_show_date_epoch} = $end_show_date_epoch, if defined($end_show_date_epoch);
	return $self->{end_show_date_epoch};
}



}1;

