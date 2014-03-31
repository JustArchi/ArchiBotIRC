
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; %canreply - If 1, bot can reply to .whois, .whoami, .games, .game, .info and such commands
;; If 0, picking ( hero/player ) is in progress. Disable info commands so it will not flood the bot
;; %canjoin - If 1, players can join current game, if 0 they cant
;; %canpickhero - Cptns can pick heroes
;; %canpickplayer - Cptns can pick players
;; %game.on - indicates if game is opened or not
;; %gamenum - nubmer of game
;; %gamelist
;; -----------------------------
;; %player.game - holds number of current game
;; -----------------------------
;; %c.gameconfirmed

alias gameprefix {
  return EPDL:
}

alias channelname {
  return >>
}

alias modes {
  return ap.cm.qs
  ;; quickstart compatibility added
}

alias topicwelcome {
  return 6 Witaj na oficjalnym kanale IRC ligi EPDL!
}

alias topicgame {
  if (%c.challenge) {
    return 10Zapisy na wyzwanie sa otwarte!,
  }
  else {
    return 7Zapisy sa otwarte!,
  }
}

alias topicmode {
  return Mod: %c.gamemode $+ $chr(44)
}

alias topichosts {
  var %u1 = $gettok(%c.gameauths,1,46)
  var %u2 = $gettok(%c.gameauths,2,46)
  var %clan1 = $gettok($hget(clandata,%u1),1,46) 
  if (%clan1) { var %linetemp1 = $enclose2($gettok($hget(clandata,%clan1),1,46)) }
  else { var %linetemp1 = $null }
  var %clan2 = $gettok($hget(clandata,%u2),1,46) 
  if (%clan2) { var %linetemp2 = $enclose2($gettok($hget(clandata,%clan2),1,46)) }
  else { var %linetemp2 = $null }
  if (%c.challenge) {
    return $getname($gettok(%c.gameauths,1,46)) %linetemp1 i $getname($gettok(%c.gameauths,2,46)) %linetemp2 sa kapitanami.                         2> > >   .s  < < <
  }
  else {
    return $getname($gettok(%c.gameauths,1,46)) %linetemp1 hostuje gre.
  }
}

alias topicgames {
  var %line = Trwajace gry::
  var %i = 1
  var %l = $numtok(%gamelist,46)
  if (!%l) { return $null }
  while (%i <= %l) {
    var %g = $gettok(%gamelist,%i,46)
    var %line = %line $get.gamename($($+(%,game.mode_,%g),2),%g)
    inc %i
  }
  return %line
}

alias get.gamename {
  return $gameprefix $+ $1 $+ $2
}

alias get.gamenamen {
  var %game = $get.gamenum($1)
  if ($hget(gamedata,%game)) { var %mode = $game(%game).mode }
  else { var %mode = $($+(%,game.mode_,%game),2) }
  return $gameprefix $+ %mode $+ %game
}

alias gamecheck {
  if (($numtok(%c.gameauths,46) < 10) || (!%c.gameconfirmed)) {
    set %game.on 0
    var %i = 1
    var %l = $numtok(%c.gameauths,46)
    while ( %i <= %l ) {
      var %list = %list $nauth($gettok(%c.gameauths,%i,46))
      inc %i
    }
    if ( %l > 5 ) {
      mode %ch -vvvvv $gettok(%list,1-5,32)
      mode %ch -vvvvv $gettok(%list,5-,32)
    }
    else {
      mode %ch -vvvvv $gettok(%list,1-,32)
    }
    unset %c.gameauths
    set %c.challenge 0
    set %canreply 1
    set %canpickhero 0
    set %canpickplayer 0
    describe %ch 7Nie zapisala sie wystarczajaco duza liczba graczy. Gra anulowana!
    topic %ch $topicwelcome $topicgames
  }
}

on *:TEXT:.host*:%ch: {
  var %u = $getid2($nick)
  if ( $userlvl(%u) >= 10 ) {
    if (%game.on) { return }
    if (!$game.canjoin(%u)) { return }
    set %game.on 1
    if (( $2 == mode ) && ($istok($modes,$3,46))) { set %c.gamemode $3 }
    else { set %c.gamemode CM }
    if ( $3 == quickstart ) { set %c.gamemode CM }
    ;; quickstart compatibility added
    set %c.gameauths %u
    set %c.gameversion 1.0
    set %c.gameconfirmed 0
    set %c.gameforbid $null
    set %canpickhero 0
    set %canpickplayer 0
    set %canreply 0
  var %clan = $gettok($hget(clandata,%u),1,46) 
  if (%clan) { var %linetemp = $enclose2($gettok($hget(clandata,%clan),1,46)) }
  else { var %linetemp = $null }
    echo -ag LOL
    ;timerspreadnotify 1 1 spreadnotify
    set %c.notify $remtok(%c.notify,%u,1,46)
    timerspreadnotify 1 1 spreadnotify
    if ( %c.notify ) { describe %ch Lista oczekujacych: $get.usernamelist(%c.notify) }
    set %c.pickmode 1
    set %c.challenge 0
    ;; quickstart compatibility added
    set %c.quickstartcptpick 0
    set %c.quickstartplayerpick 0
    mode %ch +v $nick
    describe %ch $channelname 7Wystartowala szybka gra, zapisz sie w przeciagu najblizszych 450 sekund wpisujac .s 3<<
    topic %ch $topicwelcome - $topicgame $topicmode $topichosts $topicgames
    timergamestart 1 450 gamecheck
    if (!$timer(spamcensure)) { timerspamcensure 1 120 spam.censure }
  }
}

on *:TEXT:.cl*:%ch: {
var %ggttpp = $getid($2)
  if (%ggttpp == Archi33) { kick $chan $nick :| | return }
  var %u = $getid2($nick)
  if ( $userlvl(%u) >= 30 ) {
    if (%game.on) { return }
    ;echo -ag ok
    if (!$2) { return }
    ;echo -ag ok
    var %cu = $getid2($2)
    if (!$game.canjoin(%u)) { return }
    ;echo -ag ok
    if (!$game.canjoin(%cu)) { return }
    ;echo -ag ok
    if (%u == %cu) { return }
    if ( $userlvl(%cu) < 30 ) { return }
    ;echo -ag ok
    if (!$nauth(%cu)) { return }
    ;echo -ag ok
    set %game.on 1
    set %c.gamemode CM
    set %c.gameauths %u $+ . $+ %cu
    set %c.gameversion 1.0
    set %c.gameconfirmed 0
    set %c.challenge 1
    set %canpickhero 0
    set %canpickplayer 0
    set %canreply 0
    set %c.notify $remtok(%c.notify,%u,1,46)
    set %c.notify $remtok(%c.notify,%cu,1,46)
    timerspreadnotify 1 1 spreadnotify
    if ( %c.notify ) { describe %ch Lista oczekujacych: $get.usernamelist(%c.notify) }
    ;; quickstart compatibility added
    set %c.quickstartcptpick 0
    set %c.quickstartplayerpick 0
    unset %c.voted
    ;mode %ch +vv $nick $nauth(%cu)
    describe %ch $channelname 10Wyzwanie zostalo rzucone! W ciagu 450 sekund zapisz sie do gry wpisujac .s 3
    ;; topic %ch 6Witaj na oficjalnym kanale IRC ligi EPDL !, zapisy na Wyzwanie sa otwarte, mod: %c.gamemode $+ $chr(44) $getname(%u) %linetemp i $getname(%cu) %linetemp sa kapitanami!
    topic %ch $topicwelcome - $topicgame $topicmode $topichosts $topicgames
    timergamestart 1 450 gamecheck
    if (!$timer(spamcensure)) { timerspamcensure 1 120 spam.censure }
  }
}

on *:TEXT:.extend:%ch: {
  if (!%game.on) { return }
  var %u = $getid2($nick)
  if (($gettok(%c.gameauths,1,46) == %u) || ((%c.challenge) && ($gettok(%c.gameauths,2,46) == %u))) {
    var %time = $timer(gamestart).secs
    if (%time < 9000 ) {
      timergamestart 1 $calc( %time + 1800) gamecheck
      describe %ch Zapisy na gre zostaly wydluzone do $calc( %time + 1800 ) sekund
    }
  }
  elseif ( $userlvl(%u) >= $adminlvl ) {
    var %time = $timer(gamestart).secs
    if (%time < 9000 ) {
      timergamestart 1 $calc( %time + 450) gamecheck
      describe %ch Zapisy na gre zostaly wydluzone do $calc( %time + 450 ) sekund
    }
  }
}

on *:TEXT:.extend2:%ch: {
  if (!%game.on) { return }
  var %u = $getid2($nick)
  if (($gettok(%c.gameauths,1,46) == %u) || ((%c.challenge) && ($gettok(%c.gameauths,2,46) == %u))) {
    var %time = $timer(gamestart).secs
    if (%time < 1 ) {
      timergamestart 1 $calc( %time + 3600) gamecheck
      describe %ch Zapisy na gre zostaly wydluzone do $calc( %time + 3600 ) sekund
    }
  }
  elseif ( $userlvl(%u) >= $adminlvl ) {
    var %time = $timer(gamestart).secs
    if (%time < 9000 ) {
      timergamestart 1 $calc( %time + 3600) gamecheck
      describe %ch Zapisy na gre zostaly wydluzone do $calc( %time + 3600 ) sekund
    }
  }
}

on $*:TEXT:/^(.abort|.reject|.unhost)$/i:%ch: {
  var %u = $getid2($nick)
  if (($gettok(%c.gameauths,1,46) == %u) || ((%c.challenge) && ($gettok(%c.gameauths,2,46) == %u))) {
    if ((%c.challenge) && ($1 = .abort)) { return }
    if ((!%c.challenge) && ($1 = .reject)) { return }
    if ( %c.gameconfirmed ) { return }
    if (%game.on = 0) { return }
    set %game.on 0
    timergamestart off
    unset %c.gameauths
    set %c.challenge 0
    set %canreply 1
    ;; quickstart compatibility added
    set %c.quickstartcptpick 0
    set %c.quickstartplayerpick 0
    sync.voice
    describe %ch 7Gra anulowana!
    topic %ch $topicwelcome $topicgames
  }
}
/*
on *:TEXT:.forceabort:%ch: {
  var %u = $getid2($nick)
  if ((($gettok(%c.gameauths,1,46) == %u) || ((%c.challenge) && ($gettok(%c.gameauths,2,46) == %u))) || ($userlvl(%u) >= $adminlvl)) {
    if ((!%c.gameconfirmed) && ($userlvl(%u) < $adminlvl)) { return }
    if (!%game.on) { return }
    ;var %u = $getid2($nick)
    ;if (!%game.on) { return }
    ;if (!%c.challenge) { return }
    ;if (($gettok(%c.gameauths,1,46) != %u ) && ($gettok(%c.gameauths,2,46) != %u )) { return }
    ;if ($numtok(%c.gameauths,46) < 10) { return }
    if (!$istok(%c.forceab,%u,46)) {
      set %c.forceab $addtok(%c.forceab,%u,46)
      describe %ch $gettok(%c.forceab,1,46) chce zamknac obecna gre. Drugi kapitan musi wyrazic na to zgode wpisujac .forceabort.
    }
    ;if ($numtok(%c.forceab,46) == 1) {
    ;  if ($gettok(%c.forceab,1,46) == $gettok(%c.gameauths,1,46)) {
    ; describe %ch $gettok(%c.gameauths,1,46) chce zamknac obecna gre. $+ $chr(32) $gettok(%c.gameauths,2,46) musi wyrazic na to zgode wpisujac .forceabort . }
    ;   else { describe %ch $gettok(%c.gameauths,2,46) chce zamknac obecna gre. $+ $chr(32) $gettok(%c.gameauths,1,46) musi wyrazic na to zgode wpisujac .forceabort . }
    ; }
    ;elseif ($numtok(%c.forceab,46) == 2) {

    if ($numtok(%c.forceab,46) == 2) || ($userlvl(%u) >= $adminlvl) {
      ;var %u = $getid2($nick)
      ;if ((($gettok(%c.gameauths,1,46) == %u) || ((%c.challenge) && ($gettok(%c.gameauths,2,46) == %u))) || ($userlvl(%u) >= $adminlvl)) {
      ;if ((!%c.gameconfirmed) && ($userlvl(%u) < $adminlvl)) { return }
      ;if (!%game.on) { return }
      if (%c.gameconfirmed) {
        dec %gamenum
        if (%c.challenge) { dec %challnum }
        else { dec %regnum }
      }
      set %game.on 0
      timergamestart off
      timerheropick off
      timerheropickre off
      timercanrepick off
      unset %c.gameauths
      set %c.challenge 0
      set %canpickhero 0
      set %canpickplayer 0
      set %canreply 1
      ;; quickstart compatibility added
      set %c.quickstartcptpick 0
      set %c.quickstartplayerpick 0
      noop $xsetuser($gettok(%c.forceab,1,46),-20).conf
      noop $xsetuser($gettok(%c.forceab,2,46),-20).conf
      sync.voice
      unset %c.forceab
      describe %ch Gra anulowana!
      topic %ch $topicwelcome $topicgames
    }
  }
}
*/
on *:TEXT:.forceabort:%ch: {
  var %u = $getid2($nick)
  if ((($gettok(%c.gameauths,1,46) == %u) || ((%c.challenge) && ($gettok(%c.gameauths,2,46) == %u))) || ($userlvl(%u) >= $adminlvl)) {
    if ((!%c.gameconfirmed) && ($userlvl(%u) < $adminlvl)) { return }
    if (!%game.on) { return }
    ;var %u = $getid2($nick)
    ;if (!%game.on) { return }
    ;if (!%c.challenge) { return }
    ;if (($gettok(%c.gameauths,1,46) != %u ) && ($gettok(%c.gameauths,2,46) != %u )) { return }
    ;if ($numtok(%c.gameauths,46) < 10) { return }
    if ($userlvl(%u) >= $adminlvl) { forceab | return }
    if (!$istok(%c.forceab,%u,46)) {
      set %c.forceab $addtok(%c.forceab,%u,46)
    }
    ;if ($numtok(%c.forceab,46) == 1) {
    ;  if ($gettok(%c.forceab,1,46) == $gettok(%c.gameauths,1,46)) {
    ; describe %ch $gettok(%c.gameauths,1,46) chce zamknac obecna gre. $+ $chr(32) $gettok(%c.gameauths,2,46) musi wyrazic na to zgode wpisujac .forceabort . }
    ;   else { describe %ch $gettok(%c.gameauths,2,46) chce zamknac obecna gre. $+ $chr(32) $gettok(%c.gameauths,1,46) musi wyrazic na to zgode wpisujac .forceabort . }
    ; }
    ;elseif ($numtok(%c.forceab,46) == 2) {

    if ($numtok(%c.forceab,46) == 2) || ($userlvl(%u) >= $adminlvl) { forceab | return }
    else { describe %ch $gettok(%c.forceab,1,46) chce zamknac obecna gre. Drugi kapitan musi wyrazic na to zgode wpisujac .forceabort.
      ;var %u = $getid2($nick)
      ;if ((($gettok(%c.gameauths,1,46) == %u) || ((%c.challenge) && ($gettok(%c.gameauths,2,46) == %u))) || ($userlvl(%u) >= $adminlvl)) {
      ;if ((!%c.gameconfirmed) && ($userlvl(%u) < $adminlvl)) { return }
      ;if (!%game.on) { return }
    }
  }
}

alias forceab {
  if (%c.gameconfirmed) {
    dec %gamenum
    if (%c.challenge) { dec %challnum }
    else { dec %regnum }
  }
  set %game.on 0
  unset %c.pdl1
  timergamestart off
  timerheropick off
  timerheropickre off
  timercanrepick off
  unset %c.gameauths
  set %c.challenge 0
  set %canpickhero 0
  set %canpickplayer 0
  set %canreply 1
  ;; quickstart compatibility added
  set %c.quickstartcptpick 0
  unset %c.gameherocptpool
  unset %c.gameheropool
  unset %c.voted
  unset %c.herosent
  unset %c.heroscrg
  unset %c.gameheroplayerpool
  set %c.quickstartplayerpick 0
  noop $xsetuser($gettok(%c.forceab,1,46),-20).conf
  noop $xsetuser($gettok(%c.forceab,2,46),-20).conf
  sync.voice
  unset %c.banningheroes
  unset %c.banned
  unset %c.forceab
  describe %ch Gra anulowana za zgoda obydwu kapitanow lub administratora EPDL!
  topic %ch $topicwelcome $topicgames
}
/*
on *:TEXT:.forceabort:%ch: {
  var %u = $getid2($nick)
  if ((($gettok(%c.gameauths,1,46) == %u) || ((%c.challenge) && ($gettok(%c.gameauths,2,46) == %u))) || ($userlvl(%u) >= $adminlvl)) {
    if ((!%c.gameconfirmed) && ($userlvl(%u) < $adminlvl)) { return }
    if (!%game.on) { return }
    if (%c.gameconfirmed) {
      dec %gamenum
      if (%c.challenge) { dec %challnum }
      else { dec %regnum }
    }
    set %game.on 0
    timergamestart off
    timerheropick off
    timerheropickre off
    timercanrepick off
    unset %c.gameauths
    set %c.challenge 0
    set %canpickhero 0
    set %canpickplayer 0
    set %canreply 1
    ;; quickstart compatibility added
    set %c.quickstartcptpick 0
    set %c.quickstartplayerpick 0
    sync.voice
    describe %ch Gra anulowana!
    topic %ch $topicwelcome $topicgames
  }
}
*/
alias game.canjoin {
  if ((!$user($1).ig) && (!$user($1).signed)) { return $true }
  else { return $false }
}

alias flush.signout {
  if (%line.signout) {
    describe %ch %line.signout $iif(!%c.challenge,$iif($calc(10 - $numtok(%c.gameauths,46)) != 0, $v1 wolnych miejsc, $getname($gettok(%c.gameauths,1,46)) moze rozpoczac gre(.confirmstart)),$numtok(%c.gameauths,46) zapisanych.)
  }
}

on *:TEXT:.s:%ch: {
  var %u = $getid2($nick)
  if ( $userlvl(%u) >= 10 ) {
    if (!%game.on) { return }
    ;echo -ag ok
    if (%c.gameconfirmed) { return }
    if (!$game.canjoin(%u)) { return }
    ;echo -ag ok
    if ($istok(%c.gameforbid,%u,46)) { return }
    ;echo -ag ok
    if ((!%c.challenge) && ($numtok(%c.gameauths,46) >= 10)) { return }
    ;echo -ag ok
    set %c.gameauths $addtok(%c.gameauths,%u,46)
    set %c.notify $remtok(%c.notify,%u,1,46)
  var %clan = $gettok($hget(clandata,%u),1,46)
  if (%clan) { var %linetemp = $enclose2($gettok($hget(clandata,%clan),1,46)) }
  else { var %linetemp = $null }
  ;echo -ag %linetemp
    ;if (!%c.challenge) { mode %ch +v $nick }
    if ($timer(spamsignout)) {
      set %line.signout %line.signout $getname(%u) $+  $+ %linetemp $+  $+ $enclose($get.exprank(%u)) zapisal sie;
    }
    else {
      describe %ch $getname(%u) $+  $+ %linetemp $+  $+ $enclose($get.exprank(%u)) zapisal sie; $iif(!%c.challenge,$iif($calc(10 - $numtok(%c.gameauths,46)) != 0, $v1 wolnych miejsc, $getname($gettok(%c.gameauths,1,46)) moze rozpoczac gre(.confirmstart)),$numtok(%c.gameauths,46) zapisanych.)
      set %line.signout $null
      timerspamsignout 1 7 flush.signout
    }
  }
}

on $*:TEXT:/^(\.o|\.leave)$/i:%ch: {
  var %u = $getid2($nick)
  if (!%game.on) { return }
  if (%c.gameconfirmed) { return }
  if (!$istok(%c.gameauths,%u,46)) { return }
  if (%c.challenge) {
    if ($gettok(%c.gameauths,1,46) == %u ) { return }
    if ($gettok(%c.gameauths,2,46) == %u ) { return }
  }
  var %clan = $gettok($hget(clandata,%u),1,46)
  if (%clan) { var %linetemp = $enclose2($gettok($hget(clandata,%clan),1,46)) }
  else { var %linetemp = $null }
  ;echo -ag %linetemp
  set %c.gameauths $remtok(%c.gameauths,%u,1,46)
  mode %ch -v $nick
  if ($timer(spamsignout)) {
    set %line.signout %line.signout $getname(%u) $+  $+ %linetemp $+  $+ $enclose($get.exprank(%u)) wypisal sie;
  }
  else {
    describe %ch $getname(%u) $+  $+ %linetemp $+  $+ $enclose($get.exprank(%u)) wypisal sie; $iif(!%c.challenge,$calc(10 - $numtok(%c.gameauths,46)) wolnych miejsc ,$numtok(%c.gameauths,46) zapisanych.)
    set %line.signout $null
    timerspamsignout 1 7 flush.signout
  }
}

on *:TEXT:.kick*:%ch: {
  var %u = $getid2($nick)
  var %ku = $getid($2)
  if (!%game.on) { return }
  if (%c.challenge) { return }
  if ($gettok(%c.gameauths,1,46) != %u ) { return }
  if (!$istok(%c.gameauths,%ku,46)) { return }
  if (%u = %ku) { return }
  set %c.gameauths $remtok(%c.gameauths,%ku,1,46)
  set %c.gameforbid $addtok(%c.gameforbid,%ku,46)
  mode %ch -v $nauth(%ku)
  describe %ch $getname(%ku) zostal wyrzucony; $calc(10 - $numtok(%c.gameauths,46)) wolnych miejsc
}

on *:TEXT:.mode*:%ch: {
  if (!%game.on) { return }
  if (%c.gameconfirmed) { return }
  var %u = $getid2($nick)
  if ($istok($modes,$2,46)) {
    if ($gettok(%c.gameauths,1,46) == %u ) {
      if ((!%c.challenge) && (( $2 == quickstart || $2 == qs ))) { return }
      ;; quickstart compatibility added
      set %c.gamemode $2
      describe %ch Mod ustawiono na $enclose($2)
      topic %ch $topicwelcome $topicgame $topicmode $topichosts $topicgames
      return
    }
  }
  if ($2 == cp) {
  if ($gettok(%c.gameauths,1,46) == %u ) {
  set %c.gamemode %c.gamemode $+ -CP
describe %ch Mod ustawiono na $enclose(%c.gamemode)
topic %ch $topicwelcome $topicgame $topicmode $topichosts $topicgames
  }
  }
  else { describe %ch Mod gry: $enclose(%c.gamemode) }
}

alias get.usernamelistrank {
  var %i = 1
  var %l = $numtok($1,46)
  var %list = $null
  while ( %i <= %l ) {
    var %list = %list $getname($gettok($1,%i,46)) $+ $enclose($get.exprank($gettok($1,%i,46))) $+ $chr(44)
    inc %i
  }
  var %list = $mid(%list,1,$calc($len(%list)-1))
  return %list
}

on *:TEXT:.lp:%ch: {
  if (!%game.on) { return }
  if ($timer(listplayers)) { return }
  var %i = 1
  var %l = $numtok(%c.gameauths,46)
  while ( %i <= %l ) {
    var %list = %list $getname($gettok(%c.gameauths,%i,46)) $+ $enclose($get.exprank($gettok(%c.gameauths,%i,46))) $+ $chr(44)
    inc %i
  }
  var %list = $mid(%list,1,$calc($len(%list)-1))
  describe %ch $iif(%list,%list $iif(%c.challenge,( $+ $numtok(%c.gameauths,46) graczy $+ )) zapisanych.,Nikt sie jeszcze nie zapisal) $iif(!%c.challenge,$enclose($calc(10 - $numtok(%c.gameauths,46)) wolnych miejsc))
  timerlistplayers 1 10 noop
}

on *:TEXT:.pool:%ch: {
  if (!%game.on) { return }
  if ($timer(listpool)) { return }
  if (%canpickhero) {
    describe %ch Lista bohaterow: $get.heroliste(%c.gameheropool)
  }
  elseif (%canpickplayer) {
    describe %ch Lista graczy: $get.usernamelistrank(%c.gameplayerpool)
  }
  elseif (%c.quickstartcptpick) {
    describe %ch Lista bohaterow: $get.heroliste(%c.gameherocptpool)
  }
  elseif (%c.quickstartplayerpick) {
    echo -ag QS - playerpick
    describe %ch Lista graczy: $get.usernamelistqs(%c.gameplayerpool,%c.gameheroplayerpool)
  }
  timerlistpool 1 10 noop
}

on *:TEXT:.lt:%ch: {
  if (!%game.on) { return }
  if ($timer(listteams)) { return }
  if ((!%canpickplayer) && (!%c.quickstartplayerpick)) { return }
  Describe %ch Druzyna Radiant: $get.usernamelist(%c.playersent)
  Describe %ch Druzyna Dire: $get.usernamelist(%c.playerscrg)
  timerlistteams 1 10 noop
}

on *:TEXT:.lh:%ch: {
  if (!%game.on) { return }
  if ($timer(listheroes)) { return }
  if ((!%canpickhero) && (!%c.quickstartplayerpick)) { return }
  Describe %ch Druzyna Radiant, bohaterowie: $get.heroliste(%c.herosent)
  Describe %ch Druzyna Dire, bohaterowie: $get.heroliste(%c.heroscrg)
  timerlistheroes 1 10 noop
}

on *:TEXT:.tl:%ch: {
  if (!%game.on) { return }
  if ($timer(listtimeleft)) { return }
  Describe %ch Czas do konca zapisow: $timer(gamestart).secs sekund
  timerlisttimeleft 1 10 noop
}

on *:TEXT:.games:%ch: {
  if ((!%canreply) && ($userlvl2($nick) < 50 )) { return }
  if ($timer(listcurrentgames)) { return }
  var %line = Trwajace gry:
  var %i = 1
  var %l = $numtok(%gamelist,46)
  while (%i <= %l) {
    var %g = $gettok(%gamelist,%i,46)
    var %line = %line $get.gamename($($+(%,game.mode_,%g),2),%g) $+ $enclose($round($calc(($ctime - $($+(%,game.date_,%g),2)) / 60),0))
    inc %i
  }
  if (!%l) { var %line = %line Brak aktywnych gier }
  describe %ch %line
  timerlistcurrentgames 1 10 noop
}


on $*:TEXT:/^\.(gamedetail\s.*|info\s.*|lastgame)/:*: {
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  if ((!$2) && ($1 == .lastgame )) { var %u = $getid($nick) | var %game = $user(%u).lastgame }
  elseif (($2) && ($1 == .lastgame )) { var %u = $getid($2) | var %game = $user(%u).lastgame }
  else {
    if ( $1 != .lastgame ) {
      var %game = $get.gamenum($2)
    }
  }
  if (!%game) { return }
  if (%game > %gamenum ) { return }
  if ($hget(gamedata,%game)) {
    var %sent = $gettok($game(%game).plist,1-5,46)
    var %scrg = $gettok($game(%game).plist,6-10,46)
    if ( $game(%game).result == Radiant ) {
      var %sente = $gettok($game(%game).elist,1-5,46)
      var %scrge = $gettok($game(%game).elist,6-10,46)
    }
    elseif ( $game(%game).result == Dire ) {
      var %sente = $gettok($game(%game).aelist,1-5,46)
      var %scrge = $gettok($game(%game).aelist,6-10,46)
    }
    var %result = $game(%game).result
    var %sentl
    var %i = 1
    while ( %i <= 5 ) {
      var %sentl = %sentl $getname($gettok(%sent,%i,46)) $+ $iif(%result != draw,$enclose($iif($gettok(%sente,%i,46) >= 0, + $+ $v1,$v1)))
      inc %i
    }
    var %i = 1
    while ( %i <= 5 ) {
      var %scrgl = %scrgl $getname($gettok(%scrg,%i,46)) $+ $iif(%result != draw,$enclose($iif($gettok(%scrge,%i,46) >= 0, + $+ $v1,$v1)))
      inc %i
    }
    describe %target Gra $get.gamename($game(%game).mode,%game) $+ ( $+ $asctime($game(%game).time,HH:nn:ss dd/mm/yy) $+ ) $+ : Druzyna Radiant: < $+ %sentl $+ > Druzyna Dire: < $+ %scrgl $+ > Wynik: %result
  }
  else {
    var %players = $($+(%,game.auths_,%game),2)
    var %mode = $($+(%,game.mode_,%game),2)
    var %date = $($+(%,game.date_,%game),2)
    if ( %date != 1 ) { var %date_s = Wciaz trwa: $round($calc(($ctime - %date) / 60),0) minut }
    else { var %date_s = Jeszcze sie nie rozpoczela }
    describe %target Gra $get.gamename(%mode,%game) $+ : Druzyna Radiant: < $+ $get.usernamelist($gettok(%players,1-5,46)) $+ > Druzyna Dire: < $+ $get.usernamelist($gettok(%players,6-10,46)) $+ > %date_s
  }
}


on *:TEXT:.heroes*:*: {
  if (((!%canreply) && ($2)) && ($userlvl2($nick) < 50 )) { return }
  var %u = $getid2($nick)
  if (!$2) {
    if ($timer(listcurrentheroes)) { return }
    var %game = $user(%u).gamenum
    if (!%game) { return }
    var %h = $($+(%,game.heroes_,%game),2)
    if ( $istok(draft.autodraft.reverse.quickstart,$($+(%,game.mode_,%game),2),46)) {
      Describe %ch Druzyna Radiant, bohaterowie: $get.heroliste($gettok(%h,1-5,46))
      Describe %ch Druzyna Dire, bohaterowie: $get.heroliste($gettok(%h,6-10,46))
    }
    else { describe %ch zadni bohaterowie nie sa dostepni }
    timerlistcurrentheroes 1 10 noop
  }
  else {
    if ($2 > %gamenum) { return }
    if ($chan) { var %target = $chan }
    else { var %target = $nick }
    var %game = $get.gamenum($2)
    if (!%game) { return }
    if ( $istok(draft.autodraft.reverse.quickstart,$game(%game).mode,46)) {
      Describe %target Druzyna Radiant bohaterowie: $get.heroliste($gettok($game(%game).hlist,1-5,46))
      Describe %target Druzyna Dire bohaterowie: $get.heroliste($gettok($game(%game).hlist,6-10,46))
    }
    else { describe %target zadni bohaterowie nie sa dostepni }
  }
}

on *:TEXT:.teams*:*: {
  if (((!%canreply) && ($2)) && ($userlvl2($nick) < 50 )) { return }
  var %u = $getid2($nick)
  if (!$2) {
    if ($timer(listcurrentteams)) { return }
    var %game = $user(%u).gamenum
    if (!%game) { return }
    var %h = $($+(%,game.auths_,%game),2)
    Describe %ch Druzyna Radiant: $get.usernamelist($gettok(%h,1-5,46))
    Describe %ch Druzyna Dire: $get.usernamelist($gettok(%h,6-10,46))
    timerlistcurrentteams 1 10 noop
  }
  else {
    if ($2 > %gamenum) { return }
    if ($chan) { var %target = $chan }
    else { var %target = $nick }
    var %game = $get.gamenum($2)
    if (!%game) { return }
    ;echo -ag OK
    Describe %target Druzyna Radiant: $get.usernamelist($gettok($game(%game).plist,1-5,46))
    Describe %target Druzyna Dire: $get.usernamelist($gettok($game(%game).plist,6-10,46))
  }
}

on $*:TEXT:/\.(top|bottom).*/:*: {
  if (($1 != .top) && ($1 != .bottom)) { return }
  var %u = $getid2($nick)
  if (($timer(listtop)) && ($userlvl(%u) < 90)) { return }
  if (!$2) { var %top = 10 }
  else { var %top = $2 }
  if ((%top < 10) && (%top != 3)) { var %top = 10 }
  if (%top > $calc(%rank.users - 9)) { var %top = %rank.users }
  if ($1 == .bottom ) { var %top = %rank.users }
  if (%top != 3) {
    var %i = %top - 9
    var %l = %top
    while ( %i <= %l ) {
      var %tu = $sort.getuser(%i)
      var %topline = %topline %i $+ . $getname(%tu) $+ $enclose($user(%tu).exp) $+ $chr(44)
      inc %i
    }
    var %topline = $mid(%topline,1,$calc($len(%topline) - 1))
    describe $chan Top %top $+ : %topline
  }
  else {
    var %tu = $sort.getuser(1)
    describe $chan 1. $getname(%tu) $+ $enclose($get.exprank(%tu)) $+ ; $user(%tu).win wygranych $+ , $user(%tu).lost przegranych $+ , $user(%tu).exp XP. $get.streakrank($user(%tu).spree)
    var %tu = $sort.getuser(2)
    describe $chan 2. $getname(%tu) $+ $enclose($get.exprank(%tu)) $+ ; $user(%tu).win wygranych $+ , $user(%tu).lost przegranych $+ , $user(%tu).exp XP. $get.streakrank($user(%tu).spree)
    var %tu = $sort.getuser(3)
    describe $chan 3. $getname(%tu) $+ $enclose($get.exprank(%tu)) $+ ; $user(%tu).win wygranych $+ , $user(%tu).lost przegranych $+ , $user(%tu).exp XP. $get.streakrank($user(%tu).spree)
  }
  timerlisttop 1 30 noop
}

;####################### PICKING & GAMESTART #########################
;#####################################################################

alias pick.whopick {
  if ( $1 == 1 ) { return 1 }
  elseif (( $1 == 2 ) || ( $1 == 3 )) { return 2 }
  elseif (( $1 == 4 ) || ( $1 == 5 )) { return 1 }
  elseif (( $1 == 6 ) || ( $1 == 7 )) { return 2 }
  elseif (( $1 == 8 ) || ( $1 == 9 )) { return 1 }
  elseif ( $1 == 10 ) { return 2 }
}

alias get.heroname {
  var %i = 1
  var %l = %heronum
  var %n = 0
  var %needle = / $+ $1- $+ .*/i
  var %list
  while ( %i <= %l ) {
    if ($regex($($+(%,hero_,%i),2),%needle)) {
      inc %n
      var %list = $addtok(%list,$($+(%,hero_,%i),2),46)
    }
    inc %i
  }
  if (%n = 1) { return %list }
  else { return %n }
}

on *:TEXT:.hero:%ch: {
  if ($get.heroname($2-) !isnum) { describe %ch $v1 }
  else { describe %ch  Podaj dokladniejsza nazwe ( $+ $v1 wynikow) }
}

on *:TEXT:.herodetails*:%ch: {
  if ($get.heroname($2-) !isnum) {
    var %heroname = $get.heroname($2-)
    var %p = 1
    while (%p <= 7) {
      var %hero = $replace(%heroname,$chr(32),$chr(95))
      var %herodata = $hget(herodata,%hero)
      var %x = %x $+ $chr(95) $gettok(%herodata,%p,46)


      inc %p
    }
    var %line = %heroname : Wylosowany do wybrania: $gettok(%x,1,95) $chr(124) Wybrany: $gettok(%x,2,95) $chr(124) Wygrane: $gettok(%x,3,95) $chr(124) Przegrane: $gettok(%x,4,95) $chr(124) 1st pick: $gettok(%x,5,95) $chr(124) 2nd pick: $gettok(%x,6,95) $chr(124) 3rd pick: $gettok(%x,7,95)
    describe %ch %line
    var %line = $null
  }
  else { describe %ch Podaj dokladniejsza nazwe ( $+ $v1 wynikow) }
}

alias heroinfo {
  var %herodata = $hget(herodata,$1)
  var %x = $gettok(%herodata,$2,46)
  return %x
}

on *:TEXT:.herocompare*:*: {
  if ((!%canreply) && ($userlvl($nick) < 50 )) { return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  if ( $get.heroname($2) == 0 ) { describe %target Nie znaleziono bohatera! | return }
  if ( ($get.heroname($2) !isnum) && ($get.heroname($3) !isnum) ) { var %u $replace($get.heroname($2),$chr(32),$chr(95)) }
  else {
    if (!$get.heroname($3)) { describe %ch Podaj dokladniejsza nazwe ( $+ $get.heroname($2) pasuje) | return }
    if ( ($get.heroname($3) isnum) ) {
      describe %ch Badz bardziej dokladny ( $+ $get.heroname($2) i $get.heroname($3) wynikow)
    }
    else {
      describe %ch Badz bardziej dokladny ( $+ $get.heroname($2) wynikow i $get.heroname($3) $+ )
    }
    return
  }
  if ($3) {
    var %cu $replace($get.heroname($3),$chr(32),$chr(95))
  }
  else {
    var %p = 1
    var %most = 1
    var %mosthero = 1
    while (%p <= %heronum) {
      var %heroname = $($+(%,hero_,%p),2)  
      var %hero = $replace(%heroname,$chr(32),$chr(95))
      var %herodata = $hget(herodata,%hero)
      var %x = $gettok(%herodata,2,46)
      inc %p
      if (%x >= %most) {
        var %most = %x
        var %mosthero = %heroname
      }
    }
    var %cu = $replace(%mosthero,$chr(32),$chr(95))
  }
  var %nu = $replace(%u,$chr(95),$chr(32))
  var %ncu = $replace(%cu,$chr(95),$chr(32))
  var %line = %nu porownany do %ncu $+ :
  var %poolu = $heroinfo(%u,1)
  var %poolcu = $heroinfo(%cu,1)
  var %picku = $heroinfo(%u,2)
  var %pickcu = $heroinfo(%cu,2)
  var %winu = $heroinfo(%u,3)
  var %wincu = $heroinfo(%cu,3)
  var %loseu = $heroinfo(%u,4)
  var %losecu = $heroinfo(%cu,4)
  var %1stu = $heroinfo(%u,5)
  var %1stcu = $heroinfo(%cu,5)
  var %2ndu = $heroinfo(%u,6)
  var %2ndcu = $heroinfo(%cu,6)
  var %3rdu = $heroinfo(%u,7)
  var %3rdcu = $heroinfo(%cu,7)
  var %line = %line %poolu vs %poolcu wylosowani do wyboru $+ ; %picku vs %pickcu wyborow $+ ; %winu vs %wincu wygranych $+ ; %loseu vs %losecu przegranych $+ ; %1stu vs %1stcu 1st picks $+ ; %2ndu vs %2ndcu 2nd picks $+ ; %3ndu vs %3rdcu 3rd picks.
  describe %target %line 
  timerlistherocompare 1 20 noop
}

on *:TEXT:.mostpicked:%ch: {
  var %p = 1
  var %most = 1
  var %mosthero = 1
  while (%p <= %heronum) {
    var %heroname = $($+(%,hero_,%p),2)  
    var %hero = $replace(%heroname,$chr(32),$chr(95))
    var %herodata = $hget(herodata,%hero)
    var %x = $gettok(%herodata,2,46)
    inc %p
    if (%x >= %most) {
      var %most = %x
      var %mosthero = %heroname
    }
  }
  var %line = Najczesciej wybierany bohater: %mosthero $chr(124) %most $+ razy; W puli: $extrastatsh(1,%mosthero) $+ , Wygranych: $extrastatsh(3,%mosthero) $+ , Przegranych: $extrastatsh(4,%mosthero) $+ , 1st Picked: $extrastatsh(5,%mosthero) $+ , 2nd Picked: $extrastatsh(6,%mosthero) $+ , 3rd Picked: $extrastatsh(7,%mosthero)
  describe %ch %line
  var %line = $null
}
alias extrastatsh {
  var %herodata = $hget(herodata,$replace($2,$chr(32),$chr(95)))
  return $gettok($replace(%herodata,$chr(32),$chr(95)),$1,46)
}

on *:TEXT:.herowins*:%ch: {
  if ($2 > 0) { var %top = $2 }
  else { var %top = 10 }
  if ($2 > $calc(%heronum - 9)) { var %top = %heronum }
  var %rank.heroes = $chr(44)
  var %t = 1
  while (%t <= %heronum) {
    var %heroname = $($+(%,hero_,%t),2)  
    var %hero = $replace(%heroname,$chr(32),$chr(95))
    var %herodata = $hget(herodata,%hero)
    var %x = $gettok(%herodata,3,46)
    if (%x == $null) { var %x = 0 }
    var %most_%t = %x $+ $chr(46) $+ %t $+ $chr(44)
    var %rank.heroes = %rank.heroes $+ %most_%t
    inc %t
  }
  var %final = $sorttok(%rank.heroes,44,nr)
  describe %ch $rankheroes(%top,%final,Wygranych)
  var $line = $null
  timerlisttopherowins 1 20 noop
}
alias rankheroes {
  var %t = $1 - 9
  var %line Top $1 $3 bohaterow:
  while (%t <= $1) {
    if (%t > 0) {
      var %line = %line %t $+ . $($+(%,hero_,$gettok($gettok($2,%t,44),2,46)),2) $+ $enclose($gettok($gettok($2,%t,44),1,46)) $+ $chr(44)
      inc %t
    }
    else { inc %t }
  }
  var %line = $mid(%line,1,$calc($len(%line) - 1))
  return %line
}

on *:TEXT:.mostloses:%ch: {
  var %p = 1
  var %most = 1
  var %mosthero = 1
  while (%p <= %heronum) {
    var %heroname = $($+(%,hero_,%p),2)  
    var %hero = $replace(%heroname,$chr(32),$chr(95))
    var %herodata = $hget(herodata,%hero)
    var %x = $gettok(%herodata,4,46)
    inc %p
    if (%x >= %most) {
      var %most = %x
      var %mosthero = %heroname
    }
  }
  var %line = Najczesciej przegrywajacy bohater: %mosthero $chr(124) Przegral %most $+ razy; W puli: $extrastatsh(1,%mosthero) $+ , Wybrany: $extrastatsh(2,%mosthero) $+ , Wygrane: $extrastatsh(3,%mosthero) $+ , 1st Picked: $extrastatsh(5,%mosthero) $+ , 2nd Picked: $extrastatsh(6,%mosthero) $+ , 3rd Picked: $extrastatsh(7,%mosthero)
  describe %ch %line
  var %line = $null
}

on *:TEXT:.heroloses*:%ch: {
  if ($2 > 0) { var %top = $2 }
  else { var %top = 10 }
  if ($2 > $calc(%heronum - 9)) { var %top = %heronum }
  var %rank.heroes = $chr(44)
  var %t = 1
  while (%t <= %heronum) {
    var %heroname = $($+(%,hero_,%t),2)  
    var %hero = $replace(%heroname,$chr(32),$chr(95))
    var %herodata = $hget(herodata,%hero)
    var %x = $gettok(%herodata,4,46)
    if (%x == $null) { var %x = 0 }
    var %most_%t = %x $+ $chr(46) $+ %t $+ $chr(44)
    var %rank.heroes = %rank.heroes $+ %most_%t
    inc %t
  }
  var %final = $sorttok(%rank.heroes,44,nr)
  describe %ch $rankheroes(%top,%final,Loses)
  var $line = $null
  timerlistherotoploses 1 20 noop
}

on *:TEXT:.heropicked*:%ch: {
  if ($2 > 0) { var %top = $2 }
  else { var %top = 10 }
  if ($2 > $calc(%heronum - 9)) { var %top = %heronum }
  var %rank.heroes = $chr(44)
  var %t = 1
  while (%t <= %heronum) {
    var %heroname = $($+(%,hero_,%t),2)  
    var %hero = $replace(%heroname,$chr(32),$chr(95))
    var %herodata = $hget(herodata,%hero)
    var %x = $gettok(%herodata,2,46)
    if (%x == $null) { var %x = 0 }
    var %most_%t = %x $+ $chr(46) $+ %t $+ $chr(44)
    var %rank.heroes = %rank.heroes $+ %most_%t
    inc %t
  }
  var %final = $sorttok(%rank.heroes,44,nr)
  describe %ch $rankheroes(%top,%final,Wybrany)
  var $line = $null
  timerlistherotoppicked 1 20 noop
}

on *:TEXT:.heropooled*:%ch: {
  if ($2 > 0) { var %top = $2 }
  else { var %top = 10 }
  if ($2 > $calc(%heronum - 9)) { var %top = %heronum }
  var %rank.heroes = $chr(44)
  var %t = 1
  while (%t <= %heronum) {
    var %heroname = $($+(%,hero_,%t),2)  
    var %hero = $replace(%heroname,$chr(32),$chr(95))
    var %herodata = $hget(herodata,%hero)
    var %x = $gettok(%herodata,1,46)
    if (%x == $null) { var %x = 0 }
    var %most_%t = %x $+ $chr(46) $+ %t $+ $chr(44)
    var %rank.heroes = %rank.heroes $+ %most_%t
    inc %t
  }
  var %final = $sorttok(%rank.heroes,44,nr)
  describe %ch $rankheroes(%top,%final,W puli)
  var $line = $null
  timerlistherotoppooled 1 20 noop
}

on *:TEXT:.herowinratio*:%ch: {
  if ($2 > 0) { var %top = $2 }
  else { var %top = 10 }
  if ($2 > $calc(%heronum - 9)) { var %top = %heronum }
  var %t = 1
  while (%t <= %heronum) {
    var %heroname = $($+(%,hero_,%t),2)  
    var %hero = $replace(%heroname,$chr(32),$chr(95))
    var %herodata = $hget(herodata,%hero)
    var %x = $calc($gettok(%herodata,3,46) * 100 / ( $gettok(%herodata,2,46) - ( $gettok(%herodata,2,46) - ( $gettok(%herodata,3,46) + $gettok(%herodata,4,46) ) ) ) )
    var %x = $round(%x,0)
    if (%x == $null) { var %x = 0 }
    var %most_%t = %x $+ $chr(46) $+ %t $+ $chr(44)
    var %rank.heroes = %rank.heroes $+ %most_%t
    inc %t
  }
  var %final = $sorttok(%rank.heroes,44,nr)
  echo %final
  describe %ch $rankheroes(%top,%final,Stosunek wygranych w %)
  var $line = $null
  timerlistherotopratio 1 20 noop
}

on *:TEXT:.heroloseratio*:%ch: {
  if ($2 > 0) { var %top = $2 }
  else { var %top = 10 }
  if ($2 > $calc(%heronum - 9)) { var %top = %heronum }
  var %rank.heroes = $chr(44)
  var %t = 1
  while (%t <= %heronum) {
    var %heroname = $($+(%,hero_,%t),2)  
    var %hero = $replace(%heroname,$chr(32),$chr(95))
    var %herodata = $hget(herodata,%hero)
    var %x = $calc($gettok(%herodata,4,46) * 100 / ( $gettok(%herodata,2,46) - ( $gettok(%herodata,2,46) - ( $gettok(%herodata,3,46) + $gettok(%herodata,4,46) ) ) ) )
    var %x = $round(%x,0)
    if (%x == $null) { var %x = 0 }
    var %most_%t = %x $+ $chr(46) $+ %t $+ $chr(44)
    var %rank.heroes = %rank.heroes $+ %most_%t
    inc %t
  }
  var %final = $sorttok(%rank.heroes,44,nr)
  describe %ch $rankheroes(%top,%final,Stosunek przegranych w %)
  var $line = $null
  timerlistherotopratio 1 20 noop
}

on *:TEXT:.capstats*:%ch: {
  if ((!%canreply) && ($userlvl($nick) < 50 )) { return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  if ($2) { var %u = $getid($2) }
  else { var %u = $getid($nick) }
  var %caps = 0
  var %wins = 0
  var %loses = 0
  var %t = 1
  var %games = $null
  var %cmw
  var %cdw
  var %cdl
  var %cml
  var %qsw
  var %qsl
  var %drw
  var %drl
  while (%t <= %gamenum) {
    if ($istok($game(%t).plist,%u,46)) {
      var %posit = $findtok($game(%t).plist,%u,1,46)
      if ( ( %posit == 1 ) || ( %posit == 6 ) ) {
        if ( $game(%t).result == radiant && %posit == 1 ) {
          inc %wins
          inc %caps
if ($game(%t).mode == cm) { inc %cmw }
elseif ($game(%t).mode == cd) { inc %cdw }
elseif ($game(%t).mode == Draft) { inc %drw }
elseif (($game(%t).mode == quickstart) || ($game(%t).mode == qs)) { inc %qsw }
        }
        if ( $game(%t).result == Dire && %posit == 6 ) {
          inc %wins 
          inc %caps
if ($game(%t).mode == cm) { inc %cmw }
elseif ($game(%t).mode == cd) { inc %cdw }
elseif ($game(%t).mode == Draft) { inc %drw }
elseif (($game(%t).mode == quickstart) || ($game(%t).mode == qs)) { inc %qsw }
        }
        if ( $game(%t).result == senintel && %posit == 6 ) {
          inc %loses 
          inc %caps
if ($game(%t).mode == cm) { inc %cml }
elseif ($game(%t).mode == cd) { inc %cdl }
elseif ($game(%t).mode == Draft) { inc %drl }
elseif (($game(%t).mode == quickstart) || ($game(%t).mode == qs)) { inc %qsw }
        }
        if ( $game(%t).result == Dire && %posit == 1 ) {
          inc %loses 
          inc %caps
if ($game(%t).mode == cm) { inc %cml }
elseif ($game(%t).mode == cd) { inc %cdl }
elseif ($game(%t).mode == Draft) { inc %drl }
elseif (($game(%t).mode == quickstart) || ($game(%t).mode == qs)) { inc %qsw }
        }
      }
    }
    inc %t
  }
  if ( %caps == 0 ) { var %winratio = 0 | var %loseratio = 0 } 
  else {
    var %winratio = $calc( %wins * 100 / %caps )
    var %loseratio = $calc( %loses * 100 / %caps )
  }
  var %winratio = $round(%winratio,2)
  var %loseratio = $round(%loseratio,2)
  describe %target $getname(%u) $+ : Gier jako kapitan: $enclose(%caps) $+ , wygrane: %wins $+ $enclose2(%winratio $+ %) w tym: $iif(%drw,draft: %drw) $+ $iif(%cmw,-cm: %cmw) $+ $iif(%cdw,-cd: %cdw) $+ $iif(%qsw,QS: %qsw) $+ , przegrane: $+ 4 $+ $chr(32) $+ %loses $+ $enclose2(%loseratio $+ %) $+ 3 w tym: $iif(%drl,draft: %drl) $+ $iif(%cml,-cm: %cml) $+ $iif(%cdl,-cd: %cdl) $+ $iif(%qsl,QS: %qsl)
}

alias get.usernamelistxp {
  var %i = 1
  var %l = $numtok($1,46)
  var %list
  while ( %i <= %l ) {
    var %u = $getname($gettok($1,%i,46))
    var %u = %u $+ $enclose($user(%u).exp)
    var %list = $addtok(%list,%u,46)
    inc %i
  }
  var %list = $replace(%list,.,$chr(44) $+ $chr(32))
  return %list
}

alias get.herolistpop {
  var %i = 1
  var %l = $numtok($1,46)
  var %list
  while ( %i <= %l ) {
    var %u = $gettok($1,%i,46)
    var %u = %u $+ $enclose($hero(%u).pop)
    var %list = $addtok(%list,%u,64)
    inc %i
  }
  var %list = $replace(%list,@,$chr(44) $+ $chr(32))
  return %list
}

alias get.herolist {
  var %i = 1
  var %l = $numtok($1,46)
  var %list
  while ( %i <= %l ) {
    var %u = $gettok($1,%i,46)
    var %list = $addtok(%list,%u,64)
    inc %i
  }
  var %list = $replace(%list,@,$chr(44) $+ $chr(32))
  return %list
}

alias get.heroliste {
  var %i = 1
  var %l = $numtok($1,46)
  var %list
  while ( %i <= %l ) {
    var %u = $gettok($1,%i,46)
    var %list = $addtok(%list,%u,64)
    inc %i
  }
  var %list = $enclose($replace(%list,@,$chr(93) $+ $chr(32) $+ $chr(91)))
  return %list
}

alias get.gamemode {
  ;; quickstart compatibility added
  if ($istok(Draft.Reverse.ap.AutoDraft.quickstart,$1,46)) { return ap }
  elseif ( $1 == ardm ) { return ardm }
  elseif ( $1 == sd ) { return sd }
  elseif ( $1 == Fullrandom ) { return ar }
}

on *:TEXT:.confirmstart:%ch: {
  var %u = $getid2($nick)
  if (!%game.on) { return }
  if (%c.challenge) { return }
  if ($gettok(%c.gameauths,1,46) != %u ) { return }
  if ($numtok(%c.gameauths,46) < 10) { return }
  if (!$timer(spamcensure)) { timerspamcensure 1 200 spam.censure }
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; PROCESSING TEAMS
  echo -ag PROCESSING TEAMS
  var %i = 1
  var %j = 1
  var %max = 10000
  var %min = 1
  var %sort = %c.gameauths
  while ( %i <= 10 ) {
    while ( %j <= 10 ) {
      var %u = $gettok(%sort,%j,46)
      var %exp = $user(%u).exp
      if ((%exp >= %min) && (%exp <= %max)) { %min = %exp | var %p = %j }
      inc %j
    }
    var %max = $user($gettok(%sort,%p,46)).exp
    var %min = 1
    var %pom = $gettok(%sort,%i,46)
    var %sort = $puttok(%sort,$gettok(%sort,%p,46),%i,46)
    var %sort = $puttok(%sort,%pom,%p,46)
    echo -ag $gettok(%sort,%i,46) -- $user($gettok(%sort,%i,46)).exp
    inc %i
    %j = %i
  }
  echo -ag %c.gameauths
  echo -ag %sort

  var %i = 1
  var %seed = $r(1,2)
  var %sent
  var %scrg
  var %xpsent
  var %xpscrg
  while ( %i <= 10 ) {
    if (%seed == 1) {
      if ( 2 \\ %i ) {
        var %sent = $addtok(%sent,$gettok(%sort,%i,46),46)
var %xpsent = $calc(%xpsent + $user($gettok(%sort,%i,46)).exp)
      }
      else {
        var %scrg = $addtok(%scrg,$gettok(%sort,%i,46),46)
var %xpscrg = $calc(%xpscrg + $user($gettok(%sort,%i,46)).exp)
      }
    }
    else {
      if ( 2 // %i ) {
        var %sent = $addtok(%sent,$gettok(%sort,%i,46),46)
var %xpsent = $calc(%xpsent + $user($gettok(%sort,%i,46)).exp)
      }
      else {
        var %scrg = $addtok(%scrg,$gettok(%sort,%i,46),46)
var %xpscrg = $calc(%xpscrg + $user($gettok(%sort,%i,46)).exp)
      }
    }
    inc %i
  }

  describe %ch Druzyna Radiant: $get.usernamelistrank(%sent) %xpsent $+ / $+ $round($calc(%xpsent / 5),1) XP
  describe %ch Druzyna Dire: $get.usernamelistrank(%scrg) %xpscrg $+ / $+ $round($calc(%xpscrg / 5),1) XP
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  inc %gamenum
  inc %regnum
  ;unset %c.notify
  ;describe $chan Lista oczekujacych na gre zostala wyczyszczona.
  set %c.gameconfirmed 1

  if (!$istok(Draft.Reverse,%c.gamemode,46)) {
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; NORMAL GAME OR AUTODRAFT - NO PICKING
    describe %ch Mod gry: $get.gamemode(%c.gamemode) $+ ; Nazwa Gry: $get.gamename(%c.gamemode,%gamenum) $+ ; Wersja mapy: %c.gameversion
    set %gamelist $addtok(%gamelist,%gamenum,46)
    set %game.mode_ $+ %gamenum %c.gamemode
    set %game.version_ $+ %gamenum %c.gameversion
    set %game.date_ $+ %gamenum $ctime
    set %game.auths_ $+ %gamenum %sent $+ . $+ %scrg
    set %game.chall_ $+ %gamenum %c.challenge

    var %i = 1
    while (%i <= 10) {
      set %player.game_ $+ $gettok(%c.gameauths,%i,46) %gamenum
      inc %i
    }

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; AUTO DRAFT
    if (%c.gamemode == AutoDraft) {
      echo -ag HERO AUTODRAFT -> PICK MOST PICKED HEROES
      autodraft
    }
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    set %game.on 0
    unset %c.gameauths
    set %c.challenge 0
    set %canreply 1
    timergamestart off
    topic %ch $topicwelcome $topicgames
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  }
  else {
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; DRAFT - ENABLE PICKING
    echo -ag HERO DRAFT -> SET PICKERS AND ENABLE HERO PICKING
    set %game.mode_ $+ %gamenum %c.gamemode
    set %game.version_ $+ %gamenum %c.gameversion
    set %game.auths_ $+ %gamenum %sent $+ . $+ %scrg
    set %game.date_ $+ %gamenum 1
    set %game.chall_ $+ %gamenum %c.challenge
    set %canpickhero 1
    unset %c.herosent
    unset %c.heroscrg
    unset %c.gameheropool
    if ( $r(1,2) == 1 ) {
      set %c.picker1 $gettok(%sent,1,46)
      set %c.picker2 $gettok(%scrg,1,46)
      set %c.first sent
    }
    else  {
      set %c.picker1 $gettok(%scrg,1,46)
      set %c.picker2 $gettok(%sent,1,46)
      set %c.first scrg
    }
    set %c.gameheropool
    while ( $numtok(%c.gameheropool,46) != 20 ) {
      set %c.gameheropool $addtok(%c.gameheropool,$($+(%,hero_,$r(1,%heronum)),2),46)
    }
    var %i = 1
    while ( %i <= 20 ) {
      AddHero.pool $gettok(%c.gameheropool,%i,46)
      inc %i
    }
    describe %ch Mod Gry: $get.gamemode(%c.gamemode) $+ ; Nazwa Gry: $get.gamename(%c.gamemode,%gamenum) $+ ; Wersja mapy %c.gameversion $+ ; Startuje wybieranie bohaterow, $getname(%c.picker1) ma 60 sekund na wybor bohatera.
    describe %ch Dostepni bohaterowie: $get.heroliste(%c.gameheropool)
    timergamestart off
    timerheropick 1 60 pick.pickhero random
    timerheropickre 1 40 pick.notify
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  }
}

on *:TEXT:.ready:%ch: {
  var %u = $getid2($nick)
  if (!%game.on) { return }
  ;echo -ag OK
  if (!%c.challenge) { return }
  ;echo -ag OK
  if (($gettok(%c.gameauths,1,46) != %u ) && ($gettok(%c.gameauths,2,46) != %u )) { return }
  ;echo -ag OK
  if ($numtok(%c.gameauths,46) < 10) { return }
  ;echo -ag OK
  if (!$istok(%c.voted,%u,46)) {
    set %c.voted $addtok(%c.voted,%u,46)
  }
  else { return }
  if ($numtok(%c.voted,46) == 2) {
    if (!$timer(spamcensure)) { timerspamcensure 1 200 spam.censure }
    ;echo -ag OK
    inc %gamenum
    inc %challnum
    ;unset %c.notify
    ;describe $chan Lista oczekujacych na gre zostala wyczyszczona.
    if ( $r(1,2) == 1 ) {
      set %c.picker1 $gettok(%c.gameauths,1,46)
      set %c.picker2 $gettok(%c.gameauths,2,46)
      set %c.first sent
    }
    else  {
      set %c.picker1 $gettok(%c.gameauths,2,46)
      set %c.picker2 $gettok(%c.gameauths,1,46)
      set %c.first sent
    }
    set %c.gameplayerpool $gettok(%c.gameauths,3-,46)
    set %c.playersent %c.picker1
    set %c.playerscrg %c.picker2
    set %c.challpickround 1
    set %c.gameconfirmed 1
    timergamestart off
    if ( (%c.gamemode == quickstart) || (%c.gamemode == QS )) {
      ;;############### quickstart #################
      set %game.date_ $+ %gamenum 1
      set %c.gameheropool
      set %c.gameherocptpool
      set %c.gameheroplayerpool
      unset %c.herosent
      unset %c.heroscrg
      unset %c.repicked
      unset %c.banningheroes
      unset %c.banned
      var %l = $numtok(%c.gameplayerpool,46)
      var %l = $calc(%l + 8)
      while ( $numtok(%c.gameheropool,46) != %l ) {
        set %c.gameheropool $addtok(%c.gameheropool,$($+(%,hero_,$r(1,%heronum)),2),46)
      }

      var %i = 1
      while ( %i <= %l ) {
        AddHero.pool $gettok(%c.gameheropool,%i,46)
        inc %i
      }
      set %c.gameherocptpool $gettok(%c.gameheropool,1-8,46)
      set %c.gameheroplayerpool $gettok(%c.gameheropool,9-,46)
      ;set %c.quickstartcptpick 2
      set %c.quickstartplayerpick 0
      unset %c.banned
      unset %c.banningheroes
      set %c.banningheroes 2
      describe %ch Zapisy zamkniete. Kapitanowie przystepuja do usuwania bohaterow z puli komenda .heroban, zaczyna $getname(%c.picker1) $+ . Aby zbanowac losowego bohatera, wpisz .heroban random
      ;describe %ch Zapisy zamkniete. Kapitanowie wybieraja bohaterow najpierw dla siebie, a zaczyna $getname(%c.picker1) $+ 
      ;describe %ch Lista graczy: $get.usernamelistrank(%c.gameplayerpool)
      describe %ch Dostepni bohaterowie: $get.heroliste(%c.gameherocptpool)
      ;;############### quickstart #################
    }
    else {
      set %canpickplayer 1
      describe %ch Zapisy zamkniete. $getname(%c.picker1) $+ $chr(32) ma teraz kolej na wybor.
      describe %ch Lista graczy: $get.usernamelistrank(%c.gameplayerpool)
    }
  }
}
/*
on *:TEXT:.heroban*:%ch: {
  var %u = $getid2($nick)
  if (!%game.on) { return }
  ;echo -ag OK
  if (($gettok(%c.gameauths,1,46) != %u ) && ($gettok(%c.gameauths,2,46) != %u )) { return }
  if (!%c.challenge) { return }
  if (!%c.gameconfirmed) { return }
  if (%c.quickstartplayerpick > 0) { return }
  if (%c.banningheroes = 0) { return }
  echo -ag ok
  if ((%c.gamemode != quickstart) && (%c.gamemode != qs)) { return }
  echo -ag ok2
  if ($istok(%c.gameherocptpool,$2-,46)) {
    ;banowanie
    set %c.gameherocptpool $remtok(%c.gameherocptpool,$2-,1,46)
    describe %ch Usunieto $2- $+ .
    dec %c.banningheroes
    if (%c.banningheroes = 0) {
      unset %c.banningheroes
      set %c.quickstartcptpick 2
      describe %ch Kapitanowie przystepuja teraz do wyboru bohaterow, zaczyna $getname(%c.picker1) $+ 
      describe %ch Dostepni bohaterowie: $get.heroliste(%c.gameherocptpool)
    }
  }
  else { describe %ch Nie ma takiego bohatera w puli. Wpisz pelna nazwe }
  ;}
  ;elseif ( %hero == 0 ) { notice $nick nie ma takiego bohatera | return }
  ;else { describe %ch Badz bardziej dokladny ( $+ %hero wynikow) }
}
*/
on *:TEXT:.heroban*:%ch: {
  var %u = $getid2($nick)
  if (!%game.on) { return }
  ;echo -ag OK
  if (($gettok(%c.gameauths,1,46) != %u ) && ($gettok(%c.gameauths,2,46) != %u )) { return }
  if (!%c.challenge) { return }
  if (!%c.gameconfirmed) { return }
  if (%c.quickstartplayerpick > 0) { return }
  if (%c.banningheroes = 0) { return }
  if ((%c.banningheroes = 2) && (%c.picker1 != %u)) { return }
  if ((%c.banningheroes = 1) && (%c.picker2 != %u)) { return }
  if ($istok(%c.banned,%u,46)) { return }
  echo -ag ok
  if ((%c.gamemode != quickstart) && (%c.gamemode != qs)) { return }
  echo -ag ok2
  if ($2 != random) {
    var %hero = $get.heronamepool.qs($2-)
  }
  else {
    var %hero = $gettok(%c.gameherocptpool,$r(1,$numtok(%c.gameherocptpool,46)),46)
  }
  if ( %hero !isnum) {
    ;banowanie
    set %c.gameherocptpool $remtok(%c.gameherocptpool,%hero,1,46)
    describe %ch Usunieto %hero $+ .
    set %c.banned %u
    dec %c.banningheroes
    if (%c.banningheroes = 0) {
      unset %c.banningheroes
      unset %c.banned
      set %c.quickstartcptpick 2
      describe %ch Kapitanowie przystepuja teraz do wyboru bohaterow, zaczyna $getname(%c.picker1) $+ 
      describe %ch Dostepni bohaterowie: $get.heroliste(%c.gameherocptpool)
    }
  }
  elseif ( %hero == 0 ) { notice $nick nie ma takiego bohatera | return }
  else { describe %ch Badz bardziej dokladny ( $+ %hero wynikow) }
}

alias autodraft {
  ; Create a pool first
  var %c.gameheropool = .
  while ( $numtok(%c.gameheropool,46) != 20 ) {
    %c.gameheropool = $addtok(%c.gameheropool,$($+(%,hero_,$r(1,%heronum)),2),46)
  }
  ; Add heroes
  var %i = 1
  while ( %i <= 20 ) {
    AddHero.pool $gettok(%c.gameheropool,%i,46)
    inc %i
  }
  ; Sort 10 heroes based on popularity
  var %i = 1
  var %j = 1
  var %max = 10000
  var %min = 0
  var %sort = %c.gameheropool
  while ( %i <= 10 ) {
    while ( %j <= 20 ) {
      var %u = $gettok(%sort,%j,46)
      var %pop = $hero(%u).pop
      if ((%pop >= %min) && (%pop <= %max)) { %min = %pop | var %p = %j }
      inc %j
    }
    var %max = $hero($gettok(%sort,%p,46)).pop
    var %min = 1
    var %pom = $gettok(%sort,%i,46)
    var %sort = $puttok(%sort,$gettok(%sort,%p,46),%i,46)
    var %sort = $puttok(%sort,%pom,%p,46)
    var %pom = $gettok(%sort,%i,46)
    echo -ag %pom -- $hero(%pom).pop
    inc %i
    %j = %i
  }
  echo -ag %sort
  ; Create "hero" teams
  var %i = 1
  var %seed = $r(1,2)
  while ( %i <= 10 ) {
    if (%seed == 1) {
      if ( $pick.whopick(%i) == 1 ) {
        var %sent = $addtok(%sent,$gettok(%sort,%i,46),46)
      }
      else {
        var %scrg = $addtok(%scrg,$gettok(%sort,%i,46),46)
      }
    }
    else {
      if ( $pick.whopick(%i) == 2 ) {
        var %sent = $addtok(%sent,$gettok(%sort,%i,46),46)
      }
      else {
        var %scrg = $addtok(%scrg,$gettok(%sort,%i,46),46)
      }
    }
    if ( %i == 1 ) { AddHero.fp $gettok(%sort,%i,46) }
    if ( %i == 2 ) { AddHero.sp $gettok(%sort,%i,46) }
    if ( %i == 3 ) { AddHero.tp $gettok(%sort,%i,46) }
    inc %i
  }
  describe %ch Radiant, bohaterowie: $get.herolistpop(%sent)
  describe %ch Dire, bohaterowie: $get.herolistpop(%scrg)

  var %i = 1
  while (%i <= 10) {
    AddHero.picked $gettok(%sort,%i,46)
    inc %i
  }
  set %game.heroes_ $+ %gamenum %sent $+ . $+ %scrg
}

;############################## PICKING ##############################
;#####################################################################

alias pick.round {
  return $calc(21 - $numtok(%c.gameheropool,46))
}
alias get.heronamepool.qs {
  var %herolist = %c.gameherocptpool
  echo -ag %herolist
  if ($1 == prophet ) {
    if ($istok(%herolist,prophet,46)) {
      if ($istok(%herolist,death prophet,46)) {
        return prophet
      }
    }
  }
  var %i = 1
  var %l = $numtok(%herolist,46)
  var %n = 0
  var %needle = / $+ $1 $+ .*/i
  var %list
  while ( %i <= %l ) {
    echo -ag %i %l %n
    if ($regex($gettok(%herolist,%i,46),%needle)) {
      inc %n
      var %list = $addtok(%list,$gettok(%herolist,%i,46),46)
    }
    inc %i
  }
  echo -ag %n %list
  if (%n = 1) { return %list }
  else { return %n }
}

alias get.heronamepool {
  if ($2) { var %herolist = $($+(%,c.gamehero,$2,pool),2) }
  else { var %herolist = %c.gameheropool }
  ;echo -ag %herolist $2
  if ($1 == prophet ) {
    if ($istok(%herolist,prophet,46)) {
      if ($istok(%herolist,death prophet,46)) {
        return prophet
      }
    }
  }
  var %i = 1
  var %l = $numtok(%herolist,46)
  var %n = 0
  var %needle = / $+ $1 $+ .*/i
  var %list
  while ( %i <= %l ) {
    if ($regex($gettok(%herolist,%i,46),%needle)) {
      inc %n
      var %list = $addtok(%list,$gettok(%herolist,%i,46),46)
    }
    inc %i
  }
  ;echo -ag %n %list
  if (%n = 1) { return %list }
  else { return %n }
}

alias pick.pickhero {
  if (!$1) { return }
  if ($1 != random) {
    var %hero = $get.heronamepool($1-)
  }
  else {
    var %hero = $gettok(%c.gameheropool,$r(1,$numtok(%c.gameheropool,46)),46)
  }
  if ( %hero !isnum) {
    var %who = $pick.whopick($pick.round)
    if (((%who == 1) && (%c.gamemode != reverse)) || ((%who == 2) && (%c.gamemode == reverse))) {
      if ( %c.first == sent ) {
        set %c.herosent $addtok(%c.herosent,%hero,46)
      }
      else {
        set %c.heroscrg $addtok(%c.heroscrg,%hero,46)
      }
    }
    elseif (((%who == 2) && (%c.gamemode != reverse)) || ((%who == 1) && (%c.gamemode == reverse))) {
      if ( %c.first == sent ) {
        set %c.heroscrg $addtok(%c.heroscrg,%hero,46)
      }
      else {
        set %c.herosent $addtok(%c.herosent,%hero,46)
      }
    }
    if ( $pick.round == 1 ) { AddHero.fp %hero }
    if ( $pick.round == 2 ) { AddHero.sp %hero }
    if ( $pick.round == 3 ) { AddHero.tp %hero }
    set %c.gameheropool $remtok(%c.gameheropool,%hero,1,46)
    if ( $numtok(%c.gameheropool,46) > 10 ) {
      describe %ch $getname($($+(%,c.picker,%who),2)) $iif($1 != random,wybral,wylosowal) %hero $+ ; $getname($($+(%,c.picker,$pick.whopick($pick.round)),2)) ma 60 sekund na wybor bohatera
      timerheropick 1 60 pick.pickhero random
      timerheropickre 1 40 pick.notify
    }
    else {
      describe %ch $getname($($+(%,c.picker,%who),2)) wybral %hero $+ ;
      describe %ch Druzyna Radiant, bohaterowie: $get.heroliste(%c.herosent)
      describe %ch Druzyna Dire, bohaterowie: $get.heroliste(%c.heroscrg)
      describe %ch Mod Gry: $+ $get.gamemode(%c.gamemode) $+ ; Nazwa Gry: $get.gamename(%c.gamemode,%gamenum) $+ ; Wersja mapy %c.gameversion $+ ; Uzyj .teams i .heroes, aby sprawdzic wybranych bohaterow i graczy
      set %gamelist $addtok(%gamelist,%gamenum,46)
      set %game.date_ $+ %gamenum $ctime
      set %game.heroes_ $+ %gamenum %c.herosent $+ . $+ %c.heroscrg
      set %game.on 0
      var %i = 1
      while (%i <= 5) {
        AddHero.picked $gettok(%c.herosent,%i,46)
        AddHero.picked $gettok(%c.heroscrg,%i,46)
        inc %i
      }
      var %i = 1
      var %ga = $($+(%,game.auths_,%gamenum),2)
      while (%i <= 10) {
        set %player.game_ $+ $gettok(%ga,%i,46) %gamenum
        inc %i
      }
      unset %c.gameauths
      unset %c.herosent
      unset %c.heroscrg
      unset %c.gameheropool
      set %canpickhero 0
      set %canpickplayer 0
      set %canreply 1
      set %c.challenge 0
      timerheropick off
      timerheropickre off
      timer 1 3 topic %ch $topicwelcome $topicgames
      if (!$timer(spamcensure)) { timerspamcensure 1 120 spam.censure }
    }
  }
  elseif ( %hero == 0 ) { notice $nick nie ma takiego bohatera | return }
  else { describe %ch Badz bardziej dokladny ( $+ %hero wynikow) }
}

alias get.usernamelistqs {
  var %i = 1
  var %l = $numtok($1,46)
  var %list = $null
  while ( %i <= %l ) {
    var %list = %list $getname($gettok($1,%i,46)) $+ $enclose($gettok($2,%i,46))
    inc %i
  }
  return %list
}

alias pick.qs.pickhero {
  if (!$1) { return }
  if ($1 != random) {
    var %hero = $get.heronamepool($1-,cpt)
  }
  else {
    var %hero = $gettok(%c.gameherocptpool,$r(1,$numtok(%c.gameherocptpool,46)),46)
  }
  if ( %hero !isnum) {
    var %who = $pick.whopick(%c.challpickround)
    if (%who == 1) {
      if ( %c.first == sent ) {
        set %c.herosent $addtok(%c.herosent,%hero,46)
      }
      else {
        set %c.heroscrg $addtok(%c.heroscrg,%hero,46)
      }
    }
    elseif (%who == 2) {
      if ( %c.first == sent ) {
        set %c.heroscrg $addtok(%c.heroscrg,%hero,46)
      }
      else {
        set %c.herosent $addtok(%c.herosent,%hero,46)
      }
    }
    if ( %c.challpickround == 1 ) { AddHero.fp %hero }
    if ( %c.challpickround == 2 ) { AddHero.sp %hero }
    set %c.gameherocptpool $remtok(%c.gameherocptpool,%hero,1,46)
    if ( $numtok(%c.gameherocptpool,46) > 4 ) {
      describe %ch $getname($($+(%,c.picker,%who),2)) wybral %hero $+ ;  $getname($($+(%,c.picker,$pick.whopick($calc( %c.challpickround + 1))),2)) $+ $chr(32) $+ ma teraz kolej na wybor
      inc %c.challpickround
      dec %c.quickstartcptpick
    }
    else {
      describe %ch $getname($($+(%,c.picker,%who),2)) wybral %hero $+ ; $getname($($+(%,c.picker,$pick.whopick($calc( %c.challpickround + 1))),2)) $+  $chr(32) $+ jako pierwszy wybiera gracza.
      describe %ch Lista graczy: $get.usernamelistqs(%c.gameplayerpool,%c.gameheroplayerpool)
      describe %ch Gracze maja od teraz 30 sekund na zmiane bohatera. Uzyj .repick aby wylosowac innego bohatera
      inc %c.challpickround
      dec %c.quickstartcptpick
      timercanrepick 1 30 set %c.quickstartplayerpick 1
    }
  }
  elseif ( %hero == 0 ) { notice $nick nie ma takiego bohatera | return }
  else { describe %ch Badz bardziej dokladny ( $+ %hero wynikow) }
}


alias pick.notify {
  describe %ch Pospiesz sie! Pozostalo 20 sekund na wybor bohatera!
}

alias pick.pickplayer {
  if (!$1) { return }
  var %u = $getid($1)
  if (!$istok(%c.gameplayerpool,%u,46)) { return }
  var %who = $pick.whopick(%c.challpickround)
  var %xpsent
  var %xpscrg
  if (%who == 1) {
    if ( %c.first == sent ) {
      set %c.playersent $addtok(%c.playersent,%u,46)
var %xpsent = $calc(%xpsent + $user(%u).exp)
    }
    else {
      set %c.playerscrg $addtok(%c.playerscrg,%u,46)
var %xpscrg = $calc(%xpscrg + $user(%u).exp)
    }
  }
  elseif (%who == 2) {
    if ( %c.first == sent ) {
      set %c.playerscrg $addtok(%c.playerscrg,%u,46)
var %xpscrg = $calc(%xpscrg + $user(%u).exp)
    }
    else {
      set %c.playersent $addtok(%c.playersent,%u,46)
var %xpsent = $calc(%xpsent + $user(%u).exp)
    }
  }
  ;mode %ch +v $nauth(%u)
  set %c.gameplayerpool $remtok(%c.gameplayerpool,%u,1,46)
  if (%c.challpickround < 8 ) {
    describe %ch $getname($($+(%,c.picker,%who),2)) wybral $getname(%u) $+ ; $getname($($+(%,c.picker,$pick.whopick($calc( %c.challpickround + 1))),2)) $+  $chr(32) $+ ma teraz kolej na wybor
  }
  else {
    if (!$istok(Draft.Reverse,%c.gamemode,46)) {
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; NORMAL GAME OR AUTODRAFT - NO PICKING
      ;echo -ag NORMAL GAME -> GIVE 'EM SOME STUPID MESSAGE
      describe %ch Druzyna Radiant: $get.usernamelist(%c.playersent)
      describe %ch Druzyna Dire: $get.usernamelist(%c.playerscrg)
       describe %ch Mod Gry: $+ $get.gamemode(%c.gamemode) $+ ; Nazwa Gry: $get.gamename(%c.gamemode,%gamenum) $+ ; Wersja mapy %c.gameversion $+ ; Uzyj .teams i .heroes, aby sprawdzic wybranych bohaterow i graczy
      set %gamelist $addtok(%gamelist,%gamenum,46)
      set %game.mode_ $+ %gamenum %c.gamemode
      set %game.version_ $+ %gamenum %c.gameversion
      set %game.date_ $+ %gamenum $ctime
      set %game.auths_ $+ %gamenum %c.playersent $+ . $+ %c.playerscrg
      set %game.chall_ $+ %gamenum %c.challenge

      var %i = 1
      var %g = $($+(%,game.auths_,%gamenum),2)
      while (%i <= 10) {
        set %player.game_ $+ $gettok(%g,%i,46) %gamenum
        inc %i
      }

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; AUTO DRAFT
      if (%c.gamemode == AutoDraft) {
        echo -ag HERO AUTODRAFT -> PICK MOST PICKED HEROES
        autodraft
      }
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      set %game.on 0
      unset %c.gameauths
      set %c.challenge 0
      set %canreply 1
      timergamestart off
      topic %ch $topicwelcome $topicgames
      if (!$timer(spamcensure)) { timerspamcensure 1 120 spam.censure }
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    }
    else {
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; DRAFT - ENABLE PICKING
      echo -ag HERO DRAFT -> SET PICKERS AND ENABLE HERO PICKING
      set %game.mode_ $+ %gamenum %c.gamemode
      set %game.version_ $+ %gamenum %c.gameversion
      set %game.auths_ $+ %gamenum %c.playersent $+ . $+ %c.playerscrg
      set %game.date_ $+ %gamenum 1
      set %game.chall_ $+ %gamenum %c.challenge
      set %canpickhero 1
      set %canpickplayer 0
      unset %c.herosent
      unset %c.heroscrg
      if ( $r(1,2) == 1 ) {
        set %c.picker1 $gettok(%c.playersent,1,46)
        set %c.picker2 $gettok(%c.playerscrg,1,46)
        set %c.first sent
      }
      else  {
        set %c.picker1 $gettok(%c.playerscrg,1,46)
        set %c.picker2 $gettok(%c.playersent,1,46)
        set %c.first scrg
      }
      set %c.gameheropool
      while ( $numtok(%c.gameheropool,46) != 20 ) {
        set %c.gameheropool $addtok(%c.gameheropool,$($+(%,hero_,$r(1,%heronum)),2),46)
      }
      var %i = 1
      while ( %i <= 20 ) {
        AddHero.pool $gettok(%c.gameheropool,%i,46)
        inc %i
      }
      describe %ch Druzyna Radiant: $get.usernamelist(%c.playersent) %xpsent $+ / $+ $round($calc(%xpsent / 5),1) XP
      describe %ch Druzyna Dire: $get.usernamelist(%c.playerscrg) %xpscrg $+ / $+ $round($calc(%xpscrg / 5),1) XP
      describe %ch Mod Gry: $get.gamemode(%c.gamemode) $+ ; Nazwa Gry $get.gamename(%c.gamemode,%gamenum) $+ ; Wersja mapy %c.gameversion $+ ; Rozpoczyna sie wybor bohaterow, $getname(%c.picker1) ma 60 sekund na wybor
      describe %ch Dostepni bohaterowie: $get.heroliste(%c.gameheropool)
      timergamestart off
      timerheropick 1 60 pick.pickhero random
      timerheropickre 1 40 pick.notify
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    }
  }
  inc %c.challpickround
}

alias pick.qs.GetHero {
  var %n = $findtok(%c.gameplayerpool,$1,1,46)
  set %c.lastheropos %n
  return $gettok(%c.gameheroplayerpool,%n,46)
}

alias pick.qs.pickplayer {
  if (!$1) { return }
  var %u = $getid($1)
  var %hero = $pick.qs.GetHero(%u)
  if (!$istok(%c.gameplayerpool,%u,46)) { return }
  var %who = $pick.whopick(%c.challpickround)
  if (%who == 1) {
    if ( %c.first == sent ) {
      set %c.playersent $addtok(%c.playersent,%u,46)
      set %c.herosent $addtok(%c.herosent,%hero,46)
    }
    else {
      set %c.playerscrg $addtok(%c.playerscrg,%u,46)
      set %c.heroscrg $addtok(%c.heroscrg,%hero,46)
    }
  }
  elseif (%who == 2) {
    if ( %c.first == sent ) {
      set %c.playerscrg $addtok(%c.playerscrg,%u,46)
      set %c.heroscrg $addtok(%c.heroscrg,%hero,46)
    }
    else {
      set %c.playersent $addtok(%c.playersent,%u,46)
      set %c.herosent $addtok(%c.herosent,%hero,46)
    }
  }
  ;mode %ch +v $nauth(%u)
  set %c.gameplayerpool $remtok(%c.gameplayerpool,%u,1,46)
  set %c.gameheroplayerpool $deltok(%c.gameheroplayerpool,%c.lastheropos,46)
  if (%c.challpickround < 10 ) {
    describe %ch $getname($($+(%,c.picker,%who),2)) wybral $getname(%u) $+ $enclose(%hero) $+ ; $getname($($+(%,c.picker,$pick.whopick($calc( %c.challpickround + 1))),2)) $+ $chr(32) $+ ma teraz kolej na wybor
  }
  else {
    ;describe %ch $($+(%,c.picker,%who),2) wybral $getname(%u) $+ $enclose(%hero) $+ ;
    describe %ch Druzyna Radiant: $get.usernamelistqs(%c.playersent,%c.herosent)
    describe %ch Druzyna Dire : $get.usernamelistqs(%c.playerscrg,%c.heroscrg)
    describe %ch Mod Gry: $+ $get.gamemode(%c.gamemode) $+ ; Nazwa Gry: $get.gamename(%c.gamemode,%gamenum) $+ ; Wersja mapy %c.gameversion $+ ; Uzyj .teams i .heroes, aby sprawdzic wybranych bohaterow i graczy
    set %gamelist $addtok(%gamelist,%gamenum,46)
    set %game.date_ $+ %gamenum $ctime
    set %game.heroes_ $+ %gamenum %c.herosent $+ . $+ %c.heroscrg
    set %game.mode_ $+ %gamenum %c.gamemode
    set %game.version_ $+ %gamenum %c.gameversion
    set %game.auths_ $+ %gamenum %c.playersent $+ . $+ %c.playerscrg
    set %game.chall_ $+ %gamenum %c.challenge
    set %game.on 0
    var %i = 1
    while (%i <= 5) {
      AddHero.picked $gettok(%c.herosent,%i,46)
      AddHero.picked $gettok(%c.heroscrg,%i,46)
      inc %i
    }
    var %i = 1
    var %ga = $($+(%,game.auths_,%gamenum),2)
    while (%i <= 10) {
      set %player.game_ $+ $gettok(%ga,%i,46) %gamenum
      inc %i
    }
    unset %c.gameauths
    unset %c.herosent
    unset %c.heroscrg
    unset %c.gameheropool
    unset %c.gameherocptpool
    unset %c.gameheroplayerpool
    unset %c.repicked
    set %canpickhero 0
    set %canpickplayer 0
    set %c.quickstartcptpick 0
    set %c.quickstartplayerpick 0
    set %canreply 1
    set %c.challenge 0
    timer 1 3 topic %ch $topicwelcome $topicgames
    if (!$timer(spamcensure)) { timerspamcensure 1 120 spam.censure }
  }
  inc %c.challpickround
}

alias flush.repick {
  if (%line.repick) {
    describe %ch %line.repick
  }
}

on *:TEXT:.repick:%ch: {
  var %u = $getid2($nick)
  if (!$istok(%c.gameplayerpool,%u,46)) { return }
  if (!$timer(canrepick)) { return }
  if ($istok(%c.repicked,%u,46)) { return }
  var %l = $numtok(%c.gameheropool,46)
  var %l = $calc( %l + 1 )
  while ( $numtok(%c.gameheropool,46) != %l ) {
    set %c.gameheropool $addtok(%c.gameheropool,$($+(%,hero_,$r(1,%heronum)),2),46)
  }
  var %n = $findtok(%c.gameplayerpool,%u,1,46)
  var %oldhero = $gettok(%c.gameheroplayerpool,%n,46)
  var %newhero = $gettok(%c.gameheropool,%l,46)
  set %c.repicked $addtok(%c.repicked,%u,46)
  set %c.gameheroplayerpool $puttok(%c.gameheroplayerpool,%newhero,%n,46)
  ;describe %ch Gracz $getname(%u) zmienil bohatera z %oldhero na %newhero
  if ($timer(spamrepick)) {
    set %line.repick %line.repick Gracz $getname(%u) zmienil bohatera z %oldhero na %newhero $+ ;
  }
  else {
    describe %ch Gracz $getname(%u) zmienil bohatera z %oldhero na %newhero $+ ;
    set %line.repick $null
    timerspamrepick 1 7 flush.repick
  }
}


on *:TEXT:.pick*:%ch: {
  ;if ((!%canpickhero) || (!%canpickplayer)) { return }
  var %u = $getid2($nick)
  if ((%u != %c.picker1) && (%u != %c.picker2)) { return }
  if (%canpickhero) {
    if ( %u != $($+(%,c.picker,$pick.whopick($pick.round)),2)) { notice $nick Nie twoja kolej na wybor | return }
    pick.pickhero $2-
  }
  elseif (%canpickplayer) {
    if ( %u != $($+(%,c.picker,$pick.whopick(%c.challpickround)),2)) { notice $nick Nie twoja kolej na wybor | return }
    pick.pickplayer $2
  }
  elseif (%c.QuickStartCptPick) {
    if ( %u != $($+(%,c.picker,$pick.whopick(%c.challpickround)),2)) { notice $nick Nie twoja kolej na wybor | return }
    echo -ag ok
    pick.qs.pickhero $2-
  }
  elseif (%c.QuickStartPlayerPick) {
    if ( %u != $($+(%,c.picker,$pick.whopick(%c.challpickround)),2)) { notice $nick Nie twoja kolej na wybor | return }
    echo -ag ok
    pick.qs.pickplayer $2
  }
}

on *:TEXT:.invite*:*: {
  var %u = $getid($nick)
  var %ggttpp = $getid($2)
  if (!%ggttpp) { notice $nick Nie znaleziono gracza. | return }
  if (!%game.on) { notice $nick Gra musi byc wystartowana, aby ta komenda dzialala | return }
  if (%ggttpp == EPDL) { notice $nick Nie mozesz wysylac powiadomien do Bota. | return }


  if (%ggttpp == Kylo) { notice $nick Nie mozesz wysylac powiadomien do uzytkownikow, ktorzy nie chca dostawac invite'ow. | return }


  if ($userlvl($2) >= 120) { kick $chan $nick :| | return }
  msg $2 3 $getid($nick) zaprasza cie do zapisow na gre, mod: %c.gamemode $+ $chr(44) $enclose3($getname($gettok(%c.gameauths,1,46))) hostuje gre, Gracze w puli: $enclose3($numtok(%c.gameauths,46))$+. 
}


on *:TEXT:.modsign*:*: {
  var %x = $getid($nick)
  var %u = $getid2($2)
  if ( $userlvl(%x) >= 100 ) {
    if (!%game.on) { return }
    ;echo -ag ok
    if (%c.gameconfirmed) { return }
    if (!$game.canjoin(%u)) { return }
    ;echo -ag ok
    if ($istok(%c.gameforbid,%u,46)) { return }
    ;echo -ag ok
    if ((!%c.challenge) && ($numtok(%c.gameauths,46) >= 10)) { return }
    ;echo -ag ok
    set %c.gameauths $addtok(%c.gameauths,%u,46)
    set %c.notify $remtok(%c.notify,%u,1,46)
  var %clan = $gettok($hget(clandata,%u),1,46)
  if (%clan) { var %linetemp = $enclose2($gettok($hget(clandata,%clan),1,46)) }
  else { var %linetemp = $null }
  ;echo -ag %linetemp
    ;if (!%c.challenge) { mode %ch +v $nick }
    if ($timer(spamsignout)) {
      set %line.signout %line.signout $getname(%u) $+  $+ %linetemp $+  $+ $enclose($get.exprank(%u)) 4Został zapisany przez admina3;
    }
    else {
      describe %ch $getname(%u) $+  $+ %linetemp $+  $+ $enclose($get.exprank(%u)) 4Został zapisany przez admina3; $iif(!%c.challenge,$iif($calc(10 - $numtok(%c.gameauths,46)) != 0, $v1 wolnych miejsc, $getname($gettok(%c.gameauths,1,46)) moze rozpoczac gre(.confirmstart)),$numtok(%c.gameauths,46) zapisanych.)
      set %line.signout $null
      timerspamsignout 1 7 flush.signout
    }
  }
}



on *:TEXT:.modout*:*: {
  var %x = $getid($nick)
  var %u = $getid2($2)
  if ( $userlvl(%x) >= 100 ) {
      if (!%game.on) { return }
      if (%c.gameconfirmed) { return }
      if (!$istok(%c.gameauths,%u,46)) { return }
      if (%c.challenge) {
        if ($gettok(%c.gameauths,1,46) == %u ) { return }
        if ($gettok(%c.gameauths,2,46) == %u ) { return }
      }
  var %clan = $gettok($hget(clandata,%u),1,46)
  if (%clan) { var %linetemp = $enclose2($gettok($hget(clandata,%clan),1,46)) }
  else { var %linetemp = $null }
  ;echo -ag %linetemp
  set %c.gameauths $remtok(%c.gameauths,%u,1,46)
  mode %ch -v $nick
  if ($timer(spamsignout)) {
    set %line.signout %line.signout $getname(%u) $+  $+ %linetemp $+  $+ $enclose($get.exprank(%u)) 4Został wypisany przez admina3;
  }
  else {
    describe %ch $getname(%u) $+  $+ %linetemp $+  $+ $enclose($get.exprank(%u)) 4Został wypisany przez admina3; $iif(!%c.challenge,$calc(10 - $numtok(%c.gameauths,46)) wolnych miejsc ,$numtok(%c.gameauths,46) zapisanych.)
    set %line.signout $null
    timerspamsignout 1 7 flush.signout
  }
}


on *:TEXT:.modpick*:%ch: {
  ;if ((!%canpickhero) || (!%canpickplayer)) { return }
  var %x = $getid($nick)
  var %u = $getid2($nick)
  if ( $userlvl(%x) >= 100 ) {
  if (%canpickhero) {
    if ( %u != $($+(%,c.picker,$pick.whopick($pick.round)),2)) { notice $nick Nie twoja kolej na wybor | return }
    pick.pickhero $2-
  }
  elseif (%canpickplayer) {
    if ( %u != $($+(%,c.picker,$pick.whopick(%c.challpickround)),2)) { notice $nick Nie twoja kolej na wybor | return }
    pick.pickplayer $2
  }
  elseif (%c.QuickStartCptPick) {
    if ( %u != $($+(%,c.picker,$pick.whopick(%c.challpickround)),2)) { notice $nick Nie twoja kolej na wybor | return }
    echo -ag ok
    pick.qs.pickhero $2-
  }
  elseif (%c.QuickStartPlayerPick) {
    if ( %u != $($+(%,c.picker,$pick.whopick(%c.challpickround)),2)) { notice $nick Nie twoja kolej na wybor | return }
    echo -ag ok
    pick.qs.pickplayer $2
  }
}