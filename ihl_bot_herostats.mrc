;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; pool.picked.won.lost.fp.sp.tp

alias AddHero.pool {
  var %hero = $replace($1-,$chr(32),$chr(95))
  var %herodata = $hget(herodata,%hero)
  var %x = $gettok(%herodata,1,46)
  inc %x
  hadd herodata %hero $puttok(%herodata,%x,1,46)
}

alias AddHero.picked {
  var %hero = $replace($1-,$chr(32),$chr(95))
  var %herodata = $hget(herodata,%hero)
  var %x = $gettok(%herodata,2,46)
  inc %x
  hadd herodata %hero $puttok(%herodata,%x,2,46)
}

alias AddHero.won {
  var %hero = $replace($1-,$chr(32),$chr(95))
  var %herodata = $hget(herodata,%hero)
  var %x = $gettok(%herodata,3,46)
  inc %x
  hadd herodata %hero $puttok(%herodata,%x,3,46)
}

alias AddHero.lost {
  var %hero = $replace($1-,$chr(32),$chr(95))
  var %herodata = $hget(herodata,%hero)
  var %x = $gettok(%herodata,4,46)
  inc %x
  hadd herodata %hero $puttok(%herodata,%x,4,46)
}

alias AddHero.fp {
  var %hero = $replace($1-,$chr(32),$chr(95))
  var %herodata = $hget(herodata,%hero)
  var %x = $gettok(%herodata,5,46)
  inc %x
  hadd herodata %hero $puttok(%herodata,%x,5,46)
}

alias AddHero.sp {
  var %hero = $replace($1-,$chr(32),$chr(95))
  var %herodata = $hget(herodata,%hero)
  var %x = $gettok(%herodata,6,46)
  inc %x
  hadd herodata %hero $puttok(%herodata,%x,6,46)
}

alias AddHero.tp {
  var %hero = $replace($1-,$chr(32),$chr(95))
  var %herodata = $hget(herodata,%hero)
  var %x = $gettok(%herodata,7,46)
  inc %x
  hadd herodata %hero $puttok(%herodata,%x,7,46)
}

alias resetherodata {
  hfree herodata
  hmake herodata 1000
  var %i = 1
  while (%i <= 97) {
    var %hero = $replace($($+(%,hero_,%i),2),$chr(32),$chr(95))
    hadd herodata %hero 0.0.0.0.0.0.0
    inc %i
  }
  hsave herodata herodata.txt
}

alias hero {
  var %hero = $replace($1-,$chr(32),$chr(95))
  if ( $prop == pop ) {
    var %a = $gettok($hget(herodata,%hero),1,46)
    var %b = $gettok($hget(herodata,%hero),2,46)
    var %f = $gettok($hget(herodata,%hero),5,46)
    var %s = $gettok($hget(herodata,%hero),6,46)
    var %t = $gettok($hget(herodata,%hero),7,46)
    /*
    var %rating = $calc(40 * %f / %a)
    inc %rating $calc(20 * %s / %a)
    inc %rating $calc(5 * %t / %a)
    inc %rating $calc(100 * %b / %a)
    */
    /*
    var %base = %b
    var %mul = $calc(1 + (%f * 0.4))
    var %base = %base * %mul
    var %mul = $calc(1 + (%s * 0.25))
    var %base = %base * %mul
    var %mul = $calc(1 + (%t * 0.15))
    var %base = %base * %mul
    var %rating = $calc(100 * %base / %a)
    */
    /*
    var %base = %b
    inc %base $calc(%f * 0.4)
    inc %base $calc(%s * 0.25)
    inc %base $calc(%t * 0.15)
    var %rating = $calc(100 * %base / %a)
    */
    var %base = %b
    var %mul = $calc(1 + (%f * 0.4))
    inc %mul $calc(%s * 0.25)
    inc %mul $calc(%t * 0.15)
    var %base = %base * %mul
    var %rating = $calc(100 * %base / %a)
    return $round(%rating,2)
  }
  if ( $prop == pool ) {
    return $gettok($hget(herodata,%hero),1,46)
  }
  if ( $prop == picked ) {
    return $gettok($hget(herodata,%hero),2,46)
  }
  if ( $prop == won ) {
    return $gettok($hget(herodata,%hero),3,46)
  }
  if ( $prop == lost ) {
    return $gettok($hget(herodata,%hero),4,46)
  }
  if ( $prop == fp ) {
    return $gettok($hget(herodata,%hero),5,46)
  }
  if ( $prop == sp ) {
    return $gettok($hget(herodata,%hero),6,46)
  }
  if ( $prop == tp ) {
    return $gettok($hget(herodata,%hero),7,46)
  }
}

;########################### PENALTY #############################
;#################################################################

;;;;;;;;;;;;;;;;;;
;; takes user, penalty-user, penalty-type, reason optional
alias AddPenalty {
  var %pu = $2
  var %n = $hget(pendata,$+(n.,%pu))
  inc %n
  hinc pendata $+(n.,%pu) 1
  hadd pendata $+(p.,%n,.,%pu) $+($1,.,$3,.,$ctime,.,$4)
}

alias pen {
  if (!$1) { return }
  var %u = $1
  if (!$2) {
    return $hget(pendata,$+(n.,%u))
  }
  if ( $prop == author ) {
    return $gettok($hget(pendata,$+(p.,$2,.,%u)),1,46)
  }
  if ( $prop == type ) {
    return $gettok($hget(pendata,$+(p.,$2,.,%u)),2,46)
  }
  if ( $prop == date ) {
    return $asctime($gettok($hget(pendata,$+(p.,$2,.,%u)),3,46),dd/mm/yy)
  }
  if ( $prop == info ) {
    return $gettok($hget(pendata,$+(p.,$2,.,%u)),4,46)
  }
}

on *:TEXT:.warnhist*:*: {
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %u = $getid2($nick)
  if ($userlvl(%u) < $adminlvl ) { return }
  var %pu = $getid($2)
  if (!%pu) { describe %target Uzytkownik nie znaleziony! | return }
  var %l = $pen(%pu)
  if (!%l) { describe %target Brak wpisow | return }
  if ($3 == full) { var %i = 1 }
  else {
    if ( %l <= 10 ) {
      var %i = 1
    }
    else {
      var %i = %l - 10
    }
  }
  var %list = $null
  while (%i <= %l) {
    if ($len(%list) >= 780) {
      describe %target %list [wiecej...]
      var %list = $null
    }
    var %list = %list $enclose($pen(%pu,%i).type - $getname($pen(%pu,%i).author) - $pen(%pu,%i).date - IWT: $+ $pen(%pu,%i).info)
    inc %i
  }
  describe %target %list
}



;############################# LOG ###############################
;#################################################################

;;;;;;;;;;;;;;;;;;;;;;
;; $1 = user who caused action
;; $2 = action ( .report/.closegame/.voidgame/.submit/.reward/.penalty )
;; $3- = bonus info

alias AddRecord {
  write adminlog.txt $enclose($time) $enclose($date) $enclose($level.str($userlvl($1))) $enclose($2)
  write adminlog.txt $enclose(Operator $1 - $userlvl($1))
  write adminlog.txt $3-
  write adminlog.txt $crlf
}

;########################## CHANSTATS ############################
;#################################################################

on *:TEXT:.chanstats:*: {
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %ulvl = $userlvl2($nick)
  if ( %ulvl >= 50 ) {
    var %line = Liczba Uzytkownikow: %rank.users $chr(124)
    var %line = %line Gier dzisiaj/max: %game.today $+ / $+ %game.daymax ( $+ $asctime(%game.daymax.time,dd/mm/yy) $+ ) $chr(124)
    var %line = %line Najwiekszy zysk XP: %max.xpgained ( $+ %max.xpgained.info $+ ) $chr(124)
    var %line = %line Najwieksza strata XP: %max.xplost ( $+ %max.xplost.info $+ )
    describe %target %line
  }
}

;############################ RE-SYNC ############################
;#################################################################

;resync xp gained/lost
alias resync.expstats {
  var %game = 1
  var %l = %gamenum
  while (%game <= %l) {
    if ($hget(gamedata,%game)) {
      var %re = $game(%game).result
      var %players = $game(%game).plist
      if ( %re == Radiant ) {
        var %expchange = $game(%game).elist
      }
      elseif ( %re == Dire ) {
        var %expchange = $game(%game).aelist
      }
      var %i = 1
      while ( %i <= 10 ) {
        var %e = $gettok(%expchange,%i,46)
        if ( %e < 0 ) {
          if ( %e < %max.xplost ) {
            set %max.xplost %e
            set %max.xplost.info $getname($gettok(%players,%i,46)) w grze %game dnia $asctime($game(%game).time,dd/mm/yy)
          }
        }
        else {
          if ( %e > %max.xpgained ) {
            set %max.xpgained %e
            set %max.xpgained.info $getname($gettok(%players,%i,46)) w grze %game dnia $asctime($game(%game).time,dd/mm/yy)
          }
        }
        inc %i
      }
    }
    inc %game
  }
}

alias resetconf {
  var %i = 1
  var %l = $hget(userdata,0).item
  while ( %i <= %l ) {
    if ( . !isin $hget(userdata,%i).item ) {
      var %u = $v2
      var %c = $user(%u).conf
      if ( %c > 1000 ) {
        noop $setuser(%u,1000).conf
      }
    }
    inc %i
  }
}

on *:TEXT:.gamestats:*: {
  if ((!%canreply) && ($userlvl2($nick) < 50 )) { return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %i = 1
  var %sent = 0
  var %scrg = 0
  var %draw = 0
  var %modetype = $modes
  var %modenum = 0.0.0.0.0.0.0.0.0
  var %error = 0
  while (%i <= %gamenum ) {
    var %r = $game(%i).result
    if (%r == Radiant ) { inc %sent }
    elseif (%r == Dire ) { inc %scrg }
    else { inc %draw }
    var %m = $game(%i).mode
    var %p = $findtok(%modetype,%m,1,46)
    if (%p) {
      var %n = $gettok(%modenum,%p,46)
      inc %n
      ;echo -ag %i $+ . %p - %n - %m - %modenum
      var %modenum = $puttok(%modenum,%n,%p,46)
    }
    else {
      ;echo -ag %i $+ . 4BLAD!
      inc %error
    }
    inc %i
  }
  var %i = 1
  var %l = $numtok(%modetype,46)
  var %modelist = $null
  while (%i <= %l) {
    if ($gettok(%modenum,%i,46)) {
      var %modelist = %modelist $gettok(%modetype,%i,46) $+ : $gettok(%modenum,%i,46)
    }
    inc %i
  }
  describe %target Ilosc gier: %gamenum $chr(124) Radiant: %sent Dire: %scrg Remis: %draw $chr(124) %modelist $chr(124) Wyzwan: %challnum Szybkich gier: %regnum $chr(124) Blednych wpisow: %error
}
/*
on *:TEXT:.playerhist*:*: {
  if ((!%canreply) && ($userlvl2($nick) < 50 )) { return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  if ($2) { var %u = $getid($2) }
  else { var %u = $getid2($nick) }
  var %ulvl = $userlvl2($nick)
  var %i = 1
  var %list = $null
  while ( %i <= %gamenum ) {
    if ($istok($game(%i).plist,%u,46)) {
      var %p = $findtok($game(%i).plist,%u,1,46)
      if ( $game(%i).result == Radiant ) {
        var %exp = $gettok($game(%i).elist,%p,46)
      }
      elseif ( $game(%i).result == Dire ) {
        var %exp = $gettok($game(%i).aelist,%p,46)
      }
      else {
        inc %i
        continue
      }
      var %list = %list $iif(%exp >= 0, + $+ $v1,$v1)
    }
    inc %i
  }
  describe %target Historia zdobytego XP dla $getname(%u) $+ : %list
  var %list = $null
}
*/

on *:TEXT:.gamehist*:%ch: {
  if ((!%canreply) && ($userlvl2($nick) < 70 )) { return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  if ($2) { var %u = $getid($2) }
  else { var %u = $getid2($nick) }
  var %ulvl = $userlvl2($nick)
  var %i = %gamenum
  var %list = $null
  var %s = $null
  var %j = 20
  while ( %i >= 1 ) && ( %j > 0 ) {
    if ($istok($game(%i).plist,%u,46)) {
            var %p = $game(%i).mode
var %f = $findtok($game(%i).plist,%u,1,46)
                 if ( %p = quickstart ) { var %p = qs }
            var %n = $get.gamenum(%i)
      if ( $game(%i).result == Radiant ) {
        var %exp = $gettok($game(%i).elist,%f,46)
if (%exp < 0) { var %exp = 4 $+ %exp $+ 3 }
else { var %exp = + $+ %exp }
      }
      elseif ( $game(%i).result == Dire ) {
        var %exp = $gettok($game(%i).aelist,%f,46)
if (%exp < 0) { var %exp = 4 $+ %exp $+ 3 }
else { var %exp = + $+ %exp }
      }
           ;;echo -ag s =  %s gn: %gamenum i: %i gnumb: $get.gamenum(%i) mode: %p  
      else {
          dec %i
          continue
      }
      var %list = %list %p $+ %n $+ : $+ %exp
dec %j
      if ($len(%list) > 400) { var %list = $null }
    }
    dec %i
  }
  describe %ch Zakonczone gry uzytkownika $getname(%u) $+ : $enclose(%list)
  var %list = $null
}

on *:TEXT:.playerdetails*:*: {
  if ((!%canreply) && ($userlvl2($nick) < 50 )) { return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  if ($2) { var %u = $getid($2) }
  else { var %u = $getid2($nick) }
  var %ulvl = $userlvl2($nick)
  var %xp = 1500
  var %top.xp = 0
  var %bottom.xp = 9999
  var %sent = 0
  var %scrg = 0
  var %draw = 0
  var %sentw = 0
  var %sentl = 0
  var %scrgw = 0
  var %scrgl = 0
  var %top.lost = 0
  var %top.gain = 0
  var %i = 1
  var %line = $null
  while ( %i <= %gamenum ) {
    if ($istok($game(%i).plist,%u,46)) {
      var %p = $findtok($game(%i).plist,%u,1,46)
      if ( $game(%i).result == Radiant ) {
        var %exp = $gettok($game(%i).elist,%p,46)
        if (%exp > 0) {
          inc %sentw
        }
        else {
          inc %sentl
        }
        inc %sent
        var %xp = $calc(%xp + %exp)
      }
      elseif ( $game(%i).result == Dire ) {
        var %exp = $gettok($game(%i).aelist,%p,46)
        if (%exp > 0) {
          inc %scrgw
        }
        else {
          inc %scrgl
        }
        inc %scrg
        var %xp = $calc(%xp + %exp)
      }
      else {
        inc %draw
      }
      if (%exp > %top.gain) { var %top.gain = %exp }
      if (%exp < %top.lost) { var %top.lost = %exp }
      if (%xp > %top.xp) { var %top.xp = %xp }
      if (%xp < %bottom.xp) { var %bottom.xp = %xp }
    }
    inc %i
  }
  var %line = Radiant: %sent $enclose(%sentw $+ / $+ %sentl) Dire: %scrg $enclose(%scrgw $+ / $+ %scrgl) Remisow: %draw $chr(124)
  var %line = %line Najwiekszy zysk XP: %top.gain $chr(124) Najwieksza strata xP: %top.lost $chr(124)
  var %line = %line Najwiecej XP kiedykolwiek: %top.xp $chr(124) Najmniej XP kiedykolwiek: %bottom.xp
  describe %target %line
  var %line = $null
}


alias cleanvars {
  var %i = 1
  var %l = %gamenum
  while (%i <= %l ) {
    unset $+(%game.mode_,$(%i))
    unset $+(%game.version_,$(%i))
    unset $+(%game.auths_,$(%i))
    unset $+(%game.date_,$(%i))
    unset $+(%game.heroes_,$(%i))
    unset $+(%game.chall,$(%i))
    unset $+(%cen.pergame_,$(%i),*)
    unset $+(%cen.game_,$(%i),*)
    unset $+(%cen.game.censured_,$(%i),*)
    inc %i
  }
  set %gamenum 0
  set %challnum 0
  set %regnum 0
  set %max.xpgained 0
  set %max.xplost 0
  set %game.daymax 0
  set %game.today 0
  set %max.xpgained.info nobody
  set %max.xplost.info nobody
}

alias resetstats {
  var %i = 1
  var %l = $hget(userdata,0).item
  while ( %i <= %l ) {
    if ( . !isin $hget(userdata,%i).item ) {
      var %u = $v2
      var %n = $getname(%u)
      var %wz = $user(%u).conf
      ;hadd userdata %u 0.0.0.1000.0.0.0.0. $+ %wz $+ . $+ %n
hadd userdata %u 0.0.0.1000.0.0.0.0.500. $+ %n $+ .0.0
    }
    inc %i
  }
}

on *:TEXT:.zresetuj *:*: {
  var %u = $getid($nick)
  if ($userlvl(%u) < $adminlvl) { return }
  var %cu = $getid($2)
  if (!%cu) { describe %ch Nie ma takiego uzytkownika. | return }
  var %n = $getname(%cu)
  hadd userdata %cu 0.0.0.1000.0.0.0.0.500. $+ %n $+ .0.0
  describe %ch Pomyslnie zresetowano statystyki dla %cu $+ .
}

on *:TEXT:.compare *:*: {
  if ((!%canreply) && ($userlvl2($nick) < 50 )) { return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  if ($3) {
    var %u = $getid($2)
    var %cu = $getid($3)
  }
  else {
    var %u = $getid2($nick)
    var %cu = $getid($2)
  }
  if ((!%u) || (!%cu)) { describe %target Uzytkownik nie znaleziony! | return }
  var %nu = $getname(%u)
  var %ncu = $getname(%cu)
  var %line = %nu $+ $enclose($get.exprank(%u)) porownany do %ncu $+ $enclose($get.exprank(%cu)) $+ :
  var %gameu = $user(%u).game
  var %gamecu = $user(%cu).game
  var %gamediff = $abs($calc(%gameu - %gamecu))
  if (%gameu > %gamecu) {
    var %line = %line %gamediff gier wiecej dla %nu $+ ;
    var %windiff = $calc( $user(%u).win - $user(%cu).win )
    var %lostdiff = $calc( $user(%u).lost - $user(%cu).lost )
    if (%windiff != 0) { var %line = %line $abs(%windiff)% wygranych $iif( %windiff > 0 ,wiecej,mniej) $+ ; }
    if (%lostdiff != 0) { var %line = %line $abs(%lostdiff) przegranych $iif( %lostdiff > 0 ,wiecej,mniej) $+ ; }
  }
  elseif (%gameu < %gamecu) {
    var %line = %line %gamediff wiecej gier dla %ncu $+ ;
    var %windiff = $calc( $user(%cu).win - $user(%u).win )
    var %lostdiff = $calc( $user(%cu).lost - $user(%u).lost )
    if (%windiff != 0) { var %line = %line $abs(%windiff) wygranych $iif( %windiff > 0 ,wiecej,mniej) $+ ; }
    if (%lostdiff != 0) { var %line = %line $abs(%lostdiff) przegranych $iif( %lostdiff > 0 ,wiecej,mniej) $+ ; }
  }
  var %ranku = $user(%u).rankonly
  var %rankcu = $user(%cu).rankonly
  if (%ranku < %rankcu) {
    var %line = %line Roznica w rankingu: + $+ $abs($calc(%ranku - %rankcu)) dla %nu ( $+ %ranku przeciwko %rankcu $+ );
  }
  else {
    var %line = %line Roznica w rankingu: + $+ $abs($calc(%rankcu - %ranku)) dla %ncu ( $+ %rankcu przeciwko %ranku $+ );
  }
  var %stw = 0
  var %stl = 0
  var %saw = 0
  var %sal = 0
  var %i = 1
  var %lu = $user(%u).lastgame
  var %lcu = $user(%cu).lastgame
  if (%lu > %lcu) { var %l = %lu }
  else { var %l = %lcu }
  echo -ag %l
  while (%i <= %l) {
    var %p = $game(%i).plist
    var %pu = $findtok(%p,%u,1,46)
    var %pcu = $findtok(%p,%cu,1,46)
    if ((!%pu) || (!%pcu)) {
      inc %i
      continue
    }
    ;echo -ag 
    var %result = $game(%i).result
    if (%result == draw) {
      inc %i
      continue
    }
    ;echo -ag 
    if ((( %pu <= 5 ) && ( %pcu <= 5)) || (( %pu > 5 ) && ( %pcu > 5))) {
      ;;;;;;;;;;;;;;;;;;  ;;;;;;;;;;;;;;;;;
      ;echo -ag ;;;;;;;;;;;;;;;;;;  ;;;;;;;;;;;;;;;;;
      if ( %result == Radiant ) {
        if (%pu <= 5) {
          inc %stw
        }
        else {
          inc %stl
        }
      }
      else {
        if (%pu <= 5) {
          inc %stl
        }
        else {
          inc %stw
        }
      }
    }
    else {
      ;;;;;;;;;;;;;;;;;;  ;;;;;;;;;;;;;;;;;
      ;echo -ag ;;;;;;;;;;;;;;;;;;  ;;;;;;;;;;;;;;;;;
      if ( %result == Radiant ) {
        if (%pu <= 5) {
          inc %saw
        }
        else {
          inc %sal
        }
      }
      else {
        if (%pu <= 5) {
          inc %sal
        }
        else {
          inc %saw
        }
      }
    }
    inc %i
  }
  var %line = %line Wynik wspolny: %stw $+ / $+ %stl $+ $enclose($iif( %stw == %stl ,Neutralny,$iif(%stw > %stl,+ $+ $calc(%stw - %stl),- $+ $calc(%stl - %stw))))
  var %line = %line Wynik naprzeciw: %saw $+ / $+ %sal $+ $enclose($iif( %saw == %sal ,Wyrownany,$iif(%saw > %sal,%nu prowadzi: + $+ $calc(%saw - %sal),%ncu prowadzi: + $+ $calc(%sal - %saw))))
  describe %target %line
}

on *:TEXT:.inactive*:*: {
  if ((!%canreply) && ($userlvl2($nick) < 50 )) { return }
  if (($timer(listinactive)) && ($userlvl2($nick) < 90)) { return }
  if ($chan) { var %target = $chan }
  else { var %target = $nick }
  var %i = 1
  var %n = 0
  var %l = %rank.users
  var %list = Nieaktywni gracze:
  while (%i <= %l) {
    var %u = $sort.getuser(%i)
    if ($user(%u).inactive) {
      if ($len(%list) >= 780) {
        describe %target %list [wiecej...]
        var %list = $null
      }
      var %list = %list $getname(%u) $+ ,
      inc %n
    }
    inc %i
  }
  describe %target $left(%list,-1) $enclose(%n graczy ogolem)
  timerlistinactive 1 30 noop
}
