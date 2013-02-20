package WAR::Client; {

	#use strict;
	use lib 'WAR';
	our $VERSION = 0.1;
	use WAR::CCnf;
	use IO::Socket::INET;
	
	my $socket;
	my $msocket;

	
	sub new {
    		my $class = shift;
    		my $self  = {};
        	bless $self, $class;
        	return $self;
    	}


	sub init {
		my ($self,$type) = @_;
		# sanity check
		$self->{'server'} = SERVER_ADDRESS or die "Error: server name is missing\n";
		$self->{type} = $type;

		if($self->{type} ne 'mysql'){
			$self->{'port'} = PORT or die "Error: port is missing\n";
				$socket = IO::Socket::INET->new(
				'PeerAddr' => $self->{'server'},
				'PeerPort' => $self->{'port'},
				'Proto' => 'tcp',
			) 
			or 
			die "Error: Unable to create socket ($!) MAYBE YOU FORGOT TO LOAD ". SERVER_SCRIPT."\n";
		}else{
			$self->{'mysql_port'} = MYSQL_PORT or die "Error: port is missing\n";
			$msocket = IO::Socket::INET->new(
				'PeerAddr' => $self->{'server'},
				'PeerPort' => $self->{'mysql_port'},
				'Proto' => 'tcp',
			) 
			or 
			die "Error: Unable to create msocket ($!) MAYBE YOU FORGOT TO LOAD ". MYSQL_SERVER_SCRIPT."\n";

		}

		#print "Connected...\n";
		return 'conected';
	}
	sub get_server_status {
		my($self) = @_;

		my $msg = ' get status CNTRL_status*1';
		my $nonblocking = 1;
		ioctl($socket, 0x8004667e, \$nonblocking);
		$buf = "&$msg\n";
		syswrite($socket, $buf, BUFFER_SIZE);
		$socket->flush;
		sysread($socket, $buf, BUFFER_SIZE);
		$socket->flush;
		return $buf;



	}
	sub send_command {
		my($self,$msg_ref) = @_;

		my $msg = join '&', map{ "$_*$msg_ref->{$_}"} keys %{$msg_ref};
		my $nonblocking = 1;
		ioctl($socket, 0x8004667e, \$nonblocking);
		$buf = "&$msg\n";
		print "\n$buf";
		syswrite($socket, $buf,BUFFER_SIZE);
		$socket->flush;
		sysread($socket, $buf, BUFFER_SIZE);
		$socket->flush;
		$socket->flush;
		return $buf;

	}
	sub send_mysql_command {
		my($self,$msg_ref) = @_;

		my $msg = join '&', map{ "$_*$msg_ref->{$_}"} keys %{$msg_ref};
		my $nonblocking = 1;
		ioctl($msocket, 0x8004667e, \$nonblocking);
		$buf = "&$msg\n";
		print "\n$buf";
		syswrite($msocket, $buf,BUFFER_SIZE);
		$msocket->flush;
		sysread($msocket, $buf, BUFFER_SIZE);
		$msocket->flush;
		$msocket->flush;
		return $buf;

	}

	sub DESTROY {
    		my $self = shift;
       		close $self->{'socket'} or die "Error: Unable to close socket ($!)\n";

	}
}1;
