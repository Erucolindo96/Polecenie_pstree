#!usr/bin/perl

package main;
use warnings;

 #stale:
 $MAX_TREE_LENGTH;

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
	$, = " ";
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
	open(INP, "ps -e --format=\"pid ppid user fname\" | "); 
	my $line = "";
	while(<INP>)
	{
		$line = <INP>;
		chomp($line);
		#print $line;
		$line =~ /[ ]*(\d+)[ ]+(\d+)[ ]+(\D+)[ ]+(\D+)/;
		
		$pid_to_ppid{$1} = $2;
		$pid_to_name{$1} = $4;
		$pid_to_user{$1} = $3;
		#print $1, $2,$3, $4, "\n";
	}
	&initTreeVariable();	
	close(INP);
}
sub initTreeVariable
{	
	#ustal jaka jest maksymalna mozliwa dlugosc drzewa
	$TREE_LENGTH = scalar(keys %pid_to_ppid);
	foreach $w(@tree)
	{
		$w = " ";
	}

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

#wypisuje na konsole zmienna globalna "tree"
#
#
sub printTreeVariable
{
	print "Begin of tree\n";
	$size = scalar(@tree);
	print "Size of tree : $size, $TREE_LENGTH\n";
	foreach $w(@tree)
	{
		print $w, "\n";
	}
	print "End of tree\n";
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
sub findChildren
{
	my $pid = $_[0];
	my @children = ();
	foreach $w (keys %pid_to_ppid)
	{
		if($pid_to_ppid{$w} == $pid)
		{
			push(@children,$w );
			print "Dziecko procesu o PID = $pid, nazywa sie $pid_to_name{$w} i ma PID = $w\n";
		}
	}
	return @children;
}

#oblicza jak wiele linijek potrzebuje na wypisanie swoich dzieci dany proces
#Argument - PID procesu
#Zwraca ilośc linijek
sub howManyLinesNeed
{
	my $pid = $_[0];
	my @my_children = &findChildren($pid);
	if(scalar(@my_children) == 0)
	{
		return 1;
	}
	my $lines = 0;
	foreach $child_pid (@my_children)
	{
		$lines = $lines + &howManyLinesNeed($child_pid);
	}
	return $lines;
}

#zwraca string zawierajacy tyle spacji ile podano jako argument
sub generateSpace
{
	$string = "";
	for(my $i = 0;$i < $_[0]; ++$i)
	{
		$string = $string." ";
	}
	return $string;	
}


sub generateNextNode	#argument 1 - wiersz w ktorym zaczyna pisac swoje pierwsze dziecko
{			#argument 2 - kolumna w ktorej piszemy 
			#argument 3 - swoj PID
			#wartosc zwracana - wiersz w ktorym piszemy kolejne dziecko
	my $act_line = $_[0], $act_col = $_[1], $begin_col = $_[1], $begin_line = $_[0];
	my $my_pid = $_[2];
	my $my_name = $pid_to_name{$my_pid};
	my @children = &findChildren($my_pid);
	
	my $separ_hor = "___", $sep_vert = " | ";
	my $sep_size = 3;

	#wpisz samego siebie
	$tree[$act_line] = $tree[$act_line].$my_name;
	$act_col = $act_col + length($my_name);

	#jesli masz dzieci - dopisz separator poziomy
	if(scalar(@children) != 0)
	{
		$tree[$act_line] = $tree[$act_line].$separ_hor;
		$act_col = $act_col + $sep_size;
	}

	#dla kazdego dziecka oblicz ile zajmie linijek
	#w tylu wierszach - 1 (bo jedna juz jest wypisana) ponizej aktualnego
	#dodaj tyle spacji ile zajmuje $my_name(od kolumny poczatkowej)
	#oraz separator pionowy
	my $lines_needed = 0;
	foreach $child (@children)
	{
		$lines_needed =$lines_needed +  &howManyLinesNeed($child);
	}
	$lines_needed--; #bo pierwsza liniom jest nasz napis
	$space = &generateSpace(length($my_name));
	for($i = 1; $i <=$lines_needed; $i++)
	{
		$tree[$act_line+$i] = $tree[$act_line+$i].$space.$sep_vert;
	}
	#wywowaj rekursywnie fcje generateNextNode
	foreach $child(@children)
	{
		$act_line = &generateNextNode($act_line, $act_col, $child);
		$act_line++;
	}
	return $begin_line;

			

}

sub printNextNode	#argument 1 - wiersz w ktorym zaczyna pisac swoje pierwsze dziecko
{			#argument 2 - kolumna w ktorej piszemy 
			#argument 3 - swoj PID
			#wartosc zwracana - wiersz w ktorym piszemy kolejne dziecko
	#stale:
	my $separ_size = 3;  # "---"
	print "Node no. $_[0], $_[1], $_[2] for ";
	#zmienne
	my $act_line = $_[0], my $act_col = $_[1];	
	my $my_pid = $_[2];

	my @my_children = &findChildren($my_pid);
	#wpisz samego siebe  
	$tree[$act_line] = $tree[$act_line].$pid_to_name{$my_pid};
	print " $pid_to_name{$my_pid} ";
	print"  $tree[$act_line] ";

	#zapisz ile znakow wpisales
	$act_col = $act_col + length($pid_to_name{$my_pid});
	print "in line $act_line, in column $act_col ";
	
	#jesli mamy jakies dzieci
	if(scalar(@my_children) > 0)
	{
		#dodaj separator poziomy
		$tree[$act_line] = $tree[$act_line]."___";
		$act_col = $act_col + $separ_size;
		print "with separator ___ ";

		# dodaj spacje i separator poziomy w nizszych liniach tyle razy, ile aktualny proc ma dzieci
		my $space_sep = &generateSpace( length($pid_to_name{$my_pid} )) ;  #ilosc spacji odpowiadajaca dl nazwy procesu
		for(my $i = $act_line + 1 ; $i < scalar(@my_children); ++$i) 
		{
			$tree[$i] = $tree[$i].$space_sep." "."|"." ";#dodajemy spacje i separator poziomy
			print "with separator | ";
		}
	}
	for(my $i = 0 ; $i < scalar(@my_children); ++$i)
	{
		$act_line = &printNextNode($act_line, $act_col,$my_children[$i]);
		print "act_line = $act_line \n";
		
		#	&printTreeVariable();
	}
	return $act_line+1;
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
	&generateNextNode(0,0,1);

	&printTreeVariable();
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

	&printGlobalTables();
	#@children = &findChildren(1);
	#print"Dzieci procesu init: ", @children, "\n";
	
	#$one_child = $children[0];
	#foreach $one_child (@children)
	#{
	#	print "Jak wiele linii potrzeba dla procesu o nazwie $pid_to_name{$one_child}: ",  &howManyLinesNeed($one_child), "\n";	
	#}
}



&main_f();




