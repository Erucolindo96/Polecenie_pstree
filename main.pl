#!usr/bin/perl

package main;


 @proc_descrip;
 #informacje o procesach
 %pid_to_name = ();
 %pid_to_ppid = ();
 %pid_to_user = ();


 #parametry skryptu
 %is_param = ("-p" => 0, "-png" =>  0, "-u" => 0, "-help" => 0 );
 %args_param = ("-png"=>"", "-u"=>"");

sub init
{
	print "init\n";

	open(INP, "pwd |");
	my $dir_pwd = <INP>;
	
	#print $dir_pwd, "\n";

	push(@INC, $dir_pwd); 
	$, = ", ";
	print "end init\n";
}

sub readParameters
{
	my $all_args = "begin: ";
	foreach $par (@ARGV)
	{
		$all_args = $all_args.$par;
		$all_args = $all_args." ";
	}

	#my %is_param = ("-p" => 0, "-png" =>  0, "-u" => 0, "-help" => 0 );
	#my %args_param = ("-png"=>"", "-u"=>"");
	my $must_close = 0;
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
		#print $line;
		$line =~ /[ ]*(\d+)[ ]+(\d+)[ ]+(\D+)[ ]+(\D+)/;
		
		$pid_to_ppid{$1} = $2;
		$pid_to_name{$1} = $3;
		$pid_to_user{$1} = $4;
		#print $1, $2,$3, $4, "\n";
	}
	
	close(INP);
}


sub main_f
{	
	&init();
	my  $must_close  = &readParameters();
	readProcessData();
	print sort(keys %pid_to_ppid),"\n", values %pid_to_ppid, "\n";
	print sort(keys %pid_to_user),"\n", values %pid_to_user, "\n";
	print sort(keys %pid_to_name),"\n", values %pid_to_name, "\n";
	#print keys %is_param;
	#print values %is_param;
	#print"\n";

	#print keys %args_param;
	#print values %args_param;
	#print"\n";

	#print $must_close;


}



&main_f();



































