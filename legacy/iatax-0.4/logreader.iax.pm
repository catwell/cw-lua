# Iatax v0.4 : LogReader module
# Iatax is Copyright (C) 2004-2005 Pierre 'AlSim' CHAPUIS (alsim@users.sf.net)
# Homepage : http://iatax.sf.net
# Released under the terms of the GPL

package LogReader ;

if ($main::ig) {require "$main::ipath/ig.iax.pm"} ;

sub Examine
{
   my $log = shift ;
   $longfn = "$log REP" ;
   my ($rien,$shortlog) = ($longfn =~ /(.+)\/(.+?) REP/) ;                       # calcul du nom du
   open (LOG,'<',$log) or &main::Erq("$txt::err_load_logfile $shortlog ...") ; # fichier de log ...
   @log = <LOG> ;
   ($date) = (@log[0] =~ /Iatax LogFile, (.+?)\n/) ;
   ($date) or &main::Erq("$shortlog $txt::err_invalid_logfile !") ;
   print "\n   IATAX LOGREADER\n\n \u$txt::logfile : $shortlog, $date\n" ;
   if ($main::ig) {&SetMatch(1) ; &IG::LogReader_Main(1)} 
   else {&SetMatch ; &Main}
}

sub Play
{
   my ($type,$coup) = @_ ;
   ($main::Tr,@main::move[0],@main::move[1],@main::move[2],@main::move[3]) = ($coup =~ /(\w?) : \((\d?),(\d?)\) => \((\d?),(\d?)\)/) ;
   &main::GridUpdate($type) ;
}

sub PlayTurn
{
   my $turn_nb = shift ;

   my $type = (2-2*($turn_nb/2-int($turn_nb/2))) ;
   my $pastype = 3-$type ;

   my $played_a_turn = 0 ;
   my $prob_err = 0 ;
   PLAYTURN:
   foreach $line (@match)
   {
    chomp($line) ;
    if ($line =~ m/^Turn/) {($actual_turn) = ($line =~ /^Turn (\d+) /)} 
    elsif ($line eq 's' and $actual_turn == $turn_nb) {$played_a_turn = 1 ; last PLAYTURN}
    elsif ($line =~ m/^(\w?) : / and $actual_turn == $turn_nb) 
    {
     &Play($type,$line) ;
     $played_a_turn = 1 ;
     last PLAYTURN
    }
    elsif ($actual_turn == $turn_nb) 
    {
     $played_a_turn = 1 ; 
     $prob_err = $line ; 
     last PLAYTURN
    }
   }
   $turn_nb++ ; # $turn_nb représente alors le tour affiché APRES l'exécution
   if (!$played_a_turn) {print "\u$txt::turn $turn_nb $txt::of $txt::match $match_nb $txt::not_recorded.\n"}
   elsif ($prob_err) {print "\u$txt::turn $turn_nb : bot $pastype $txt::won_by_segfault ($prob_err).\n"}
   else {return 1}
   return 0
}

sub ShowTurn
{
   print "\n\u$txt::turn $shown_turn" ;
   &main::PrintGrid ;
   print "\n"
}

sub GotoTurn
{
   my $turn_nb = shift ;
   my $current_turn = 1 ;
   &main::NewGame ;
   while ($current_turn != $turn_nb and &PlayTurn($current_turn)) {$current_turn++}
   $shown_turn = $current_turn ;
}

sub SetMatch
{
   SETMATCH:
   while (1)
   {
    my $arg = shift ;
    if ($arg) {$match_nb = $arg} 
    else {print "\n\u$txt::which $txt::match ? " ; chomp($match_nb = <STDIN>)}
    @match = () ;
    $mnb_cur = 1 ;
    $mnb_max = 0 ;
    foreach $line (@log)
    {
     if ($line =~ m/---/) {$match_in = 0}
     if ($match_in == 1 and $line ne "\n") {@match = (@match, $line)}
     elsif ($line =~ m/--- Match number : $match_nb ---/) {$match_in = 1}
     if ($main::ig and ($mnb_cur) = ($line =~ /--- Match number : (\d+?) ---/) and $mnb_cur > $mnb_max) {$mnb_max = $mnb_cur}
    }
    if (@match) {last SETMATCH} 
    else {print "\u$txt::match $match_nb $txt::not_recorded or $shortlog $txt::err_invalid_logfile.\n"} 
   }

}

sub Main
{
   &GotoTurn(1) ;
   &ShowTurn ;

   LRMAIN:
   while (1)
   {
    print "$txt::lr_what_to_do\n>>> " ;
    chomp($Rep = <STDIN>) ;
    if ($Rep eq '+' or $Rep eq '') {&PlayTurn($shown_turn) and $shown_turn++ ; &ShowTurn}
    elsif ($Rep eq '-' and $shown_turn != 1) {&GotoTurn($shown_turn-1) ; &ShowTurn}
    elsif ($Rep eq 1*$Rep and $Rep > 0) {&GotoTurn($Rep) ; &ShowTurn}
    elsif ($Rep eq 'r') {&main::PlayFromTurn}
    elsif ($Rep eq 'q') {exit(0)}
    else {print "\u$txt::invalid_answer !\n\n"}
   }
}

1;
