; Copyright 2014 Łukasz "JustArchi" Domeradzki
; Contact: JustArchi@JustArchi.net
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

;########################## GAME IDENTIFIER ##########################
;#####################################################################

alias bla {
  var %i = 1
  while ( %i <= 6 ) {
    var %line = %line $enclose(Team %result) zostala wynagrodzona dodatkowym bonusem za przerwanie passy $getname(%u) $+  %sp wygranych z rzedu!
    inc %i
  }
  echo -ag %line
  describe %ch %line
}


alias get.gamenum {
  if ($1 isnum) { return $1 }
  else {
    noop $regex($1,^.*?(\d*)$)
    if ($regml(1)) { return $v1 }
    else { return $null }
  }
}

alias get.gamestatusconst {
  if ( $1 == draw ) { return 1 }
  elseif ( $1 == Radiant ) { return 2 }
  else { return 3 }
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GAME FORMAT
;; gamenum
;; p1.p2.p3.p4.p5.p6.p7.p8.p9.p10.ctime.result.mode
;; where result is 1 for draw, 2 for sent, 3 for scrg
;; h.gamenum
;; h1.h2.h3.h4.h5.h6.h7.h8.h9.h10
;; e.gamenum
;; xp1.xp2.xp3.xp4.xp5.xp6.xp7.xp8.xp9.xp10.axp1.axp2.axp3.axp4.axp5.axp6.axp7.axp8.axp9.axp10
;; p.gamenum
;; pen1.pen2.pen3.pen4.pen5.pen6.pen7.pen8.pen9.pen10
;; where pen1 is constant counted as
;; nopenalty = 0
;; exclude = 1
;; truant = 2

alias game {
  var %game =  $get.gamenum($1)
  if (!%game) { return }
  if  ( $prop == plist ) {
    return $gettok($hget(gamedata,%game),1-10,46)
  }
  if  ( $prop == time ) {
    return $gettok($hget(gamedata,%game),11,46)
  }
  if  ( $prop == result ) {
    var %re = $gettok($hget(gamedata,%game),12,46)
    if ( %re == 1 ) { return draw }
    elseif ( %re == 2 ) { return radiant }
    else { return dire }
  }
  if  ( $prop == mode ) {
    return $gettok($hget(gamedata,%game),13,46)
  }
  if ( $prop == hlist ) {
    return $hget(gamedata,$+(h.,%game))
  }
  if ( $prop == elist ) {
    return $gettok($hget(gamedata,$+(e.,%game)),1-10,46)
  }
  if ( $prop == aelist ) {
    return $gettok($hget(gamedata,$+(e.,%game)),11-20,46)
  }
  if ( $prop == pelist ) {
    return $hget(gamedata,$+(p.,%game))
  }
  if ( $prop == name ) {
    return $get.gamename($gettok($hget(gamedata,%game),13,46),%game)
  }
}





;############################## RESULTS ##############################
;#####################################################################

alias result.getresult {
  var %psent = $matchtok($($+(%,game.results_,$1),2),radiant,0,46)
  var %pscrg = $matchtok($($+(%,game.results_,$1),2),dire,0,46)
  var %pdraw = $matchtok($($+(%,game.results_,$1),2),draw,0,46)
  if (( %psent > %pscrg ) && ( %psent > %pdraw )) { return radiant }
  elseif (( %pscrg > %psent ) && ( %pscrg > %pdraw )) { return dire }
  elseif (( %pdraw > %pscrg ) && ( %pdraw > %psent )) { return draw }
  else { return 0 }

}

on *:TEXT:.result*:%ch: {
  var %u = $getid2($nick)
  if (!$user(%u).gamenum) { return }
  var %gn = $user(%u).gamenum
  if (!$istok($($+(%,game.auths_,%gn),2),%u,46)) { return }
  if (!$istok(radiant.dire.draw,$2,46)) { return }
  if ($istok($($+(%,game.results.voted_,%gn),2),%u,46)) { return }
  if ($hget(gamedata,%gn)) { return }
  if ( $numtok($($+(%,game.results_,%gn),2),46) >= 5 ) { return }
  var %gameauths = $($+(%,game.auths_,%gn),2)
  var %team = $findtok(%gameauths,%u,1,46)
  if (%team <= 5) { var %team = sent }
  else { var %team = scrg }
  if ( $($+(%,game.results.,%team,_,%gn),2) >= 3 ) { return }
  inc $+(%,game.results.,%team,_,%gn)
  set %game.results_ $+ %gn $instok($($+(%,game.results_,%gn),2),$2,10,46)
  set %game.results.voted_ $+ %gn $instok($($+(%,game.results.voted_,%gn),2),%u,10,46)
  if ( $numtok($($+(%,game.results_,%gn),2),46) == 5 ) {
    var %res = $result.getresult(%gn)
    if (%res) {
      result.closegame %gn %res
	  sortingrank
      ;describe %ch Gra $get.gamename($($+(%,game.mode_,%gn),2),%gn) zamknieta! %res
    }
    else {
      describe %ch Nie mozna zamknac gry $get.gamename($($+(%,game.mode_,%gn),2),%gn) $+ .
    }
  }
}
;epdl
on *:TEXT:.votecap*:%ch: {
  var %u = $getid2($nick)
  if (!$user(%u).lastgame) { return }
  var %gn = $user(%u).lastgame
  if (!$($+(%,game.chall_,%gn),2)) { return }
  if (!$istok($($+(%,game.auths_,%gn),2),%u,46)) { return }
  if ($istok($($+(%,game.cap.voted_,%gn),2),%u,46)) { return }
  if (!$hget(gamedata,%gn)) { return }
  var %team = $findtok($($+(%,game.auths_,%gn),2),%u,1,46)
  echo -ag %team
  if ((%team == 1) || (%team == 6)) { return }
  echo -ag %team
  if (%team <= 5) { var %team = 1 }
  else { var %team = 6 }
  echo -ag %team
  set %game.cap.voted_ $+ %gn $instok($($+(%,game.cap.voted_,%gn),2),%u,10,46)
  noop $xsetuser($gettok($($+(%,game.auths_,%gn),2),%team,46),1).cap
  describe $nick Pomyslnie oddano glos na kapitana z gry  $+ %gn $+  $+ : $gettok($($+(%,game.auths_,%gn),2),%team,46) $+ !
}

on *:TEXT:.capswap *:%ch: {
  var %u = $getid2($nick)
  if (!%game.on) { describe %ch Tej komendy mozna uzywac wylacznie przed wyborem graczy! | return } 
  if (($gettok(%c.gameauths,1,46) == %u ) || ($gettok(%c.gameauths,2,46) == %u )) {
  var %nu = $getid($2)
  if ($userlvl(%nu) < 30) { describe %ch Nowy kapitan musi miec co najmniej status Challengera | return }
  var %pos = $findtok($($+(%,game.auths_,%gn),2),%u,1,46)
  if ($findtok($($+(%,game.auths_,%gn),2),%nu,1,46)) {
    set %game.auths_ $+ %gn $remtok($($+(%,game.auths_,%gn),2),%u,1,46)
}
    set %game.auths_ $+ %gn $puttok($($+(%,game.auths_,%gn),2),%nu,%pos,46)
    if (%pos == 1) { %team = radiant }
    if (%pos == 2) { %team = dire }
    describe %ch Kapitan druzyny %team -  $+ %u $+  zostal zastapiony przez  $+ %nu $+ .
  }
  elseif ($userlvl(%u) >= 70) {
    if ((!$2) || (!$3)) { describe %ch Prawidlowy format komendy dla moderatorow: .capswap staryCAP nowyCAP | return }
    var %ru = $getid($2)
    var %nu = $getid($3)
    if ($userlvl(%nu) < 30) { describe %ch Nowy kapitan musi miec co najmniej status Challengera! | return }
    var %pos = $findtok($($+(%,game.auths_,%gn),2),%ru,1,46)
    if ($findtok($($+(%,game.auths_,%gn),2),%nu,1,46)) {
    set %game.auths_ $+ %gn $remtok($($+(%,game.auths_,%gn),2),%ru,1,46)
}
    set %game.auths_ $+ %gn $puttok($($+(%,game.auths_,%gn),2),%nu,%pos,46)
    if (%pos == 1) { %team = radiant }
    if (%pos == 2) { %team = dire }
    describe %ch Kapitan druzyny %team -  $+ %ru $+  zostal zastapiony przez  $+ %nu $+ .
  }
}


on *:TEXT:.replace *:%ch: {
  var %u = $getid2($nick)
  if (!$user(%u).gamenum) { return }
  var %gn = $user(%u).gamenum
  var %ru = $getid($2)
  var %nu = $getid($3)
  if (!$istok($($+(%,game.auths_,%gn),2),%u,46)) { return }
  if (!$istok($($+(%,game.auths_,%gn),2),%ru,46)) { return }
  if (!$hget(userdata,%nu)) { return }
  if ($istok($($+(%,game.replace.voted_,%gn,_,%ru,_,%nu),2),%u,46)) { notice $nick Zaglosowano! | return }
  ;;### if ($istok($($+(%,game.exclude_,%gn),2),%eu,46)) { return }
  if ($hget(gamedata,%gn)) { return }
  if ( $($+(%,game.replace.votes_,%gn,_,%ru,_,%nu),2) >= 6 ) { return }
  inc %game.replace.votes_ $+ %gn $+ _ $+ %ru $+ _ $+ %nu
  set %game.replace.voted_ $+ %gn $+ _ $+ %ru $+ _ $+ %nu $instok($($+(%,game.replace.voted_,%gn,_,%ru,_,%nu),2),%u,10,46)
  if ( $($+(%,game.replace.votes_,%gn,_,%ru,_,%nu),2) == 6 ) {
    ;describe %ch Gracze %ru i %nu musza potwierdzic zamiane komenda .replace (bez parametrow)
    echo -ag REPLACED
    var %pos = $findtok($($+(%,game.auths_,%gn),2),%ru,1,46)
    set %game.auths_ $+ %gn $puttok($($+(%,game.auths_,%gn),2),%nu,%pos,46)
    set %player.game_ $+ %ru 0
    set %player.game_ $+ %nu %gn
    noop $xsetuser(%ru,-15).conf
    AddPenalty $botname %ru Replace %gn
    describe %ch Gracz $getname(%ru) zostal zastapiony przez $getname(%nu) w grze $get.gamename($($+(%,game.mode_,%gn),2),%gn)
  }
}

on *:TEXT:.modreplace *:%ch: {
  var %u = $getid2($nick)
  if ($userlvl(%u) < 70) { return } 
  ;if (!$user(%u).gamenum) { return }
  ;if ($2 !isnum) { return }
  if  (!$2) { notice $nick Prawidlowy format komendy: .areplace nick nick | return }
  if  (!$3) { notice $nick Prawidlowy format komendy: .areplace nick nick | return }
  var %ru = $getid($2)
  var %nu = $getid($3)
  if (!$user(%ru).gamenum) { return }
  var %gn = $user(%ru).gamenum
  if ($user(%nu).gamenum) { describe %ch %nu jest w aktywnej grze. | return }
  ;if (!$istok($($+(%,game.auths_,%gn),2),%u,46)) { return }
  if (!$istok($($+(%,game.auths_,%gn),2),%ru,46)) { Nie ma takiego gracza w grze $get.gamename($($+(%,game.mode_,%gn),2),%gn) | return }
  if (!$hget(userdata,%nu)) { return }
  ;if ($istok($($+(%,game.replace.voted_,%gn,_,%ru,_,%nu),2),%u,46)) { notice $nick Oddales juz glos! | return }
  ;;### if ($istok($($+(%,game.exclude_,%gn),2),%eu,46)) { return }
  if ($hget(gamedata,%gn)) { describe %ch Gra zostala juz zakonczona | return }
  ;if ( $($+(%,game.replace.votes_,%gn,_,%ru,_,%nu),2) >= 6 ) { return }
  ;inc %game.replace.votes_ $+ %gn $+ _ $+ %ru $+ _ $+ %nu
  ;set %game.replace.voted_ $+ %gn $+ _ $+ %ru $+ _ $+ %nu $instok($($+(%,game.replace.voted_,%gn,_,%ru,_,%nu),2),%u,10,46)
  ;if ( $($+(%,game.replace.votes_,%gn,_,%ru,_,%nu),2) == 6 ) {
    ;describe %ch Gracze %ru i %nu musza potwierdzic zamiane komenda .replace (bez parametrow)
    echo -ag REPLACED
    var %pos = $findtok($($+(%,game.auths_,%gn),2),%ru,1,46)
    set %game.auths_ $+ %gn $puttok($($+(%,game.auths_,%gn),2),%nu,%pos,46)
    set %player.game_ $+ %ru 0
    set %player.game_ $+ %nu %gn
    ;noop $xsetuser(%ru,-30).conf
    ;AddPenalty $botname %ru Replace %gn
    describe %ch Gracz $getname(%ru) zostal zastapiony przez $getname(%nu) w grze $get.gamename($($+(%,game.mode_,%gn),2),%gn)
  ;}
}

on *:TEXT:.replaceme:%ch: {
  var %u = $getid2($nick)
  if ($istok($($+(%,game.auths_,%gn),2),%u,46)) { return }
}

on *:TEXT:.exclude*:%ch: {
  var %u = $getid2($nick)
  if (!$user(%u).gamenum) { return }
  var %gn = $user(%u).gamenum
  var %eu = $getid($2)
  if (!$istok($($+(%,game.auths_,%gn),2),%u,46)) { return }
  if (!$istok($($+(%,game.auths_,%gn),2),%eu,46)) { return }
  if ($istok($($+(%,game.exclude.voted_,%gn,_,%eu),2),%u,46)) { return }
  if ($istok($($+(%,game.exclude_,%gn),2),%eu,46)) { return }
  if ($hget(gamedata,%gn)) { return }
  if ( $($+(%,game.exclude.votes_,%gn,_,%eu),2) >= 4 ) { return }
  inc %game.exclude.votes_ $+ %gn $+ _ $+ %eu
  set %game.exclude.voted_ $+ %gn $+ _ $+ %eu $instok($($+(%,game.exclude.voted_,%gn,_,%eu),2),%u,10,46)
  if ( $($+(%,game.exclude.votes_,%gn,_,%eu),2) == 4 ) {
    echo -ag EXCLUDED
    set %game.exclude_ $+ %gn $addtok($($+(%,game.exclude_,%gn),2),%eu,46)
    AddPenalty $botname %eu Exclude %gn
    describe %ch Gracz $getname(%eu) wykluczony z gry $get.gamename($($+(%,game.mode_,%gn),2),%gn)
    msg pdl-invite .timeban %eu
    timerban 1 10 msg pdl-invite .modkick $nauth(%eu)
  }
}


on *:TEXT:.modexclude*:%ch: {
  var %u = $getid2($nick)
  if ($userlvl(%u) < 70) { return } 
  var %gn = $int($2)
  echo -ag %gn
  if (!%gn) { describe %ch ID gry musi byc liczba | return }
  var %eu = $getid($3)
  if (!%eu) { describe %ch Nie znaleziono uzytkownika $3 | return }
  if (!$istok($($+(%,game.auths_,%gn),2),%eu,46)) { msg $nick Gracz %eu nie znajdowal sie w grze %gn | return }
  if (!$hget(gamedata,%gn)) {
  set %game.exclude_ $+ %gn $addtok($($+(%,game.exclude_,%gn),2),%eu,46)
  describe %ch Pomyslnie wykluczono $getname(%eu) z gry $get.gamename($($+(%,game.mode_,%gn),2),%gn) $+ . Gracz zostanie ukarany po potwierdzeniu wyniku gry. 
  AddPenalty %u %eu Exclude %gn
  }
  else {
  var %el = $gettok($hget(gamedata,$+(p.,%gn)),1-,46)
  var %pos = $findtok($hget(gamedata,%gn),%eu,1,46)
  if (%pos > 10) { return }
  if ($gettok($hget(gamedata,$+(p.,%gn)),%pos,46) != 0) { describe %ch Ten gracz zostal juz wykluczony z tej gry | return }
  var %el = $puttok(%el,1,%pos,46)
  hadd gamedata p. $+ %gn %el
  noop $xsetuser(%eu,1).lost
  if ( $user(%eu).spree >= 0 ) { noop $setuser(%eu,0).spree }
  else { noop $xsetuser(%eu,-1).spree }
  noop $xsetuser(%eu,-30).exp
  noop $setuser(%eu,-30).lastexp
  noop $xsetuser(%eu,-60).conf
  AddPenalty %u %eu MODExclude %gn
  describe %ch Gracz $getname(%eu) wykluczony z gry $get.gamename($($+(%,game.mode_,%gn),2),%gn)
  }
  msg pdl-invite .timeban %eu
  timer 1 10 msg pdl-invite .modkick $nauth(%eu)
}

on *:TEXT:.modtruant*:%ch: {
  var %u = $getid2($nick)
  if ($userlvl(%u) < 70) { return } 
  var %gn = $int($2)
  echo -ag %gn
  if (!%gn) { describe %ch ID gry musi byc liczba! | return }
  var %eu = $getid($3)
  if (!%eu) { describe %ch Nie znaleziono uzytkownika $3 | return }
  if (!$istok($($+(%,game.auths_,%gn),2),%eu,46)) { msg $nick Gracz %eu nie znajdowal sie w grze %gn | return }
  if (!$hget(gamedata,%gn)) {
  set %game.truant_ $+ %gn %eu
  result.closegame %gn draw truant
  AddPenalty %u %eu Truant %gn
  } 
  else {
  var %el = $gettok($hget(gamedata,$+(p.,%gn)),1-,46)
  var %pos = $findtok($hget(gamedata,%gn),%eu,1,46)
  if ($gettok($hget(gamedata,%gn),12,46) > 1) { describe %ch Gra %gn ma wynik inny niz remis, uzyj komendy .modexclude aby wykluczyc gracza z tej gry. | return }
  if (%pos > 10) { return }
  if ($gettok($hget(gamedata,$+(p.,%gn)),%pos,46) != 0) { describe %ch Ten gracz zostal juz wykluczony z tej gry | return }
  var %el = $puttok(%el,2,%pos,46)
  hadd gamedata p. $+ %gn %el
  if ( $user(%eu).spree >= 0 ) { noop $setuser(%eu,0).spree }
  else { noop $xsetuser(%eu,-1).spree }
  noop $xsetuser(%eu,-40).exp
 ;noop $setuser(%eu,-30).lastexp
  noop $xsetuser(%eu,-80).conf
  AddPenalty %u %eu MODTruant %gn
  }
  AddPenalty %u %eu Truant %gn
  describe %ch Gracz $getname(%eu) wykluczony z gry $get.gamename($($+(%,game.mode_,%gn),2),%gn)
  msg pdl-invite .timeban %eu
  timer 1 10 msg pdl-invite .modkick $nauth(%eu) 
}

on *:TEXT:.truant*:%ch: {
  var %u = $getid2($nick)
  if (!$user(%u).gamenum) { return }
  var %gn = $user(%u).gamenum
  var %eu = $getid($2)
  if (!$istok($($+(%,game.auths_,%gn),2),%u,46)) { return }
  if (!$istok($($+(%,game.auths_,%gn),2),%eu,46)) { return }
  if ($istok($($+(%,game.truant.voted_,%gn),2),%u,46)) { notice $nick Zaglosowano! | return }
  if ($hget(gamedata,%gn)) { return }
  if ( $($+(%,game.truant_,%gn,_,%eu),2) >= 4 ) { return }
  var %gameauths = $($+(%,game.auths_,%gn),2)
  var %team = $findtok(%gameauths,%u,1,46)
  if (%team <= 5) { var %team = sent }
  else { var %team = scrg }
  if ( $($+(%,game.truant.,%team,_,%gn,_,%eu),2) >= 2 ) { return }
  inc $+(%,game.truant.,%team,_,%gn,_,%eu)
  inc %game.truant_ $+ %gn $+ _ $+ %eu
  set %game.truant.voted_ $+ %gn $instok($($+(%,game.truant.voted_,%gn),2),%u,10,46)
  if ( $($+(%,game.truant_,%gn,_,%eu),2) == 4 ) {
    set %game.truant_ $+ %gn %eu
    result.closegame %gn draw truant
    AddPenalty %u %eu Truant %gn
    ;describe %ch Gra $get.gamename($($+(%,game.mode_,%gn),2),%gn) zamknieta! %res
    ;describe %ch Uzytkownik $getname(%eu) tymczasowo zbanowany!
  }
}

alias get.censureconst {
  if ( $1 >= 100 ) { return -50 }
  elseif ( $1 >= 90 ) { return -40 }
  elseif ( $1 >= 70 ) { return -30 }
  elseif ( $1 >= 50 ) { return -30 }
  elseif ( $1 >= 30 ) { return -10 }
  elseif ( $1 >= 10 ) { return -5 }
  else { return 0 }
}

;; takes nick
alias cen.numtoday {
  return $($+(%,cen.today_,$1),2)
}

;; takes gamenum, nick
alias cen.numgame {
  return $($+(%,cen.game_,$1,_,$2),2)
}

;; takes gamenum, nick, usernick(one who censure)
alias cen.gameallowed {
  if ($istok($($+(%,cen.game.censured_,$1,_,$2),2),$3,46)) { return $false }
  else { return $true }
}

;; takes gamenum, nick
alias cen.pergame {
  if ($($+(%,cen.pergame_,$1,_,$2),2)) { return $v1 }
  else { return 0 }
}

on *:TEXT:.censure*:*: {
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %u = $getid2($nick)
  var %cu = $getid($2)
  var %game = $user(%u).lastgame
  var %players = $game(%game).plist
  if (!$istok(%players,%cu,46)) { describe %target Niedostepne! Gracz nie znajdowal sie w Twojej ostatniej grze! | return }
  if ($calc($ctime - $game(%game).time) > 172800 ) { describe %target Niedostepne! Minal czas przyznawania uwag! | return }
  if ($cen.numtoday(%cu) >= 10) { describe %target Niedostepne! Gracz nie moze dzisiaj otrzymac wiecej uwag! | return }
  if ($cen.numgame(%game,%cu) >= 5) { describe %target Niedostepne! Gracz nie moze otrzymac wiecej uwag za ta gre! | return }
  if (!$cen.gameallowed(%game,%cu,%u)) { describe %target Niedostepne! Nie mozesz przyznac dwoch uwag jednemu graczowi! | return }
  if ($cen.pergame(%game,%u) >= 2) { describe %target Niedostepne! Mozesz przyznac uwage tylko dwom graczom z jednej gry! | return }
  inc $+(%,cen.pergame_,%game,_,%u)
  inc $+(%,cen.game_,%game,_,%cu)
  set $+(%,cen.game.censured_,%game,_,%cu) $addtok($($+(%,cen.game.censured_,%game,_,%cu),2),%u,46)
  inc %cen.today_ $+ %cu
  var %confpen = $get.censureconst($userlvl(%u))
  if ( $userlvl(%cu) <= 90 ) {
    noop $xsetuser(%cu,%confpen).conf
    AddPenalty %u %cu Uwaga %confpen $+ - $+ %game
  }
  else {
    noop $xsetuser(%cu,$int($calc(%confpen / 2))).conf
    AddPenalty %u %cu Uwaga $int($calc(%confpen / 2)) %game
  }
  if ( $userlvl(%u) <= 50 ) {
    noop $xsetuser(%u,$int($calc( %confpen / 2))).conf
  }
  else {
    noop $xsetuser(%u,$int($calc( %confpen / 4))).conf
  }
  describe %target Uwaga przyznana!
}

on *:TEXT:.delheroes*:%ch: {
  var %u = $getid2($nick)
  if ( $userlvl(%u) >= 120 ) {
    resetherodata 
    notice $nick Zrobione!
  }
  else { notice $nick Nie masz uprawnien do uzywania tej komendy. }
}

on *:TEXT:.delvars*:%ch: {
  var %u = $getid2($nick)
  if ( $userlvl(%u) >= 120 ) {
    cleanvars
    notice $nick Zrobione!
  }
  else { notice $nick Nie masz uprawnien do uzywania tej komendy. }
}

on *:TEXT:.delladder*:%ch: {
  var %u = $getid2($nick)
  if ( $userlvl(%u) >= 120 ) {
    resetstats 
    notice $nick Zrobione!
  }
  else { notice $nick Nie masz uprawnien do uzywania tej komendy. }
}

on *:TEXT:.delconfig*:%ch: {
  var %u = $getid2($nick)
  if ( $userlvl(%u) >= 120 ) {
    resetconf
    notice $nick Zrobione!
  }
  else { notice $nick Nie masz uprawnien do uzywania tej komendy. }
}

on *:TEXT:.gameover*:%ch: {
  var %u = $getid2($nick)
  if ( $userlvl(%u) >= 120 ) {
    describe %ch 5Weryfikacja powiodla sie -=[4 $nick 35]=- Bot przystepuje do wyjebania ligi. $fulldate
    cleanvars
    resetstats
    resetconf
    describe %ch 4Liga oficjalnie zostala wyjebana!3
    /reconnect
  }

  else { notice $nick Chyba Cie pojebalo dziewczynko. }
}

on *:TEXT:.report*:%ch: {
  var %u = $getid2($nick)
  if ( $userlvl(%u) >= 70 ) {
    var %game = $get.gamenum($2)
    echo -ag %game
    if (!%game) { return }
    if ($hget(gamedata,%game)) { notice $nick Gra juz zostala potwierdzona! | return }
    if (!$istok(radiant.dire,$3,46)) { return }
    ;describe %ch Gra $get.gamename($($+(%,game.mode_,$2),2),$2) zamknieta! %res
    result.closegame %game $3
    AddRecord %u .report Gra o numerze %game zmieniona. Wynik: $3
    sortingrank
  }
}

on *:TEXT:.closegame*:%ch: {
  var %u = $getid2($nick)
  if ( $userlvl(%u) >= 70 ) {
    var %game = $get.gamenum($2)
    if (!%game) { return }
    if ($hget(gamedata,%game)) { notice $nick Gra juz zostala potwierdzona! | return }
    ;describe %ch Gra $get.gamename($($+(%,game.mode_,$2),2),$2) zamknieta! %res
    result.closegame %game draw
    AddRecord %u .closegame Gra o numerze %game zamknieta jako Remis.
    run -min pro.bat
  }
}

on *:TEXT:.voidgame*:%ch: {
  var %u = $getid2($nick)
  if ( $userlvl(%u) >= 70 ) {
    var %op = %u
    var %game = $get.gamenum($2)
    if (!%game) { return }
    if (!$hget(gamedata,%game)) { return }
    var %result = $game(%game).result
    if ( %result == draw ) { describe %ch Gra zostala juz wczesniej zamknieta jako Remis. | return }
    var %players = $game(%game).plist
    if ( %result == radiant ) {
      var %wfrom = 1
      var %lfrom = 6
      var %exp = $game(%game).elist
    }
    elseif ( %result == dire ) {
      var %wfrom = 6
      var %lfrom = 1
      var %exp = $game(%game).aelist
    }

    var %plist

    var %i = %wfrom
    var %l = %wfrom + 4
    while ( %i <= %l ) {
      var %u = $gettok(%players,%i,46)
      var %e = $calc(-1 * $gettok(%exp,%i,46))
      noop $xsetuser(%u,-1).win
;epdl
if ($gettok($($+(%,game.mode_,%game),2),1,46) == ardm) { noop $xsetuser(%u,-1).gpl }
else noop $xsetuser(%u,-2).gpl
      noop $xsetuser(%u,%e).exp
      var %plist = %plist $getname(%u) $+ $iif(%e >= 0,$enclose(+ $+ %e),$enclose(%e))
      inc %i
    }

    var %i = %lfrom
    var %l = %lfrom + 4
    while ( %i <= %l ) {
      var %u = $gettok(%players,%i,46)
      var %e = $calc(-1 * $gettok(%exp,%i,46))
      noop $xsetuser(%u,-1).lost
;epdl
if ($gettok($($+(%,game.mode_,%game),2),1,46) == ardm) { noop $xsetuser(%u,-1).gpl }
else noop $xsetuser(%u,-2).gpl
      noop $xsetuser(%u,%e).exp
      var %plist = %plist $getname(%u) $+ $iif(%e >= 0,$enclose(+ $+ %e),$enclose(%e))
      inc %i
    }
    var %gamelist = $hget(gamedata,%game)
    var %gamelist = $puttok(%gamelist,1,12,46)
    hadd gamedata %game %gamelist
    describe %ch Gra $game(%game).name usunieta! Zmiany w XP: %plist
    AddRecord %op .voidgame Game# %game voided
    run -min pro.bat
  }
}

on *:TEXT:.submit*:%ch: {
  var %u = $getid2($nick)
  if ( $userlvl(%u) >= 70 ) {
    var %op = %u
    var %game = $get.gamenum($2)
    if (!%game) { return }
    if (!$istok(radiant.dire,$3,46)) { return }
    if (!$hget(gamedata,%game)) { describe %ch Uzyj .potwierdzgre do zamykania trwajacych gier! | return }
    var %result = $game(%game).result
    if ( %result != draw ) { describe %ch Uzyj .usungre przed .zmienwynik | return }
    var %players = $game(%game).plist
    if ( $3 == radiant ) {
      var %wfrom = 1
      var %lfrom = 6
      var %exp = $game(%game).elist
    }
    elseif ( $3 == dire ) {
      var %wfrom = 6
      var %lfrom = 1
      var %exp = $game(%game).aelist
    }

    var %plist

    var %i = %wfrom
    var %l = %wfrom + 4
    while ( %i <= %l ) {
      var %u = $gettok(%players,%i,46)
      var %e = $gettok(%exp,%i,46)
      noop $xsetuser(%u,1).win
;epdl
if ($gettok($($+(%,game.mode_,%game),2),1,46) == ardm) { noop $xsetuser(%u,1).gpl }
else noop $xsetuser(%u,2).gpl
      noop $xsetuser(%u,%e).exp
      var %plist = %plist $getname(%u) $+ $iif(%e >= 0,$enclose(+ $+ %e),$enclose(%e))
      inc %i
    }

    var %i = %lfrom
    var %l = %lfrom + 4
    while ( %i <= %l ) {
      var %u = $gettok(%players,%i,46)
      var %e = $gettok(%exp,%i,46)
      noop $xsetuser(%u,1).lost
;epdl
if ($gettok($($+(%,game.mode_,%game),2),1,46) == ardm) { noop $xsetuser(%u,1).gpl }
else noop $xsetuser(%u,2).gpl
      noop $xsetuser(%u,%e).exp
      var %plist = %plist $getname(%u) $+ $iif(%e >= 0,$enclose(+ $+ %e),$enclose(%e))
      inc %i
    }
    var %gamelist = $hget(gamedata,%game)
    var %gamelist = $puttok(%gamelist,$get.gamestatusconst($3),12,46)
    hadd gamedata %game %gamelist
    describe %ch Wynik gry $game(%game).name zmieniony na $3 $+ ! Zmiany w XP: %plist
    AddRecord %op .submit Game# %game submitted result: $3
    run -min pro.bat
  }
}

on *:TEXT:.reward*:*: {
  if (!$3) { return }
  if ($timer(penaltydolgogo2)) { describe $msg $chan Nie mozesz uzywac tej komendy czesciej niz raz na 10 sekund. | return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %u = $getid2($nick)
  if ($userlvl(%u) >= $adminlvl ) {
    var %ru = $getid($2)
    if ( $3 isnum ) {
      var %exp = $round($abs($3),0)
      var %oldxp $user(%ru).exp
      noop $xsetuser(%ru,%exp).exp
      describe %target Zmiana XP z %oldxp na $calc( %oldxp + %exp )
      AddRecord %u .reward User %ru has been rewarded an extra $3 XP
      run -min pro.bat
    }
    timerpenaltydolgogo2 1 10 noop
  }
}

on *:TEXT:.penalty*:*: {
  if (!$3) { return }
  if ($timer(penaltydolgo)) { describe $msg $chan Nie mozesz uzywac tej komendy czesciej niz raz na 10 sekund. | return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %u = $getid2($nick)
  if ($userlvl(%u) >= $adminlvl ) {
    var %ru = $getid($2)
    if ( $3 isnum ) {
      var %exp = $round($calc( -1 * $abs($3)),0)
      var %oldxp $user(%ru).exp
      noop $xsetuser(%ru,%exp).exp
      describe %target Zmiana XP z %oldxp na $calc( %oldxp + %exp )
      AddRecord %u .penalty User %ru has been penalized for an extra $3 XP
      run -min pro.bat
    }
    timerpenaltydolgo 1 10 noop
    ;if (timerpenaltydolgo <= 29) { msg $nick Nie mozesz uzywac tej komendy czesciej niz raz na 10 sekund. | return }
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EXP SYSTEM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

alias e {
  echo -ag $1-
}

alias DefaultTeamFactor {
  ;;return 12
  return 24
}

alias TeamCountModifier {
  return 8
}

alias TeamCountModifierMult {
  return 0.1
}

alias result.compare {
  ;;var %x = $calc($1 / $2)
  ;;var %x = $calc(1 / %x)
  ;;return $round(%x,3)
  var %x = $calc(10 ^ (( $2 - $1 ) / 400 ))
  var %x = $calc(%x + 1)
  var %x = $calc(1 / %x)
  return $round(%x,3)
}

alias result.rc {
  return $round($calc($1 * ($2 - $3)),0)
}

alias result.pdefbase {
  /*
  if ($1 < 40) { return 20 }
  elseif ($1 < 100) { return 16 }
  elseif ($1 < 400) { return 12 }
  else { return 8 }
  */
  if ($1 < 10) { return 36 }
  elseif ($1 < 20) { return 32 }
  elseif ($1 < 30) { return 28  }
  elseif ($1 < 50) { return 24 }
  elseif ($1 < 75) { return 20 }
  else { return 18 }
}

alias result.streakmod {
  if ($1 >= 9) { return 1.8 }
  elseif ($1 >= 7) { return 1.6 }
  elseif ($1 >= 5) { return 1.4 }
  elseif ($1 >= 4) { return 1.2 }
  elseif ($1 >= 3) { return 1.2 }
  elseif ($1 >= 2) { return 1 }
  else { return 1 }
}

alias result.closegame {
  var %game = $get.gamenum($1)
  if ($hget(gamedata,%game)) { describe %ch Gra zostala juz potwierdzona | return }
  var %players = $($+(%,game.auths_,%game),2)
  var %heroes = $($+(%,game.heroes_,%game),2)
  var %mode = $($+(%,game.mode_,%game),2)
  var %date = $($+(%,game.date_,%game),2)
  var %exclude = $($+(%,game.exclude_,%game),2)
  var %challmode = $($+(%,game.chall_,%game),2)
  var %result = $2
  var %randombonus = $calc( 2 * $r(1,4) )
  if ($3 == truant) { var %truant = $($+(%,game.truant_,%game),2) }
  var %exclude = $addtok(%exclude,%truant,46)
  echo -ag %players
  ;return
  ;; GET XP ARRAY
  var %i = 1
  while ( %i <= 10 ) {
    var %u = $gettok(%players,%i,46)
    var %exp = $user(%u).exp
    echo -ag %i %u %exp
    var %exparray = $instok(%exparray,%exp,11,46)
    inc %i
  }

  echo -ag ExpArray: %exparray

  ;; GET POSITION OF WINNER / LOSER
  if ( %result == radiant ) {
    var %wfrom = 1
    var %lfrom = 6
  }
  elseif ( %result == dire ) {
    var %wfrom = 6
    var %lfrom = 1
  }
  elseif ( %result == draw ) {
    var %wfrom = 1
    var %lfrom = 6
  }

  ;############################################################
  ;############################################################
  ;############################################################

  ;;;;;;;;;;;;;;;;;;;;;; GET XP TEAM-MODIFIERS
  ;; GET WINNER XP
  var %i = %wfrom
  var %l = %wfrom + 4
  var %n = 0
  while ( %i <= %l ) {
    if (!$istok(%exclude,$gettok(%players,%i,46),46)) {
      var %winnerXP = $calc( %winnerXP + $gettok(%exparray,%i,46) )
      inc %n
    }
    inc %i
  }
  var %winnerXP = $round($calc(%winnerXP / %n),0)
  var %winnercount = %n
  ;echo -ag XP za wygrana: %winnerxp Podliczenie: %winnercount

  ;; GET LOSER XP
  var %i = %lfrom
  var %l = %lfrom + 4
  var %n = 0
  while ( %i <= %l ) {
    if (!$istok(%exclude,$gettok(%players,%i,46),46)) {
      var %loserXP = $calc( %loserXP + $gettok(%exparray,%i,46) )
      inc %n
    }
    inc %i
  }
  var %loserXP = $round($calc(%loserXP / %n),0)
  var %losercount = %n
  ;echo -ag XP za przegrana: %loserxp Podliczenie: %losercount
  ;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;; GET CASEBONUS
  var %i = %lfrom
  var %l = %lfrom + 4
  var %casebonus = 0
  while ( %i <= %l ) {
    var %u = $gettok(%players,%i,46)
    var %sp = $user(%u).spree
    if ( %sp >= 4 ) {
      var %casebonus = %casebonus + $calc(1.5 * %sp )
      var %spreebonusmsg = %spreebonusmsg $enclose(Druzyna %result) zostala wynagrodzona dodatkowym bonusem za przerwanie graczowi $getname(%u) $+ $chr(32) passy %sp wygranych z rzedu!
    }
    inc %i
  }
  var %casebonus = $round(%casebonus,0)

  if ( %gamenum >= 200 ) {
    ;; count casebonus for beginners in team
    var %i = %wfrom
    var %l = %wfrom + 4
    while ( %i <= %l ) {
      var %u = $gettok(%players,%i,46)
      var %r = $get.exprank(%u)
      if ( %r == beginner ) {
        var %casebonus = $calc(%casebonus + 3)
      }
      inc %i
    }

    ;; count casebonus for beginners in losing team ( so they lose less xp )
    var %i = %lfrom
    var %l = %lfrom + 4
    var %lcasebonus = 0
    while ( %i <= %l ) {
      var %u = $gettok(%players,%i,46)
      var %r = $get.exprank(%u)
      if ( %r == beginner ) {
        var %lcasebonus = $calc(%lcasebonus - 3)
      }
      inc %i
    }
    ;echo -ag Spreebonus: %spreebonusmsg
    ;echo -ag Casebonus: %casebonus
    ;;;;;;;;;;;;;;;;;;;;;;
  }

  ;echo -ag Casebonus: %casebonus
  ;echo -ag LCasebonus: %lcasebonus

  ;;;;;;;;;;;;;;;;;;;;;; GET BASE TEAM FACTOR
  var %BTF = $DefaultTeamFactor
  if (!%challmode) {
    var %BTF = $calc(1.5 * %BTF)
  }
  if ($calc($ctime - %date) < 1800) { var %BTF = $calc( %BTF / 1.3 ) }
  elseif ($calc($ctime - %date) < 2700) { var %BTF = $calc( %BTF / 1.1 ) }
  echo -a BTF %btf
  ;echo -ag RB %randombonus
  ;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;; GET TEAMFACTORS AND TEAMGAIN / TEAMLOSS
  ;; Zwyciezka Druzyna
  var %TF = %BTF - $calc(( %winnercount - %losercount ) * $TeamCountModifier )
  var %TeamGain = $result.rc(%TF,1,$result.compare(%winnerXP,%loserXP))
  var %TeamGain = $round($calc( %TeamGain + %casebonus),0)
  if ( %teamgain < 0 ) { var %TeamGain = 0 }
  echo -a TeamGain %teamgain

  ;; Przegrana Druzyna
  var %TF = %BTF + $calc(( %losercount - %winnercount ) * $TeamCountModifier )
  var %TeamLoss = $result.rc(%TF,0,$result.compare(%loserXP,%winnerXP))
  var %TeamLoss = $round($calc( %TeamLoss - %lcasebonus),0)
  if ( %teamloss > 0 ) { var %TeamLoss = 0 }
  echo -a teamloss %teamloss
  ;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;; GET PLAYERFACTORS AND CREATE EXPDIFFARRAY
  var %expdiffarray = 0.0.0.0.0.0.0.0.0.0
  ;; Zwyciezka Druzyna
  var %i = %wfrom
  var %l = %wfrom + 4
  while ( %i <= %l ) {
    var %u = $gettok(%players,%i,46)
    var %g = $user(%u).game
    var %s = $user(%u).spree
    var %playerXP = $gettok(%exparray,%i,46)
    var %base = $result.pdefbase(%g)
    echo -ag %u XP: %playerXP %base
    var %sm = $result.streakmod(%s)
    var %base = $calc( %base * %sm )
    echo -ag %u XP: %playerXP base after spree: %base
    var %wonxp = $result.rc(%base,1,$result.compare(%playerXP,%loserXP))
    echo -ag %u 1 : %wonxp
    var %wonxp = $calc( %wonxp + %TeamGain )
    var %wonxp = $calc(((1 - (( %winnercount - %losercount ) * $TeamCountModifierMult )) * %wonxp) * 1.1)
;epdl
echo -ag %u %wonxp $gettok($($+(%,game.mode_,%game),2),1,46)
if ($gettok($($+(%,game.mode_,%game),2),1,46) == ardm) { var %wonxp = $calc(%wonxp / 2.5) }
echo -ag $game(%game).mode $game(%game).name , %u %wonxp
    var %wonxp = $round(%wonxp,0)
    if ( %wonxp < 0 ) { var %wonxp = 0 }
    var %expdiffarray = $puttok(%expdiffarray,%wonxp,%i,46)
    echo -a 1. $+ %i Uzytkownik: %u base %base otrzymal: %wonxp
    inc %i
  }

  ;; Przegrana Druzyna
  var %i = %lfrom
  var %l = %lfrom + 4
  while ( %i <= %l ) {
    var %u = $gettok(%players,%i,46)
    var %g = $user(%u).game
    var %s = $user(%u).spree
    var %playerXP = $gettok(%exparray,%i,46)
    var %base = $result.pdefbase(%g)
    var %sm = $result.streakmod(%s)
    var %base = $calc( %base * %sm * 0.75)
    var %lostxp = $result.rc(%base,0,$result.compare(%playerXP,%winnerXP))
    var %lostxp = $calc((1 + (( %losercount - %winnercount ) * $TeamCountModifierMult )) * %lostxp)
    var %lostxp = $calc(( %lostxp + %TeamLoss ) * 0.9 )
if ($gettok($($+(%,game.mode_,%game),2),1,46) == ardm) { var %lostxp = $calc(%lostxp / 2.5) }
    var %lostxp = $round(%lostxp,0)
    if ( %lostxp > 0 ) { var %lostxp = 0 }
    var %expdiffarray = $puttok(%expdiffarray,%lostxp,%i,46)
    echo -a 1. $+ %i Uzytkownik: %u base %base stracil: %lostxp
    inc %i
  }
  echo -ag ExpDiff %expdiffarray
  ;;;;;;;;;;;;;;;;;;;;;;

  var %expchange = %expdiffarray

  ;############################################################
  ;############################################################
  ;############################################################

  if (%wfrom == 1) {
    var %wfrom = 6
    var %lfrom = 1
  }
  else {
    var %wfrom = 1
    var %lfrom = 6
  }

  ;;;;;;;;;;;;;;;;;;;;;; GET XP TEAM-MODIFIERS
  ;; GET WINNER XP
  var %i = %wfrom
  var %l = %wfrom + 4
  var %n = 0
  var %winnerXP = 0
  while ( %i <= %l ) {
    if (!$istok(%exclude,$gettok(%players,%i,46),46)) {
      var %winnerXP = $calc( %winnerXP + $gettok(%exparray,%i,46) )
      inc %n
    }
    inc %i
  }
  var %winnerXP = $round($calc(%winnerXP / %n),0)
  var %winnercount = %n
  ;echo -ag XP za wygrana: %winnerxp Count: %winnercount

  ;; GET LOSER XP
  var %i = %lfrom
  var %l = %lfrom + 4
  var %n = 0
  var %loserXP = 0
  while ( %i <= %l ) {
    if (!$istok(%exclude,$gettok(%players,%i,46),46)) {
      var %loserXP = $calc( %loserXP + $gettok(%exparray,%i,46) )
      inc %n
    }
    inc %i
  }
  var %loserXP = $round($calc(%loserXP / %n),0)
  var %losercount = %n
  ;echo -ag XP za przegrana: %loserxp Podliczenie: %losercount
  ;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;; GET CASEBONUS
  var %i = %lfrom
  var %l = %lfrom + 4
  var %casebonus = 0
  while ( %i <= %l ) {
    var %u = $gettok(%players,%i,46)
    var %sp = $user(%u).spree
    if ( %sp >= 4 ) {
      var %casebonus = %casebonus + $calc(1.5 * %sp )
      ;var %spreebonusmsg = %spreebonusmsg $enclose(Druzyna %result) zostala wynagrodzona dodatkowym bonusem za przerwanie graczowi $getname(%u) $+ $chr(32) passy %sp zwyciestw z rzedu!
    }
    inc %i
  }
  var %casebonus = $round(%casebonus,0)

  if ( %gamenum >= 200 ) {
    ;; count casebonus for beginners in team
    var %i = %wfrom
    var %l = %wfrom + 4
    while ( %i <= %l ) {
      var %u = $gettok(%players,%i,46)
      var %r = $get.exprank(%u)
      if ( %r == beginner ) {
        var %casebonus = $calc(%casebonus + 3)
      }
      inc %i
    }

    ;; count casebonus for beginners in losing team ( so they lose less xp )
    var %i = %lfrom
    var %l = %lfrom + 4
    var %lcasebonus = 0
    while ( %i <= %l ) {
      var %u = $gettok(%players,%i,46)
      var %r = $get.exprank(%u)
      if ( %r == beginner ) {
        var %lcasebonus = $calc(%lcasebonus - 3)
      }
      inc %i
    }
    ;echo -ag Spreebonus: %spreebonusmsg
    ;echo -ag Casebonus: %casebonus
    ;;;;;;;;;;;;;;;;;;;;;;
  }
  ;echo -ag Casebonus: %casebonus
  ;echo -ag LCasebonus: %lcasebonus

  ;;;;;;;;;;;;;;;;;;;;;; GET BASE TEAM FACTOR
  var %BTF = $DefaultTeamFactor
  if (!%challmode) {
    var %BTF = $calc(1.5 * %BTF)
  }
  if ($calc($ctime - %date) < 1800) { var %BTF = $calc( %BTF / 1.5 ) }
  elseif ($calc($ctime - %date) < 2700) { var %BTF = $calc( %BTF / 1.3 ) }
  echo -a BTF %btf
  ;echo -ag RB %randombonus
  ;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;; GET TEAMFACTORS AND TEAMGAIN / TEAMLOSS
  ;; Zwyciezka Druzyna
  var %TF = %BTF - $calc(( %winnercount - %losercount ) * $TeamCountModifier )
  var %TeamGain = $result.rc(%TF,1,$result.compare(%winnerXP,%loserXP))
  var %TeamGain = $round($calc( %TeamGain + %casebonus),0)
  if ( %teamgain < 0 ) { var %TeamGain = 0 }
  echo -a TeamGain %teamgain

  ;; Przegrana Druzyna
  var %TF = %BTF + $calc(( %losercount - %winnercount ) * $TeamCountModifier )
  var %TeamLoss = $result.rc(%TF,0,$result.compare(%loserXP,%winnerXP))
  var %TeamLoss = $round($calc( %TeamLoss - %lcasebonus),0)
  if ( %teamloss > 0 ) { var %TeamLoss = 0 }
  echo -a teamloss %teamloss
  ;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;; GET PLAYERFACTORS AND CREATE EXPDIFFARRAY
  var %expdiffarray = 0.0.0.0.0.0.0.0.0.0
  ;; Winning team
  var %i = %wfrom
  var %l = %wfrom + 4
  while ( %i <= %l ) {
    var %u = $gettok(%players,%i,46)
    var %g = $user(%u).game
    var %s = $user(%u).spree
    var %playerXP = $gettok(%exparray,%i,46)
    var %base = $result.pdefbase(%g)
    ;echo -ag %u XP: %playerXP %base
    var %sm = $result.streakmod(%s)
    var %base = $calc( %base * %sm )
    ;echo -ag %u XP: %playerXP base after spree: %base
    var %wonxp = $result.rc(%base,1,$result.compare(%playerXP,%loserXP))
    ;echo -ag %u 1 : %wonxp
    var %wonxp = $calc( %wonxp + %TeamGain )
    var %wonxp = $calc((1 - (( %winnercount - %losercount ) * $TeamCountModifierMult )) * %wonxp)
;epdl
echo -ag %u %wonxp
if ($gettok($($+(%,game.mode_,%game),2),1,46) == ardm) { var %wonxp = $calc(%wonxp / 2.5) }
echo -ag $game(%game).mode , %u %wonxp
    var %wonxp = $round(%wonxp,0)
    if ( %wonxp < 0 ) { var %wonxp = 0 }
    var %expdiffarray = $puttok(%expdiffarray,%wonxp,%i,46)
    echo -a 2. $+ %i Uzytkownik: %u base %base otrzymal: %wonxp
    inc %i
  }

  ;; Losing team
  var %i = %lfrom
  var %l = %lfrom + 4
  while ( %i <= %l ) {
    var %u = $gettok(%players,%i,46)
    var %g = $user(%u).game
    var %s = $user(%u).spree
    var %playerXP = $gettok(%exparray,%i,46)
    var %base = $result.pdefbase(%g)
    var %sm = $result.streakmod(%s)
    var %base = $calc( %base * %sm )
    var %lostxp = $result.rc(%base,0,$result.compare(%playerXP,%winnerXP))
    var %lostxp = $calc((1 + (( %losercount - %winnercount ) * $TeamCountModifierMult )) * %lostxp)
    var %lostxp = $calc( %lostxp + %TeamLoss )
if ($gettok($($+(%,game.mode_,%game),2),1,46) == ardm) { var %lostxp = $calc(%lostxp / 2.5) }
echo -ag $game(%game).mode , %u %lostxp
    var %lostxp = $round(%lostxp,0)
    if ( %lostxp > 0 ) { var %lostxp = 0 }
    var %expdiffarray = $puttok(%expdiffarray,%lostxp,%i,46)
    echo -a 2. $+ %i Uzytkownik: %u base %base stracil: %lostxp
    inc %i
  }
  echo -ag ExpDiff %expdiffarray
  ;;;;;;;;;;;;;;;;;;;;;;
  var %altexpchange = %expdiffarray
  ; return
  ;###########################################################
  ;###########################################################
  ;###########################################################

  ;; GET POSITION OF WINNER / LOSER
  if ( %result == radiant ) {
    var %wfrom = 1
    var %lfrom = 6
  }
  elseif ( %result == dire ) {
    var %wfrom = 6
    var %lfrom = 1
  }
  elseif ( %result == draw ) {
    var %wfrom = 1
    var %lfrom = 6
  }

  var %excludelist = 0.0.0.0.0.0.0.0.0.0

if ( %result != draw ) {
    var %i = %wfrom
    var %l = %wfrom + 4
    while ( %i <= %l ) {
      var %u = $gettok(%players,%i,46)
      if (%heroes) {
        AddHero.won $gettok(%heroes,%i,46)
      }
      if (!$istok(%exclude,%u,46)) {
        noop $xsetuser(%u,1).win
;epdl
if ($gettok($($+(%,game.mode_,%game),2),1,46) == ardm) { noop $xsetuser(%u,1).gpl }
else noop $xsetuser(%u,2).gpl
        noop $xsetuser(%u,$gettok(%expchange,%i,46)).exp
        noop $setuser(%u,$gettok(%expchange,%i,46)).lastexp
        if ( $user(%u).spree >= 0 ) { noop $xsetuser(%u,1).spree }
        else { noop $setuser(%u,1).spree }
        if ( $user(%u).spree >= $user(%u).bspree )  {
          noop $setuser(%u,$v1).bspree
        }
        noop $setuser(%u,%game).lastgame
        if ( $user(%u).conf < 1000 ) {
          noop $xsetuser(%u,6).conf
        }
        var %excludelist = $puttok(%excludelist,0,%i,46)
      }
      else {
        var %excludelist = $puttok(%excludelist,1,%i,46)
        noop $xsetuser(%u,1).lost
;epdl
if ($gettok($($+(%,game.mode_,%game),2),1,46) == ardm) { noop $xsetuser(%u,-1).gpl }
else noop $xsetuser(%u,-2).gpl
        if ( $user(%u).spree >= 0 ) { noop $setuser(%u,0).spree }
        else { noop $xsetuser(%u,-1).spree }
        noop $xsetuser(%u,-30).exp
        noop $setuser(%u,-30).lastexp
        noop $xsetuser(%u,-60).conf
      }
      inc %i
    }

    var %i = %lfrom
    var %l = %lfrom + 4
    while ( %i <= %l ) {
      var %u = $gettok(%players,%i,46)
      if (%heroes) {
        AddHero.lost $gettok(%heroes,%i,46)
      }
      if (!$istok(%exclude,%u,46)) {
        noop $xsetuser(%u,1).lost
;epdl
if ($gettok($($+(%,game.mode_,%game),2),1,46) == ardm) { noop $xsetuser(%u,1).gpl }
else noop $xsetuser(%u,2).gpl
        noop $xsetuser(%u,$gettok(%expchange,%i,46)).exp
        noop $setuser(%u,$gettok(%expchange,%i,46)).lastexp
        if ( $user(%u).spree < 0 ) { noop $xsetuser(%u,-1).spree }
        else { noop $setuser(%u,-1).spree }
        noop $setuser(%u,%game).lastgame
        if ( $user(%u).conf < 1000 ) {
          noop $xsetuser(%u,4).conf
        }
        var %excludelist = $puttok(%excludelist,0,%i,46)
      }
      else {
        var %excludelist = $puttok(%excludelist,1,%i,46)
;epdl
if ($gettok($($+(%,game.mode_,%game),2),1,46) == ardm) { noop $xsetuser(%u,-1).gpl }
else noop $xsetuser(%u,-2).gpl
        noop $xsetuser(%u,1).lost
        if ( $user(%u).spree >= 0 ) { noop $setuser(%u,0).spree }
        else { noop $xsetuser(%u,-1).spree }
        noop $xsetuser(%u,-30).exp
        noop $setuser(%u,-30).lastexp
        noop $xsetuser(%u,-60).conf
      }
      inc %i
    }
  }
  else {
    var %i = 1
    while (%i <= 10) {
      var %u = $gettok(%players,%i,46)
      if ($istok(%exclude,%u,46)) {
        if ( %u = %truant ) {
          var %excludelist = $puttok(%excludelist,2,%i,46)
          noop $xsetuser(%u,1).lost
          if ( $user(%u).spree >= 0 ) { noop $setuser(%u,0).spree }
          else { noop $xsetuser(%u,-1).spree }
          noop $xsetuser(%u,-40).exp
          noop $setuser(%u,-40).lastexp
          noop $xsetuser(%u,-80).conf
        }
        else {
          var %excludelist = $puttok(%excludelist,1,%i,46)
        }
      }
      else {
        var %excludelist = $puttok(%excludelist,0,%i,46)
      }
      inc %i
    }
  }

  echo -ag excludelist %excludelist

  hadd gamedata %game %players $+ . $+ $ctime $+ . $+ $get.gamestatusconst(%result) $+ . $+ %mode $+ . $+ %challmode
  hadd gamedata $+(h.,%game) %heroes
  hadd gamedata $+(p.,%game) %excludelist

  if ( %wfrom == 1 ) {
    hadd gamedata $+(e.,%game) %expchange $+ . $+ %altexpchange
  }
  else {
    hadd gamedata $+(e.,%game) %altexpchange $+ . $+ %expchange
  }


  var %i = 1
  while ( %i <= 10 ) {
    set %player.game_ $+ $gettok(%players,%i,46) 0
    inc %i
  }

  if ( %result != draw ) {
    describe %ch Game $get.gamename(%mode,%game) $+ : Wynik potwierdzony i zapisany; Druzyna %result wygrala
    sortingrank
    if (%spreebonusmsg) {
      describe %ch %spreebonusmsg
    }
    describe %ch Zmiana XP: $get.xpchangelist(%players,%expchange)
    var %i = 1
    while ( %i <= 10 ) {
      var %e = $gettok(%expchange,%i,46)
      if ( %e < 0 ) {
        if ( %e < %max.xplost ) {
          set %max.xplost %e
          set %max.xplost.info $getname($gettok(%players,%i,46)) w grze %game dnia $date
        }
      }
      else {
        if ( %e > %max.xpgained ) {
          set %max.xpgained %e
          set %max.xpgained.info $getname($gettok(%players,%i,46)) w grze %game dnia $date
        }
      }
      inc %i
    }
  }
  else {
    describe %ch Game $get.gamename(%mode,%game) $+ : Wynik potwierdzony i zapisany; Gra anulowana
  }
  /*
  var %i = 1
  while ( %i <= 10 ) {
    var %list = %list $nauth($gettok(%players,%i,46))
    inc %i
  }
  if ( %l > 5 ) {
    mode %ch -vvvvv $gettok(%list,1-5,32)
    mode %ch -vvvvv $gettok(%list,5-,32)
  }
  else {
    mode %ch -vvvvv $gettok(%list,1-,32)
  }
  */
  sync.voice

  set %gamelist $remtok(%gamelist,%game,1,46)
  inc %game.today
  topic %ch $topicwelcome $iif(%game.on,$topicgame $topicmode $topichosts) $topicgames

  unset $+(%,game.exclude.votes_,$(%game),*)
  unset $+(%,game.exclude.voted_,$(%game),*)
  unset $+(%,game.exclude_,$(%game),*)
  unset $+(%,game.truant.voted_,$(%game),*)
  unset $+(%,game.truant.sent_,$(%game),*)
  unset $+(%,game.truant.scrg_,$(%game),*)
  unset $+(%,game.truant_,$(%game),*)
  unset $+(%,game.results.voted_,$(%game),*)
  unset $+(%,game.results.sent_,$(%game),*)
  unset $+(%,game.results.scrg_,$(%game),*)
  unset $+(%,game.results_,$(%game),*)
  ;rank.sortexp
}

on *:TEXT:.sort:*: {
  var %u = $getid2($nick)
  if ( $userlvl(%u) < 70 ) { msg $nick nie mozesz uzywac tej komendy | return }
  sortingrank
}

alias get.xpchangelist {
  var %i = 1
  var %p = $1
  var %e = $2
  while ( %i <= 10 )  {
    var %r = %r $getname($gettok(%p,%i,46)) $+ $iif($gettok(%e,%i,46) >= 0,$enclose(+ $+ $gettok(%e,%i,46)),$enclose($gettok(%e,%i,46)))
    inc %i
  }
  return %r
}

alias sort.getxp {
  return $($+(%,userxp_,$1),2)
}

alias sort.getuser {
  return $($+(%,user_,$1),2)
}

alias rank.sortexp {
  var %i = 1
  var %l = $hget(userdata,0).item
  var %n = 0
  while ( %i <= %l ) {
    if ( . !isin $hget(userdata,%i).item ) {
      inc %n
      set %user_ $+ %n $v2
      set %userxp_ $+ $v2 $user($v2).exp
    }
    inc %i
  }

  var %i = 1
  var %j = 1
  var %max = 0
  while ( %i <= %n ) {
    while ( %j <= %n ) {
      if ( $sort.getxp($sort.getuser(%j)) >= %max ) {
        var %max = $v1
        var %p = %j
      }
      inc %j
    }
    var %max = 0
    var %tmp = $sort.getuser(%i)
    set %user_ $+ %i $sort.getuser(%p)
    set %user_ $+ %p %tmp
    inc %i
    var %j = %i
  }
  /*
  var %i = 1
  while ( %i <= %n ) {
    set %rank_ $+ $sort.getuser(%i) %i
    inc %i
  }
  */
  var %i = 1
  var %j = 0
  while ( %i <= %n ) {
    if (!$user($sort.getuser(%i)).inactive) {
      set %rank_ $+ $sort.getuser(%i) $calc( %i - %j )
    }
    else {
      set %rank_ $+ $sort.getuser(%i) 0
      inc %j
    }
    inc %i
  }
  set %rank.users %n
  set %ranked.users $calc(%n - %j)
  echo -ag SORTOWANIE ZAKONCZONE!
  describe %ch Statystyki graczy zostaly zaktualizowane!
  mode %ch -m
}

;$regsubex($getname(%u),/\x03\d\d(.*?)\x03\d\d/,\1)
alias exportdata {
  write -c user_season4.txt %rank.users
  var %i = 1
  while ( %i <= %rank.users ) {
    var %u = $sort.getuser(%i)
    var %img = $($+(%,user.img_,%u),2)
    if (!%img) { var %img = 1 }
    var %lastgame.time = $game($user(%u).lastgame).time
    if (!%lastgame.time) {
      var %lastgame.time = $user(%u).voucheddate
    }
    write user_season4.txt $regsubex($getname(%u),/\x03\d\d(.*?)\x03\d\d/,\1) $user(%u).win $user(%u).lost $user(%u).exp $user(%u).spree $user(%u).bspree $user(%u).conf $user(%u).lastgame %lastgame.time %img
    inc %i
  }
  write -c hero_season4.txt 89
  var %i = 1
  while ( %i <= 89 ) {
    var %h = $($+(%,hero_,%i),2)
    write hero_season4.txt $replace(%h,$chr(32),$chr(95)) $hero(%h).pool $hero(%h).picked $hero(%h).won $hero(%h).lost $hero(%h).fp $hero(%h).sp $hero(%h).tp $hero(%h).pop
    inc %i
  }
  ;run ftp.bat
  write -c top_5.txt
  var %i = 1
  while ( %i <= 5 ) {
    write top_5.txt $getname($sort.getuser(%i)) $user($sort.getuser(%i)).exp
    inc %i
  }
  ;run ftp_top5.bat
}

alias redraw.sig {
  echo -ag Making Connection
  if ($sock(redraw)) { sockclose redraw }
  sockopen redraw www.dasnet.cz 80
}

on *:sockopen:redraw: {
  echo -ag Sending request
  ;to tell the server which file you want to receive
  var %link = /safelist/redraw.php?what=redraw
  sockwrite -n $sockname GET %link HTTP/1.1
  sockwrite -n $sockname Host: www.ligapdl.pl
  sockwrite -n $sockname user-agent: Mozilla/??
  sockwrite -n $sockname Connection: Keep-Alive
  sockwrite -n $sockname $crlf
  echo -ag Connected
}