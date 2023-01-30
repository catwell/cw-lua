# Iatax v0.4 : IG module
# Iatax is Copyright (C) 2004-2005 Pierre 'AlSim' CHAPUIS (alsim@users.sf.net)
# Homepage : http://iatax.sf.net
# Released under the terms of the GPL

package IG ;

use SDL ;
use SDL::App ;
use SDL::Event ;
use SDL::Color ;
use SDL::Surface ; 
use SDL::Rect ;
use SDL::Font ;

#  < VARS >

$imgpath = "$main::theme" ;
$size = 50 ;

$BlackS = new SDL::Surface (-name => "$imgpath/black.png") ;
$WhiteS = new SDL::Surface (-name => "$imgpath/white.png") ;
$SelectedS = new SDL::Surface (-name => "$imgpath/selected.png") ;
$fond = new SDL::Surface (-name => "$imgpath/fond.png") ;
$screen = new SDL::Surface (-name => "$imgpath/fond.png") ;

#  < SUBS >

sub New
{
   print "\n$txt::igload ...\n" ;
   $igW = new SDL::App (-title => "Iatax",
                        -width => 7*$size,
                        -height => 7*$size,
                        -depth => 24)
}

sub DrawPion
{
   my ($inputx,$inputy,$type) = @_ ;
   my $rect = new SDL::Rect (-height => $size,
                             -width => $size,
                             -x => $inputx*$size,
                             -y => $inputy*$size) ;

   if ($type == 0) {$fond -> blit($rect,$screen,$rect)}
   if ($type == 1) {$BlackS -> blit(NULL,$screen,$rect)}
   if ($type == 2) {$WhiteS -> blit(NULL,$screen,$rect)}
}

sub SetSelected
{
   my ($inputx,$inputy,$on) = @_ ;
   my $rect = new SDL::Rect (-height => $size,
                             -width => $size,
                             -x => $inputx*$size,
                             -y => $inputy*$size) ;
   my $type = @main::grid[$inputx]->[$inputy] ;
   if ($on) {$SelectedS -> blit(NULL, $screen, $rect)}
   else
   {
    $fond -> blit($rect,$screen,$rect) ;
    if ($type == 1) {$BlackS -> blit(NULL,$screen,$rect)}
    if ($type == 2) {$WhiteS -> blit(NULL,$screen,$rect)}
   }
}

sub Redraw_all
{
   for my $i (0 .. 6) 
   {
    for my $j (0 .. 6) {&DrawPion($i,$j,@main::grid[$i]->[$j])}
   }
}

sub Refresh
{
   $screen -> blit(NULL,$igW,NULL) ;
   $igW -> sync()
}

sub SetTitle
{
   my ($jeu,$tour,$texte) = @_ ;
   $igW -> title("Iatax $texte- $txt::game $jeu - $txt::turn $tour")
}

sub HumanPlay
{
   my $type = shift ;
   my $event = new SDL::Event ;
   my $phase = 1 ;
   if ($type == 1) {$col = $txt::col_black} 
   elsif ($type == 2) {$col = $txt::col_white}

   HUMPL:
   while ($event -> wait()) 
   {
    &Refresh ;
    if ($event -> type() == SDL_QUIT or $event -> type() == SDL_KEYDOWN && $event -> key_sym() == SDLK_ESCAPE) {&main::Flt($type,$col,$txt::withdrawed)}
    if ($event -> type() == SDL_KEYDOWN and $event -> key_sym() == SDLK_TAB) 
    {
     if (&main::VerSkip($type))
     {
      ($xdep,$ydep,$xarr,$yarr) = (-1,0,0,0) ;
      last HUMPL
     }
     else {print "$txt::no_skip\n"} # graphique ...
    }

    if ($event -> type() == SDL_MOUSEBUTTONDOWN) 
    {
     $xcas = int($event -> motion_x()/$size) ; 
     $ycas = int($event -> motion_y()/$size) ;
     if ($phase and @main::grid[$xcas] -> [$ycas] == $type)
     {
      if (@main::grid[$xcas] -> [$ycas] == $type)
      {
       $xdep = $xcas ;
       $ydep = $ycas ;
       &SetSelected($xdep,$ydep,1) ;
       $phase = 0
      }
     }
     elsif ($phase) {} #patch 29/01/05
     else
     {
      $xarr = $xcas ;
      $yarr = $ycas ;
      if (@main::grid[$xarr]->[$yarr] == $type)
      {
       &SetSelected($xdep,$ydep,0) ; 
       &SetSelected($xarr,$yarr,1) ;
       $xdep = $xarr ;
       $ydep = $yarr
      }
      elsif ((abs($xdep-$xarr)>2 or  abs($ydep-$yarr)>2) or (@main::grid[$xarr]->[$yarr] != 0)) {} # ne fait rien car invalide
      else
      {
       &SetSelected($xdep,$ydep,0) ; 
       last HUMPL
      }
     }
    }
   }
   return ($xdep, $ydep, $xarr, $yarr)
}

sub LogReader_ShowTurn
{
   &SetTitle($mnb,$LogReader::shown_turn,'LogReader ') ;
   &Redraw_all ;
   &Refresh
}

sub LogReader_Main
{
   $mnb = shift ;
   &LogReader::GotoTurn(1) ;
   &New ;
   &SetTitle($mnb,$LogReader::shown_turn,'LogReader ') ;
   &Redraw_all ;
   &Refresh ;
   &LogReader_ShowTurn ;
   my $last_turn = 0 ;
   foreach $line (@LogReader::match) 
   {
    if (chomp($line) =~ m/^Turn/) {$last_turn++} 
   }

   my $event = new SDL::Event ;
   LRMAINIG:
   while ($event -> wait()) 
   {
    if ($event -> type() == SDL_QUIT or $event -> type() == SDL_KEYDOWN && $event -> key_sym() == SDLK_ESCAPE) {&main::Erq("Exiting LogReader ...")}
    if ($event -> type() == SDL_KEYDOWN)
    {
     if ($event -> key_sym() == SDLK_RIGHT) {&LogReader::PlayTurn($LogReader::shown_turn) and $LogReader::shown_turn++} # LogReader::PlayTurn ne renvoie plus 1 si erreur mais si réussite !
     if ($event -> key_sym() == SDLK_LEFT and $LogReader::shown_turn != 1) {&LogReader::GotoTurn($LogReader::shown_turn-1)}
     if ($event -> key_sym() == SDLK_PAGEUP and $LogReader::shown_turn != 1) {&LogReader::GotoTurn(1)}
     if ($event -> key_sym() == SDLK_PAGEDOWN and $LogReader::shown_turn != $last_turn) {&LogReader::GotoTurn($last_turn)}
     if ($event -> key_sym() == SDLK_DOWN and $mnb < $LogReader::mnb_max) 
     {
      $new_mnb = $mnb+1 ;
      &LogReader::SetMatch($new_mnb) ;
      last LRMAINIG
     }
     if ($event -> key_sym() == SDLK_UP and $mnb>1) 
     {
      $new_mnb = $mnb-1 ;
      &LogReader::SetMatch($new_mnb) ;
      last LRMAINIG
     }
     if ($event -> key_sym() == SDLK_RETURN) {&main::PlayFromTurn ; last LRMAINIG}
     &LogReader_ShowTurn
    }
   }
   &LogReader_Main($new_mnb)
}

1;
