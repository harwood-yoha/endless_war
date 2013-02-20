package WAR::Settings;
#use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
our $VERSION=0.1;

require Exporter;

@ISA     = qw(Exporter);

@EXPORT =
  qw (
    %MYSQL_TABLES 
   	MYSQL_PASS MYSQL_DB MYSQL_USER
 	MYSQL_PRINT_ERROR MYSQL_RAISE_ERROR
);

# USED for 'search' 'admin' on web interface:

use constant MYUSER   => 'root';
use constant MYDATABASE => 'WAR_DIARY';
use constant MYPASS => 'YSB40_c'; 

use constant {

    MYSQL_PASS        => MYPASS,
    MYSQL_DB          => 'dbi:mysql:'.MYDATABASE.';mysql_read_default_file=/etc/mysql/my.cnf',
    MYSQL_USER        => MYUSER,
    MYSQL_PRINT_ERROR => 1,
    MYSQL_RAISE_ERROR => 1,

};

# Now we will define our table
# varible types char integer

%MYSQL_TABLES = (
    war_diary => 'CREATE TABLE war_diary (
		war_diary_id int  not null AUTO_INCREMENT,
		ReportKey varchar(255), 
		Date varchar(255), 
		Type varchar(255), 
		Category varchar(255), 
		TrackingNumber varchar(255), 
		Title text, 
		Summary text, 
		Region varchar(255), 
		AttackOn varchar(255), 
		ComplexAttack varchar(255), 
		ReportingUnit varchar(255), 
		UnitName varchar(255), 
		TypeOfUnit varchar(255), 
		FriendlyWIA varchar(255), 
		FriendlyKIA varchar(255), 
		HostNationWIA varchar(255), 
		HostNationKIA varchar(255), 
		CivilianWIA varchar(255), 
		CivilianKIA varchar(255), 
		EnemyWIA varchar(255), 
		EnemyKIA varchar(255), 
		EnemyDetained varchar(255), 
		MGRS varchar(255), 
		Latitude varchar(255), 
		Longitude varchar(255), 
		OriginatorGroup varchar(255), 
		UpdatedByGroup varchar(255), 
		CCIR varchar(255), 
		Sigact varchar(255), 
		Affiliation varchar(255), 
		DColor varchar(255), 
		Classification varchar(255),
		index (war_diary_id),
		UNIQUE (war_diary_id),
		FULLTEXT (Summary),
		FULLTEXT (Title)
	) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',
intersection => 'CREATE TABLE intersection (
		intersection_id int  not null AUTO_INCREMENT,
		intersection_ngram_size smallint not null,
		intersection_str varchar(255),
		intersection_occurrence int not null,
		index (intersection_id),
		UNIQUE (intersection_str),
		FULLTEXT (intersection_str )
	) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',
	ngram_war_diary => 'CREATE TABLE ngram_wdiary (
		ngram_wdiary_id int  not null AUTO_INCREMENT,
		ngram_wdiary_intersection_id  smallint not null, 
		ngram_wdiary_after_id smallint not null,
		index (ngram_wdiary_id)
	) DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci',



);
