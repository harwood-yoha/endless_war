Perl libs 

Regex::PreSuf;
Term::ANSIColor::Markup;
Term::ScreenColor;
Term::ReadKey;

Lingua::StopWords qw( getStopWords );
Lingua::EN::Sentence qw( get_sentences add_acronyms );
Lingua::EN::Splitter qw(words);
	# ngram libs
Text::Ngram qw(ngram_counts add_to_counts);
Text::Wrap;
Benchmark qw(:all) ;
Benchmark::Timer;
	use DateTime;
	use DateTime::Duration;
