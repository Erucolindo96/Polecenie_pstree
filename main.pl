#!usr/bin/perl

package main;


 #stale:
 $MAX_TREE_LENGTH;

 @proc_descrip;
 #informacje o procesach
 %pid_to_name = ();
 %pid_to_ppid = ();
 %pid_to_user = ();

 #procesy nalezace do uzytkownika podanego jako parametr
 @user_pids = ();

 #parametry skryptu
 %is_param = ("-p" => 0, "-png" =>  0, "-u" => 0, "-help" => 0 );
 %args_param = ("-png"=>"", "-u"=>"");

 #drzewo w postaci tablicy stringow - do wypisania na konsole
 @tree = ();

sub init
{
	#dodajemy katalog skryptu do sciezki poszukiwnia modulow
	open(INP, "pwd |");
	my $dir_pwd = <INP>;
	push(@INC, $dir_pwd); 
	$, = ", ";
}


#
#
#
#funkcje wczytujace info o parametrach oraz procesach
#
#
#
sub readParameters
{
	my $all_args = "begin: ";
	foreach $par (@ARGV)
	{
		$all_args = $all_args.$par;
		$all_args = $all_args." ";
	}

	my $must_close = 0;
#oznaczamy czy dany parametr wystapil	
	if ($all_args =~ / -p /)
	{
		$is_param{"-p"} = 1;
	}
	
	if ($all_args =~ / -help /)
	{
		$is_param{"-help"} = 1;	
	}

	if ($all_args =~ / -u ([A-z]+)/)
	{
		$is_param{"-u"} = 1;
		$args_param{"-u"} = $1;
	}
	elsif ($all_args !~ / -u ([A-z]+)/ and $all_args =~ / -u / )#jesli jest -u a nie ma podanego pliku
	{
		$must_close = 1;
	}

	if ($all_args =~ / -png ([A-z]+)/)
	{
		$is_param{"-png"} = 1;
		$args_param{"-png"} = $1;
	}
	elsif ($all_args !~ / -png ([A-z]+)/ and $all_args =~ / -png / )#jesli jest -u a nie ma podanego pliku
	{
		$must_close = 1;
	}
	return  $must_close;
}

sub readProcessData
{
	open(INP, "ps -e --format=\"pid ppid fname user\" | "); 
	my $line,  $pid,  $ppid, $user, $name;
	while(<INP>)
	{
		$line = <INP>;
		chomp($line);
		#print $line;
		$line =~ /[ ]*(\d+)[ ]+(\d+)[ ]+(\D+)[ ]+(\D+)/;
		
		$pid_to_ppid{$1} = $2;
		$pid_to_name{$1} = $3;
		$pid_to_user{$1} = $4;
		#print $1, $2,$3, $4, "\n";
	}
	
	close(INP);
	#ustal jaka jest maksymalna dlugosc drzewa
	$TREE_LENGTH = length(keys %pid_to_ppid);
}

#
#
#
#funkcje wypisujace na konsole 
#Uzywane do debugowania i testowania
#Jak rowniez do podawania userowi komunikatow
#
sub printGlobalTables
{
	print "Pid ti Ppid\n";
	print sort(keys %pid_to_ppid),"\n", values %pid_to_ppid, "\n";
	print "Pid to User\n";
	print sort(keys %pid_to_user),"\n", values %pid_to_user, "\n";
	print "Pid to names\n";
	print sort(keys %pid_to_name),"\n", values %pid_to_name, "\n";
	print "Is Parameters:\n";
	print keys %is_param;
	print values %is_param;
	print"\n";
	print "Parameters arguments:\n";
	print keys %args_param;
	print values %args_param;
	print"\n";
}

sub printIncorrectSyntax
{
	print "Składnia jest niepoprawna.\n Wpisz -help aby zobaczyć jaka powinna być poprawna\n";
}

sub printHelp
{
	print "Skrypt wyswietla drzewo procesow.\n ";
	print "Parametry:\n";
	print "-help 		  ---> wyswietlenie pomocy\n";
	print "-p    		  ---> procesy sa wyswietlane wraz ze swoim PIDem\n";
	print "-u [nazwa_usera]   ---> wyswietla tylko procesy zwiazane z danym uzytkownikiem(oraz rodzicow tych procesow)\n";
	print "-png [nazwa_pliku] ---> zapisuje drzewo jako obrazek w formacie PNG\n";
}


#
#
#
#Znajduje procesy uzytkownika podanego jako parametr skryptu
#Gromadzi je w tablicy 
#
#
sub findUserProcesses
{
	$user_name = $args_param{"-u"};
	foreach $w (keys %pid_to_user)
	{
		if($pid_to_user{$w} eq $user_name)
		{
			push(@user_pids, $w);
			#print "Pid: $w, user: $pid_to_user{$w}\n";
		}
	}
	#print "Wartosc tablicy user_pids : \n";
	#print @user_pids;
}

#zwraca dzieci danego jako argument PIDu 
sub findChildrens
{
	my $pid = $_[0];
	my @childrens = ();
	foreach $w (keys %pid_to_ppid)
	{
		if($pid_to_ppid{$w} == $pid)
		{
			push(@childrens,$w );
		}
	}
	return @childrens;
}
#zwraca string zawierajacy tyle spacji ile podano jako argument
sub generateSpace
{
	$string = "";
	for(my $i = 0;$i = $_[0]; ++$i)
	{
		$string = $string." ";
	}
	return $string;	
}

sub printNextNode	#argument 1 - wiersz w ktorym zaczyna pisac swoje pierwsze dziecko
{			#argument 2 - kolumna w ktorej piszemy 
			#argument 3 - swoj PID
			#wartosc zwracana - wiersz w ktorym piszemy kolejne dziecko
	#stale:
	my $separ_size = 3;
	
	#zmienne
	my $first_line = $_[0];
	my $column = $_[1];
	my $my_pid = $_[2];
	my $act_col = $column, $act_line = $first_line;
	
	my @my_childrens = &findChildrens();
	
	#wpisz samego siebe  
	$tree[$act_line] = $tree[$act_line].$pid_to_name{$my_pid}."---";

	#zapisz ile znakow wpisales
	$act_col = $act_col + length($pid_to_name{$my_pid}) + $separ_size;
	
	# dodaj spacje i separator poziomy w kazdej nizszej linii
	$space_sep = generateSpace($act_col + length($pid_to_name{$my_pid});
	for(my $i = 0 ; $i < $TREE_LENGTH; ++$i) 
	{
		$l = $tree[$i];
		$l = $l.$space_sep." |"."  ";
	}

	my @my_childrens = &findChildrens();
	for(my $i = 0 ; $i < length @my_childrens; ++$i)
	{
		$act_line = printNextNode($act_line, $act_col,$my_cildrens[$i]);
	}	
}


sub printTreeToPngFile
{
	print "PNG file\n";
}
sub printTreeToConsole
{
	if($is_param{"-u"} == 0 )#wypisz cale drzewo
	{
		local $actual_printline = 0;

		
	}
	else#wypisz tylko procesy danego usera
	{

	}

	print "Console tree\n";
}

#
#
#
#Funkcja decydujaca, na podstawie parametrow danych jako argumenty skryptu,
#co nalezy zrobic - w jaki sposob wygenerowac drzewo
#Czy moze wypisac pomoc
#
#
sub chooseOperationAndExecute
{
	if($is_param{"-help"} == 1)
	{
		&printHelp();
	}
	else #nie wybrano wyswietlania pomocy - trzeba w jakis sposob wyswietlic drzewo
	{
		&findUserProcesses if($is_param{"-u"} == 1);

		if($is_param{"-png"} == 1)
		{
			&printTreeToPngFile();
		}
		else#wypisujemy na konsole
		{
			&printTreeToConsole();
		}
	}
}





sub main_f
{	
	&init();
	my  $must_close  = &readParameters();
	&readProcessData();
	if($must_close == 1)
	{
		&printIncorrectSyntax();
		return;
	}
	else
	{

		&chooseOperationAndExecute();
	}
	
}



&main_f();



































