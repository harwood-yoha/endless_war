package WAR::DBD;
{
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
	$VERSION=0.1;
	use WAR::Settings;

    use DBI;
	use strict;
	use warnings;
    use constant FOUND     => 1;
    use constant NOT_FOUND => 0;

    sub new {
        my $class = shift;
        my $This  = {};

        bless $This, $class;
        return $This;
    }

    sub Connect_DB {
        my $This = shift;
        $This->{Dbh} = DBI->connect(
            MYSQL_DB,
            MYSQL_USER,
            MYSQL_PASS,
            {
                PrintError => MYSQL_PRINT_ERROR, #don't report errors via warn
                RaiseError => MYSQL_RAISE_ERROR, #Report errors via die
            }
        );
        return "ERROR: MSQL:\n Did not connect to (MYSQL){DB}: Maybe MYSQL is not setup " unless defined $This->{Dbh};
 
        return;
    }

    sub Init_DB {
        my $This = shift;
        # create the rables of the Monster
        #no strict "refs";
        my @Tables = keys(%MYSQL_TABLES);
        foreach (@Tables) {
            print "\n making table $_ ";
            my $query = $This->{Dbh}->prepare( $MYSQL_TABLES{$_} )
              or return "\n<P>ERROR: MSQL:<P>\n Can't prepare SQL $DBI::errstr\n";
            $query->execute
              or return "\n<P>ERROR: MSQL:<P>\n Can't execute SQL $DBI::errstr\n";
        }
        return;
    }

# special stuff to disconect properly from the database.
#
    sub Disconnect_DB {
        my $This = shift;
        # connect to database (regular DBI)
        $This->{Dbh}->disconnect;
        return;
    }

    sub DESTROY {
        my $This = shift;
        $This->Disconnect_DB unless not defined $This->{Dbh};

    }
    sub get_war_diary_by_id {
		# update values for an image 
        my $This = shift;
        my $id   = shift;

        if ($id) {
            my $query_str = "
			SELECT 
				* 
			FROM 
				war_diary 
			WHERE 
			war_diary_id='$id';";
            
			my $query = $This->{Dbh}->prepare($query_str);
			$query->execute;
			 my $ref = $query->fetchrow_hashref;
			$query->finish;
			return $ref;
        } else { die "<P> NO id for get_war_diary_by_id " }
		
    }
    sub search_war_diary {
		# update values for an image 
        my $This = shift;
        my $search_str   = shift;

        if ($search_str) {
            my $query_str = "
			SELECT 
				* 
			FROM 
				war_diary 
			WHERE MATCH (Summary) 
			AGAINST ( $search_str IN NATURAL LANGUAGE MODE );";
            
			my $query = $This->{Dbh}->prepare($query_str);
			$query->execute;
			my @results;
			while ( my $ref = $query->fetchrow_hashref){
				#print @str;
				push(@results,$ref);
			}
			$query->finish;
			return @results;
        } else { die "<P> NO Search str for search war diary " }
		
    }

	sub get_war_diary_ids {
		# update values for an image 
        my $This = shift;

            my $query_str = "
			SELECT 
				war_diary_id 
			FROM 
				war_diary 
9
			";
            
			my $query = $This->{Dbh}->prepare($query_str);
			$query->execute;
			my @results;
			while ( my ($id) = $query->fetchrow_array){
				#print "$id\n";
				push(@results,$id);
			}
			$query->finish;
			return @results;
		
    }


#    sub update_war_diary {
#		# update values for an image 
#        my $This = shift;
#        my $id   = shift;
#
#        if ($id) {
#            my %keyPairs = @_;
#            my @query = ();
#            my @keys  = keys(%keyPairs);
#            foreach (@keys) {
#                push( @query, "$_ = " . $This->{Dbh}->quote( $keyPairs{$_} ) );
#            }
#            my $query_str = "update student set ";
#            $query_str .= join( ", ", @query ) . " where student_id = $id";
#            my $query = $This->{Dbh}->prepare($query_str);
#            $query->execute;
#            $query->finish;
#        }
#        else { die "<P> NO student_id for update_student_DB $id" }
#
#    }
#

sub find_intersection_war_diary_by_str {
my ($self,$intersection_str) = @_;

	my $query   = $self->{Dbh}->prepare(
		"select 
			war_diary_id 
		from 
			war_diary 
		where 
		MATCH 
			(Summary) 
		AGAINST 
		('\"$intersection_str\"' IN BOOLEAN MODE)"
		); 
		$query->execute;
		my @results;
		while ( my ($id) = $query->fetchrow_array){
				#print "$id\n";
				push(@results,$id);
			}
		$query->finish;
		return @results;

}


sub find_intersection_in_war_diary {
	
	my ($self,$intersection_id) = @_;
	
	my	$query   = $self->{Dbh}->prepare(
            "SELECT 
					intersection_str 
				FROM 
					intersection 
				WHERE 
					intersection_id  = '$intersection_id';
				"
        );
        $query->execute;

		my	($intersection_str) = $query->fetchrow_array;
		$query->finish;
		$intersection_str = uc $intersection_str ;
		#print "$intersection_id = $intersection_str \n"; 
		$query   = $self->{Dbh}->prepare(
		"select 
			war_diary_id 
		from 
			war_diary 
		where 
		MATCH 
			(Summary) 
		AGAINST 
		('\"$intersection_str\"' IN BOOLEAN MODE)"
		); 
		$query->execute;
		my @results;
		while ( my ($id) = $query->fetchrow_array){
				#print "$id\n";
				push(@results,$id);
			}
		$query->finish;
		return @results;

		
}


sub update_intersection {
	
	my ($self,$int_ngram_size,$int_str,$int_occurrence) = @_;
	
	my $qint_str = $self->{Dbh}->quote($int_str);
 	#my $intersection_id = -1;
	my	$query   = $self->{Dbh}->prepare(
            "SELECT 
					intersection_id, intersection_occurrence 
				FROM 
					intersection 
				WHERE 
					intersection_str  LIKE $qint_str;
				"
        );
        $query->execute;
	my	($intersection_id,$intersection_occurrence ) = $query->fetchrow_array;
		$query->finish;

	if($intersection_id){  		
			$query = $self->{Dbh}->prepare(
                "UPDATE intersection
				SET
					intersection_occurrence = '$int_occurrence'
				WHERE 
					intersection_id='$intersection_id'"
                );
        	$query->execute;
			$query->finish;
			return $intersection_id;
	}else{
			$query = $self->{Dbh}->prepare(
            	"INSERT into intersection 
				(
					intersection_ngram_size,
					intersection_str,
					intersection_occurrence
				)
				values 
				(
					'$int_ngram_size',
					$qint_str,
					'$int_occurrence'
				)"
     );		
		$query->execute;
        $query->finish;
	}
        return ( $self->last_inserted_id('intersection') );

}



sub add_ngram_wdiary  {
	
	my ($self,$intersection_id,$war_diary_id) = @_;
	
	die if (! $intersection_id)||(! $war_diary_id);

	my	$query   = $self->{Dbh}->prepare(
            "SELECT 
					ngram_wdiary_id 
				FROM 
					ngram_wdiary 
				WHERE 
					ngram_wdiary_intersection_id = '$intersection_id'
					and
					ngram_wdiary_war_diary_id = '$war_diary_id'
					;
				"
        );
        $query->execute;
		my	($ngram_wdiary_id ) = $query->fetchrow_array;
		$query->finish;

	if($ngram_wdiary_id){  		
		return $ngram_wdiary_id;
	}else{
			$query = $self->{Dbh}->prepare(
            	"INSERT into ngram_wdiary
				(
					ngram_wdiary_intersection_id,
					ngram_wdiary_war_diary_id
				)
				values 
				(
					'$intersection_id',
					'$war_diary_id'
				)"
     );		
		$query->execute;
        $query->finish;
	}
        return ( $self->last_inserted_id('ngram_wdiary') );

}

    sub get_intersection_by_id {
		# update values for an image 
        my $This = shift;
        my $id   = shift;

        if ($id) {
            my $query_str = "
			SELECT 
				* 
			FROM 
				intersection 
			WHERE 
			intersection_id='$id';";
            
			my $query = $This->{Dbh}->prepare($query_str);
			$query->execute;
			 my $ref = $query->fetchrow_hashref;
			$query->finish;
			return $ref;
        } else { die "<P> NO student_id for update_student_DB " }
		
    }
#	ngram_war_diary => 'CREATE TABLE ngram_wdiary (
#		ngram_wdiary_id smallint  not null AUTO_INCREMENT,
#		ngram_wdiary_intersection_id  smallint not null, 
#		ngram_wdiary_war_diary_id smallint not null,
#		index (ngram_wdiary_id)
#	)
    sub last_inserted_id {
        my $This  = shift;
        my $table = shift;

        my $query =
          $This->{Dbh}->prepare("SELECT LAST_INSERT_ID() FROM $table ");
        $query->execute;
        my ($ID) = $query->fetchrow_array;

        $query->finish;

        return $ID;

    }


	sub add_war_diary {
        	my ( 	
			$This,$str
			  	) = @_;

        	#my $qstudent_name = $This->{Dbh}->quote($student_name);
	
        	my $query    = $This->{Dbh}->prepare(
            	"$str"
     		);
        	$query->execute;
		
	}
}
1;

