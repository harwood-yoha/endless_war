use strict;
use lib '/home/harwood/Void_Gallery/endless_war_0_5';
use WAR::CCnf;
#server stuff
use IO::Socket;
#screen stuff
use Time::HiRes qw(usleep);
# flush after every write
$| = 1; 
use Switch;

my $socket;
init_server();
unless ($socket){ die " Something's wrong w/server \n"; }

#sleep 5;
# flag to pass client info to server
my $flag;
#my $socket;
my $new_socket;
my $window;
my $c_addr;
my $status = 'IDLE';
init(); 
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
	chomp $buf;
	my @params = split(/\&/,$buf);
	my %stats;
	foreach (@params){ 
		my ($cmd,$val) = split(/\*/,$_); 
	
		
		$stats{$cmd} = $val;
		print "\n'$val' '$cmd'\n";
		if ($cmd =~ /QUIT/){last SRV;}
	}
	print "($stats{from} > 0 && $stats{to} > 0)\n";
	die "NO VALUES TO SEND $buf"  unless ($stats{from} > 0 && $stats{to} > 0);
	send_mesg($stats{from},$stats{to});
	warn "\n$buf\n";
	
	syswrite($new_socket, "$buf\n", BUFFER_SIZE);
	$new_socket->flush;
	}
    close $new_socket or die "Error: unable to close ($!)\n";
}

close_mysql();
close $socket or die "Error: unable to close ($!)\n";

sub init_server {

	$socket = IO::Socket::INET->new(
		'LocalPort' => MYSQL_PORT,
		'Proto' => 'tcp',
		'Listen' => SOMAXCONN,
		Reuse       => 1,
    	#	Timeout     => 20
) or die sprintf "ERRRR:(%d)(%s)(%d)(%s)\n", $!,$!,$^E,$^E;
}
sub init {
	
		system("xterm -geometry 212x82+0+0 -fn *-fixed-*-*-*-12-* -bg white -fg black -T 'slobb' -name 'slobb' &");
		sleep(1);
		my $str = `xwininfo -root -all | grep slobb`;
		$str =~ s/\s\s+//g;
		chomp $str;
		print "string '$str'\n";
		my @ar = split(/\s/,$str);
		#print @ar;
		my $tr = $ar[0];
		$window = $tr;
		print "\ntr '$tr'\n";
		#`xvkbd -window $self{window} -text "mysql -u root --password='YSB40_c'\r"`;

		#print "\033]0;@ARGV\007";
		`xvkbd -window $window -text "mysql -u root --password='YSB40_c'\r"`;
		sleep(2);
		`xvkbd -window $window -text "use WAR_DIARY;\r"`;
		sleep(1);
	}

	sub close_mysql {
	
		my ($self, $str) = @_;
		warn "\nCL0SSING DOWN MYSQL\n";
		`xvkbd -window $window -text "exit;\r"`;
		sleep(1);
		`xvkbd -window $window -text "exit;\r"`;
		sleep(1);

	}

	sub send_mesg {
	
		my ($from,$to) = @_;
		print "\n from $from to $to\n";
		`xvkbd -window $window -text "select Summary from war_diary where war_diary_id > '$from' and war_diary_id < '$to';\r" 2>/dev/null`;
		sleep(1);
	}

