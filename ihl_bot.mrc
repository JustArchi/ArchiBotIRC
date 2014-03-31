;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copyright C
;; This program was made by ARCHI
;;				~Łukasz Domeradzki
;; All rights reserved
;; THIS VERSION CAN NOT BE EXECUTED WITHOUT ACCESS
;;
;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Admin   - 100 ( 2/3/3/10 - 75 )
;; Manager -  90 ( 0/2/2/10 - 65 )
;; Voucher -  70 ( 0/0/0/5  - 65 )
;; Censor  -  50 ( 0/0/0/3  - 20 )
;; Leader  -  30
;; User    -  10
;;

;############################## ON START #############################
;#####################################################################

on *:LOAD: {
  set %game.daymax 0
  set %max.xpgained 0
  set %max.xplost 0
}

on *:INVITE:*: {
  if ( $nick == Q ) {
    join $chan
  }
}

on *:START: { 
  hmake clandata 1000
  hload clandata clandata.txt
  timerclandata 0 180 hsave clandata clandata.txt
  hmake trialpen 100
  hload trialpen trialpen.txt
  timertrialpen 0 180 hsave trialpen trialpen.txt
  hmake friend 1000
  hload friend friend.txt
  timerfriends 0 180 hsave friend friend.txt
  hmake leaders 1000
  hload leaders leaders.txt
  timer 0 180 hsave leaders leaders.txt
  hmake userdata 1000
  hload userdata userdata.txt
  timeruser 0 180 hsave userdata userdata.txt
  hmake pendata 1000
  hload pendata pendata.txt
  timerpen 0 180 hsave pendata pendata.txt
  hmake gamedata 1000
  hload gamedata gamedata.txt
  timergame 0 180 hsave gamedata gamedata.txt
  hmake vouchdata 1000
  hload vouchdata vouchdata.txt
  timervouch 0 180 hsave vouchdata vouchdata.txt
  hmake herodata 1000
  hload herodata herodata.txt
  timerhero 0 180 hsave herodata herodata.txt
  timervars 0 180 save -rv scripts\vars.nns
  timersort 0 37200 sortingrank
  timer -oi 00:00 1 61 daychange
  timersyncvoice 0 180 sync.voice
}


alias closebot {
hfree userdata
timer user off
hfree vouchdata
timer vouch off
hfree pendata
timer pen off
hfree herodata
timer hero off
hfree gamedata
timer game off
timer sort off
timer vars off
}

alias startbot {
  hmake userdata 1000
  hload userdata userdata.txt
  timeruser 0 180 hsave userdata userdata.txt
  hmake pendata 1000
  hload pendata pendata.txt
  timerpen 0 180 hsave pendata pendata.txt
  hmake gamedata 1000
  hload gamedata gamedata.txt
  timergame 0 180 hsave gamedata gamedata.txt
  hmake vouchdata 1000
  hload vouchdata vouchdata.txt
  timervouch 0 180 hsave vouchdata vouchdata.txt
  hmake herodata 1000
  hload herodata herodata.txt
  timerhero 0 180 hsave herodata herodata.txt
  timervars 0 180 save -rv scripts\vars.nns
  timersort 0 37200 sortingrank
}
on *:EXIT: {
  hsave userdata userdata.txt
  hsave gamedata gamedata.txt
  hsave vouchdata vouchdata.txt
  hsave herodata herodata.txt
  hsave clandata clandata.txt
  hsave friend friend.txt
  hsave pendata pendata.txt
  save -rv scripts\vars.nns

}

;########################### ALIAS DAYCHANGE #########################
;#####################################################################

on *:TEXT:.fix *:*: {
  var %u = $getid($nick)
  if ( $userlvl(%u) < 70 ) { return }
  set %player.game_ $+ $2 0
  hsave userdata userdata.txt
  hsave vouchdata vouchdata.txt
}

on *:TEXT:.say *:*: {
  var %u = $getid($nick)
  if ( $userlvl(%u) < 70 ) { return }
  describe %ch $2-
}

alias dupka {
  echo -ag $nauth($1) $nauth($2)
}

alias sortingrank {
  mode %ch +m
  msg %ch 7Uwaga! Trwa sortowanie rankingu graczy. Prosimy o cierpliwosc!
  timer 1 2 rank.sortexp
  timer 1 30 mode %ch -m
}

alias botversion {
  return 1.0 by Archi
}

alias daychange {
  unset %cen.today_*
  var %i = 1
  var %l = %rank.users
  while ( %i <= %l ) {
    var %u = $sort.getuser(%i)
    var %lg = $user(%u).lastgame
    if ( $calc($ctime - $game(%lg).time) > 1728000 ) {
      var %e = $user(%u).exp
      if ( %e > 1000 ) {
        if ( $calc($ctime - $user(%u).lastdecay ) > 1728000 ) {
          set %last.decay_ $+ %u $ctime
          var %decay = $round($calc( %e * -0.04 ),0)
          noop $xsetuser(%u,%decay).exp
          AddPenalty $botname %u Decayed %decay
        }
      }
    }
    if ( $calc($ctime - $game(%lg).time) <= 1728000 ) {
      if ( $user(%u).conf < 1000 ) {
        noop $xsetuser(%u,5).conf
      }
    }
    inc %i
  }
  var %ctime = $ctime
  mkdir backup\ $+ %ctime
  copy userdata.txt $+(backup\,%ctime,\userdata.txt)
  copy gamedata.txt $+(backup\,%ctime,\gamedata.txt)
  copy vouchdata.txt $+(backup\,%ctime,\vouchdata.txt)
  copy herodata.txt $+(backup\,%ctime,\herodata.txt)
  copy pendata.txt $+(backup\,%ctime,\pendata.txt)
  copy clandata.txt $+(backup\,%ctime,\clandata.txt)
  copy learn.txt $+(backup\,%ctime,\learn.txt)
  copy reply.txt $+(backup\,%ctime,\reply.txt)
  copy react.txt $+(backup\,%ctime,\react.txt)
  copy quotes.txt $+(backup\,%ctime,\quotes.txt)
  copy words.txt $+(backup\,%ctime,\words.txt)
  copy idle.txt $+(backup\,%ctime,\idle.txt)
  copy scripts\vars.nns $+(backup\,%ctime,\vars.nns)


  if (%game.today >= %game.daymax) {
    set %game.daymax %game.today
    set %game.daymax.time $ctime
  }
  set %game.today 0
  timer -oi 00:00 1 61 daychange
}
;######################### LEADERS ###################################
;#####################################################################

alias backup2 {
  var %ctime = $ctime
  mkdir backup\ $+ %ctime
  copy userdata.txt $+(backup\,%ctime,\userdata.txt)
  copy gamedata.txt $+(backup\,%ctime,\gamedata.txt)
  copy vouchdata.txt $+(backup\,%ctime,\vouchdata.txt)
  copy herodata.txt $+(backup\,%ctime,\herodata.txt)
  copy pendata.txt $+(backup\,%ctime,\pendata.txt)
  copy clandata.txt $+(backup\,%ctime,\clandata.txt)
  copy scripts\vars.nns $+(backup\,%ctime,\vars.nns)
}
alias lider {
  var %i = 1
  var %l = $hget(userdata,0).item
  while ( %i <= %l ) {
    if ( . !isin $hget(userdata,%i).item ) {
      var %u = $v2
      if ( $userlvl(%u) >= 30 ) {
        hadd leaders $+(%u)                        
      }

    }
    inc %i
  }
}

on *:TEXT:.leaders:*: {
  var %u = $getid($nick)
  if ((!%canreply)) { return }
  if ( $userlvl(%u) < 30 ) { msg $nick Musisz posiadac przynajmniej range challengera, aby uzywac tej komendy! | return }
  lider
  onlineleader
}


alias onlineleader {
  var %i = 1
  var %l = $hget(leaders,0).item 
  var %linia = Challengerzy Online:
  var %liczba = 0
  var %razem = 0
  while ( %i <= %l ) {
    var %u = $nauth($hget(leaders,%i).item)
    var %n = $hget(leaders,%i).item
    if ( %u ison $chan ) && ($game.canjoin(%n)) {
      %linia = $addtok(%linia,%u,32)
    }
    inc %liczba
    inc %i
  }
  var %razem = $calc($numtok(%linia,32) - 2)
  describe %ch %linia / Razem: $enclose(%razem sposrod %liczba)
} 

;###################### BASIC ALIASES ( returns ) ####################
;#####################################################################

on *:text:.ts:%ch: {
  msg $chan %ts
}

alias botname {
  return EPDL
}

alias adminlvl {
  return 70
}

alias managerlvl {
  return 90
}

alias describe {
  if ( $len($2-) < 400 ) { describe $1 03 $+ $2- }
  else {
    var %line = $2-
    var %l = $numtok(%line,32)
    var %i = 1
    var %r
    while ( %i <= %l ) {
      if ( $len(%r) > 400 ) { describe $1 03 $+ %r [wiecej...] | var %r = $null }
      var %r = %r $gettok(%line,%i,32)
      inc %i
    }
    describe $1 03 $+ %r
  }
}

alias enclose {
  return $chr(91) $+ $1 $+ $chr(93)
}

alias enclose2 {
  return ( $+ $1 $+ )
}

alias enclose3 {
  return < $+ $1 $+ >
}

alias getauth {
  return $hget(userdata,$+(id.,$1))
}

alias getid {
  if ($auth($1)) { return $v1 }
  elseif ($hget(userdata,$1)) { return $1 }
  elseif ($hget(userdata,$+(id.,$1))) { return $v1 }
  else { return $null }
}

alias getpdl2 {
  if ($auth($1)) { return $v1 }
  elseif ($hget(pdl2,$1)) { return $1 }
  elseif ($hget(pdl2,$+(id.,$1))) { return $v1 }
  else { return $null }
}

alias lvlpdl2 {
  if ($hget(pdl2,$+(level.,$getid($1)))) { return $v1 }
  else { return 0 }
}

alias getid2 {
  if ($auth($1)) { return $v1 }
  else { return $null }
}


alias getname {
  if ( $1 != DASik ) {
    var %n = $gettok($hget(userdata,$getid($1)),10,46)
    return %n
  }
  else { return DASik }
}

alias userlvl {
  if ($hget(userdata,$+(level.,$getid($1)))) { return $v1 }
  else { return 0 }
}

alias userlvl2 {
  if ($hget(userdata,$+(level.,$getid2($1)))) { return $v1 }
  else { return 0 }
}

alias spam.censure {
  describe %ch 3 Kulturka obowiązuje.
}

;register format: win.lost.draw.exp.lastexp.spree.bestspree.lastgame.conf.name
;id format: id.USERNAME -> AUTH

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GET STUFF ABOUT USER

alias user {
  if (!$1) { return }
  ;var %n = $getid($1)
  var %n = $1
  if ( $prop == win ) {
    return $gettok($hget(userdata,%n),1,46)
  }
  if ( $prop == lost ) {
    return $gettok($hget(userdata,%n),2,46)
  }
  if ( $prop == draw ) {
    return $gettok($hget(userdata,%n),3,46)
  }
  if ( $prop == exp ) {
    return $gettok($hget(userdata,%n),4,46)
  }
  if ( $prop == lastexp ) {
    return $gettok($hget(userdata,%n),5,46)
  }
  if ( $prop == spree ) {
    return $gettok($hget(userdata,%n),6,46)
  }
  if ( $prop == bspree ) {
    return $gettok($hget(userdata,%n),7,46)
  }
  if ( $prop == lastgame ) {
    return $gettok($hget(userdata,%n),8,46)
  }
  if ( $prop == conf ) {
    return $gettok($hget(userdata,%n),9,46)
  }
  if ( $prop == name ) {
    return $gettok($hget(userdata,%n),10,46)
  }
  if ( $prop == gpl ) {
    return $gettok($hget(userdata,%n),11,46)
  }
  if ( $prop == cap ) {
    return $gettok($hget(userdata,%n),12,46)
  }
  if ( $prop == game ) {
    return $calc($gettok($hget(userdata,%n),1,46) + $gettok($hget(userdata,%n),2,46) + $gettok($hget(userdata,%n),3,46))
  }
  if ( $prop == winp ) {
    return $round($calc($gettok($hget(userdata,%n),1,46) * 100 / $calc($gettok($hget(userdata,%n),1,46) + $gettok($hget(userdata,%n),2,46) + $gettok($hget(userdata,%n),3,46))),0)
  }
  if ( $prop == lostp ) {
    return $round($calc($gettok($hget(userdata,%n),2,46) * 100 / $calc($gettok($hget(userdata,%n),1,46) + $gettok($hget(userdata,%n),2,46) + $gettok($hget(userdata,%n),3,46))),0)
  }
  if ( $prop == drawp ) {
    return $round($calc($gettok($hget(userdata,%n),3,46) * 100 / $calc($gettok($hget(userdata,%n),1,46) + $gettok($hget(userdata,%n),2,46) + $gettok($hget(userdata,%n),3,46))),0)
  }
  if ( $prop == ig ) {
    return $($+(%,player.game_,%n),2)
  }
  if ( $prop == signed ) {
    return $istok(%c.gameauths,%n,46)
  }
  if ( $prop == gamenum ) {
    return $($+(%,player.game_,%n),2)
  }
  if ( $prop == vouchedby ) {
    return $gettok($hget(vouchdata,$+(info.,%n)),1,46)
  }
  if ( $prop == promoteby ) {
    return $gettok($hget(vouchdata,$+(info.,%n)),2,46)
  }
  if ( $prop == vouchinfo ) {
    return $hget(vouchdata,$+(info.,%n))
  }
  if ( $prop == voucheddate ) {
    return $hget(vouchdata,$+(date.,%n))
  }
  if ( $prop == rank ) {
    return $($+(%,rank_,%n),2) $+ / $+ %ranked.users
  }
  if ( $prop == rankonly ) {
    return $($+(%,rank_,%n),2)
  }
  if ( $prop == lastdecay ) {
    if ($($+(%,last.decay_,%n),2)) { return $v1 }
    else { return 0 }
  }
  if ( $prop == inactive ) {
    var %lg = $gettok($hget(userdata,%n),8,46)
    var %g = $calc($gettok($hget(userdata,%n),1,46) + $gettok($hget(userdata,%n),2,46) + $gettok($hget(userdata,%n),3,46))
    if ((%g == 0) || ($calc($ctime - $game(%lg).time) > 2592000)) {
      return $true
    }
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SET VALUE TO $2

alias setuser {
  if (!$1) { return }
  ;var %n = $getid($1)
  var %n = $1
  if ($2 isnum) { var %p = $int($2) }
  if ( $prop == win ) {
    var %a = $puttok($hget(userdata,%n),%p,1,46)
    var %canset = 1
  }
  if ( $prop == lost ) {
    var %a = $puttok($hget(userdata,%n),%p,2,46)
    var %canset = 1
  }
  if ( $prop == draw ) {
    var %a = $puttok($hget(userdata,%n),%p,3,46)
    var %canset = 1
  }
  if ( $prop == exp ) {
    var %a = $puttok($hget(userdata,%n),%p,4,46)
    var %canset = 1
  }
  if ( $prop == lastexp ) {
    var %a = $puttok($hget(userdata,%n),%p,5,46)
    var %canset = 1
  }
  if ( $prop == spree ) {
    var %a = $puttok($hget(userdata,%n),%p,6,46)
    var %canset = 1
  }
  if ( $prop == bspree ) {
    var %a = $puttok($hget(userdata,%n),%p,7,46)
    var %canset = 1
  }
  if ( $prop == lastgame ) {
    var %a = $puttok($hget(userdata,%n),%p,8,46)
    var %canset = 1
  }
  if ( $prop == conf ) {
    var %a = $puttok($hget(userdata,%n),%p,9,46)
    var %canset = 1
  }
  if ( $prop == name ) {
    var %a = $puttok($hget(userdata,%n),$2,10,46)
    var %canset = 1
  }
  if ( $prop == gpl ) {
    var %a = $puttok($hget(userdata,%n),$2,11,46)
    var %canset = 1
  }
  if ( $prop == cap ) {
    var %a = $puttok($hget(userdata,%n),$2,12,46)
    var %canset = 1
  }
  if (%canset) {
    hadd userdata %n %a
    return 0
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SET VALUE TO <value> + $2

alias xsetuser {
  if (!$1) { return }
  ;var %n = $getid($1)
  var %n = $1
  if ($2 isnum) { var %p = $int($2) }
  else { return 0 }
  if ( $prop == win ) {
    var %a = $puttok($hget(userdata,%n),$calc($user(%n).win + %p),1,46)
    var %canset = 1
  }
  if ( $prop == lost ) {
    var %a = $puttok($hget(userdata,%n),$calc($user(%n).lost + %p),2,46)
    var %canset = 1
  }
  if ( $prop == draw ) {
    var %a = $puttok($hget(userdata,%n),$calc($user(%n).draw + %p),3,46)
    var %canset = 1
  }
  if ( $prop == exp ) {
    var %a = $puttok($hget(userdata,%n),$calc($user(%n).exp + %p),4,46)
    var %canset = 1
  }
  if ( $prop == lastexp ) {
    var %a = $puttok($hget(userdata,%n),$calc($user(%n).lastexp + %p),5,46)
    var %canset = 1
  }
  if ( $prop == spree ) {
    var %a = $puttok($hget(userdata,%n),$calc($user(%n).spree + %p),6,46)
    var %canset = 1
  }
  if ( $prop == bspree ) {
    var %a = $puttok($hget(userdata,%n),$calc($user(%n).bspree + %p),7,46)
    var %canset = 1
  }
  if ( $prop == lastgame ) {
    var %a = $puttok($hget(userdata,%n),$calc($user(%n).lastgame + %p),8,46)
    var %canset = 1
  }
  if ( $prop == conf ) {
    var %a = $puttok($hget(userdata,%n),$calc($user(%n).conf + %p),9,46)
    var %canset = 1
  }
  if ( $prop == gpl ) {
    var %a = $puttok($hget(userdata,%n),$calc($user(%n).gpl + %p),11,46)
    var %canset = 1
  }
  if ( $prop == cap ) {
    var %a = $puttok($hget(userdata,%n),$calc($user(%n).cap + %p),12,46)
    var %canset = 1
  }
  if (%canset) {
    hadd userdata %n %a
    return 0
  }
}

;########################### USER MANAGEMENT #########################
;#####################################################################

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Admin   - 100 ( 1/3/3/10 - 50 )
;; Manager -  90 ( 0/2/2/10 - 40 )
;; Voucher -  70 ( 0/0/0/5  - 40 )
;; Censor  -  50 ( 0/0/0/3  - 15 )
;; Leader  -  30
;; User    -  10

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VOUCH DATA STRUCTURE
;; info.ID
;; vouched_by.promoted_by
;;
;; m.ID
;; manager
;; promoted by nick
;; v.ID
;; voucher1.voucher2.voucher3
;; promoted by nick
;; c.ID
;; censor1.censor2.censor3
;; promoted by nick
;; l.ID
;; leader1-10
;; leaders promoted by nick
;; u.ID
;; number of users vouched.


/*
;; Admin   - 100 ( 2/3/3/10 - 300 )
;; Manager -  90 ( 0/2/2/10 - 65 )
;; Voucher -  70 ( 0/0/0/5  - 65 )
;; Censor  -  50 ( 0/0/0/3  - 10 )
*/

alias maxvouch {
  if ( $2 == user ) {
    if ( $1 >= 100 ) { return 1000 }
    elseif ( $1 >= 90 ) { return 1000 }
    elseif ( $1 >= 70 ) { return 1000 }
    ;elseif ( $1 >= 50 ) { return 0 }
    else { return 0 }
  }
  if ( $2 == Gracz ) {
    if ( $1 >= 100 ) { return 1000 }
    elseif ( $1 >= 90 ) { return 1000 }
    elseif ( $1 >= 70 ) { return 1000 }
    ;elseif ( $1 >= 50 ) { return 0 }
    else { return 0 }
  }
  if ( $2 == Gracz 7Premium3 ) {
    if ( $1 >= 100 ) { return 1000 }
    elseif ( $1 >= 90 ) { return 1000 }
    elseif ( $1 >= 70 ) { return 1000 }
    ;elseif ( $1 >= 50 ) { return 0 }
    else { return 0 }
  }
  if ( $2 == 2VIP3 ) {
    if ( $1 >= 100 ) { return 1000 }
    elseif ( $1 >= 90 ) { return 1000 }
    elseif ( $1 >= 70 ) { return 1000 }
    ;elseif ( $1 >= 50 ) { return 0 }
    else { return 0 }
  }
  if ( $2 == 7Challenger3 ) {
    if ( $1 >= 100 ) { return 1000 }
    elseif ( $1 >= 90 ) { return 1000 }
    elseif ( $1 >= 70 ) { return 100 }
    ;elseif ( $1 >= 50 ) { return 0 }
    else { return 0 }
  }
  if ( $2 == 6Streamer3 ) {
    if ( $1 >= 100 ) { return 1000 }
    elseif ( $1 >= 90 ) { return 1000 }
    elseif ( $1 >= 70 ) { return 1000 }
    else { return 0 }
  }
  if ( $2 == voucher ) {
    if ( $1 >= 100 ) { return 20 }
    elseif ( $1 >= 90 ) { return 0 }
    else { return 0 }
  }
  if ( $2 == 12Menadzer EPDL3 ) {
    if ( $1 >= 100 ) { return 5 }
    else { return 0 }
  }
  if ( $2 == 10Administrator EPDL3 ) {
    if ( $1 >= 101 ) { return 5 }
    else { return 0 }
  }
    if ( $2 == 4Head Admin EPDL3 ) {
    if ( $1 >= 101 ) { return 0 }
    else { return 0 }
  }
}

alias nextlevel {
  if ( $1 >= 100 ) { return 101 }
  elseif ( $1 >= 90 ) { return 100 }
  elseif ( $1 >= 70 ) { return 90 }
  elseif ( $1 >= 45 ) { return 70 }
  elseif ( $1 >= 40 ) { return 45 }
  elseif ( $1 >= 30 ) { return 40 }
  elseif ( $1 >= 20 ) { return 30 }
  elseif ( $1 >= 15 ) { return 20 }
  elseif ( $1 >= 10 ) { return 15 }
  else { return 0 }
}

alias prevlevel {
  if ( $1 >= 101 ) { return 100 }
  elseif ( $1 >= 100 ) { return 90 }
  elseif ( $1 >= 90 ) { return 70 }
  elseif ( $1 >= 70 ) { return 45 }
  elseif ( $1 >= 45 ) { return 40 }
  elseif ( $1 >= 40 ) { return 30 }
  elseif ( $1 >= 30 ) { return 20 }
  elseif ( $1 >= 20 ) { return 15 }
  elseif ( $1 >= 15 ) { return 10 }
  else { return 0 }
}

alias level.str {
  if ( $1 >= 101 ) { return 4Head Admin EPDL3 }
  elseif ( $1 >= 100 ) { return 10Administrator EPDL3 }
  elseif ( $1 >= 90 ) { return 12Menadzer EPDL3 }
  elseif ( $1 >= 70 ) { return Voucher }
  elseif ( $1 >= 45 ) { return 6Streamer3 }
  elseif ( $1 >= 40 ) { return 2VIP3 }
  elseif ( $1 >= 30 ) { return 7Challenger3 }
  elseif ( $1 >= 20 ) { return Gracz 7Premium3  }
  elseif ( $1 >= 15 ) { return Gracz }
  elseif ( $1 >= 10 ) { return user }
  else { return unknown }
}

alias voucher {
  if ( $2 == user ) {
    if ($hget(vouchdata,$+(u.,$getid($1)))) { return $v1 }
    else { return 0 }
  }
  if ( $2 == Gracz ) {
    if ($hget(vouchdata,$+(u.,$getid($1)))) { return $v1 }
  }
  if ( $2 == Gracz 7Premium3 ) {
    return $numtok($hget(vouchdata,$+(premiumu.,$getid($1))),46)
  }
  if ( $2 == 2VIP3 ) {
    return $numtok($hget(vouchdata,$+(premiuml.,$getid($1))),46)
  }

  if ( $2 == 7Challenger3 ) {
    return $numtok($hget(vouchdata,$+(leader.,$getid($1))),46)
  }
  if ( $2 == 6Streamer3 ) {
    return $numtok($hget(vouchdata,$+(streamer.,$getid($1))),46)
  }
  if ( $2 == voucher ) {
    return $numtok($hget(vouchdata,$+(voucher.,$getid($1))),46)
  }
  if ( $2 == 12Menadzer EPDL3 ) {
    return $numtok($hget(vouchdata,$+(manager.,$getid($1))),46)
  }
  if ( $2 == 10Administrator EPDL3 ) {
    return 0
  }
  if ( $2 == leaderlist ) {
    if ($hget(vouchdata,$+(leader.,$getid($1)))) { return $v1 }
    else { return . }
  }
  if ( $2 == voucherlist ) {
    if ($hget(vouchdata,$+(voucher.,$getid($1)))) { return $v1 }
    else { return . }
  }
  if ( $2 == managerlist ) {
    if ($hget(vouchdata,$+(manager.,$getid($1)))) { return $v1 }
    else { return . }
  }
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Format .vouch <q-auth> <nick>

on $*:TEXT:/^\.vouch\s.*/:*: {
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %ulvl = $userlvl2($nick)
  if ( %ulvl >= 70 ) {
    if ( $maxvouch(%ulvl,user) > $voucher($nick,user) ) {
      if ($3) {
        if ( $userlvl($getid($2)) != 1 ) {
          if (($hget(userdata,$+(id.,$3))) || ($hget(userdata,$+(id.,$2)))) { notice $nick Gracz $2 $+ / $+ $3 jest juz zarejestrowany! | return }
          if (($hget(userdata,$2)) || ($hget(userdata,$3))) { notice $nick Gracz $2 $+ / $+ $3 jest juz zarejestrowany! | return }
        }
        ;elseif ( $getname($2) != $3 ) { notice $nick Auth i nick sie nie zgadzaja! | return }
        if ( $3 == x ) { notice $nick "x" nie jest prawidlowa forma nicka! | return }
        if ( . isin $3 ) { notice $nick To nie jest poprawna nazwa uzytkownika! | return }
        if ( $userlvl($getid($2)) != 1 ) {
          hadd userdata $2 0.0.0.1000.0.0.0.0.500. $+ $3 $+ .0.0
          hadd userdata $+(id.,$3) $2
          var %re = 1
        }
        else { var %re = 0 }
        hadd userdata $+(level.,$2) 10
        hadd vouchdata $+(info.,$2) $getid2($nick) $+ . $+ x
        hadd vouchdata $+(date.,$2) $ctime
        hinc vouchdata $+(u.,$getid2($nick)) 1
        describe %target Uzytkownik $2 zostal $iif(%re,zarejestrowany,ponownie zarejestrowany) na nicku $3 $+ .
      }
      else { notice $nick Musisz podac zarowno Auth jak i nazwe uzytkownika! }
    }
    else { notice $nick Nie mozesz zvouchowac wiecej osob! }
  }
}

on *:TEXT:.unvouch*:*: {
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %ulvl = $userlvl2($nick)
  if ( %ulvl >= 50 ) {
    if ($2) {
      var %u = $getid($2)
      var %un = $getname(%u)
      var %v = $user(%u).vouchedby
      ;if (( %v == $getid2($nick) ) || ( %ulvl > $userlvl(%v) )) {
      if (($userlvl(%v) < 50) && (%ulvl < 70)) { notice $nick Potrzebujesz przynajmniej rangi Vouchera do uzywania tej komendy! | return }
      if ( $userlvl(%u) == 10 ) {
        if ($hget(userdata,%u)) {
          hadd userdata $+(level.,%u) 1
          hdel vouchdata $+(info.,%u)
          hdel vouchdata $+(leader.,%u)
          hdel vouchdata $+(voucher.,%u)
          hdel vouchdata $+(manager.,%u)
          hdec vouchdata $+(u.,%v) 1
          describe %target Uzytkownik %un zostal zawieszony!
        }
        else { notice $nick Uzytkownik nie zostal znaleziony! }
      }
      else { notice $nick Musisz najpierw zdegradowac uzytkownika do rangi User zanim go zawiesisz! }
    }
    else { notice $nick Musisz podac nick/Auth! }
  }
}


on *:TEXT:.delvouch*:*: {
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %ulvl = $userlvl2($nick)
  if ( %ulvl > 100 ) {
    var %vu = $getid($2)
    if ($userlvl(%vu) == 1) {
      if ($hget(userdata,%vu)) {
        var %vun = $getname(%vu)
        hdel userdata level. $+ %vu
        hdel userdata id. $+ %vun
        hdel userdata %vu
        hdel vouchdata info. $+ %vu
        describe %target Wszystkie dane na temat uzytkownika %vun zostaly wymazane!
        run -min pro.bat
      }
      else { describe %target Uzytkownik nie znaleziony! }
    }
    else { notice $nick Zunvochuj najpierw uzytkownika! }
  }
}



;################################ NOTIFY #############################
;#####################################################################

on *:TEXT:.notifylist:*: {
  if (%c.notify) {
    describe %ch Lista oczekujących na grę: $get.usernamelist(%c.notify)
  }
  else { describe %ch Nikt nie oczekuje na grę }
}

on *:TEXT:.notify:*: {
  var %u = $getid($nick)
  if ($istok(%c.notify,%u,46)) { 
    notice $nick Wypisałeś się z listy oczekujących na grę.
    set %c.notify $remtok(%c.notify,%u,1,46)
  return }
  if (%game.on) { msg $nick Zapisy do gry są otwarte, nie możesz dopisać się do listy oczekujących na grę. | return }
  if (!$game.canjoin(%u)) { return }
  if ($numtok(%c.notify,46) == 10) { 
    describe $chan Lista oczekujących na zapisy osiągnęła limit. Lista oczekujących: $get.usernamelist(%c.notify)
  }
  set %c.notify $addtok(%c.notify,%u,46)
  notice $nick Zostaniesz powiadomiony, gdy wystartuje gra na tym kanale.
}

alias spreadnotify {
  if (!%c.notify) { timerspreadnotify off | return }
  if (!%game.on) { return }
  if (%game.confirmed) { return }
  var %kolejka = 1
  var %l = $numtok(%c.notify,46)
  echo -ag zapisanych: $numtok(%c.notify,46)
  timerkolejka %l 1 kolej
}

alias kolej {
  if (!%c.notify) { timerkolejka off | return }
  if (!%game.on) { return }
  if (%game.confirmed) { return }
  echo -ag teraz: %kolejka
  if (%kolejka <= $numtok(%c.notify,46)) {
    var %u = $nauth($gettok(%c.notify,%kolejka,46))
    echo -ag nick obecny %u
    echo -ag qauth $gettok(%c.notify,%kolejka,46)
    if (!%c.challenge) {
      msg %u  Wystartowała gra na EPDL 1. mod: %c.gamemode $+ $chr(44) $enclose2($getname($gettok(%c.gameauths,1,46))) hostuje grę, Gracze w puli: $enclose2($numtok(%c.gameauths,46)) Powiadomionych graczy: $enclose2($numtok(%c.notify,46))$+.
    }
    else { msg %u  Wystartowała gra na EPDL 1. mod: %c.gamemode $+ $chr(44) $enclose2($getname($gettok(%c.gameauths,1,46)) i $getname($gettok(%c.gameauths,2,46))) są kapitanami, Zapisanych graczy: $enclose2($numtok(%c.gameauths,46)) Powiadomionych graczy: $enclose2($numtok(%c.notify,46))$+.
    }
    inc %kolejka
  }
  else { set %kolejka 1 }
  if (%kolejka < $numtok(%c.notify,46)) {
    var %u = $nauth($gettok(%c.notify,%kolejka,46))
    echo -ag nick obecny %u
    echo -ag qauth $gettok(%c.notify,%kolejka,46)
    if (!%c.challenge) {
      msg %u  Wystartowała gra na EPDL 1. mod: %c.gamemode $+ $chr(44) $enclose2($getname($gettok(%c.gameauths,1,46))) hostuje grę, Gracze w puli: $enclose2($numtok(%c.gameauths,46)) Powiadomionych graczy: $enclose2($numtok(%c.notify,46))$+.
    }
    else { msg %u  Wystartowała gra na EPDL 1. mod: %c.gamemode $+ $chr(44) $enclose2($getname($gettok(%c.gameauths,1,46)) i $getname($gettok(%c.gameauths,2,46))) są kapitanami, Zapisanych graczy: $enclose2($numtok(%c.gameauths,46)) Powiadomionych graczy: $enclose2($numtok(%c.notify,46))$+.
    }
    inc %kolejka
  }
}

on *:TEXT:.nick*:*: {
  if (!$3) { return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %u = $getid2($nick)
  var %ulvl = $userlvl(%u)
  if ( %ulvl >= $adminlvl ) {
    if (($hget(userdata,$+(id.,$2))) && (!$hget(userdata,$+(id.,$3)))) {
      if ((!$hget(userdata,$3)) || ($getid($2) == $3)) {
        var %cu = $getid($2)
        var %rec = $hget(userdata,%cu)
        hadd userdata $+(id.,$3) %cu
        hdel userdata $+(id.,$2)
        hadd userdata %cu $puttok(%rec,$3,10,46)
        describe %target Nick gracza $2 zostala zmieniona na $3!
      }
    }
  }
}

on *:TEXT:.promote*:*: {
  if (!$2) { return }
  if ($2 == $nick) { notice $nick $+ , Nie mozesz awansowac samego siebie | return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %u = $getid($2)
  var %ulvl = $userlvl2($nick)
  if ( %ulvl >= 50 ) {
    var %plvl = $userlvl(%u)
    var %orank = $level.str(%plvl)
    var %nrank = $level.str($nextlevel(%plvl))
    if ( $maxvouch(%ulvl,%nrank) > $voucher($nick,%nrank) ) {
      if ( %orank != user ) {
        var %olist = $voucher($nick,$+(%orank,list))
        var %nlist = $voucher($nick,$+(%nrank,list))
        hadd vouchdata $+(%orank,.,$getid($nick)) $remtok(%olist,%u,1,46)
        hadd vouchdata $+(%nrank,.,$getid($nick)) $addtok(%nlist,%u,46)
        hadd vouchdata $+(info.,%u) $puttok($user(%u).vouchinfo,$getid($nick),2,46)
        hadd userdata $+(level.,%u) $nextlevel(%plvl)
      }
      else {
        var %nlist = $voucher($nick,$+(%nrank,list))
        hadd vouchdata $+(%nrank,.,$getid($nick)) $addtok(%nlist,%u,46)
        hadd vouchdata $+(info.,%u) $puttok($user(%u).vouchinfo,$getid($nick),2,46)
        hadd userdata $+(level.,%u) $nextlevel(%plvl)
      }
      describe %target $enclose(%orank) $getname(%u) awansowal do rangi $enclose(%nrank)
      if ((%nrank == manager) || (%nrank == administrator)) {
        noop $setuser(%u,1000).conf
      }
      else { do nothing }
    }
    else { notice $nick Nie mozesz awansowac z rangi %orank na %nrank $+ ! }
  }
}

on *:TEXT:.demote *:*: {
  if (!$2) { return }
  if ($2 == $nick) { notice $nick $+ , Nie mozesz zdegradowac samego siebie! | return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %u = $getid($2)
  var %ulvl = $userlvl2($nick)
  var %tlvl = $userlvl($getid($2))
  if ( %tlvl >= %ulvl ) { notice $nick Nie mozesz zdegradowac tego uzytkownika! | return }
  if ( %ulvl >= 50 ) {
    var %plvl = $userlvl(%u)
    var %orank = $level.str(%plvl)
    var %nrank = $level.str($prevlevel(%plvl))
    if ( %nrank != unknown ) {
      if ( %plvl >= 50 ) {
        var %prank = %nrank
        var %pplvl = $prevlevel(%plvl)
        while ( %prank != user ) {
          var %i = 1
          var %l = $numtok($voucher(%u,$+(%prank,list)),46)
          echo -ag %prank -- %l
          while (%i <= %l) {
            var %dnick = $gettok($voucher(%u,$+(%prank,list)),%i,46)
            hadd userdata $+(level.,%dnick) 10
            ;hadd vouchdata $+(info.,%dnick) $puttok($user(%dnick).vouchinfo,x,2,46)
            var %list = $addtok(%list,%dnick,46)
            ;echo -ag DEMOTED: %dnick
            ;echo -ag %list
            inc %i
          }
          hdel vouchdata $+(%prank,.,%u)
          %pplvl = $prevlevel(%pplvl)
          %prank = $level.str(%pplvl)
        }
        if (%list) {
          describe %target Zdegradowani uzytkownicy: $replace(%list,.,$chr(44) $+ $ch(32)))
        }
      }
      var %v = $user(%u).promoteby
      while (( $maxvouch(%ulvl,%nrank) <= $voucher(%v,%nrank)) && ( %nrank != user )) {
        %plvl = $prevlevel(%plvl)
        %nrank = $level.str($prevlevel(%plvl))
      }
      ;if ((( $user(%u).promoteby == $getid($nick)) || ($user(%u).promoteby == x )) || ( $userlvl2($nick) > $userlvl(%v))) {
      var %olist = $voucher(%v,$+(%orank,list))
      var %nlist = $voucher(%v,$+(%nrank,list))
      hadd vouchdata $+(%orank,.,%v) $remtok(%olist,%u,1,46)
      if ( %nrank != user ) {
        hadd vouchdata $+(info.,%u) $puttok($user(%u).vouchinfo,%v,2,46)
        hadd vouchdata $+(%nrank,.,%v) $addtok(%nlist,%u,46)
      }
      else {
        hadd vouchdata $+(info.,%u) $puttok($user(%u).vouchinfo,x,2,46)
      }
      hadd userdata $+(level.,%u) $prevlevel(%plvl)
      describe %target $enclose(%orank) $getname(%u) zostal zdegradowany do rangi $enclose(%nrank)
      if ((%orank == manager) || (%orank == administrator)) {
        noop $setuser(%u,700).conf
      }
      ;}
      ;else { notice $nick Uzytkownik byl wczesniej awansowany przez $+ $getname(%v) $+. Tylko ta osoba badz ktos z wyzsza ranga moze ja zdegradowac! }
    }
    else { notice $nick Uzyj .unvouch do dalszej degradacji uzytkownika! }
  }
}

on *:TEXT:.admin*:*: {
  if (!$2) { return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %u = $getid2($nick)
  var %gu = $getid($2)
  if (!$hget(userdata,%gu)) { describe %target Uzytkownik nie zostal znaleziony! | return }
  if ($userlvl(%gu) != 10) { describe %target Uzytkownik musi posiadac range User, nim zostanie awansowany do rangi Administratora! | return }
  if ($userlvl(%u) < 101) { describe %target Nie masz wystarczajacej rangi, aby awansowac Uzytkownika do rangi Administratora! | return }
  if ($user(%gu).vouchedby != %u) { describe %target Do rangi Administratora mozesz awansowac tylko osoby wczesniej zvouchowane! | return }
  hadd userdata level. $+ %gu 100
  hadd vouchdata info. $+ %gu %u $+ . $+ %u
  noop $setuser(%gu,700).conf
}

on *:TEXT:.score*:*: {
var %u = $getid2($nick)
if ($userlvl(%u) < 70) { return }
var %cu = $getid($2)
if (!%cu) { return }
describe $nick Wynik rozegranych gier dla %cu $+ : $round($calc($user(%cu).gpl / 2),2) $+ , punkty kapitana: $user(%cu).cap
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; takes token, returns token separated by ", "
alias get.usernamelist {
  var %i = 1
  var %l = $numtok($1,46)
  var %list
  while ( %i <= %l ) {
    var %list = $addtok(%list,$getname($gettok($1,%i,46)),46)
    inc %i
  }
  var %list = $replace(%list,.,$chr(44) $+ $chr(32))
  return %list
}

alias dwhois {
  var %nick = $1
  var %chan = $2
  tokenize 32 $3-
  if ((!%canreply) && ($userlvl(%nick) < 50 )) { return }
  if (%chan) { var %target = %chan }
  else { var %target = %nick }
  if ( $2 == dasik ) {
    describe %target i am BoT
    return
  }
  if ($2) { var %u = $getid($2) }
  else { var %u = $getid(%nick) }
  if ($1 = .whoami) { var %u = $getid(%nick) }
  echo -ag %u $userlvl(%u)
  if ((!%u) || (!$userlvl(%u))) { describe %target Uzytkownik nie zostal znaleziony! | return }
  var %level = $userlvl(%u)
  var %rank = $level.str(%level)
  var %line = $getname(%u) $+ ( $+ %u $+ ) %linetemp $enclose(%rank) $+ :
  var %line = %line $iif($user(%u).inactive != $true,$iif($userlvl(%u) != 1,Ranga: $get.exprank(%u) $+ ( $+ $user(%u).rank $+ );),Nieaktywny;)
  var %line = %line $iif($user(%u).rankonly != 0,Ostatnia gra: $get.gamenamen($user(%u).lastgame) $+ ;)
  if ( %level >= 100 ) {
    
  }
  elseif ( %level >= 90 ) {
    %line = %line Voucherzy: $iif($voucher(%u,voucher) > 0,$get.usernamelist($voucher(%u,voucherlist))) $+ $chr(91) $+ $voucher(%u,voucher) $+ / $+ $maxvouch(%level,voucher) $+ $chr(93) $+ .
    %line = %line Liderzy: $iif($voucher(%u,leader) > 0,$get.usernamelist($voucher(%u,leaderlist))) $+ $chr(91) $+ $voucher(%u,leader) $+ / $+ $maxvouch(%level,leader) $+ $chr(93) $+ .
    
  }
  elseif ( %level >= 70 ) {
        ;%line = %line Hosts: $iif($voucher(%u,ggwp) > 0,$get.usernamelist($voucher(%u,hostlist))) $+ $chr(91) $+ $voucher(%u,host) $+ / $+ $maxvouch(%level,host) $+ $chr(93) $+ .
    
  }
  if (%target != garena) {
    describe %target %line $iif($get.cfrank($user(%u).conf),$ifmatch)
  }
  else {
    gmsg %line $iif($get.cfrank($user(%u).conf),$ifmatch)
  }
}

on *:TEXT:.modes:*: {
  if ((!%canreply) && ($userlvl2($nick) < 50 )) { return  }
  if ($chan) { var %target = $chan }
  var %zzlvl = $userlvl($nick)
  describe %target 4Obslugiwane mody:3 -cm -cd -qs -ap -sd -ardm -ar
}

on $*:TEXT:/^(\.whois\s\S*|\.whoami$)/:*: {
  dwhois $nick $iif($chan,$chan,$false) $1-
}

on $*:TEXT:/^\.vouchee(s|s\s.*)$/:*: {
  if ((!%canreply) && ($userlvl2($nick) < 50 )) { return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  if ($2) { var %u = $getid($2) }
  else { var %u = $getid2($nick) }
  if ( $userlvl(%u) < 50 ) { return }
  var %man = $voucher(%u,managerlist)
  var %vou = $voucher(%u,voucherlist)
  var %lea = $voucher(%u,leaderlist)
  var %manl, %voul, %leal, %usrl, %adml
  var %l = $hget(vouchdata,0).item
  var %i = 1
  var %n = 0
  while ( %i <= %l ) {
    var %item = $hget(vouchdata,%i).item
    if ( info. isin %item) {
      if ( $gettok($hget(vouchdata,%i).data,1,46) == %u ) {
        var %name = $mid(%item,6,$calc($len(%item)-5))
        if ($userlvl(%name) >= 100 ) { var %adml = %adml $getname(%name) $+ $enclose(A) }
        elseif ($istok(%man,%name,46)) { var %manl = %manl $getname(%name) $+ $enclose(M) }
        elseif ($istok(%vou,%name,46)) { var %voul = %voul $getname(%name) $+ $enclose(V)  }
        ;elseif ($istok(%cen,%name,46)) { var %cenl = %cenl $getname(%name) $+ $enclose(C)  }
        elseif ($istok(%lea,%name,46)) { var %leal = %leal $getname(%name) $+ $enclose(L)  }
        ;elseif ($istok(%hos,%name,46)) { var %hosl = %hosl $getname(%name) $+ $enclose(H) }
        ;else { var %usrl = %usrl $getname(%name)  }
        inc %n
      }
    }
    inc %i
  }
  var %list = %adml %manl %voul %leal
  var %line = Poleceni przez $getname(%u) $+ : %list
  %line = %line $iif($voucher(%u,user),$voucher(%u,user),0) poleconych uzytkownikow.
  describe %target %line
}

alias get.exprank {
  var %xprank
  if ( $1 = %user_1 ) { %xprank = 7Zloto 3 }
  if ( $1 = %user_2 ) { %xprank = 15Srebro 3 }
  if ( $1 = %user_3 ) { %xprank = 5Braz 3 }
  var %e = $user($1).exp
  if ( %e >= 1800 ) { 
    %xprank = %xprank $+ 5,7One level above 3
    var %e = $calc(%e - 400) 
  }
  if ( %e >= 1760 ) { %xprank = %xprank $+ 5,7Close to an END!3 }
  elseif ( $1 = ARCHI33 ) { %xprank = 4Mistrzu3 }
  elseif ( $1 = CJK ) { %xprank = 10Osa3 }
  elseif ( $1 = ErazmCzarny ) { %xprank = 4Übermensch3 }
  elseif ( $1 = auth ) { %xprank = 13RANGA3 }
  elseif ( %e >= 1750 ) { %xprank = %xprank $+ 6,15This guy's even better than me `-`3 }
  elseif ( %e >= 1700 ) { %xprank = %xprank $+ 0,1[•••••••|•] Skill-o-meter3 }
  elseif ( %e >= 1650 ) { %xprank = %xprank $+ 9Bog Dota3 }
  elseif ( %e >= 1600 ) { %xprank = %xprank $+ 4Wspanialy3 }
  elseif ( %e >= 1550 ) { %xprank = %xprank $+ 6Nieludzki3 }
  elseif ( %e >= 1500 ) { %xprank = %xprank $+ 12Gwalciciel3 }
  elseif ( %e >= 1450 ) { %xprank = %xprank $+ 12Genialny3 }
  elseif ( %e >= 1400 ) { %xprank = %xprank $+ 10Imponujacy3 }
  elseif ( %e >= 1350 ) { %xprank = %xprank $+ 10Nadzwyczajny3 }
  elseif ( %e >= 1300 ) { %xprank = %xprank $+ Solidny }
  elseif ( %e >= 1250 ) { %xprank = %xprank $+ Utalentowany }
  elseif ( %e >= 1200 ) { %xprank = %xprank $+ Obiecujacy }
  elseif ( %e >= 1150 ) { %xprank = %xprank $+ Adekwantny }
  elseif ( %e >= 1100 ) { %xprank = %xprank $+ Dobry }
  elseif ( %e >= 1050 ) { %xprank = %xprank $+ Przecietny }
  elseif ( %e >= 1000 ) { %xprank = %xprank $+ Normalny }
  elseif ( %e >= 950 ) { %xprank = %xprank $+ Slaby }
  elseif ( %e >= 900 ) { %xprank = %xprank $+ Tragedia }
  elseif ( %e >= 850 ) { %xprank = %xprank $+ Biedny }
  elseif ( %e >= 800 ) { %xprank = %xprank $+ Smierdziel }
  elseif ( %e >= 750 ) { %xprank = %xprank $+ Totalne Zero }
  elseif ( %e >= 700 ) { %xprank = %xprank $+ Palant }
  elseif ( %e >= 650 ) { %xprank = %xprank $+ Juz Przegrales }
  elseif ( %e >= 600 ) { %xprank = %xprank $+ Unvouch me please! }
  else { %xprank = %xprank $+ Niezarejestrowany }
  return %xprank
}

alias get.streakrank {
  if ( $1 >= 20 ) { var %r = Skurwysyn }
  elseif ( $1 >= 17 ) { var %r = 13JAK Z GÓWNEM3 }
  elseif ( $1 >= 15 ) { var %r = 6,15POJEBANY3 }
  elseif ( $1 >= 13 ) { var %r = 0,1SZALONY3 }
  elseif ( $1 >= 11 ) { var %r = 12Sa tu jeszcze jacys chetni?3 }
  elseif ( $1 >= 9 ) { var %r = 4OGNIA3 }
  elseif ( $1 >= 7 ) { var %r = 10Jest Niepowstrzymany!3 }
  elseif ( $1 >= 5 ) { var %r = Kosi Wszystko }
  elseif ( $1 = 4 ) { var %r = Rozwala Lby }
  elseif ( $1 = 3 ) { var %r = Owni }
  elseif ( $1 = 2 ) { var %r = Ogrywa }
  elseif ( $1 = 1 ) { var %r = Wygral! }
  elseif ( $1 = 0 ) { var %r = Nieaktywny }
  elseif ( $1 = -1 ) { var %r = Przegral! }
  elseif ( $1 = -2 ) { var %r = Ograny }
  elseif ( $1 = -3 ) { var %r = Zowniony } 
  elseif ( $1 = -4 ) { var %r = Rozwalony } 
  elseif ( $1 = -5 ) { var %r = Pokarany }
  elseif ( $1 = -6 ) { var %r = Przejebany }
  elseif ( $1 = -7 ) { var %r = Zmieszany z gownem }
  elseif ( $1 = -8 ) { var %r = Ktos chce przegrac? }
  elseif ( $1 = -9 ) { var %r = Gram bez monitora! }
  elseif ( $1 = -10 ) { var %r = Mialem laga! }
  elseif ( $1 <= -11 ) { var %r = O chuj chodzi? }
  else { var %r = Pointless L0L }
  if ( $1 > 0 ) { return Obecna passa wygranych: + $+ $1 $iif(%r,$enclose(%r)) }
  elseif ( $1 < 0 ) { return Obecna passa przegranych: $1 $iif(%r,$enclose(%r)) }
  else { return $null }
}

alias get.cfrank {
  if ( $1 >= 11000 ) { var %r = Santa Claus }
  elseif ( $1 >= 10000 ) { var %r = Chillin }
  elseif ( $1 >= 9000 ) { var %r = Pretty Good }
  elseif ( $1 >= 8000 ) { var %r = Normal }
  elseif ( $1 >= 7000 ) { var %r = Pedobear }
  elseif ( $1 >= 6000 ) { var %r = Very Low }
  elseif ( $1 >= 5000 ) { var %r = 4Wisi na wlosku3 }
  
}

on *:TEXT:.stats*:*: {
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  if ($2) { var %u = $getid($2) }
  else { var %u = $getid2($nick) }
  if (!$hget(userdata,%u)) { describe %target Uzytkownik nie zostal znaleziony! | return }
  var %line = $getname(%u) zwyciezyl w  $+ $user(%u).win  $+ grach, przegral  $+ $user(%u).lost $+  gier $+  a jego procent wszystkich wygranych gier wynosi $+ $enclose($round($calc($user(%u).win / $calc($user(%u).win + $user(%u).lost) * 100),2) $+ $chr(37)), aktualnie posiada  $+ $user(%u).exp pkt  
    var %line = %line $iif($get.streakrank($user(%u).spree),$ifmatch)
    if (%canreply) {
    if ($userlvl(%u) >= 151) { describe %target $nick has 14Hidden3 wins, 14Hidden3 losses, 14Hidden3 experience, Inactive; Confidence factor: 14Hidden3 | return }
    describe %target %line $iif($get.cfrank($user(%u).conf),$ifmatch)
  }
  else {
    if ( $userlvl2($nick) < 50 ) {
      describe $nick %line $iif($get.cfrank($user(%u).conf),$ifmatch)
    }
    else {
      describe %target %line $iif($get.cfrank($user(%u).conf),$ifmatch)
    }
  }
}

;#########################################################
;#########################################################

alias update.online.status {
  write -c lastupdate.txt $calc($ctime) $crlf
  write lastupdate.txt $nick(#IDL,0)
  write lastupdate.txt $numtok(%gamelist,46)
}

alias sync.voice {
  var %l = $nick(%ch,0,v)
  var %i = 1
  var %list = $null
  var %m = $null
  while (%i <= %l ) {
    if ( (!$user($auth($nick(%ch,%i,v))).ig) && (!$user($auth($nick(%ch,%i,v))).signed) ) {
      ;mode %ch -v $nick(%ch,%i,v)
      var %m = %m $+ v
      var %list = %list $nick(%ch,%i,v)
      if ( $numtok(%list,32) == 5 ) {
        mode %ch - $+ %m %list
        var %m = $null
        var %list = $null
      }
    }
    inc %i
  }
  mode %ch - $+ %m %list
}

on *:TEXT:!devoice:*: {
  if ($userlvl($auth($nick)) > 50 ) {
    sync.voice
  }
}

alias reinvite {
  var %l = $nick(#EPDL,0)
  var %i = 1
  while (%i <= %l ) {
    if ( $auth($nick(#EPDL,%i)) >= 10 ) {
      if ( $nick(#EPDL,%i) !ison %ch ) {
        timer 1 $calc(%i * 2) invite $nick(#EPDL,%i) %ch
      }
    }
    inc %i
  }
}

;;;;;;;;;;;;;;;; set sig
on *:TEXT:.setsig *:*: {
  var %u = $getid2($nick)
  if ($userlvl(%u) >= 10 ) {
    set %user.img_ $+ %u $2
    notice $nick Sygnatura uzytkownika $getname(%u) zmieniona na $chr(35) $+ $2
  }
}

;#########################################################
;#########################################################
; TIME BAN
alias lols {
  echo -ag $nauth($2)
}
on *:TEXT:.closemsg:*: {
  if ($timer(closemsgdada)) { describe $msg $chan Nie mozesz uzywac tej komendy czesciej niz co 10 sekund. | return }
  var %u = $getid2($nick)
  if ($userlvl(%u) < 100 ) { kick $chan $nick Nie masz wystarczajacej rangi do uzycia tej komendy. | return }
  describe %ch Wszystkie prywatne okna czata zostaly zamkniete!
  timerclosemsgdada 1 10 noop
  /closemsg
}

on *:TEXT:.restart*:*: {
  var %nn99lvl = $userlvl($nick)
  if ( $userlvl($auth($nick)) < 90 { kick $chan $nick Nie masz wystarczajacej rangi do uzycia tej komendy. | return }
  if ( $userlvl($auth($nick)) >= 90 ) {
    msg $chan 5Weryfikacja powiodla sie $nick Bot przystepuje do resetu. $fulldate
    /reconnect
  }
}

on *:TEXT:.botnick*:*: {
  var %u = $getid2($nick)
  if ($userlvl(%u) < 100 ) { kick $chan $nick Nie masz wystarczajacej rangi do uzywania tej komendy! | return }
  /nick $2
  describe %ch Nick bota zostal zmieniony!
}

on *:TEXT:.botnickd:*: {
  var %u = $getid2($nick)
  if ($userlvl(%u) < 70 ) { kick $chan $nick Nie masz wystarczajacej rangi do uzywania tej komendy! | return }
  /nick EPDL
  describe %ch Zrobione!
}

on $*:TEXT:/^\.vouchme\s.*/:*: {
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %ulvl = $userlvl2($nick)
  if ( $getid2($nick) != $2 ) { notice $nick To nie jest twoj AUTH! (zauthuj sie lub podaj poprawny, komenda powinna wygladac .vouchme auth nick) | return }
  if ( %ulvl == 1 ) { notice $nick Jestes zbanowany! | return }
      if ($3) {
        if ( $userlvl($getid($2)) != 1 ) {
          if (($hget(userdata,$+(id.,$3))) || ($hget(userdata,$+(id.,$2)))) { notice $nick Gracz $2 $+ / $+ $3 jest juz zarejestrowany! | return }
          if (($hget(userdata,$2)) || ($hget(userdata,$3))) { notice $nick Gracz $2 $+ / $+ $3 jest juz zarejestrowany! | return }
        }
        ;elseif ( $getname($2) != $3 ) { notice $nick Auth i nick sie nie zgadzaja! | return }
        if ( $3 == x ) { notice $nick "x" nie jest prawidlowa forma nicka! | return }
        if ( . isin $3 ) { notice $nick To nie jest poprawna nazwa uzytkownika! | return }
        if ( $userlvl($getid($2)) != 1 ) {
          hadd userdata $2 0.0.0.1000.0.0.0.0.500. $+ $3 $+ .0.0
          hadd userdata $+(id.,$3) $2
          var %re = 1
        }
        else { var %re = 0 }
        hadd userdata $+(level.,$2) 15
        hadd vouchdata $+(info.,$2) $getid2($nick) $+ . $+ x
        hadd vouchdata $+(date.,$2) $ctime
        hinc vouchdata $+(u.,$getid2($nick)) 1
        describe %target Uzytkownik $2 zostal $iif(%re,zarejestrowany,ponownie zarejestrowany) na nicku $3 $+ .
      }
      else { notice $nick Musisz podac zarowno Auth jak i nazwe uzytkownika! }
}