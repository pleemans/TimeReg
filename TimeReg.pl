#!/usr/bin/perl -w

# Copyright 2006-2011 Leemans Peter <peter@bist2.be>
# TimeReg is released under the terms and conditions of version 3 of the GNU Affero General Public License.
# For further information please visit www.fsf.org/licensing/licenses/agpl-3.0.html 
# or refer to the agpl.txt file included in the distribution package 

use strict;

#use Time::localtime;

use Win32::GUI();
use Win32::GUI::Grid;

my $place = 1;
my $StartTime;
my $Timer1;
my $ElapsedTime;

my $event_id = 2;
my $contest_id = 1;
my $wave = 1;

my %EventIndex;
my %ContestIndex;
my $PersonIndex;
my %WaveIndex;
my @ResultArray;

# main Window
#my $Window = new Win32::GUI::DialogBox (
my $Window = new Win32::GUI::Window (
	-title		=> "Tijdsregistratie",
	-pos		=> [100, 20],
	-size		=> [800, 700],
	-name		=> "Window",
	-dialogui	=> 1,
) or die "new Window";

my $fntBigRed = Win32::GUI::Font->new(
	-name		=> "Comic Sans MS", 
	-size		=> 24,
);

my $label = $Window->AddLabel(
	-text		=> "Tijdsregistratie",
	-pos		=> [50, 0],
	-font		=> $fntBigRed,
	-foreground	=> [255, 0, 0],
);

$Window->AddLabel(
	-name		=> "Combo_Label",
	-text		=> "Wedstrijd: ",
	-left		=> 25,
	-top		=> 80,
	-width		=> 180,
	-height		=> 65,
	-visible	=> 1,
);

my $EventList = $Window->AddCombobox(
	-name			=> "EventDropdown",
	-left			=> 25,
	-top			=> 75,
	-width			=> 180,
	-height			=> 65,
	-dropdownlist	=> 1,
	-vscroll		=> 1,
);

my $ContestList = $Window->AddCombobox(
	-name			=> "ContestDropdown",
	-left			=> 25,
	-top			=> 100,
	-width			=> 180,
	-height			=> 65,
	-dropdownlist	=> 1,
	-vscroll		=> 1,
);

# Grid Window
my $Grid = $Window->AddGrid (
	-name			=> "Grid",
	-pos			=> [250, 50],
	-columns		=> 6,
	-rows			=> 500,
	-fixedrows		=> 1,
	-fixedcolumns	=> 1,
	-editable		=> 1,
	-vscroll		=> 1,
) or die "new Grid";

my $txtClock = $Window->AddTextfield(
	-name		=> 'Clock',
	-left		=> 25,
	-top		=> 175,
	-width		=> 180,
	-height		=> 65,
	-prompt		=> "",
	-font		=> $fntBigRed,
	-foreground	=> [255, 0, 0],
	-edit		=> 0,
);

my $btnStartTimer = $Window->AddButton(
	-name		=> 'StartTimer',
	-text		=> "Start Timer",
	-left		=> 25,
	-top		=> 250,
);

#my $btnStopTimer = $Window->AddButton(
#	-name		=> 'StopTimer',
#	-text		=> "Stop Timer",
#	-left		=> 100,
#	-top		=> 250,
#);

my $btnResetTimer = $Window->AddButton(
	-name		=> 'ResetTimer',
	-text		=> "Reset Timer",
	-left		=> 100,
	-top		=> 250,
);

my $fldNumber = $Window->AddTextfield(
	-name		=> 'Nummer',
	-left		=> 75,
	-top		=> 400,
	-width		=> 100,
	-height		=> 20,
	-prompt		=> "Nummer :",
	-ok			=> 1,
	-number		=> 1,
	#-default	=> 1,
	-tabstop	=> 1,
);

my $btnOK = $Window->AddButton(
	-name		=> 'btnOK',
	-text		=> "OK",
	-left		=> 75,
	-top		=> 450,
	-ok			=> 1,
	-tabstop	=> 1,
);

my $btnSave = $Window->AddButton(
	-name		=> 'btnSave',
	-text		=> "Opslaan resultaten",
	-left		=> 75,
	-top		=> 600,
	-ok			=> 1,
	-tabstop	=> 1,
);

# Fill Grid
ClearGrid($Grid);

# Load first Contest data
LoadEventList();
LoadContestList($event_id);
LoadPersonList($event_id, $contest_id);
LoadContestResult($event_id,$contest_id);
LoadContestTimer($event_id,$contest_id);

# set defaults for dropdown

$EventList->SetCurSel($event_id - 1);
$ContestList->SetCurSel($contest_id - 1);

# Resize Grid Cell
$Grid->AutoSize();

$fldNumber->SetFocus();

# Main Event loop
$Window->Show();
Win32::GUI::Dialog();

##
## Event handlers
##

# Main window event handler
sub Window_Terminate {
	return -1;
}

sub Window_Resize {
	my ($width, $height) = ($Window->GetClientRect)[2..3];
	$Grid->Resize ($width, $height);
}

sub EventDropdown_Change {
	SaveContestResult($event_id, $contest_id);

	StopContestTimer($event_id, $contest_id);

	ClearGrid($Grid);

	my $event = $EventList->GetString($EventList->SelectedItem);
	$event_id = $EventIndex{$event};

	$wave = $WaveIndex{$event};

	LoadContestList($event_id);

	# reset contest to the first
	$contest_id = 1;
	$ContestList->SetCurSel($contest_id - 1);

	LoadPersonList($event_id, $contest_id);
	LoadContestTimer($event_id, $contest_id);
	LoadContestResult($event_id, $contest_id);

	$Grid->Refresh();
}

sub ContestDropdown_Change {
	SaveContestResult($event_id, $contest_id);

	StopContestTimer($event_id, $contest_id);

	ClearGrid($Grid);

	my $contest = $ContestList->GetString($ContestList->SelectedItem);
	$contest_id = $ContestIndex{$contest};
	$wave = $WaveIndex{$contest};

	LoadPersonList($event_id, $contest_id);
	LoadContestTimer($event_id, $contest_id);
	LoadContestResult($event_id, $contest_id);

	$Grid->Refresh();
}

sub StartTimer_Click() {
	my $TimerFileName = "results/$event_id/$contest_id/timer.txt";

	my $time = StartContestTimer($event_id, $contest_id);

	$txtClock->Text($time);
}

sub StopTimer_Click() {
	StopContestTimer($event_id, $contest_id);
}

sub ResetTimer_Click() {
	StopContestTimer($event_id, $contest_id);
	ResetContestTimer($event_id, $contest_id);
}

sub btnOK_Click() {
	my $number = $fldNumber->Text();
	$number = 0 if ( $number eq "" );

	$Grid->EnsureCellVisible($place + 1, 0);

	$Grid->SetCellText($place, 1, $number);
	$Grid->RedrawCell($place, 1);

	$Grid->SetCellText($place, 2, $ElapsedTime);
	$Grid->RedrawCell($place, 2);

	if ( exists $PersonIndex->{$number}->{'name'} ) {
		$Grid->SetCellText($place, 3, $PersonIndex->{$number}->{'name'});
		$Grid->RedrawCell($place, 3);

		$Grid->SetCellText($place, 4, $PersonIndex->{$number}->{'year'});
		$Grid->RedrawCell($place, 4);

		$Grid->SetCellText($place, 5, $PersonIndex->{$number}->{'sex'});
		$Grid->RedrawCell($place, 5);
	}

	$Grid->AutoSize();

#	$person->{$number}->{'name'} = $last_name." ".$first_name;
#	$person->{$number}->{'contest_id'} = $contest_id;
#	$person->{$number}->{'wave'} = $wave;
#	$person->{$number}->{'year'} = $year;
#	$person->{$number}->{'sex'} = $sex;

	$fldNumber->Text("");

	$ResultArray[$place - 1]->{'Number'} = $number;
	$ResultArray[$place - 1]->{'Time'} = $ElapsedTime;
	AddResultToLog($place, $number, $ElapsedTime);

	$place++;
}

sub btnSave_Click() {
	my $rows = $place - 1;

	my $ResultFileName = "results/$event_id/$contest_id/result_final.txt";
	open my $outFile, ">".$ResultFileName;

	foreach my $row ( 1..$rows ) {
		my $place = $Grid->GetCellText($row, 0);
		my $number = $Grid->GetCellText($row, 1);
		my $time = $Grid->GetCellText($row, 2);
		my $name = $Grid->GetCellText($row, 3);
		my $year = $Grid->GetCellText($row, 4);
		my $sex = $Grid->GetCellText($row, 5);
		print $outFile $place."\t".$number."\t".$time."\t".$name."\t".$year."\t".$sex."\n";
	}

	close $outFile;
}

sub Grid_ChangedEdit {
	my ($col, $row) = @_;

	my $text = $Grid->GetCellText($col, $row);

	print "EndEdit on Cell ($col, $row)\n";
	print $text;
}

sub Timer1_Timer {
	my ($sec, $min, $hour, undef) = localtime(time);

	my $NowSeconds = ($hour * 3600) + ($min * 60) + $sec;
	my $ElapsedSeconds = $NowSeconds - $StartTime->{'TotalSeconds'};

	my $ElapsedHour = int($ElapsedSeconds / 3600); 
	my $ElapsedMin = int(($ElapsedSeconds - ($ElapsedHour * 3600)) / 60 ) ; 
	my $ElapsedSec = int($ElapsedSeconds - ($ElapsedHour * 3600) - ($ElapsedMin * 60)) ; 

	$ElapsedTime = sprintf("%02d:%02d:%02d", $ElapsedHour, $ElapsedMin, $ElapsedSec);

	$txtClock->Text($ElapsedTime);
}

##
## Timer Methods.
##

sub LoadContestTimer {
	my $event_id = shift;
	my $contest_id = shift;

	my $time = "--:--:--";
	my $TimerFileName = "results/$event_id/$contest_id/timer.txt";

	if ( -f $TimerFileName ) {
		open my $inFile, "<".$TimerFileName;
		my $line = <$inFile>;
		close $inFile;
		chomp $line;

		( $StartTime->{'TotalSeconds'}, $StartTime->{'Complete'} ) = split /\t/,$line;

		my ($sec, $min, $hour, undef) = localtime(time);

		my $NowSeconds = ($hour * 3600) + ($min * 60) + $sec;
		my $ElapsedSeconds = $NowSeconds - $StartTime->{'TotalSeconds'};

		my $ElapsedHour = int($ElapsedSeconds / 3600); 
		my $ElapsedMin = int(($ElapsedSeconds - ($ElapsedHour * 3600)) / 60 ) ; 
		my $ElapsedSec = int($ElapsedSeconds - ($ElapsedHour * 3600) - ($ElapsedMin * 60)) ; 

		$time  = sprintf("%02d:%02d:%02d", $ElapsedHour, $ElapsedMin, $ElapsedSec);

		$Timer1 = $Window->AddTimer('Timer1', 1000);
	}
	return $time;
}

sub StartContestTimer {
	my $event_id = shift;
	my $contest_id = shift;

	my $time = "00:00:00";
	my $TimerFileName = "results/$event_id/$contest_id/timer.txt";

	if ( ! -f $TimerFileName ) {
		my ($sec, $min, $hour, undef) = localtime(time);

		$StartTime->{'hour'} = $hour;
		$StartTime->{'min'} = $min;
		$StartTime->{'sec'} = $sec;
		$StartTime->{'TotalSeconds'} = ($StartTime->{'hour'} * 3600) + ($StartTime->{'min'} * 60) + $StartTime->{'sec'};

		open my $outFile, ">".$TimerFileName;
		print $outFile $StartTime->{'TotalSeconds'}."\t".$StartTime->{'hour'}.":".$StartTime->{'min'}.":".$StartTime->{'sec'}."\n";
		close $outFile;

		$Timer1 = $Window->AddTimer('Timer1', 1000);
	}
	else {
		$time = LoadContestTimer($event_id, $contest_id);
    }

	$txtClock->Text($time);

	return $time;
}

sub StopContestTimer {
	my $event_id = shift;
	my $contest_id = shift;

	$txtClock->Text("--:--:--");

	if ( $Timer1 ) {
		$Timer1->Kill();
	}
}

sub ResetContestTimer {
	my $event_id = shift;
	my $contest_id = shift;

	my $filename = "results/${event_id}/${contest_id}/timer.txt";
	unlink $filename;

	$txtClock->Text("--:--:--");
}

##
## File Methods.
##

sub LoadEventList {
	# reset event data
	%EventIndex = ();
	$EventList->ResetContent();

	# Populate EventList 
	my $EventFileName = "results/event.txt";
	open my $inEFile, "<".$EventFileName;
	foreach my $line ( <$inEFile> ) {
		chomp $line;
		my ( $event_id, $description ) = split '\t', $line;
		$EventList->InsertItem($description);
		$EventIndex{$description} = $event_id;
	}
	close $inEFile;
}

sub LoadContestList {
	my $event_id = shift;

	# reset contest data
	%ContestIndex = ();
	$ContestList->ResetContent();

	# Populate ContestList 
	my $ContestFileName = "results/$event_id/contest.txt";
	open my $inCFile, "<".$ContestFileName;
	foreach my $line ( <$inCFile> ) {
		chomp $line;
		my ( $contest_id, $description ) = split '\t', $line;
		$ContestList->InsertItem($description);
		$ContestIndex{$description} = $contest_id;
	}
	close $inCFile;
}

sub LoadPersonList {
	my $event_id = shift;
	my $contest_id = shift;

	$PersonIndex = undef;

	my $filename = "results/${event_id}/person.txt";
	#if ( -f $filename ) {
	#	print STDERR "Can't open person file : ${filename}\n";
	#	return;
	#}

	# Populate PersonList 
	open my $inPersonFile, "<".$filename;
	my $header = <$inPersonFile>;
	foreach my $line ( <$inPersonFile> ) {
		chomp $line;
		my $person;
		my ( 
			$id,
			$number,
			$last_name,
			$first_name,
			$contest_id,
			$wave,
			$year,
			$sex,
			undef) = split '\t', $line;
		# Remove double quotes
		$last_name =~ s/\"//g;
		$first_name =~ s/\"//g;
		$place =~ s/\"//g;
		$sex =~ s/\"//g;
		$sex = uc($sex);
		# set contest
		my $contest = "";
		if ( $sex ne "M" &&
			 $sex ne "V" ) {			$sex = "T";
		}
		$PersonIndex->{$number}->{'name'} = $last_name." ".$first_name;
		$PersonIndex->{$number}->{'contest_id'} = $contest_id;
		$PersonIndex->{$number}->{'wave'} = $wave;
		$PersonIndex->{$number}->{'year'} = $year;
		$PersonIndex->{$number}->{'sex'} = $sex;
	}

	close $inPersonFile;
}

sub AddResultToLog {
	my $place = shift;
	my $number = shift;
	my $time = shift;

	my $ResultFileName = "results/$event_id/$contest_id/result.log";

	open my $outFile, ">>".$ResultFileName;
	print $outFile $place."\t".$number."\t".$time."\n";
	close $outFile;
}

sub LoadContestResult {
	my $event_id = shift;
	my $contest_id = shift;

	# Reset place counter

	print STDERR "LoadContestResult\t$event_id:$contest_id\n";

	if ( ! -d "results/$event_id/$contest_id" ) {
		print STDERR "No Contest directory. Creating.\n";
		mkdir "results/$event_id/$contest_id";
		return;
	}

	if ( ! -f "results/$event_id/$contest_id/result.txt" ) {
		print STDERR "No file.\n";
		return;
	}

	my $ResultFileName = "results/$event_id/$contest_id/result.txt";
	open my $inFile, "<".$ResultFileName;

	my $row = 1;
	foreach my $line ( <$inFile> ) {
		chomp $line;
		my ( $place, $number, $time, $name, $year, $sex ) = split /\t/, $line;

		$Grid->SetCellText($row, 0, $place);
		$Grid->SetCellText($row, 1, $number);
		$Grid->SetCellText($row, 2, $time);
		$Grid->SetCellText($row, 3, $name);
		$Grid->SetCellText($row, 4, $year);
		$Grid->SetCellText($row, 5, $sex);
		$row++;
	}
	close $inFile;

	$place = $row;
}

sub SaveContestResult {
	my $event_id = shift;
	my $contest_id = shift;

	print STDERR "SaveContestResult\t$event_id:$contest_id\n";

	my $rows = $place - 1;

	my $ResultFileName = "results/$event_id/$contest_id/result.txt";
	open my $outFile, ">".$ResultFileName;

	foreach my $row ( 1..$rows ) {
		my $place = $Grid->GetCellText($row, 0);
		my $number = $Grid->GetCellText($row, 1);
		my $time = $Grid->GetCellText($row, 2);
		my $name = $Grid->GetCellText($row, 3);
		my $year = $Grid->GetCellText($row, 4);
		my $sex = $Grid->GetCellText($row, 5);
		print $outFile $place."\t".$number."\t".$time."\t".$name."\t".$year."\t".$sex."\n";
	}

	close $outFile;
}

sub ClearGrid {
	my $Grid = shift;    

	print STDERR "ClearGrid\n";

	# Reset place counter.
	$place = 1;

	# Header
	$Grid->SetCellText(0, 0,"Plaats");
	$Grid->SetCellText(0, 1,"Nummer");
	$Grid->SetCellText(0, 2,"Totale Tijd");
	$Grid->SetCellText(0, 3,"Naam");
	$Grid->SetCellText(0, 4,"Geb.Jaar");
	$Grid->SetCellText(0, 5,"M/V");

	for my $row (1..$Grid->GetRows()) {
		$Grid->SetCellText($row, 0, "$row");
		$Grid->SetCellText($row, 1, "--");
		$Grid->SetCellText($row, 2, "--:--:--");
		$Grid->SetCellText($row, 3, "");
		$Grid->SetCellText($row, 4, "");
		$Grid->SetCellText($row, 5, "");
	}
}