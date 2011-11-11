#!/usr/bin/perl -w
use strict;

use DBI;

my $event_id = 1;

# connect to the database
my $dbh = DBI->connect("dbi:mysql:timereg:10.0.0.10", "peter", "", { RaiseError => 1, AutoCommit => 1 });
#my $dbh = DBI->connect("dbi:mysql:timereg:192.168.1.112", "peter", "", { RaiseError => 1, AutoCommit => 1 });

# get the event name
my $contest_id;
my $description;

my $sth = $dbh->prepare("SELECT event_id, description FROM event WHERE event_id = ?");
$sth->execute($event_id);
$sth->bind_columns(\($event_id, $description));

open my $event_file, ">results/event.txt";
while ($sth->fetch()) {
        print STDERR "$event_id\t$description\n";
        print $event_file "$event_id\t$description\n";
}
close $event_file;

if ( ! -f "results/$event_id/contest.txt" ) {
    print STDERR "Init contest file, gelieve na te kijken.\n";
    
    my $contest_id;
    my $description;
    
    my $sth_contest = $dbh->prepare("SELECT contest_id, description FROM contest WHERE event_id = ?");
    $sth_contest->execute($event_id);
    $sth_contest->bind_columns(\($contest_id, $description));
    
    open my $contest_file, ">results/$event_id/contest.txt";
    while ($sth_contest->fetch()) {
            print STDERR "$contest_id\t$description\n";
            print $contest_file "$contest_id\t$description\n";
    }
    close $contest_file;
}

sub get_person_list {
    my $person_id;
    my $nummer;
    my $last_name;
    my $first_name;
    my $wave;
    my $year,
    my $sex_id;
    my @person_list;
    
    print STDERR "Personen lijst bijwerken.\n";
    
    my $sth = $dbh->prepare("
        SELECT
            person.person_id,
            contest_person_result.startnumber,
            contest_person_result.contest_id,
            last_name,
            first_name,
            wave,
            year_of_birth,
            sex_id
            FROM person, contest_person_result
        WHERE person.person_id = contest_person_result.person_id
          and contest_person_result.startnumber > 0");
    $sth->execute();
    $sth->bind_columns(\($person_id,
                         $nummer,
                         $contest_id,
                         $last_name,
                         $first_name,
                         $wave,
                         $year,
                         $sex_id));
      
    while ($sth->fetch) {
        my $person;
        $person->{'person_id'} = $person_id;
        $person->{'nummer'} = $nummer;
        $person->{'last_name'} = $last_name;
        $person->{'first_name'} = $first_name;
        $person->{'contest_id'} = $contest_id;
        $person->{'wave'} = $wave;
        $person->{'year'} = $year;
        $person->{'sex'} = 'V' if ( $sex_id == 1 );
        $person->{'sex'} = 'M' if ( $sex_id == 2 );
        push @person_list, $person;
    }
    
    return @person_list;
}

# create the event folder
if ( ! -d "results/$event_id" ) {
    mkdir "results/$event_id";
}

#write person list
open my $event_person_file, ">results/${event_id}/person.txt";

# download the list of participants
foreach my $person ( get_person_list() ) {
    print $event_person_file "$person->{'person_id'}\t$person->{'nummer'}\t$person->{'last_name'}\t$person->{'first_name'}\t$person->{'contest_id'}\t$person->{'wave'}\t$person->{'year'}\t$person->{'sex'}\n";
}
close $event_person_file;

print STDERR "Doorsturen uitslagen.\n";

# stuur de resultaten door.
opendir(EDIR, "results/$event_id/");
while ( my $filename = readdir(EDIR) ) {
    if ( $filename !~ /\d+/ ) {
        next;
    }
    if ( ! -f "results/$event_id/$filename/result_final.txt" ) {
        next;
    }
    
    open my $result_file, "<results/$event_id/$filename/result_final.txt";
    my $sth = $dbh->prepare("
                update contest_person_result
                   set total_time = ?
                 where startnumber = ?");

    foreach my $result ( <$result_file> ) {
        chomp $result;
        print STDERR $result."\n";
        my ( $place, $nummer, $total_time ) = split /\t/, $result;
        $sth->execute($total_time, $nummer);
    }
}
