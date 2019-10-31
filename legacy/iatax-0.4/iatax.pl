#! /usr/bin/env perl

# This is Iatax v0.4, an Ataxx game for A.I.s
# Copyright (C) 2004-2005 Pierre 'AlSim' CHAPUIS (alsim@users.sf.net)
# Homepage : http://iatax.sf.net
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program ; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


#  < VALEURS PAR DEFAUT >

$help = '
USAGE : iatax [options]

OPTIONS :

   --help : Displays this text

   --iiaB bot_name or bot_file.iax.bot : Sets black A.I. (default : human)

   --iiaW bot_name or bot_file.iax.bot : Sets white A.I. (default : human)

   --logfile any_log_file.iax.log : Allows the user to choose the logfile (default : gamelog.iax.log in Iatax\'s folder).

   --nolog : Iatax won\'t generate a log file. This is NOT recommanded : analysing a game with LogReader is only possible if a logfile has been generated.

   --readlog any_log_file.iax.log : Runs the LogReader log analyser module on the given logfile (default : gamelog.iax.log in Iatax\'s folder).

   --lang XX, where XX is a language code (ex. : FR, EN ...) : Sets the language used by Iatax. You must have previously downloaded and set up the corresponding language file (lang_XX.iax.lng ; read the documentation to know how to do). Default is English.

   --nb X, where X is a number : Iatax will play X consecutive games between the two different bots, the winner of the match is the one which wins most of them. Draw is possible if X is even. BEWARE : don\'t set X too large if you don\'t want your match to last a long time ...

   --ig : Iatax will run in front-end mode. You need SDL to use this.

' ;
$lngcode = 'EN' ;
$ipath = __FILE__ ;
$ipath =~ s/\/iatax.pl/''/eg ;
$log = "$ipath/gamelog.iax.log" ; # ex-logfile
$iiab_file = "$ipath/bots/human.iax.bot" ;
$iiaw_file = "$ipath/bots/human.iax.bot" ;
$theme = "$ipath/themes/basic" ;
$nb = 1 ;
$nb_b = 0 ;
$nb_w = 0 ;

#  < RECUPERATION DES ARGUMENTS >

my $narg = 0 ;
foreach $arg (@ARGV)
{
   $narg++ ;
   if ($arg eq '--help') {print $help ; exit (0)}
   elsif ($arg eq '--logfile') {$log = @ARGV[$narg]}
   elsif ($arg eq '--readlog')
   {
    if (@ARGV[$narg]) {$log = @ARGV[$narg]}
    $lr = 1
   }
   elsif ($arg eq '--nolog') {$log = 0}
   elsif ($arg eq '--iiaB')
   {
    if (-f "$ipath/bots/@ARGV[$narg].iax.bot") {$iiab_file = "$ipath/bots/@ARGV[$narg].iax.bot"}
    elsif (-f @ARGV[$narg]) {$iiab_file = @ARGV[$narg]}
    else {&Erq("IA file '@ARGV[$narg]' doesn't exist !")}
   }
   elsif ($arg eq '--iiaW')
   {
    if (-f "$ipath/bots/@ARGV[$narg].iax.bot") {$iiaw_file = "$ipath/bots/@ARGV[$narg].iax.bot"}
    elsif (-f @ARGV[$narg]) {$iiaw_file = @ARGV[$narg]}
    else {&Erq("IA file '@ARGV[$narg]' doesn't exist !")}
   }
   elsif ($arg eq '--lang') {$lngcode = @ARGV[$narg]}
   elsif ($arg eq '--ig') {$ig = 1}
   elsif ($arg eq '--nb') {$nb = @ARGV[$narg]}
   elsif ($arg eq '--theme')
   {
    if (-d "$ipath/themes/@ARGV[$narg]") {$theme = "$ipath/themes/@ARGV[$narg]"}
    elsif (-d @ARGV[$narg]) {$iiaw_file = @ARGV[$narg]}
    else {&Erq("Can't find theme '@ARGV[$narg]' !")}
   }
}

$nb_left = $nb ;

#  < LANGUAGE >

if ($lngcode eq 'EN') {require "$ipath/lang/lang_EN.iax.lng"}
elsif ($lngcode eq 'FR') {require "$ipath/lang/lang_FR.iax.lng"}
else {&Erq("Iatax could not load language '$lngcode'. Read the documentation to learn how to setup new languages.")}

#  < FONCTIONS DE BASE >

sub Erq
{
   my $txt = shift ;
   print "\n$txt\n" ;
   exit(0)
}

sub SetPion
{
   my ($inputx, $inputy, $type) = @_ ;
   @grid[$inputx]->[$inputy] = $type ;
   if ($ig) {&IG::DrawPion($inputx,$inputy,$type)}
}

sub PrintGrid
{
   print "\n$txt::game_state_is :\n\n  0123456\n  _______\n" ;
   for my $i (0 .. 6)
   {
    print "$i|" ;
    for my $j (0 .. 6) {print @grid[$j]->[$i]}
    print "\n"
   }
}

sub Nb
{
   my $type = shift ;
   my $nb = 0 ;
   for my $i (0 .. 6)
   {
    for my $j (0 .. 6)
    {
     if (@grid[$i]->[$j] == $type) {$nb++}
    }
   }
   return $nb
}

sub Flt
{
   my ($pl,$col,$ftype) = @_ ;
   if ($pl == 1)
   {
    $pl_name = $IIAB::Name ;
    $paspl_name = $IIAW::Name ;
    $pascol = $txt::col_white ;
    $nb_w++
   }
   elsif ($pl == 2)
   {
    $pl_name = $IIAW::Name ;
    $paspl_name = $IIAB::Name ;
    $pascol = $txt::col_black ;
    $nb_b++
   }
   if ($log)
   {
    print RAPPORT "$pl_name ($col) $txt::has $ftype ... " ;
    if ($ftype ne $txt::seg_skipturn) {print RAPPORT "[(@move[0],@move[1]) => (@move[2],@move[3])]"}
    print RAPPORT "\n$paspl_name ($pascol) $txt::has $txt::won_the_game" ;
    if ($ftype eq $txt::withdrawed) {print RAPPORT '.'}
    else {print RAPPORT " ($txt::and $pl_name $txt::needs_bugcheck ;) !"}
   }
   print "\n$txt::game_over, $paspl_name ($pascol) $txt::has " ;
   if ($ftype eq $txt::withdrawed) {print "$txt::won_the_game !\n"}
   else {print "$txt::won_by_segfault !\n"}
   last MAIN
}

#  < FONCTIONS AVANCEES >

sub LoadIA
{
   open (IATMP, '>', "$ipath/tmp_ia.pm") or &Erq("$txt::err_load_tmp_ia ...") ;
   open (IATMP, '>>', "$ipath/tmp_ia.pm") ;
   open (IIABT, '<', $iiab_file) or &Erq("'$iiab_file' $txt::doesnt_exist !") ;
   open (IIAWT, '<', $iiaw_file) or &Erq("'$iiaw_file' $txt::doesnt_exist !") ;
   print IATMP "package IIAB ;\n" ;
   while (<IIABT> ne '') {print IATMP <IIABT>}
   print IATMP "\npackage IIAW ;\n" ;
   while (<IIAWT> ne '') {print IATMP <IIAWT>}
   print IATMP "1;\n" ;
   close (IIABT) ;
   close (IIAWT) ;
   close (IATMP)
}

sub MakeLog
{
   open (RAPPORT, '>', $log) or &Erq("$txt::err_load_logfile ...") ;
   open (RAPPORT, '>>', $log) ;
   my $date = `date +"%D, %T"` ;
   print RAPPORT "Iatax LogFile, $date"
}

sub NewGame
{
   $tour = 1 ;
   @taby0 = @taby1 = @taby2 = @taby3 = @taby4 = @taby5 = @taby6 = (0,0,0,0,0,0,0) ;
   @grid = (\@taby0,\@taby1,\@taby2,\@taby3,\@taby4,\@taby5,\@taby6) ;
   @move = (0,0,0,0) ;
   &SetPion(6,0,2) ;
   &SetPion(0,6,2) ;
   &SetPion(0,0,1) ;
   &SetPion(6,6,1) ;
   if ($ig and !$lr) {&IG::Redraw_all ; &IG::Refresh}
}

sub SetVg
{
   for my $i (0 .. 6)
   {
    for my $j (0 .. 6) {@gr_verif[$i]->[$j] = @grid[$i]->[$j]}
   }
}

sub VerVal
{
   my ($type,$col) = @_ ;
   for my $i (0 .. 6)
   {
    for my $j (0 .. 6)
    {
     if (@gr_verif[$i]->[$j] != @grid[$i]->[$j]) {&Flt($type,$col,$txt::cheated)}
    }
   }
   if ($tr eq 'w') {&Flt($type,$col,$txt::withdrawed)}
   if (@move[0] == -1)
   {
    if (!&VerSkip($type)) {&Flt($type,$col,$txt::seg_skipturn)}
    $Tr = 's'
   }
   else
   {
    if (@grid[@move[0]]->[@move[1]] != $type) {&Flt($type,$col,$txt::seg_nopiece)}
    if (@move[3] < 0 or @move[3] > 7 or @move[2] < 0 or @move[2] > 7) {&Flt($type,$col,$txt::seg_exitgrid)}
    if (@grid[@move[2]]->[@move[3]] != 0) {&Flt($type,$col,$txt::seg_play_over)}
    if (abs(@move[1]-@move[3]) != 1 && abs(@move[0]-@move[2]) != 1 or abs(@move[1]-@move[3]) > 1 or abs(@move[0]-@move[2]) > 1) {$Tr = 'm'}
    else {$Tr = 'c'}
    if ($Tr eq 'm' and (abs(@move[1]-@move[3]) != 2 && abs(@move[0]-@move[2]) != 2 or abs(@move[1]-@move[3]) > 2 or abs(@move[0]-@move[2]) > 2)) {&Flt($type,$col,$txt::seg_invalid_move)}
   }
}

sub VerFin
{
   $nbB = &Nb(1) ;
   $nbW = &Nb(2) ;
   my $towrite ;
   FINI:
   {
    if ($nbW == 0)
    {
     $towrite = "$IIAB::Name ($txt::col_black) $txt::has $txt::won_the_game $txt::by_erradicating $IIAW::Name ($txt::col_white) !" ;
    $nb_b++
    }
    elsif ($nbB == 0)
    {
     $towrite = "$IIAW::Name ($txt::col_white) $txt::has $txt::won_the_game $txt::by_erradicating $IIAB::Name ($txt::col_black) !" ;
     $nb_w++
    }
    elsif (!&Nb(0) and $nbB>$nbW)
    {
     $towrite = "$IIAB::Name ($txt::col_black) $txt::has $txt::won_the_game $txt::by_end_domination ($nbB - $nbW) !" ;
     $nb_b++
    }
    elsif (!&Nb(0) and $nbW>$nbB)
    {
     $towrite = "$IIAW::Name ($txt::col_white) $txt::has $txt::won_the_game $txt::by_end_domination ($nbW - $nbB) !" ;
     $nb_w++
    }
    else {last FINI}
    if ($log) {print RAPPORT $towrite}
    print "\n$txt::game_over, $towrite\n" ;
    last MAIN
   }
}

sub VerPlay
{
   if ($nb_left < 1)
   {
    my $towrite = "\n   --- $txt::results ---\n\n$nb $txt::games_played\n$IIAB::Name ($txt::col_black) : $nb_b\n$IIAW::Name ($txt::col_white) : $nb_w\n" ;
    if ($nb_b>$nb_w) {$towrite = "$towrite\n$IIAB::Name ($txt::col_black) $txt::has $txt::won_the_match.\n"}
    elsif ($nb_w>$nb_b) {$towrite = "$towrite\n$IIAW::Name ($txt::col_white) $txt::has $txt::won_the_match.\n"}
    else {$towrite = "$towrite\n\u$txt::draw_match.\n"}
    print RAPPORT "\n\n$towrite" ;
    print $towrite ;
    exit(0)
   }
   else
   {
    $game_nb = $nb-$nb_left+1 ;
    my $towrite = "\n   --- \u$txt::match $txt::number : $game_nb ---\n\n" ;
    print RAPPORT "\n$towrite" ;
    print $towrite ;
    $nb_left-- ;
    &PlayGame
   }
}

sub VerSkip
{
   my $type = shift ;
   for my $i1 (0 .. 6)
   {
    for my $j1 (0 .. 6)
    {
     if (@grid[$j1]->[$i1] == $type)
     {
      for my $i2 (-2 .. 2)
      {
       for my $j2 (-2 .. 2)
       {
        my $iR0 = $i1+$i2 ;
        my $jR0 = $j1+$j2 ;
        if ($iR0>=0 and $iR0<=6 and $jR0>=0 and $jR0<=6 and @grid[$jR0]->[$iR0]==0) {return 0}
       }
      }
     }
    }
   }
return 1
}

sub GridUpdate
{
   my $type = shift ;
   if ($Tr eq 'm') {&SetPion (@move[0],@move[1],0)}
   for my $i (-1 .. 1)
   {
    for my $j (-1 .. 1)
    {
     if ($i+@move[2] >= 0 and $j+@move[3] >= 0 and $i+@move[2] <= 6 and $j+@move[3] <= 6 and @grid[$i+@move[2]]->[$j+@move[3]] != 0) {&SetPion ($i+@move[2],$j+@move[3],$type)}
    }
   }
   &SetPion (@move[2],@move[3],$type) ;
   if ($ig and !$lr) {&IG::Refresh}
}

sub TourB
{
   if ($log){print RAPPORT "\u$txt::turn $tour ($IIAB::Name, $txt::col_black)\n"}
   if ($ig and $IIAB::IsHuman) {@move = &IIAB::Play_IG(1)}
   else {@move = &IIAB::Play(1)}
   &VerVal(1,$txt::col_black) ;
   if ($log)
   {
    print RAPPORT "$Tr" ;
    if ($Tr ne 's') {print RAPPORT " : (@move[0],@move[1]) => (@move[2],@move[3])"}
    print RAPPORT "\n\n"
   }
   if ($Tr ne 's') {&GridUpdate(1)}
}

sub TourW
{
   if ($log) {print RAPPORT "\u$txt::turn $tour ($IIAW::Name, $txt::col_white)\n"}
   if ($ig and $IIAW::IsHuman) {@move = &IIAW::Play_IG(2)}
   else {@move = &IIAW::Play(2)}
   &VerVal(2,$txt::col_white) ;
   if ($log)
   {
    print RAPPORT "$Tr" ;
    if ($Tr ne 's') {print RAPPORT " : (@move[0],@move[1]) => (@move[2],@move[3])"}
    print RAPPORT "\n\n"
   }
   if ($Tr ne 's') {&GridUpdate(2)}
}

#  < NOUVEAU JEU >

if ($lr)
{
 require "$ipath/logreader.iax.pm" ;
 &LogReader::Examine($log) ;
 exit(0)
}

&LoadIA ;
require "$ipath/tmp_ia.pm" ;
if (!($IIAB::IsHuman or $IIAW::IsHuman)) {$botmatch = 1}
if ($ig) {require "$ipath/ig.iax.pm" ; &IG::New}
if ($log) {&MakeLog}
while (1) {&VerPlay}

sub PlayGame
{
   print "\u$txt::starting_new_game ...\n" ;
   &NewGame ;
   if ($botmatch) {print "\n\u$txt::turn $txt::number : $tour"}

   @Vtaby0 = @Vtaby1 = @Vtaby2 = @Vtaby3 = @Vtaby4 = @Vtaby5 = @Vtaby6 = (0,0,0,0,0,0,0) ;
   @gr_verif = (\@Vtaby0,\@Vtaby1,\@Vtaby2,\@Vtaby3,\@Vtaby4,\@Vtaby5,\@Vtaby6) ;

   &MainLoop(1)
}

sub PlayFromTurn
{
   &LoadIA ;
   require "$ipath/tmp_ia.pm" ;
   $game_nb = 1 ; # patch pour afficher le numero dans IG
   if (!($IIAB::IsHuman or $IIAW::IsHuman)) {$botmatch = 1}
   if ($ig)
   {
    require "$ipath/ig.iax.pm" ;
    $IG::igW = 0 ; # ferme la fenetre active
    &IG::New() ;
    &IG::Redraw_all ;
    &IG::Refresh
   }
   if ($log) {&MakeLog}

   $tour = $LogReader::shown_turn ;
   print "\u$txt::replaying $txt::match $LogReader::match_nb $txt::from $txt::turn $tour\n" ;
   if ($botmatch) {print "\n\u$txt::turn $txt::number : $tour"}
   print RAPPORT "$txt::replayed_match ($txt::from $txt::turn $tour)\n\n   --- \u$txt::match $txt::number : 1 ---\n\n" ;

   LOGRECOP:
   foreach $line (@LogReader::match)
    {
       if ($line =~ m/^Turn $tour/) {last LOGRECOP}
       else {print RAPPORT "$line\n"}
    }

   $nbB = 0 ;
   $nbW = 0 ;
   for my $i (0 .. 6)
   {
    for my $j (0 .. 6)
    {
     if (@grid[$j]->[$i] == 1) {$nbB++}
     if (@grid[$j]->[$i] == 2) {$nbW++}
    }
   }

   @Vtaby0 = @Vtaby1 = @Vtaby2 = @Vtaby3 = @Vtaby4 = @Vtaby5 = @Vtaby6 = (0,0,0,0,0,0,0) ;
   @gr_verif = (\@Vtaby0,\@Vtaby1,\@Vtaby2,\@Vtaby3,\@Vtaby4,\@Vtaby5,\@Vtaby6) ;

   if ($tour/2 == int($tour/2)) {&MainLoop(2)}
   else {&MainLoop(1)}

   exit(0)
}

sub MainLoop
{
   my $pl = shift ;
   MAIN:
   while (1)
   {
    if ($pl == 1)
    {
     &SetVg ;
     if ($ig) {&IG::SetTitle($game_nb,$tour)}
     &TourB ;
     &VerFin ;
     $tour++ ;
     if ($botmatch) {print " - $tour"}
    }
    else {$pl = 1}
    &SetVg ;
    if ($ig) {&IG::SetTitle($game_nb,$tour)}
    &TourW ;
    &VerFin ;
    $tour++ ;
    if ($botmatch) {print " - $tour"}
   }
}

&Erq('Reached end of code ... REPORT THIS BUG PLEASE !')
