#!/usr/bin/perl -w
use strict;

# Copyright 2006-2011 Leemans Peter <peter@bist2.be>
# TimeReg is released under the terms and conditions of version 3 of the GNU Affero General Public License.
# For further information please visit www.fsf.org/licensing/licenses/agpl-3.0.html 
# or refer to the agpl.txt file included in the distribution package 

use Data::Dumper;

my $event_id = 1;
my $contest_id = 1;
my $this_year = 2009;
my $distance = 15096;
#my $distance = 10000;

my $PersonIndex;
my $ResultIndex;


sub druk_header {
    my $output = shift;
    my $title = shift;

    print $output "---------------------------------------------------------------------------------\n";
    print $output "-- Natuurloop Kempisch Triathlon Team - Herenthout-Berlaar - 8 mei 2009      \n";
    print $output "-- ".$title."\n";
    print $output "---------------------------------------------------------------------------------\n";
    printf $output "%-3s|%-25s|%-20s|%-9s|%-9s|%-10s\n",
        "Pl.",
        "Naam",
        "Woonplaats",
        "Cat.",
        "Tijd",
        "km/h";
}

sub druk_line {
    my $output = shift;
    my $cnt = shift;
    my $result = shift;
    my $person = shift;

    my ($hour, $min, $sec) = split /:/, $result->{time};
    my $timesec = ($hour*3600) + ($min*60) + $sec;
    my $speed = ( $distance / $timesec ) * 3.6;

    printf $output "%3d|%-25s|%-20s|%-9s|%9s|%02.2f\n", 
        $cnt, 
        $person->{name}, 
        $person->{place}, 
        $person->{contest}, 
        $result->{time}, 
        $speed;
}

sub druk_footer {
    my $output = shift;
    print $output "---------------------------------------------------------------------------------\n";
    print $output "-- Juiste afstand ".$distance." meter - Bezoek ook onze website: http://www.ktt.be \n";
    print $output "---------------------------------------------------------------------------------\n";
}

sub druk_contest {
    my $title = shift;
    my $file_name = shift;
    my $contest = shift;

    print "Maken uitslag ${contest}\n";

    open my $ResultFile, ">results/${file_name}.txt" or die "Can't open person file\n";
    druk_header($ResultFile, $title);
    my $cnt = 1;
    foreach my $Place ( sort { $a <=> $b } keys %{ $ResultIndex } ) {
        my $Result = $ResultIndex->{$Place};
        my $Person = $PersonIndex->{$Result->{'number'}};
        if ( $Person->{'contest'} =~ /$contest/ ) {
            druk_line($ResultFile, $cnt, $Result, $Person);
            $cnt++;
        }
    } 
    druk_footer($ResultFile);
    close $ResultFile;
}



# Load PersonList 
print "Laden personen\n";

open my $inPersonFile, "<results/Natuurloop_Inschrijvingen.csv" or die "Can't open person file\n";
my $header = <$inPersonFile>;
foreach my $line ( <$inPersonFile> ) {
    chomp $line;
    my $person;
    my ( $number,
         $name,
         $place,
         $year,
         $sex,
	 undef ) = split '\t', $line;
    # Remove double quotes
    $name =~ s/\"//g;
    $place =~ s/\"//g;
    $sex =~ s/\"//g;
    # set contest
    my $contest = "";
    if ( $sex eq "M" ||
         $sex eq "V" ) {
        $contest = $sex;

        my $age = $this_year - $year;


        if ( $year >= 1990 ) {
            $contest = $sex."JUN";

        }
        if ( $age >= 40 ) {
            $contest = $sex."40";

        }
        if ( $age >= 50 ) {
            $contest = $sex."50";
        }
        if ( $age >= 60 ) {
            $contest = $sex."60";
        }
    }
    elsif ( $sex eq "Team M/M" ) {
        $contest = "TEAM";
    }
    elsif ( $sex eq "Team M/V" ) {
        $contest = "TGEM";
    }
    elsif ( $sex eq "Team V/V" ) {
        $contest = "TDAM";
    }
    elsif ( $sex eq "Team J" ) {
        $contest = "TJEUGD";
    }
    else {
        print "Unknown Contest for:\n";
        print Dumper($line);
        exit;
    }
    # Build index
    $PersonIndex->{$number}->{'name'} = $name;
    $PersonIndex->{$number}->{'place'} = $place;
    $PersonIndex->{$number}->{'year'} = $year;
    $PersonIndex->{$number}->{'contest'} = $contest;
    $PersonIndex->{$number}->{'sex'} = $sex;

#     print Dumper($PersonIndex->{$number});
}
close $inPersonFile;

#print Dumper($PersonIndex);

# Load resultFile
print "Laden resultaten\n";

open my $inFile, "<results/$event_id/$contest_id/result_final.txt";
foreach my $line ( <$inFile> ) {
    chomp $line;

    my ( $place, $number, $time, $name, $year, $sex ) = split /\t/, $line;
    $ResultIndex->{$place}->{'number'} = $number;
    $ResultIndex->{$place}->{'time'} = $time;
    $ResultIndex->{$place}->{'name'} = $name;
    $ResultIndex->{$place}->{'year'} = $year;
    $ResultIndex->{$place}->{'sex'} = $sex;
}
close $inFile;

#print Dumper($ResultIndex);

my $ResultFile;
my $cnt;

# Afdrukken uitslag algemeen:
print "Maken uitslag algemeen\n";

open $ResultFile, ">results/Natuurloop_Algemeen.txt" or die "Can't open person file\n";
druk_header($ResultFile, "Uitslag algemeen");
$cnt = 1;
foreach my $Place ( sort { $a <=> $b } keys %{ $ResultIndex } ) {
	my $Result = $ResultIndex->{$Place};
	my $Person = $PersonIndex->{$Result->{'number'}};
	druk_line($ResultFile, $cnt, $Result, $Person);
	$cnt++;
} 
druk_footer($ResultFile);
close $ResultFile;

# Afdrukken uitslag heren:
druk_contest(
    "Uitslag Heren",
    "Natuurloop_Heren",
    "M"
);

# Afdrukken uitslag dames:
druk_contest(
    "Uitslag Dames",
    "Natuurloop_Dames",
    "V"
);

# Afdrukken uitslag heren 40:
druk_contest(
    "Uitslag Heren Junior",
    "Natuurloop_HerenJun",
    "MJUN"
);

# Afdrukken uitslag dames 40:
druk_contest(
    "Uitslag Dames Junior",
    "Natuurloop_DamesJun",
    "VJUN"
);

# Afdrukken uitslag heren 40:
druk_contest(
    "Uitslag Heren 40",
    "Natuurloop_Heren40",
    "M40"
);

# Afdrukken uitslag dames 40:
druk_contest(
    "Uitslag Dames 40",
    "Natuurloop_Dames40",
    "V40"
);

# Afdrukken uitslag heren 50:
druk_contest(
    "Uitslag Heren 50",
    "Natuurloop_Heren50",
    "M50"
);

# Afdrukken uitslag heren 60:
druk_contest(
    "Uitslag Heren 60",
    "Natuurloop_Heren60",
    "M60"
);

# Afdrukken uitslag dames 50:
druk_contest(
    "Uitslag Dames 50",
    "Natuurloop_Dames50",
    "V50"
);

# Afdrukken uitslag dames 60:
druk_contest(
    "Uitslag Dames 60",
    "Natuurloop_Dames60",
    "V60"
);

# Afdrukken uitslag team:
druk_contest(
    "Uitslag Team",
    "Natuurloop_Team",
    "TEAM"
);

# Afdrukken uitslag team gemengd:
druk_contest(
    "Uitslag Team Gemengd",
    "Natuurloop_TeamGemengd",
    "TGEM"
);

# Afdrukken uitslag team dames:
druk_contest(
    "Uitslag Team Dames",
    "Natuurloop_TeamDames",
    "TDAM"
);

# Afdrukken uitslag team jeugd:
druk_contest(
    "Uitslag Team Jeugd (Leeftijd samen < 33)",
    "Natuurloop_TeamJeugd",
    "TJEUGD"
);

