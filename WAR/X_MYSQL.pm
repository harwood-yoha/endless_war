package WAR::X_MYSQL;

{
	# leave the constants here 
	#use WAR::CCnf;
   	
	sub new {
        my $class = shift;
        my $self  = {};
        bless $self, $class;
        return $self;
    }
	sub init {
		my $self = shift;
		system("xterm -geometry 212x82+1280+0 -fn *-fixed-*-*-*-12-* -bg white -fg black -T 'slobb' -name 'slobb' &");
		sleep(1);
		my $str = `xwininfo -root -all | grep slobb`;
		$str =~ s/\s\s+//g;
		chomp $str;
		print "string '$str'\n";
		my @ar = split(/\s/,$str);
		#print @ar;
		my $tr = $ar[0];
		$self{window} = $tr;
		#print "\ntr '$tr'\n";
		#`xvkbd -window $self{window} -text "mysql -u root --password='YSB40_c'\r"`;

		#print "\033]0;@ARGV\007";
		`xvkbd -window $self{window} -text "mysql -u root --password='YSB40_c'\r"`;
		sleep(2);
		`xvkbd -window $self{window} -text "use WAR_DIARY;\r"`;
		sleep(1);
	}

	sub close {
	
		my ($self, $str) = @_;
		`xvkbd -window $self{window} -text "exit;\r"`;
		sleep(1);
		`xvkbd -window $self{window} -text "exit;\r"`;
		sleep(1);

	}

	sub send_mesg {
	
		my ($self, $str) = @_;
		`xvkbd -window $self{window} -text "$str;\r" 2>/dev/null`;
		sleep(1);
	}

}1;

