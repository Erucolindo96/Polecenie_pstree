#!usr/bin/perl


require GD;
package main;
#use warnings;
use GD;
 #stale:

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

	if ($all_args =~ / -u (\S+)/)
	{
		$is_param{"-u"} = 1;
		$args_param{"-u"} = $1;
	}
	elsif ($all_args !~ / -u (\S+)/ and $all_args =~ / -u / )#jesli jest -u a nie ma podanego pliku
	{
		$must_close = 1;
	}

	if ($all_args =~ / -png (\S+)/)
	{
		$is_param{"-png"} = 1;
		$args_param{"-png"} = $1;
	}
	elsif ($all_args !~ / -png (\S+)/ and $all_args =~ / -png / )#jesli jest -u a nie ma podanego pliku
	{
		$must_close = 1;
	}
	return  $must_close;
}



sub readProcessData
{
	open(INP, "ps -e --format=\"pid ppid comm user\" | "); 
	my $line = "";
	while(<INP>)
	{
		$line = $_;
		chomp($line);
		$line =~ /[ ]*(\d+)[ ]+(\d+)[ ]+(\S+)[ ]+(\S+)[ ]*/;
		
		$pid_to_ppid{$1} = $2;
		$pid_to_name{$1} = $3;
		$pid_to_user{$1} = $4;
	}
	&initTreeVariable();	
	close(INP);
}
sub initTreeVariable
{	
	#ustal jaka jest maksymalna mozliwa dlugosc drzewa
	foreach $w(@tree)
	{
		$w = "";
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
	$size = scalar(@tree);
	foreach $w(@tree)
	{
		print $w, "\n";
	}
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
		}
	}
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


# Zwraca informacje, czy dany PID ma dzieci, ktore zostaly wywolane przed usera danego jako argument(lub sam nalezy do tego usera)
# Argument 1 - PID procesu ktorego pytamy,  2 - nazwa usera
# Zwracana wartość - 1 jeśli ma dzieci nalezace do usera, 0 jesli nie ma
#
#

sub haveChildUser
{
	my $my_pid = $_[0];
	my $user_name = $_[1];
	return 1 if($pid_to_user{$my_pid} eq $user_name);
	my @children = &findChildren($my_pid);
	foreach $child (@children)
	{
		if(&haveChildUser($child, $user_name) == 1)
		{
			return 1;
		}
	}
	return 0;

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

#Rekurencyjnie generuje drzewo od PIDu z ktorego mamy zaczac, oraz wiersza i kolumny w ktorej ma pojawic sie pierwszy proces(korzen drzewa
#
#)
sub generateNextNode	#argument 1 - wiersz w ktorym zaczyna pisac swoje pierwsze dziecko
{			#argument 2 - kolumna w ktorej piszemy 
			#argument 3 - swoj PID
			#wartosc zwracana - wiersz w ktorym piszemy kolejne dziecko
	my $act_line = $_[0], $act_col = $_[1], $begin_col = $_[1], $begin_line = $_[0];
	my $my_pid = $_[2];
	my $my_name = $pid_to_name{$my_pid};
	my @children = &findChildren($my_pid);
	
	my $separ_hor = "__", $sep_vert = " |";
	my $sep_size = 2;

	#wpisz "_"  i  samego siebie
	$tree[$act_line] = $tree[$act_line]."_".$my_name;
	$act_col = $act_col + 1 + length($my_name);

	#jesli masz wpisywac rozwniez PIDY - wpisz go
	if($is_param{"-p"} == 1)
	{
		$tree[$act_line] = $tree[$act_line]."($my_pid)";
		$act_col = $act_col + length("($my_pid)");
	}
	#jesli masz dzieci - dopisz separator poziomy
	if(scalar(@children) != 0 )
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
	$lines_needed--; #bo pierwszom liniom jest nasz napis
	$space = &generateSpace(length($my_name)+1); #+1 bo przez nasza nazwa dalismy "_"
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
#Robi to co generateNextNode, ale bierze pod uwagę rowniez usera podanego jako parametr - i tworzy tylko te dzieci, ktore zawieraja gdzies dalej procesy
#powolane do zycia przez usera podanego jako parametr

sub generateNextNodeUser	#argument 1 - wiersz w ktorym zaczyna pisac swoje pierwsze dziecko
{				#argument 2 - kolumna w ktorej piszemy 
				#argument 3 - swoj PID
				#argument 4 - nazwa usera ktorego procesy mamy wygenerowac
				#wartosc zwracana - wiersz w ktorym piszemy kolejne dziecko

	my $act_line = $_[0], $act_col = $_[1], $begin_col = $_[1], $begin_line = $_[0];
	my $my_pid = $_[2];
	my $user_to_find = $_[3];

	my $my_name = $pid_to_name{$my_pid};
	my @children = &findChildren($my_pid);
	
	my $separ_hor = "__", $sep_vert = " |";
	my $sep_size = 2;

	#wpisz "_"  i  samego siebie jesli zawierasz dzieci nalezace do danego usera
	if(&haveChildUser($my_pid, $user_to_find) == 1 )
	{
		$tree[$act_line] = $tree[$act_line]."_".$my_name;
		$act_col = $act_col + 1 + length($my_name);
	
		#jesli masz wpisywac rozwniez PIDY - wpisz go
		if($is_param{"-p"} == 1)
		{
			$tree[$act_line] = $tree[$act_line]."($my_pid)";
			$act_col = $act_col + length("($my_pid)");
		}
		#jesli nalezymy do danego usera - piszemy to
		if($pid_to_user{$my_pid} eq $user_to_find)
		{
			$tree[$act_line] = $tree[$act_line]."(U)";
			$act_col = $act_col + length("(U)");

		}
	}

	#jesli masz dzieci ktore beda zawierac jakies procesy szukanego usera - dopisz separator poziomy
	if(scalar(@children) != 0 and &haveChildUser($my_pid, $user_to_find)==1 )
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
			if(&haveChildUser($child, $user_to_find) == 1 )
			{
				$lines_needed =$lines_needed +  &howManyLinesNeed($child);
			}
	}
	$lines_needed--; #bo pierwszom liniom jest nasz napis
	$space = &generateSpace(length($my_name)+1); #+1 bo przez nasza nazwa dalismy "_"
	for($i = 1; $i <=$lines_needed; $i++)
	{
		$tree[$act_line+$i] = $tree[$act_line+$i].$space.$sep_vert;
	}
	#wywowaj rekursywnie fcje generateNextNode
	foreach $child(@children)
	{	
		if(&haveChildUser($child, $user_to_find) == 1 )
		{
			$act_line = &generateNextNodeUser($act_line, $act_col, $child, $user_to_find);
			$act_line++;
		}
	}
	return $begin_line;
}



sub generateTree #robi to co generateNextNode, ale zaczyna wypisywac
{
	if($is_param{"-u"} == 0 )
	{
		&generateNextNode(0,0,1);
	}
	else
	{
		&generateNextNodeUser(0,0,1, $args_param{"-u"} );
	}
	$tree[0] = substr($tree[0],1, length($tree[0]) ); 
}

#Wpisuje do obrazka podanego jako argument kolejne linijki drzewa
#argument : Obrazek typu Image
#zwraca gotowy obrazek
#
sub printTreeToImage
{
	my $x_size = 1000, $y_size = 1500;
	my $filename = $args_param{"-png"};
	my $image = GD::Image->new($x_size, $y_size);
	my $white = $image->colorAllocate(255,255,255);#kolor tla
	my $black = $image->colorAllocate(0,0,0);
	my $index = 5, $step = 11;# = $y_size/scalar(@tree);
	foreach $line (@tree)
	{
		$image->string(gdMediumBoldFont, 5, $index, $line, $black);
		$index = $index + $step;
	}
	my $png_file =  $image->png;	
	open(FILE,">".$filename);
       	binmode FILE;
	print FILE $png_file;
	close(FILE);	
}

sub printTreeToPngFile
{

	&generateTree();	
	&printTreeToImage();	
	$fname = $args_param{"-png"};
	print "Zapisano do pliku: $fname\n";

}
sub printTreeToConsole
{
	&generateTree();	
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
		#&findUserProcesses if($is_param{"-u"} == 1);

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

#argument - pid
sub test
{
	my $pid = $_[0];
	my $user = $args_param{"-u"};
	print "Proces o nazwie $pid_to_name{$pid}";
	print " Czy ma dzieci o uzytkowniku root? :";
	print &haveChildUser($pid, $user), "\n";
	print "nazwa szukanego usera : |", $user, "|\n"  
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




