#!/usr/bin/perl

#     _                _      _  ____          _
#    / \    _ __  ___ | |__  (_)| __ )   ___  | |_
#   / _ \  | '__|/ __|| '_ \ | ||  _ \  / _ \ | __|
#  / ___ \ | |  | (__ | | | || || |_) || (_) || |_
# /_/   \_\|_|   \___||_| |_||_||____/  \___/  \__|
#
# Copyright 2014 Łukasz "JustArchi" Domeradzki
# Contact: JustArchi@JustArchi.net
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package ArchiBot;

use strict;
use warnings FATAL => 'all';
#use warnings::unused;

use base qw(Bot::BasicBot); # Base
use utf8; # Core
use Math::Round qw(:all); # For rounding winratio
use POE; # For IRC
use DateTime; # For date/timestamps
use Date::Parse; # For str2time()
use Scalar::Util qw(looks_like_number); # For integer checks
use DBI; # For MySQL

# IRC related settings
my $server = '127.0.0.1'; # IP / hostname of the IRC server
my $port = "6671"; # Port of the IRC server, default is 6667
my $ssl = 1; # Define if we should use SSL, change back to 0 if you're unsure
my $nick  = 'proDOTA'; # Target nickname
my $password = 'ircjoinpassword'; # Password to join (if needed)
my $operPassword = "ircoperpassword"; # Oper password, leave empty if you don't have access to that
my $flood = '1'; # Toggle whether bot can flood the server (change to 0 if you're not the host of the IRC server or you have no idea what the hell is that)
my $charset = 'utf-8'; # Default charset

# MySQL
my $mysqlUser = 'mnick_prodota'; # User for MySQL
my $mysqlPassword = 'mysqlpassword'; # Password for MySQL
my $mysqlDatabase = 'mnick_prodota'; # Database for MySQL

# Core settings
my $teamspeakIP = 'TS.JustArchi.net'; # teamspeak IP
my $team1 = 'Radiant'; # name of the first team
my $team2 = 'Dire'; # name of the second team
my $draw = 'Draw'; # name of the draw
my $maxPlayers = 10; # Maximum number of players

# Justice settings
my $requestsNeeded = int($maxPlayers / 2) + 1; # Number of requests needed for certain votes to pass. Min: 0. Max: $maxPlayers

# RELEASE
#my $voteCaptainTime = 1;
#my $voteModeTime = 1;
#my $pickPlayerTime = 1;
my $voteCaptainTime = 30; # Time in seconds to vote for captains after signup completes (0 to disable)
my $voteModeTime = 30; # Time in seconds to vote for mode after signup completes (0 to disable)
my $pickPlayerTime = 30;

my $selfCaptains = 0; # When 0, .captain will act the same as voteCaptain on self
my $variationDelta = 4;
my $justiceDelta = 60; # Decides about "justice". Higher value means lower variation from startingDelta, so more ignore towards points of players, while lower value means higher variation, so less ignore towards points of players. 20 is optimal, it means that min/max variation is 20 * ($maxDelta - $startingDelta).
my $justiceStreak = 1; # Multiplier of points added for streaks.
my $testGames = 3;

# Don't change anything below unless you know what you're doing
my $databaseConnection; # MySQL connection
my %modes; # Automatically loaded from MySQL
my $averagePoints; # Automatically calculated from MySQL
my $today = returnToday(); # We want to know when day changes

# Accesses, MUST match the database
my $accessPermaBanned = 1;
my $accessBanned = 2;
my $accessTimeBanned = 3;
my $accessUser = 10;
my $accessTestUser = 15;
my $accessVouched = 20;
my $accessAdmin = 98;
my $accessRoot = 99;

# Channels
my $mainChannel = '#proDOTA';
my @channels = ('#PD-vouch', '#PD-open'); # Channels
my %channelPermissions;
$channelPermissions{'#PD-vouch'} = $accessTestUser;
$channelPermissions{'#PD-open'} = $accessUser;

# Absolutely don't change these
my $firstBoot = 1;
my $seasonIsActive;

my %phase;
my %counter;
my %canVoteOnMode;
my %canVoteOnCaptains;
my %totalModeVotes;
my %totalcaptainVotes;
my %turn;
my %lastTurn;

my %captain1;
my %captain2;
my %chosenMode;
my %gamePassword;

my %players;
my %team1;
my %team2;
for my $channel (@channels) {
	$phase{$channel} = 0;
	$counter{$channel} = 0;
	$canVoteOnMode{$channel} = 0;
	$canVoteOnCaptains{$channel} = 0;
	$totalModeVotes{$channel} = 0;
	$totalcaptainVotes{$channel} = 0;
	$turn{$channel} = 0;
	$lastTurn{$channel} = 0;

	$captain1{$channel} = '';
	$captain2{$channel} = '';
	$chosenMode{$channel} = '';
	$gamePassword{$channel} = '';

	@{$players{$channel}} = ();
	@{$team1{$channel}} = ();
	@{$team2{$channel}} = ();
}

my $second = 0;
my $minute = 0;

my %modeVotes;
my %modeVoters;
my %captainVotes;
my %captainVoters;
my %gameResult;
my %luckyPlayers;
my %colorTrades;
my %oneVersusOne;

#  ____         _
# |  _ \   ___ | |__   _   _   __ _
# | | | | / _ \| '_ \ | | | | / _` |
# | |_| ||  __/| |_) || |_| || (_| |
# |____/  \___||_.__/  \__,_| \__, |
#                             |___/

sub archiTests {
	return; # No tests
}

my $noAdmins = 0;
sub archiTest {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	#$self->sayToChannel($channel, "LICZBA: " . $#{$team1{$channel}});
	#$self->sayToChannel($channel, "GRACZE: " . arrayToStringWithSpaces(@{$team1{$channel}}));
	#$self->sayToChannel($channel, "GRACZ 0: " . arrayToStringWithSpaces(@{$team1{$channel}}[1]));

	#$self->sayToChannel($channel, "DEBUG: " . randomGamePassword());

	### TESTY ###
	if (!$noAdmins) {
		$noAdmins = 1;
		$self->sayToChannel($channel, defaultColor("Administratorzy są teraz traktowani jak zwykli użytkownicy!"));
	} else {
		$self->sayToChannel($channel, defaultColor("Administratorzy są ponownie administratorami!"));
		$noAdmins = 0;
	}
	return;
}

sub archiPrint {
	print STDERR arrayToStringWithSpaces(@_);
	print STDERR "\n";
	return;
}

#  __  __         ____    ___   _
# |  \/  | _   _ / ___|  / _ \ | |
# | |\/| || | | |\___ \ | | | || |
# | |  | || |_| | ___) || |_| || |___
# |_|  |_| \__, ||____/  \__\_\|_____|
#          |___/

sub mysqlInjectDefaultDataIfNeeded {
	# NOTICE: This may be incomplete
	my $mysqlQuery;
	if (isEmpty(mysqlGetOne("accesses", "access_id", "access_id", "1"))) {
		$databaseConnection->do("INSERT INTO accesses (`access_id`, `name`) VALUES ($accessPermaBanned, 'PermaBanned'), ($accessBanned, 'Banned'), ($accessUser, 'User'), ($accessTestUser, 'VouchTest'), ($accessVouched, 'Vouched'), ($accessAdmin, 'Admin'), ($accessRoot, 'Root')");
	}
	if (isEmpty(mysqlGetOne("seasons", "season_id", "season_id", "1"))) {
		$databaseConnection->do("INSERT INTO seasons (season_id, firstgame_id) VALUES (1, 1)");
	}
	if (!defined(mysqlGetOne("modes", "mode_id", "mode_id", "1"))) {
		$databaseConnection->do("INSERT INTO `modes` (`mode_id`, `name`, `Type`) VALUES (1, 'CM', '1'), (2, 'CD', '1')");
	}
	if (!mysqlPlayerExistsByNick($nick)) {
		$mysqlQuery = $databaseConnection->prepare("INSERT INTO `Players` (`username`, `password`, `access_id`) VALUES (?, ?, 99)");
		$mysqlQuery->execute($nick, $password);
	}
	return;
}

sub mysqlConnectToDatabase {
	$databaseConnection = DBI->connect("DBI:mysql:$mysqlDatabase", "$mysqlUser", "$mysqlPassword") || die "Could not connect to database: $DBI::errstr";
	$databaseConnection->{mysql_auto_reconnect} = 1;
	mysqlInjectDefaultDataIfNeeded();
	return;
}

sub mysqlDateToTimestamp {
	my $select = shift;
	$select = 'UNIX_TIMESTAMP(' . quoteString($select) . ')';
	my $mysqlQuery = $databaseConnection->prepare("SELECT $select");
	$mysqlQuery->execute();
	return $mysqlQuery->fetchrow_hashref()->{$select};
}

sub mysqlTimestampToDate {
	my $select = shift;
	$select = "FROM_UNIXTIME($select)";
	my $mysqlQuery = $databaseConnection->prepare("SELECT $select");
	$mysqlQuery->execute();
	return $mysqlQuery->fetchrow_hashref()->{$select};
}

sub mysqlGetCurrentDate {
	my $mysqlQuery = $databaseConnection->prepare("SELECT CURRENT_TIMESTAMP");
	$mysqlQuery->execute();
	return $mysqlQuery->fetchrow_hashref()->{CURRENT_TIMESTAMP};
}

sub mysqlGetCurrentTimestamp {
	my $select = 'UNIX_TIMESTAMP(CURRENT_TIMESTAMP)';
	my $mysqlQuery = $databaseConnection->prepare("SELECT $select");
	$mysqlQuery->execute();
	return $mysqlQuery->fetchrow_hashref()->{$select};
}

sub mysqlGetAllOne {
	my $from = shift;
	my $condition = shift;
	my $value = shift;
	my $condition2 = shift;
	my $value2 = shift;
	my $mysqlQuery;
	if (!isEmpty($condition2)) {
		# We have two conditions
		$mysqlQuery = $databaseConnection->prepare("SELECT * FROM $from WHERE $condition=? AND $condition2=?");
		$mysqlQuery->execute($value, $value2);
	} elsif (!isEmpty($condition)) {
		# We have one condition
		if (stringContainsSubstring($value, ",")) {
			# We have multiple values
			$mysqlQuery = $databaseConnection->prepare("SELECT * FROM $from WHERE $condition IN ($value)");
			$mysqlQuery->execute();
		} elsif (stringContainsSubstring($value, "'")) {
			# We have one already quoted value
			$mysqlQuery = $databaseConnection->prepare("SELECT * FROM $from WHERE $condition=$value");
			$mysqlQuery->execute();
		} else {
			# We have one unquoted value
			$mysqlQuery = $databaseConnection->prepare("SELECT * FROM $from WHERE $condition=?");
			$mysqlQuery->execute($value);
		}
	} else {
		# We have no condition
		$mysqlQuery = $databaseConnection->prepare("SELECT * FROM $from");
		$mysqlQuery->execute();
	}
	return $mysqlQuery->fetchrow_hashref();
}

sub mysqlGetOne {
	my $from = shift;
	my $select = shift;
	my $condition = shift;
	my $value = shift;
	my $condition2 = shift;
	my $value2 = shift;
	my $mysqlQuery;
	if (!isEmpty($condition2)) {
		# We have two conditions
		$mysqlQuery = $databaseConnection->prepare("SELECT $select FROM $from WHERE $condition=? AND $condition2=?");
		$mysqlQuery->execute($value, $value2);
	} elsif (!isEmpty($condition)) {
		# We have one condition
		if (stringContainsSubstring($value, ",")) {
			# We have multiple values
			$mysqlQuery = $databaseConnection->prepare("SELECT $select FROM $from WHERE $condition IN ($value)");
			$mysqlQuery->execute();
		} elsif (stringContainsSubstring($value, "'")) {
			# We have one already quoted value
			$mysqlQuery = $databaseConnection->prepare("SELECT $select FROM $from WHERE $condition=$value");
			$mysqlQuery->execute();
		} else {
			# We have one unquoted value
			if (stringContainsSubstring($condition, '=') || stringContainsSubstring($condition, '>') || stringContainsSubstring($condition, '<')) {
				# With special operator in condition
				$mysqlQuery = $databaseConnection->prepare("SELECT $select FROM $from WHERE $condition ?");
			} else {
				# With default = operator in condition
				$mysqlQuery = $databaseConnection->prepare("SELECT $select FROM $from WHERE $condition=?");
			}
			$mysqlQuery->execute($value);
		}
	} else {
		# We have no condition
		$mysqlQuery = $databaseConnection->prepare("SELECT $select FROM $from");
		$mysqlQuery->execute();
	}
	my $result = $mysqlQuery->fetchrow_hashref(); # We must fetchrow to the $result because
	return $result->{$select}; # It may return NULL and you can't cast on NULL objects
}

sub mysqlGetAllMultiple {
	my $from = shift;
	my $condition = shift;
	my $value = shift;
	my $mysqlQuery;
	if (!isEmpty($condition)) {
		# We have one condition
		if (stringContainsSubstring($value, ",")) {
			# We have multiple values
			$mysqlQuery = $databaseConnection->prepare("SELECT * FROM $from WHERE $condition IN ($value)");
			$mysqlQuery->execute();
		} elsif (stringContainsSubstring($value, 'NULL')) {
			# We have NULL check
			$mysqlQuery = $databaseConnection->prepare("SELECT * FROM $from WHERE $condition");
			$mysqlQuery->execute();
		} elsif (stringContainsSubstring($value, "'")) {
			# We have one already quoted value
			$mysqlQuery = $databaseConnection->prepare("SELECT * FROM $from WHERE $condition=$value");
			$mysqlQuery->execute();
		} else {
			# We have one unquoted value
			$mysqlQuery = $databaseConnection->prepare("SELECT * FROM $from WHERE $condition=?");
			$mysqlQuery->execute($value);
		}
	} else {
		# We have no condition
		$mysqlQuery = $databaseConnection->prepare("SELECT * FROM $from");
		$mysqlQuery->execute();
	}

	my @mysqlResult;
	while (my $ref = $mysqlQuery->fetchrow_hashref()) {
		push(@mysqlResult, $ref);
	}
	return @mysqlResult;
}

sub mysqlGetMultiple {
	my $from = shift;
	my $select = shift;
	my $condition = shift;
	my $value = shift;
	my $mysqlQuery;
	if (!isEmpty($condition)) {
		# We have one condition
		if (stringContainsSubstring($value, ",")) {
			# We have multiple values
			$mysqlQuery = $databaseConnection->prepare("SELECT $select FROM $from WHERE $condition IN ($value)");
			$mysqlQuery->execute();
		} elsif (stringContainsSubstring($value, "'")) {
			# We have one already quoted value
			$mysqlQuery = $databaseConnection->prepare("SELECT $select FROM $from WHERE $condition=$value");
			$mysqlQuery->execute();
		} else {
			# We have one unquoted value
			if (stringContainsSubstring($condition, '=') || stringContainsSubstring($condition, '>') || stringContainsSubstring($condition, '<')) {
				# With special operator in condition
				$mysqlQuery = $databaseConnection->prepare("SELECT $select FROM $from WHERE $condition ?");
			} else {
				# With default = operator in condition
				$mysqlQuery = $databaseConnection->prepare("SELECT $select FROM $from WHERE $condition=?");
			}
			$mysqlQuery->execute($value);
		}
	} else {
		# We have no condition
		$mysqlQuery = $databaseConnection->prepare("SELECT $select FROM $from");
		$mysqlQuery->execute();
	}

	my @mysqlResult;
	while (my $ref = $mysqlQuery->fetchrow_hashref()) {
		push(@mysqlResult, $ref->{$select});
	}
	return @mysqlResult;
}

sub mysqlInsert {
	my $insert = shift;
	my $rows = shift;
	my $values = shift;
	my $mysqlQuery;

	if (!isEmpty($rows)) {
		$rows = '(' . $rows . ')';
	}

	if (!isEmpty($values)) {
		if (stringContainsSubstring($values, ",")) {
			# We have multiple values
			$mysqlQuery = $databaseConnection->prepare("INSERT INTO $insert $rows VALUES ($values)");
			$mysqlQuery->execute();
		} else {
			# We have one unquoted value
			$mysqlQuery = $databaseConnection->prepare("INSERT INTO $insert $rows VALUES (?)");
			$mysqlQuery->execute($values);
		}
	} else {
		$mysqlQuery = $databaseConnection->prepare("INSERT INTO $insert VALUES ()");
		$mysqlQuery->execute();
	}
	return $mysqlQuery->{mysql_insertid};
}

sub mysqlUpdate {
	my $update = shift;
	my $set = shift;
	my $condition = shift;
	my $value = shift;
	my $mysqlQuery;

	if (isEmpty($condition)) {
			$mysqlQuery = $databaseConnection->prepare("UPDATE $update SET $set");
			$mysqlQuery->execute();
	} else {
		if (stringContainsSubstring($value, ",")) {
			# We have multiple values
			$mysqlQuery = $databaseConnection->prepare("UPDATE $update SET $set WHERE $condition IN ($value)");
			$mysqlQuery->execute();
		} elsif (stringContainsSubstring($value, "'")) {
			# We have one already quoted value
			$mysqlQuery = $databaseConnection->prepare("UPDATE $update SET $set WHERE $condition=$value");
			$mysqlQuery->execute();
		} else {
			# We have one unquoted value
			$mysqlQuery = $databaseConnection->prepare("UPDATE $update SET $set WHERE $condition=?");
			$mysqlQuery->execute($value);
		}
	}
	return;
}

sub mysqlDelete {
	my $from = shift;
	my $condition = shift;
	my $value = shift;
	my $condition2 = shift;
	my $value2 = shift;
	my $mysqlQuery;
	if (isEmpty($condition2)) {
		$mysqlQuery = $databaseConnection->prepare("DELETE FROM $from WHERE $condition=?");
		$mysqlQuery->execute($value);
	} else {
		$mysqlQuery = $databaseConnection->prepare("DELETE FROM $from WHERE $condition=? AND $condition2=?");
		$mysqlQuery->execute($value, $value2);
	}
	return;
}

### ACCESSES ###
sub mysqlGetAccessByID {
	my $accessID = shift;
	return mysqlGetOne("accesses", "name", "access_id", $accessID);
}

### MODES ###
sub mysqlGetModePoints {
	my $modeID = shift;
	return mysqlGetOne("modes", "points", "mode_id", $modeID);
}

sub mysqlGetNameOfMode {
	my $modeID = shift;
	return mysqlGetOne("modes", "name", "mode_id", $modeID);
}

### PLAYERS ###
sub mysqlPlayerExistsByNick {
	my $player = shift;
	return defined(mysqlGetOne("users", "user_id", "username", $player));
}

sub mysqlPlayerIsAdminByNick {
	my $player = shift;
	if ($player eq $nick) {
		return 1; # True
	}

	# TODO: DEBUG
	if ($noAdmins) {
		return 0;
	}
	my $access = mysqlGetOne("users", "access_id", "username", $player);
	if ($access >= $accessAdmin) {
		return 1; # True
	} else {
		return 0; # False
	}
}

sub mysqlInsertPlayer {
	my $player = shift;
	my $mysqlQuery;
	$mysqlQuery = $databaseConnection->prepare("INSERT INTO users (username) VALUES (?)");
	$mysqlQuery->execute($player);
	return $mysqlQuery->{mysql_insertid};
}

sub mysqlGetAdmins {
	return mysqlGetMultiple("users", "username", "access_id >=", 98);
}

sub mysqlGetNicknamesOfPlayers {
	return mysqlGetMultiple("users", "username", "user_id", returnGroupForMysql(@_));
}

sub mysqlGetPlayerIDByNick {
	my $nick = shift;
	return mysqlGetOne("users", "user_id", "username", $nick);
}

sub mysqlGetSumOfPlayersPointsByID {
	return mysqlGetOne("users", "SUM(points)", "user_id", returnGroupForMysql(@_));
}

sub mysqlGetSumOfPlayersPointsByNick {
	return mysqlGetOne("users", "SUM(points)", "username", returnGroupForMysql(@_));
}

sub mysqlGetPlayerColorByNick {
	my $nick = shift;
	return mysqlGetOne("users", "color", "username", $nick);
}

sub mysqlGetPlayerPointsByNick {
	my $nick = shift;
	return mysqlGetOne("users", "points", "username", $nick);
}

sub mysqlGetPlayerWinsByNick {
	my $nick = shift;
	return mysqlGetOne("users", "wins", "username", $nick);
}

sub mysqlGetPlayerLosesByNick {
	my $nick = shift;
	return mysqlGetOne("users", "loses", "username", $nick);
}

sub mysqlGetPlayerDrawsByNick {
	my $nick = shift;
	return mysqlGetOne("users", "draws", "username", $nick);
}

sub mysqlGetPlayerStreakByID {
	my $playerID = shift;
	return mysqlGetOne("users", "streak", "user_id", $playerID);
}

sub mysqlGetPlayerLongestStreakByID {
	my $playerID = shift;
	return mysqlGetOne("users", "longest_streak", "user_id", $playerID);
}

sub mysqlGetPlayerAccessByNick {
	my $nick = shift;
	return mysqlGetOne("users", "access_id", "username", $nick);
}

sub mysqlRewardPlayersByID {
	my $reward = shift;
	mysqlUpdate("users", "points = points + $reward, total_points = total_points + $reward", "user_id", returnGroupForMysql(@_));
	return;
}

sub mysqlRewardPlayerByNick {
	my $reward = shift;
	mysqlUpdate("users", "points = points + $reward, total_points = total_points + $reward", "username", returnGroupForMysql(@_));
	return;
}

sub mysqlGiveRootByNick {
	my $player = shift;
	mysqlUpdate("users", "access_id = $accessRoot", "username", "$player");
	return;
}

sub mysqlBanPlayerByNick {
	my $time = shift;
	my $access;
	if ($time >= 999) { # Ban for season
		$access = $accessBanned;
		$time = 'NULL';
	} elsif ($time > 0) { # Time ban
		$access = $accessTimeBanned;
		$time = quoteString(mysqlTimestampToDate($time * 60 * 60 + mysqlGetCurrentTimestamp()));
	} else { # Perma ban
		$access = $accessPermaBanned;
		$time = 'NULL';
	}
	mysqlUpdate("users", "access_id = $access, banned_until = $time", "username", returnGroupForMysql(@_));
	return;
}

sub mysqlUnbanPlayerByNick {
	my $player = shift;
	mysqlUpdate("users", "access_id = $accessUser, banned_until = NULL", "username", "$player");
	return;
}

sub mysqlVouchPlayersByNick {
	my $vouchAccess = shift;
	mysqlUpdate("users", "access_id = $vouchAccess", "username", returnGroupForMysql(@_));
	return;
}

sub mysqlUpdatePlayerColor {
	my $player = shift;
	my $color = shift;
	mysqlUpdate("users", "color = $color", "username", $player);
	return;
}

sub mysqlDecreaseWinsByID {
	my $playerID = shift;
	mysqlUpdate("users", "wins = wins - 1, total_wins = total_wins - 1", "user_id", $playerID);
	return;
}

sub mysqlDecreaseLosesByID {
	my $playerID = shift;
	mysqlUpdate("users", "loses = loses - 1, total_loses = total_loses - 1", "user_id", $playerID);
	return;
}

sub mysqlDecreaseWinsForPlayers {
	mysqlUpdate("users", "wins = wins - 1, total_wins = total_wins - 1", "user_id", returnGroupForMysql(@_));
	return;
}

sub mysqlDecreaseLosesForPlayers {
	mysqlUpdate("users", "loses = loses - 1, total_loses = total_loses - 1", "user_id", returnGroupForMysql(@_));
	return;
}

sub mysqlScoreWinForPlayers {
	mysqlUpdate("users", "streak = streak + 1, wins = wins + 1, total_wins = total_wins + 1", "user_id", returnGroupForMysql(@_));
	for my $playerID (@_) {
		my $request = mysqlGetAllOne("users", "user_id", $playerID);
		if ($request->{longest_streak} < $request->{streak}) {
			mysqlUpdate("users", "longest_streak = streak", "user_id", $playerID);
		}
	}
	return;
}

sub mysqlScoreLoseForID {
	my $playerID = shift;
	mysqlUpdate("users", "streak = 0, loses = loses + 1, total_loses = total_loses + 1", "user_id", $playerID);
	return;
}

sub mysqlScoreLoseForPlayers {
	mysqlUpdate("users", "streak = 0, loses = loses + 1, total_loses = total_loses + 1", "user_id", returnGroupForMysql(@_));
	return;
}

sub mysqlScoreDrawByIDs {
	mysqlUpdate("users", "draws = draws + 1, total_draws = total_draws + 1", "user_id", quoteString(arrayToStringWithDelimiter("','", @_)));
	return;
}

sub mysqlUpdateLastGameOfPlayersByNick {
	my $game = shift;
	mysqlUpdate("users", "lastgame_id = $game", "username", returnGroupForMysql(@_));
	return;
}

sub mysqlGetLastGameOfPlayerByNick {
	my $nick = shift;
	my $mysqlQuery;
	$mysqlQuery = mysqlGetOne("users", "lastgame_id", "username", $nick);
	if (defined($mysqlQuery)) {
		return $mysqlQuery;
	} else {
		return -1;
	}
}

sub mysqlGetLastGameRepOfPlayerByNick {
	my $nick = shift;
	my $mysqlQuery;
	$mysqlQuery = mysqlGetOne("users", "lastgame_rep_id", "username", $nick);
	if (defined($mysqlQuery)) {
		return $mysqlQuery;
	} else {
		return -1;
	}
}

### TEAMS ###
sub mysqlTeamExists {
	my $team = shift;
	return defined(mysqlGetOne("teams", "team_id", "team_id", $team));
}

sub mysqlInsertTeam {
	my $team = shift;
	my $mysqlQuery;
	if (isEmpty($team)) {
		$mysqlQuery = $databaseConnection->prepare("INSERT INTO teams () VALUES()");
		$mysqlQuery->execute();
	} else {
		$mysqlQuery = $databaseConnection->prepare("INSERT INTO teams (team_id) VALUES(?)");
		$mysqlQuery->execute($team);
	}
	return $mysqlQuery->{mysql_insertid};
}

sub mysqlGetTeamTotalPoints {
	my $teamID = shift;
	return mysqlGetOne("teams", "total_points", "team_id", $teamID);
}

sub mysqlUpdateTeamTotalPoints {
	my @outputpoints;
	foreach(@_) {
		my $calculatedpoints = mysqlGetSumOfPlayersPointsByID(mysqlGetPlayersFromTeam($_));
		mysqlUpdate("teams", "total_points = $calculatedpoints", "team_id", $_);
		push(@outputpoints, $calculatedpoints);
	}
	return @outputpoints;
}

sub mysqlAddPlayerToTeam {
	my $team = shift;
	my $player = shift;
	mysqlAddPlayersToTeam($team, $player);
	#my $playerID = mysqlGetPlayerIDByNick($player);
	#my $mysqlQuery = $databaseConnection->prepare("INSERT INTO team_user VALUES(?, ?)");
	#$mysqlQuery->execute($playerID, $team);
	return;
}

sub mysqlRemovePlayerFromTeam {
	my $player = shift;
	my $team = shift;
	my $playerID = mysqlGetPlayerIDByNick($player);
	mysqlDelete("team_user", "user_id", $playerID, "team_id", $team);
	return;
}

sub mysqlAddPlayersToTeam {
	my $teamID = shift;
	my @values;
	for my $playerID (mysqlGetMultiple("users", "user_id", "username", returnGroupForMysql(@_))) {
		push(@values, returnGroupForMysql($teamID, $playerID));
	}
	mysqlInsert("team_user", "team_id, user_id", returnInsertGroupForMysql(@values));
	return;
}

sub mysqlGetPlayersFromTeam {
	my $team = shift;
	return mysqlGetMultiple("team_user", "user_id", "team_id", $team);
}

sub mysqlForwardpointsToteams {
	my $deltaPoints = shift;
	my $winnerTeamID = shift;
	my $loserTeamID = shift;
	my $cancelScore = shift; # Used for reverse delta during changing score
	if (isEmpty($cancelScore)) {
		$cancelScore = 0;
	}
	if ($deltaPoints == 0) { # If this is a draw
		mysqlScoreDrawByIDs(mysqlGetPlayersFromTeam($winnerTeamID), mysqlGetPlayersFromTeam($loserTeamID));
	} else { # If this is not a draw
		my @playersInGame = mysqlGetPlayersFromTeam($winnerTeamID);
		mysqlRewardPlayersByID($deltaPoints, @playersInGame);
		if (!$cancelScore) {
			mysqlScoreWinForPlayers(@playersInGame);
		} else {
			mysqlDecreaseLosesForPlayers(@playersInGame);
		}
		@playersInGame = mysqlGetPlayersFromTeam($loserTeamID);
		mysqlRewardPlayersByID($deltaPoints * -1, @playersInGame);
		if (!$cancelScore) {
			mysqlScoreLoseForPlayers(@playersInGame);
		} else {
			mysqlDecreaseWinsForPlayers(@playersInGame);
		}
	}
	recalculateAveragePoints();
	return;
}

sub mysqlPlayerPlaysInTeamByNick {
	my $player = shift;
	my $playerID = mysqlGetPlayerIDByNick($player);
	my $team = shift;
	return defined(mysqlGetOne("team_user", "user_id", "user_id", $playerID, "team_id", $team));
}

sub mysqlGetTeamOfPlayerFromGame {
	my $player = shift;
	my $game = shift;
	my $team1 = mysqlGetTeam1ID($game);
	my $team2 = mysqlGetTeam2ID($game);
	if (mysqlPlayerPlaysInTeamByNick($player, $team1)) {
		return $team1;
	} elsif (mysqlPlayerPlaysInTeamByNick($player, $team2)) {
		return $team2;
	} else {
		return -1;
	}
}

### GAMES ###
sub mysqlGameExists {
	my $game = shift;
	return defined(mysqlGetOne("games", "game_id", "game_id", $game));
}

sub mysqlGameIsActive {
	my $game = shift;
	if (mysqlGameExists($game)) {
		return !defined(mysqlGetOne("games", "winner", "game_id", $game));
	} else {
		return 0; # False
	}
}

sub mysqlGetwinnerOfGame {
	my $game = shift;
	return mysqlGetOne("games", "winner", "game_id", $game);
}

sub mysqlInsertGame {
	my $team1 = shift;
	my $team2 = shift;
	my $modeID = shift;
	my $mysqlQuery = $databaseConnection->prepare("INSERT INTO games (team1_id, team2_id, mode_id) VALUES (?, ?, ?)");
	$mysqlQuery->execute($team1, $team2, $modeID);
	return $mysqlQuery->{mysql_insertid};
}

sub mysqlGetDeltaOfGame {
	my $game = shift;
	return mysqlGetOne("games", "delta", "game_id", $game);
}

sub mysqlGetTeam1ID {
	my $game = shift;
	return mysqlGetOne("games", "team1_id", "game_id", $game);
}

sub mysqlGetTeam2ID {
	my $game = shift;
	return mysqlGetOne("games", "team2_id", "game_id", $game);
}

sub mysqlSetwinnerOfGame {
	my $team = shift;
	my $game = shift;
	mysqlUpdate("games", "winner = $team", "game_id", $game);
	return;
}

sub mysqlSetDeltaOfGame {
	my $delta = shift;
	my $game = shift;
	mysqlUpdate("games", "delta = $delta", "game_id", $game);
	return;
}

sub mysqlGetActivegames {
	my $mysqlQuery = $databaseConnection->prepare("SELECT game_id FROM games WHERE winner IS NULL");
	$mysqlQuery->execute();
	my @activegames;
	while (my $ref = $mysqlQuery->fetchrow_hashref()) {
		push(@activegames, $ref->{'game_id'});
	}
	return @activegames;
}

sub mysqlGetSeason {
	my $seasonID = shift;
	return mysqlGetAllOne("seasons", "season_id", $seasonID);
}

sub mysqlGetLastSeasonID {
	my $mysqlQuery = $databaseConnection->prepare("SELECT season_id FROM seasons ORDER BY season_id DESC LIMIT 1");
	$mysqlQuery->execute();
	my $mysqlResult = $mysqlQuery->fetchrow_hashref();
	if (isEmpty($mysqlResult->{season_id})) {
		return 0;
	} else {
		return $mysqlResult->{season_id};
	}
}

sub mysqlGetLastGame {
	my $mysqlQuery = $databaseConnection->prepare("SELECT game_id FROM games ORDER BY game_id DESC LIMIT 1");
	$mysqlQuery->execute();
	my $mysqlResult = $mysqlQuery->fetchrow_hashref();
	my $ret = $mysqlResult->{'game_id'};
	if (defined($ret)) {
		return $ret;
	} else {
		return 0;
	}
}

sub mysqlDeleteGame {
	for my $gameID (@_) {
		my $request = mysqlGetAllOne("games", "game_id", $gameID);
		mysqlDelete("team_user", "team_id", $request->{team1_id});
		mysqlDelete("team_user", "team_id", $request->{team2_id});
		#mysqlDelete("games", "game_id", $gameID);
		#mysqlDelete("teams", "team_id", $request->{team1_id});
		#mysqlDelete("teams", "team_id", $request->{team2_id});
	}
	return;
}

#  _   _  _    _  _  _  _    _
# | | | || |_ (_)| |(_)| |_ (_)  ___  ___
# | | | || __|| || || || __|| | / _ \/ __|
# | |_| || |_ | || || || |_ | ||  __/\__ \
#  \___/  \__||_||_||_| \__||_| \___||___/

sub initArchiBot {
	mysqlConnectToDatabase();
	loadEverything();
	archiTests();
	#channels => [ "$mainChannel", @channels ]
	ArchiBot->new(raw => 1, server => $server, port => $port, ssl => $ssl, password => $password, nick => $nick, flood => $flood, charset => $charset)->run();
	return;
}

sub loadEverything {
	my $currentSeason = mysqlGetSeason(mysqlGetLastSeasonID());
	if (isEmpty($currentSeason)) {
		$seasonIsActive = 0;
	} elsif (isEmpty($currentSeason->{lastgame_id})) {
		$seasonIsActive = 1;
	} else {
		$seasonIsActive = 0;
	}

	for my $request (mysqlGetAllMultiple("modes")) {
		my $modeName = $request->{name};
		my $modePoints = $request->{points};
		$modes{$modeName} = $modePoints;
	}

	recalculateAveragePoints();

	return;
}

sub getStringModes {
	my @stringModes;
	for my $mode (keys %modes) {
		push(@stringModes, $mode . '(' . $modes{$mode} . ')');
	}
	return arrayToStringWithSpaces(@stringModes);
}

sub notNull {
	my $return = -1;
	if (!isEmpty($_[1])) {
		$return = $_[1];
	}
	if (defined($_[0])) {
		return $_[0];
	} else {
		return $return;
	}
}

sub randomBoolean {
	return int(rand(2)) == 1;
}

sub isANumber {
	my $number = shift;
	return looks_like_number($number);
}

sub stringContainsSubstring {
	my $string = shift;
	my $substring = shift;
	return index($string, $substring) != -1;
}

sub quoteString {
	my $string = shift;
	return "'" . $string . "'";
}

sub arrayToStringWithDelimiter {
	my $delimiter = shift;
	return join($delimiter, @_);
}

sub arrayToString {
	return join('', @_);
}

sub arrayToStringWithSpaces {
	return arrayToStringWithDelimiter(' ', @_);
}

sub returnArraySplitOnSpaces {
	return split(' ', arrayToStringWithSpaces(@_));
}

sub isEmpty {
	my $string = shift;
	if (defined($string)) {
		if ($string eq '') {
			return 1; # True
		} else {
			return 0; # False
		}
	} else {
		return 1; # True
	}
}

sub caseInsensitiveEquals {
	my $string = lc(shift);
	for my $string2 (@_) {
		if ($string eq lc($string2)) {
			return 1; # True
		}
	}
	return 0; # False
}

#  ___  ____    ____   _   _  _    _  _  _  _    _
# |_ _||  _ \  / ___| | | | || |_ (_)| |(_)| |_ (_)  ___  ___
#  | | | |_) || |     | | | || __|| || || || __|| | / _ \/ __|
#  | | |  _ < | |___  | |_| || |_ | || || || |_ | ||  __/\__ \
# |___||_| \_\ \____|  \___/  \__||_||_||_| \__||_| \___||___/
#
# IRC Utilities

# # formatting
# BOLD		  => "\x02",
# UNDERLINE	  => "\x1f",
# REVERSE	  => "\x16",
# ITALIC	  => "\x1d",
# FIXED		  => "\x11",
# BLINK		  => "\x06",
# 
# # mIRC colors
# WHITE		  => "\x0300",
# BLACK		  => "\x0301",
# BLUE		  => "\x0302",
# GREEN		  => "\x0303",
# RED		  => "\x0304",
# BROWN		  => "\x0305",
# PURPLE	  => "\x0306",
# ORANGE	  => "\x0307",
# YELLOW	  => "\x0308",
# LIGHT_GREEN => "\x0309",
# TEAL		  => "\x0310",
# LIGHT_CYAN  => "\x0311",
# LIGHT_BLUE  => "\x0312",
# PINK		  => "\x0313",
# GREY		  => "\x0314",
# LIGHT_GREY  => "\x0315",

sub executeRawIRC {
	my $self = shift;
	my $command = shift;
	$poe_kernel->post($self->pocoirc()->session_id() => quote => $command);
	return;
}

sub stripIRCFormatting {
	my $message = arrayToStringWithSpaces(@_);
	$message =~ s/\cC\d{1,2}(?:,\d{1,2})?|[\cC\cB\cI\cU\cR\cO\x1F]//g; # Don't even try to understand this, it just works
	return $message;
}

sub applyIRCFormatting {
	my $code = shift;
	return $code . arrayToStringWithSpaces(@_) . "\x0f";
}

sub customColor {
	my $color = shift;
	return applyIRCFormatting("\x03" . $color, @_);
}

sub defaultColor {
	return gold(@_);
	#return customColor(randomColor(), @_); # --gay
}

sub playerColor {
	my $nick = shift;
	my $color = shift;
	if (isEmpty($color)) {
		$color = mysqlGetPlayerColorByNick($nick);
	}
	if ($color == 0) {
		# Most of the players will have default color, so we favor this scenario
		return bold(defaultColor($nick));
	} elsif ($color == 1) {
		return bold(black($nick));
	} elsif ($color == 2) {
		return bold(blue($nick));
	} elsif ($color == 3) {
		return bold(green($nick));
	} elsif ($color == 4) {
		return bold(red($nick));
	} elsif ($color == 5) {
		return bold(brown($nick));
	} elsif ($color == 6) {
		return bold(purple($nick));
	} elsif ($color == 7) {
		return bold(orange($nick));
	} elsif ($color == 8) {
		return bold(yellow($nick));
	} elsif ($color == 9) {
		return bold(lgreen($nick));
	} elsif ($color == 10) {
		return bold(teal($nick));
	} elsif ($color == 11) {
		return bold(lcyan($nick));
	} elsif ($color == 12) {
		return bold(lblue($nick));
	} elsif ($color == 13) {
		return bold(pink($nick));
	} elsif ($color == 14) {
		return bold(grey($nick));
	} elsif ($color == 15) {
		return bold(lgrey($nick));
	} elsif ($color == 16) {
		return bold(gold($nick));
	# Mix of colors
	} else {
		my $randomSwitch = int(rand(2));
		my $stringLength = length($nick);
		my $splitIndex = $stringLength - int($stringLength / 2);
		my $firstPart = substr($nick, 0, $splitIndex);
		my $secondPart = substr($nick, $splitIndex);
		if ($color == 17) {
			if ($randomSwitch) {
				return bold(white($firstPart)) . bold(black($secondPart));
			} else {
				return bold(black($firstPart)) . bold(white($secondPart));
			}
		} elsif ($color == 18) {
			if ($randomSwitch) {
				return bold(white($firstPart)) . bold(blue($secondPart));
			} else {
				return bold(blue($firstPart)) . bold(white($secondPart));
			}
		} elsif ($color == 19) {
			if ($randomSwitch) {
				return bold(white($firstPart)) . bold(green($secondPart));
			} else {
				return bold(green($firstPart)) . bold(white($secondPart));
			}
		} elsif ($color == 20) {
			if ($randomSwitch) {
				return bold(white($firstPart)) . bold(red($secondPart));
			} else {
				return bold(red($firstPart)) . bold(white($secondPart));
			}
		}
	}
}

sub randomColor {
	my $randomColor = 0;
	# colors that don't go well with our website, modify as you please
	while ($randomColor == 1 || $randomColor == 2 || $randomColor == 4 || $randomColor == 5 || $randomColor == 12 || $randomColor == 16) {
		$randomColor = int(rand(17));
	}
	return $randomColor;
}

sub bold {
	return applyIRCFormatting("\x02", @_);
}

sub underline {
	return applyIRCFormatting("\x1f", @_);
}

sub white {
	return applyIRCFormatting("\x0300", @_);
}

sub black {
	return applyIRCFormatting("\x0301", @_);
}

sub blue {
	return applyIRCFormatting("\x0302", @_);
}

sub green {
	return applyIRCFormatting("\x0303", @_);
}

sub red {
	return applyIRCFormatting("\x0304", @_);
}

sub brown {
	return applyIRCFormatting("\x0305", @_);
}

sub purple {
	return applyIRCFormatting("\x0306", @_);
}

sub orange {
	return applyIRCFormatting("\x0307", @_);
}

sub yellow {
	return applyIRCFormatting("\x0308", @_);
}

sub lgreen {
	return applyIRCFormatting("\x0309", @_);
}

sub teal {
	return applyIRCFormatting("\x0310", @_);
}

sub lcyan {
	return applyIRCFormatting("\x0311", @_);
}

sub lblue {
	return applyIRCFormatting("\x0312", @_);
}

sub pink {
	return applyIRCFormatting("\x0313", @_);
}

sub grey {
	return applyIRCFormatting("\x0314", @_);
}

sub lgrey {
	return applyIRCFormatting("\x0315", @_);
}

sub gold {
	return applyIRCFormatting("\x0316", @_);
}

sub joinUserOnChannel {
	my $self = shift;
	my $user = shift;
	my $channel = shift;
	$self->executeRawIRC("sajoin $user $channel");
	#$self->inviteToChannel($user,$channel); # OBSOLETE
	return;
}

sub joinChannel {
	my $self = shift;
	$poe_kernel->post($self->pocoirc()->session_id() => join => @_);
	return;
}

sub ojoinChannel {
	my $self = shift;
	my $channel = shift;
	$self->executeRawIRC("ojoin $channel");
	return;
}

sub leaveChannel {
	my $self = shift;
	$poe_kernel->post($self->pocoirc()->session_id() => part => @_);
	return;
}

sub getOper {
	my $self = shift;
	my $operNick = shift;
	my $operPass = shift;
	$poe_kernel->post($self->pocoirc()->session_id() => oper => $operNick => $operPass);
	return;
}

sub modeChannel {
	my $self = shift;
	my $mode = shift;
	$poe_kernel->post($self->pocoirc()->session_id() => mode => $mode);
	return;
}

sub inviteToChannel {
	my $self = shift;
	my $user = shift;
	my $channel = shift;
	$poe_kernel->post($self->pocoirc()->session_id() => invite => $user => $channel);
	return;
}


sub sayToChannel {
	my $self = shift;
	my $channel = shift;
	$self->emote(channel => $channel, body => arrayToString(@_));
	return;
}

sub noticeUser {
	my $self = shift;
	my $receiver = shift;
	my $message = arrayToString(@_);
	$self->notice(who => $receiver, channel => 'msg', body => $message, address => 'false');
	return;
}

sub sayToUser {
	my $self = shift;
	my $receiver = shift;
	my $message = arrayToString(@_);
	$self->say(who => $receiver, channel => 'msg', body => $message, address => 'false');
	return;
}

sub unbanUser {
	my $self = shift;
	my $channel = shift;
	foreach (@_) {
		$poe_kernel->post($self->pocoirc()->session_id() => mode => $channel => '-b' => '*!' . $_ . '@*');
	}
	return;
}

sub banUser {
	my $self = shift;
	my $channel = shift;
	foreach (@_) {
		$poe_kernel->post($self->pocoirc()->session_id() => mode => $channel => '+b' => '*!' . $_ . '@*');
	}
	return;
}

sub kickUser {
	my $self = shift;
	my $channel = shift;
	foreach (@_) {
		$poe_kernel->post($self->pocoirc()->session_id() => kick => $channel => $_);
	}
	return;
}

#  ____    ___  _____   _   _  _    _  _  _  _    _
# | __ )  / _ \|_   _| | | | || |_ (_)| |(_)| |_ (_)  ___  ___
# |  _ \ | | | | | |   | | | || __|| || || || __|| | / _ \/ __|
# | |_) || |_| | | |   | |_| || |_ | || || || |_ | ||  __/\__ \
# |____/  \___/  |_|    \___/  \__||_||_||_| \__||_| \___||___/
#
# BOT Utilities

sub inviteUsersToChannels {
	my $self = shift;

	for my $user (@_) { # TODO: Można to zrobić z mysqlgetallmultiple
		my $request = mysqlGetAllOne("users", "username", $user);
		for my $channel (@channels) {
			if ($request->{access_id} >= $channelPermissions{$channel}) {
				archiPrint("DEBUG: JOIN $user $channel");
				$self->joinUserOnChannel($user, $channel);
			}
		}
	}
	return;
}

sub setCounter {
	my $self = shift;
	my $channel = shift;
	$counter{$channel} = shift;
	return;
}

sub startVotingOnMode() {
	my $self = shift;
	my $channel = shift;

	if ($voteModeTime > 0) {
		$canVoteOnMode{$channel} = 1;
		$chosenMode{$channel} = '';
		$self->sayToChannel($channel, defaultColor("Głosowanie na tryb gry rozpoczęło się! Głosuj przy pomocy komendy ") . bold(defaultColor(".vm <tryb>")));
		$self->sayToChannel($channel, defaultColor("Dostępne tryby gry to: ") . bold(defaultColor(getStringModes())));
		$self->sayToChannel($channel, defaultColor("Głosowanie kończy się za ") . bold(red($voteModeTime)) . defaultColor(" sekund!"));
		$self->setCounter($channel, $voteModeTime);
	} else {
		$self->setCounter($channel, 1);
	}
	return;
}

sub endVotingOnMode {
	my $self = shift;
	my $channel = shift;

	if ($chosenMode{$channel} eq '') {
		$canVoteOnMode{$channel} = 0;
		$self->sayToChannel($channel, defaultColor("Głosowanie na tryb gry zakończyło się!"));
		my @mostVoted;
		my $mostVotes = 0;
		foreach (keys %{$modeVotes{$channel}}) {
			if ($modeVotes{$channel}{$_} > $mostVotes) {
				$mostVotes = $modeVotes{$channel}{$_};
			}
		}
		foreach (keys %{$modeVotes{$channel}}) {
			if ($modeVotes{$channel}{$_} == $mostVotes) {
				push(@mostVoted, $_);
			}
		}
		if (@mostVoted != 1) {
			if (@mostVoted < 1) { # If we really have no votes...
				push(@mostVoted, keys %modes);
			}
			$self->sayToChannel($channel, defaultColor("Z powodu niejednoznacznej decyzji, tryb gry zostanie wybrany losowo z tych, które otrzymały największą liczbę głosów: ") . bold(defaultColor(arrayToStringWithSpaces(@mostVoted))));
			$chosenMode{$channel} = raffle(@mostVoted);
			$self->sayToChannel($channel, defaultColor("Wylosowany tryb gry to: $chosenMode{$channel}!"));
		} else {
			$chosenMode{$channel} = $mostVoted[0];
		}
		$self->sayToChannel($channel, defaultColor("Wybrany tryb gry to: ") . bold(defaultColor($chosenMode{$channel})));
	}
	$self->setCounter($channel, 1);
}

sub startVotingOnCaptains {
	my $self = shift;
	my $channel = shift;

	if ($voteCaptainTime > 0 && $captain2{$channel} eq '') {
		my @votablePlayers;
		for my $i (0 .. $#{$players{$channel}}) {
			if (@{$players{$channel}}[$i] ne $captain1{$channel} && @{$players{$channel}}[$i] ne $captain2{$channel}) { # If not a captain
				push @votablePlayers, playerColor(@{$players{$channel}}[$i]);
			}
		}

		$self->sayToChannel($channel, defaultColor("Głosowanie na kapitanów rozpoczęło się! Głosuj przy pomocy komendy .vc <kapitan>"));
		$self->sayToChannel($channel, defaultColor("Dostępni gracze to: ") . arrayToStringWithSpaces(@votablePlayers));
		$self->sayToChannel($channel, defaultColor("Głosowanie kończy się za ") . bold(red($voteCaptainTime)) . defaultColor(" sekund!"));

		$canVoteOnCaptains{$channel} = 1;
		$self->setCounter($channel, $voteCaptainTime);
	} else {
		$self->setCounter($channel, 1);
	}
	return;
}

sub endVotingOnCaptains {
	my $self = shift;
	my $channel = shift;

	$canVoteOnCaptains{$channel} = 0;
	if ($captain1{$channel} eq '' || $captain2{$channel} eq '') {
		my @votablePlayers;
		for my $i (0 .. $#{$players{$channel}}) {
			if (@{$players{$channel}}[$i] ne $captain1{$channel} && @{$players{$channel}}[$i] ne $captain2{$channel}) { # If not a captain
				push @votablePlayers, @{$players{$channel}}[$i];
			}
		}
		$self->sayToChannel($channel, defaultColor("Głosowanie na kapitanów zakończyło się!"));

		my @mostVoted;
		my $mostVotes = 0;
		
		# If we voted for 2 captains
		if ($captain1{$channel} eq '') {
			foreach (keys %{$captainVotes{$channel}}) {
				if ($captainVotes{$channel}{$_} > $mostVotes) {
					$mostVotes = $captainVotes{$channel}{$_};
				}
			}
			# If noone voted, add all votable players instead
			if ($mostVotes == 0) {
				push(@mostVoted, @votablePlayers);
			} else {
				foreach (keys %{$captainVotes{$channel}}) {
					if ($captainVotes{$channel}{$_} == $mostVotes) {
						push(@mostVoted, $_);
					}
				}
			}
			if (@mostVoted > 1) {
				$self->sayToChannel($channel, defaultColor("Z powodu niejednoznacznej decyzji, pierwszy kapitan zostanie wybrany losowo z tych, którzy otrzymali największą liczbę głosów: ") . bold(defaultColor(arrayToStringWithSpaces(@mostVoted))));
				$captain1{$channel} = raffle(@mostVoted);
				$self->sayToChannel($channel, defaultColor("Wylosowany kapitan to: ") . playerColor($captain1{$channel}) . defaultColor("!"));
			} else {
				$captain1{$channel} = $mostVoted[0];
			}
			delete($captainVotes{$channel}{$captain1{$channel}});
			my $captainIndex = 0;
			for my $i (0 .. $#votablePlayers) {
				if ($votablePlayers[$i] eq $captain1{$channel}) {
					$captainIndex = $i;
					last;
				}
			}
			splice(@votablePlayers, $captainIndex, 1);
		}
		$self->sayToChannel($channel, defaultColor("Pierwszy wybrany kapitan to: ") . playerColor($captain1{$channel}));

		@mostVoted = ();
		$mostVotes = 0;

		foreach (keys %{$captainVotes{$channel}}) {
			if ($captainVotes{$channel}{$_} > $mostVotes) {
				$mostVotes = $captainVotes{$channel}{$_};
			}
		}
		# If noone voted, add all votable players instead
		if ($mostVotes == 0) {
			push(@mostVoted, @votablePlayers);
		} else {
			foreach (keys %{$captainVotes{$channel}}) {
				if ($captainVotes{$channel}{$_} == $mostVotes) {
					push(@mostVoted, $_);
				}
			}
		}
		if (@mostVoted > 1) {
			$self->sayToChannel($channel, defaultColor("Z powodu niejednoznacznej decyzji, drugi kapitan zostanie wybrany losowo z tych, którzy otrzymali największą liczbę głosów: ") . bold(defaultColor(arrayToStringWithSpaces(@mostVoted))));
			$captain2{$channel} = raffle(@mostVoted);
			$self->sayToChannel($channel, defaultColor("Wylosowany kapitan to: ") . playerColor($captain2{$channel}) . defaultColor("!"));
		} else {
			$captain2{$channel} = $mostVoted[0];
		}
		$self->sayToChannel($channel, defaultColor("Drugi wybrany kapitan to: ") . playerColor($captain2{$channel}));
	}

	# Random order of captains
	if (randomBoolean()) {
		my $temp = $captain1{$channel};
		$captain1{$channel} = $captain2{$channel};
		$captain2{$channel} = $temp;
		$self->sayToChannel($channel, defaultColor("Bot losowo zadecydował o zamianie stron kapitanów!"));
	}

	# Remove captains from the player pool and put them in their teams
	push(@{$team1{$channel}}, $captain1{$channel});
	for my $i (0 .. $#{$players{$channel}}) {
		if (@{$players{$channel}}[$i] eq $captain1{$channel}) {
			splice(@{$players{$channel}}, $i, 1);
			last;
		}
	}
	push(@{$team2{$channel}}, $captain2{$channel});
	for my $i (0 .. $#{$players{$channel}}) {
		if (@{$players{$channel}}[$i] eq $captain2{$channel}) {
			splice(@{$players{$channel}}, $i, 1);
			last;
		}
	}

	$self->sayToChannel($channel, defaultColor("Rozpoczęła się faza wyboru graczy!"));
	$self->printPlayers($nick, $channel);
	$self->sayToChannel($channel, defaultColor("Teraz wybiera: ") . playerColor($captain2{$channel}));
	$self->sayToChannel($channel, defaultColor("W przypadku braku wyboru, po ") . bold(red($pickPlayerTime)) . defaultColor(" sekundach, losowy gracz z puli zostanie przydzielony automatycznie"));
	$turn{$channel} = 2;
	$lastTurn{$channel} = 2;
	$self->setCounter($channel, $pickPlayerTime);
	$self->printPasswordForAll($channel);
	return;
}

sub pickRandomPlayer {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	$self->pickPlayer($who, $channel, '.p', raffle(@{$players{$channel}}));
}

sub randomGamePassword {
	my $randomPassword = 'pd';
	$randomPassword .= int(rand(9000)) + 1000; # Add random integer to password, from 1000 to 9999
	return $randomPassword;
}

sub printPasswordForAll {
	my $self = shift;
	my $channel = shift;
	my $gameID = shift;

	if (isEmpty($gamePassword{$channel})) {
		$gamePassword{$channel} = randomGamePassword();
	}

	if (isEmpty($gameID)) {
		for my $player (@{$team1{$channel}}, @{$team2{$channel}}, @{$players{$channel}}) {
			$self->noticeUser($player, red(bold("UWAGA!")) . defaultColor(" Hasło do startującej gry na kanale $channel: ") . bold(defaultColor($gamePassword{$channel})));
			#$self->sayToUser($player, red(bold("UWAGA!")) . defaultColor(" Hasło do startującej gry na kanale $channel: ") . bold(defaultColor($gamePassword{$channel})));
		}
	} else {
		for my $player (@{$team1{$channel}}, @{$team2{$channel}}, @{$players{$channel}}) {
			$self->noticeUser($player, red(bold("UWAGA!")) . defaultColor(" Hasło do gry o numerze #$gameID na kanale $channel: ") . bold(defaultColor($gamePassword{$channel})));
			$self->sayToUser($player, red(bold("UWAGA!")) . defaultColor(" Hasło do gry o numerze #$gameID na kanale $channel: ") . bold(defaultColor($gamePassword{$channel})));
		}
		for my $admin (mysqlGetAdmins()) {
			if (!mysqlGameIsActive(mysqlGetLastGameOfPlayerByNick($admin))) {
				$self->noticeUser($admin, red(bold("UWAGA!")) . defaultColor(" Hasło do gry o numerze #$gameID na kanale $channel: ") . bold(defaultColor($gamePassword{$channel})));
				$self->sayToUser($admin, red(bold("UWAGA!")) . defaultColor(" Hasło do gry o numerze #$gameID na kanale $channel: ") . bold(defaultColor($gamePassword{$channel})));
			}
		}
	}

	return;
}

sub returnGroupForMysql {
	return quoteString(arrayToStringWithDelimiter("','", @_));
}

sub returnInsertGroupForMysql {
	return arrayToStringWithDelimiter("),(", @_);
}

sub recalculateAveragePoints {
	$averagePoints = mysqlGetOne("users", "AVG(points)", "points !=", 1000);
	if (isEmpty($averagePoints)) {
		$averagePoints = 1000;
	}
	return;
}

sub raffle {
	my $randomIndex = int(rand($#_ + 1)); # Random integer from 0 to number of elements in array passed as parameter(s)
	return $_[$randomIndex]; # Return random
}

sub parseStreak {
	my $streak = shift;
	if ($streak < 3) {
		return ".";
	} elsif ($streak == 3) {
		return bold(green(" Seria zabójstw!"));
	} elsif ($streak == 4) {
		return bold(purple(" Dominacja!"));
	} elsif ($streak == 5) {
		return bold(pink(" Megaseria zabójstw!"));
	} elsif ($streak == 6) {
		return bold(orange(" Nie do powstrzymania!"));
	} elsif ($streak == 7) {
		return bold(brown(" Szał!"));
	} elsif ($streak == 8) {
		return bold(pink(" Potworna seria zabójstw!"));
	} elsif ($streak == 9) {
		return bold(red(" Niczym bóg!"));
	} else { # Equal or more than 10
		return bold(orange(" Potężniejszy od bogów!"));
	}
}

sub printPlayers {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my @currentTeam1 = getTeam1($channel);
	if (@currentTeam1) {
		$self->sayToChannel($channel, bold(green($team1)) . defaultColor(" [") . bold(defaultColor(mysqlGetSumOfPlayersPointsByNick(@{$team1{$channel}}))) . defaultColor("]: ") . arrayToStringWithSpaces(@currentTeam1));
	}
	my @currentTeam2 = getTeam2($channel);
	if (@currentTeam2) {
		$self->sayToChannel($channel, bold(red($team2)) . defaultColor(" [") . bold(defaultColor(mysqlGetSumOfPlayersPointsByNick(@{$team2{$channel}}))) . defaultColor("]: ") . arrayToStringWithSpaces(@currentTeam2));
	}
	my @currentPool = getPool($channel);
	if (@currentPool) {
		$self->sayToChannel($channel, bold(purple("Gracze")) . defaultColor(": ") . arrayToStringWithSpaces(@currentPool));
	}
	return;
}

sub insertGame {
	my $self = shift;
	my $channel = shift;
	my $mode = shift;
	my @sTeam1;
	my @sTeam2;

	for (my $i = 0; $i < @_ / 2; $i++) {
		push(@sTeam1, $_[$i]);
	}
	for (my $i = @_ / 2; $i < @_; $i++) {
		push(@sTeam2, $_[$i]);
	}

	my $team1ID = mysqlInsertTeam();
	mysqlAddPlayersToTeam($team1ID, @sTeam1);
	my $team2ID = mysqlInsertTeam();
	mysqlAddPlayersToTeam($team2ID, @sTeam2);

	my $modeID = mysqlGetOne("modes", "mode_id", "name", $mode);
	my $gameID = mysqlInsertGame($team1ID, $team2ID, $modeID);
	mysqlUpdateLastGameOfPlayersByNick($gameID, @sTeam1, @sTeam2);

	my $currentSeason = mysqlGetLastSeasonID();
	my $request = mysqlGetAllOne("seasons", "season_id", $currentSeason);
	if (isEmpty($request->{firstgame_id})) {
		mysqlUpdate("seasons", "firstgame_id = $gameID", "season_id", $currentSeason);
	}

	my @teampoints = mysqlUpdateTeamTotalPoints($team1ID, $team2ID);

	my $deltaPoints = mysqlGetModePoints($modeID);
	my $minDelta = int($deltaPoints / $variationDelta);
	my $maxDelta = int($deltaPoints + ($minDelta * ($variationDelta - 1)));

	my $firstDelta = $deltaPoints;
	my $secondDelta = $firstDelta;

	$firstDelta -= int(($teampoints[0] - $teampoints[1]) / $justiceDelta);
	$secondDelta += int(($teampoints[0] - $teampoints[1]) / $justiceDelta);
	if ($firstDelta < $minDelta) {
		$firstDelta = $minDelta;
	} elsif ($firstDelta > $maxDelta) {
		$firstDelta = $maxDelta;
	}
	if ($secondDelta < $minDelta) {
		$secondDelta = $minDelta;
	} elsif ($secondDelta > $maxDelta) {
		$secondDelta = $maxDelta;
	}

	# Let players know that game begun while we're doing housekeeping
	$self->sayToChannel($channel, defaultColor("Gra ") . bold(defaultColor($gameID)) . defaultColor(" rozpoczęła się!"));
	$self->printPlayers($nick, $channel);

	if ($firstDelta == $secondDelta) {
		$self->sayToChannel($channel, defaultColor("Gra toczy się o ") . bold(yellow($firstDelta)) . defaultColor(" punktów!"));
	} else {
		$self->sayToChannel($channel, defaultColor("Gra toczy się o ") . bold(yellow($firstDelta)) . defaultColor(" oraz ") . bold(yellow($secondDelta)) . defaultColor(" punktów!"));
	}

	$self->printPasswordForAll($channel, $gameID);
	return;
}

sub startGame {
	my $self = shift;
	my $channel = shift;

	$phase{$channel} = 0;

	$self->insertGame($channel, $chosenMode{$channel}, @{$team1{$channel}}, @{$team2{$channel}});

	$captain1{$channel} = "";
	$captain2{$channel} = "";
	$chosenMode{$channel} = "";
	$gamePassword{$channel} = '';
	$self->voidGameVotes($channel);

	@{$players{$channel}} = ();
	@{$team1{$channel}} = ();
	@{$team2{$channel}} = ();

	$phase{$channel} = 0;
	$self->setCounter($channel, 0);

	$self->updateTopic();

	return;
}

sub updateTopic {
	my $self = shift;
	my $targetChannel = shift;
	my @targetChannels;

	if (isEmpty($targetChannel)) {
		push(@targetChannels, ($mainChannel, @channels));
	} else {
		push(@targetChannels, $targetChannel);
	}

	# Show status of signup / starting game
	my @activegames = mysqlGetActivegames();

	for my $channel (@targetChannels) {
		my $topic;
		if ($channel ne $mainChannel) {
			my $playersCount = $#{$players{$channel}} + 1;
			if (!@{$team1{$channel}} && !@{$team2{$channel}} && @{$players{$channel}} && $playersCount < $maxPlayers) {
				$topic .= bold(green("Zapisy na grę są otwarte! ")) . bold(defaultColor("$playersCount / $maxPlayers")) . defaultColor(" | ");
			} elsif (@{$team1{$channel}} || @{$team2{$channel}} || $playersCount == $maxPlayers) {
				$topic .= bold(green("Gra zaraz się rozpocznie! ")) . defaultColor("$team1: ") . defaultColor(arrayToStringWithSpaces(@{$team1{$channel}})) . defaultColor(" | ") . defaultColor("$team2: ") . defaultColor(arrayToStringWithSpaces(@{$team2{$channel}})) . defaultColor(" | ");
			}
		}

		# Show other active games
		$topic .= defaultColor("Aktualne gry w toku: ");
		if (@activegames) {
			$topic .= bold(defaultColor(arrayToStringWithSpaces(@activegames)));
		} else {
			$topic .= defaultColor("Brak");
		}

		my $poeself = $self->pocoirc();
		$poe_kernel->post($poeself->session_id() => topic => $channel => $topic);
	}
	
	return;
}

sub getPool {
	my $channel = shift;
	my @formedPlayers;
	for my $player (@{$players{$channel}}) {
		if ($player eq $captain1{$channel} || $player eq $captain2{$channel}) {
			# Player is captain
			push(@formedPlayers, playerColor($player) . defaultColor("[") . bold(orange("K")) . defaultColor("]"));
		} else {
			my $playerpoints = mysqlGetPlayerPointsByNick($player);
			if ($playerpoints > $averagePoints) {
				# Player is above average
				push(@formedPlayers, playerColor($player) . defaultColor("[") . bold(green($playerpoints)) . defaultColor("]"));
			} elsif ($playerpoints < $averagePoints) {
				# Player is below average
				push(@formedPlayers, playerColor($player) . defaultColor("[") . bold(red($playerpoints)) . defaultColor("]"));
			} else {
				# Player is average
				push(@formedPlayers, playerColor($player) . defaultColor("[") . bold(defaultColor($playerpoints)) . defaultColor("]"));
			}
		}
	}
	return @formedPlayers;
}


sub getTeam1 {
	my $channel = shift;
	my @formedPlayers;
	for my $player (@{$team1{$channel}}) {
		if ($player eq $captain1{$channel} || $player eq $captain2{$channel}) {
			# Player is captain
			push(@formedPlayers, playerColor($player) . defaultColor("[") . bold(orange("K")) . defaultColor("]"));
		} else {
			my $playerpoints = mysqlGetPlayerPointsByNick($player);
			if ($playerpoints > $averagePoints) {
				# Player is above average
				push(@formedPlayers, playerColor($player) . defaultColor("[") . bold(green($playerpoints)) . defaultColor("]"));
			} elsif ($playerpoints < $averagePoints) {
				# Player is below average
				push(@formedPlayers, playerColor($player) . defaultColor("[") . bold(red($playerpoints)) . defaultColor("]"));
			} else {
				# Player is average
				push(@formedPlayers, playerColor($player) . defaultColor("[") . bold(defaultColor($playerpoints)) . defaultColor("]"));
			}
		}
	}
	return @formedPlayers;
}


sub getTeam2 {
	my $channel = shift;
	my @formedPlayers;
	for my $player (@{$team2{$channel}}) {
		if ($player eq $captain1{$channel} || $player eq $captain2{$channel}) {
			# Player is captain
			push(@formedPlayers, playerColor($player) . defaultColor("[") . bold(orange("K")) . defaultColor("]"));
		} else {
			my $playerpoints = mysqlGetPlayerPointsByNick($player);
			if ($playerpoints > $averagePoints) {
				# Player is above average
				push(@formedPlayers, playerColor($player) . defaultColor("[") . bold(green($playerpoints)) . defaultColor("]"));
			} elsif ($playerpoints < $averagePoints) {
				# Player is below average
				push(@formedPlayers, playerColor($player) . defaultColor("[") . bold(red($playerpoints)) . defaultColor("]"));
			} else {
				# Player is average
				push(@formedPlayers, playerColor($player) . defaultColor("[") . bold(defaultColor($playerpoints)) . defaultColor("]"));
			}
		}
	}
	return @formedPlayers;
}

sub addPlayerIfNeeded {
	my $player = shift;
	if (!mysqlPlayerExistsByNick($player)) {
		mysqlInsertPlayer($player);
	}
	return;
}

sub returnToday {
	return DateTime->today(time_zone => 'local');
}

sub checkDay {
	my $self = shift;
	my $newToday = returnToday();
	if ($newToday ne $today) {
		$today = $newToday;
		for my $channel (@channels) {
			$self->sayToChannel($channel, bold(defaultColor("Nastał nowy dzień, każdy może ponownie spróbować swojego szczęścia! .kolofortuny")));
		}
		%luckyPlayers = ();
		return 1; # True
	} else {
		return 0; # False
	}
}

sub playerIsSignedOrPlaying {
	my $who = shift;
	my $channel = shift;

	if (isEmpty($channel)) {
		if (playerIsSigned($who) || playerIsPlaying($who)) {
			return 1; # True
		} else {
			return 0; # False
		}
	} else {
		if (playerIsSigned($who, $channel) || playerIsPlaying($who, $channel)) {
			return 1; # True
		} else {
			return 0; # False
		}
	}
}

sub playerIsSigned {
	my $who = shift;
	my $givenChannel = shift;

	if (isEmpty($givenChannel)) {
		for my $channel (@channels) {
			for my $player (@{$players{$channel}}) {
				if (caseInsensitiveEquals($player, $who)) {
					return 1; # True
				}
			}
		}
	} else {
		for my $player (@{$players{$givenChannel}}) {
			if (caseInsensitiveEquals($player, $who)) {
				return 1; # True
			}
		}
	}
	return 0; # False
}

sub playerIsPlaying {
	my $who = shift;
	my $givenChannel = shift;

	if (isEmpty($givenChannel)) {
		for my $channel (@channels) {
			for my $player (@{$team1{$channel}}, @{$team2{$channel}}) {
				if (caseInsensitiveEquals($player, $who)) {
					return 1; # True
				}
			}
		}
	} else {
		for my $player (@{$team1{$givenChannel}}, @{$team2{$givenChannel}}) {
			if (caseInsensitiveEquals($player, $who)) {
				return 1; # True
			}
		}
	}
	return 0; # False
}

sub voidGameVotes {
	my $self = shift;
	my $channel = shift;
	# Void all modeVotes
	foreach (keys %{$modeVotes{$channel}}) {
		$modeVotes{$channel}{$_} = 0;
	}
	for my $mode (keys %modes) {
		$modeVotes{$channel}{$mode} = 0;
	}
	foreach (keys %{$modeVoters{$channel}}) {
		$modeVoters{$channel}{$_} = "";
	}
	$totalModeVotes{$channel} = 0;
	# Void all captainVotes
	%{$captainVotes{$channel}} = ();
	%{$captainVoters{$channel}} = ();
	#foreach (keys %captainVotes{$channel}) {
		#$captainVotes{$channel}{$_} = 0;
	#}
	#for my $player (@{$players{$channel}}) {
		#$captainVotes{$channel}{$player} = 0;
	#}
	#foreach (keys %captainVoters{$channel}) {
		#$captainVoters{$channel}{$_} = "";
	#}
	$totalcaptainVotes{$channel} = 0;
	return;
}

sub voidUserVotes {
	my $self = shift;
	my $channel = shift;
	my $who = shift;
	# Void user's mapvote
	if (exists($modeVoters{$channel}{$who}) && exists($modeVotes{$channel}{$modeVoters{$channel}{$who}})) {
		if ($modeVotes{$channel}{$modeVoters{$channel}{$who}} > 0) {
			$modeVotes{$channel}{$modeVoters{$channel}{$who}} -= 1;
			$totalModeVotes{$channel}--;
		}
	}
	$modeVoters{$channel}{$who} = "";
	# Void user's captainvote
	if (exists($captainVoters{$channel}{$who}) && exists($captainVotes{$channel}{$captainVoters{$channel}{$who}})) {
		if ($captainVotes{$channel}{$captainVoters{$channel}{$who}} > 0) {
			$captainVotes{$channel}{$captainVoters{$channel}{$who}} -= 1;
			$totalcaptainVotes{$channel}--;
		}
	}
	$captainVoters{$channel}{$who} = "";
	$captainVotes{$channel}{$who} = 0;
	return;
}

sub removePlayer {
	my $self = shift;
	my $channel = shift;
	my $toRemove = shift;
	# Get the player's index in @players
	my $playerIndex = -1;
	for my $i (0 .. $#{$players{$channel}}) {
		if (@{$players{$channel}}[$i] eq $toRemove) {
			$playerIndex = $i;
			last;
		}
	}
	# If there's no such player, return
	if ($playerIndex == -1) {
		return;
	}
	# Otherwise, remove the player
	splice(@{$players{$channel}}, $playerIndex, 1);
	# Remove player's votes and requests
	$self->voidUserVotes($channel, $toRemove);
	my $playerCount = $#{$players{$channel}}+1;
	# If playerlist became empty
	if ($playerCount == 0) {
		# Clear all votes and requests
		$self->voidGameVotes($channel);
		$canVoteOnMode{$channel} = 0;
		$canVoteOnCaptains{$channel} = 0;
	}
	
	$self->updateTopic();
}

sub replacePlayer {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;
	my $toReplace = shift;
	my $replacedWith = shift;
	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}
	if (isEmpty($replacedWith)) {
		$self->noticeUser($who, bold(red("Nieprawidłowy syntax! .r <stary gracz> <nowy gracz>")));
		return;
	}
	my $lastGameOfToReplace = mysqlGetLastGameOfPlayerByNick($toReplace);
	my $lastGameOfReplacedWith = mysqlGetLastGameOfPlayerByNick($replacedWith);
	if (playerIsSigned($toReplace)) {
		if (playerIsSigned($replacedWith)) {
			# We're replacing a signed player with other signed player
			$self->noticeUser($who, bold(red("Zamiana dwóch zapisanych graczy nie ma sensu!")));
			return;
		} elsif (mysqlGameIsActive($lastGameOfReplacedWith)) {
			# We're replacing a signed player with already playing player
			$self->noticeUser($who, bold(red("Gracz $replacedWith już uczestniczy w grze!")));
			return;
		} else {
			# We're replacing a signed player with free player!
			my $replaceIndex = -1;
			for my $i (0 .. $#{$players{$channel}}) {
				if (@{$players{$channel}}[$i] eq $toReplace) {
					$replaceIndex = $i;
					last;
				}
			}
			splice(@{$players{$channel}}, $replaceIndex, 1, $replacedWith);
			$self->voidUserVotes($channel, $toReplace);
			$self->sayToChannel($channel, defaultColor("Gracz ") . playerColor($replacedWith) . defaultColor(" zastąpił gracza ") . playerColor($toReplace) . defaultColor(" w startującej grze!"));
		}
	} elsif (mysqlGameIsActive($lastGameOfToReplace)) {
		if (playerIsSigned($replacedWith)) {
			# We're replacing already playing player with signed player
			$self->outPlayer($who, $channel, ".o", $replacedWith);
			if (playerIsSigned($replacedWith)) {
				$self->noticeUser($who, bold(red("Nie można wypisać z gry gracza $replacedWith w tym momencie!")));
				return;
			}
		}
		# We're replacing already playing player with free player!
		my $toReplaceTeam = mysqlGetTeamOfPlayerFromGame($toReplace, $lastGameOfToReplace);
		mysqlRemovePlayerFromTeam($toReplace, $toReplaceTeam);
		mysqlAddPlayerToTeam($toReplaceTeam, $replacedWith);
		$self->sayToChannel($channel, defaultColor("Gracz ") . playerColor($replacedWith) . defaultColor(" zastąpił gracza ") . playerColor($toReplace) . defaultColor(" w grze $lastGameOfToReplace!"));
	} else {
		$self->noticeUser($who, bold(red("Nie znalazłem gracza $toReplace!")));
		return;
	}
	return;
}

sub shutdownIRC {
	my $self = shift;
	$self->shutdown();
	return;
}

#   ____                                                _
#  / ___| ___   _ __ ___   _ __ ___    __ _  _ __    __| | ___
# | |    / _ \ | '_ ` _ \ | '_ ` _ \  / _` || '_ \  / _` |/ __|
# | |___| (_) || | | | | || | | | | || (_| || | | || (_| |\__ \
#  \____|\___/ |_| |_| |_||_| |_| |_| \__,_||_| |_| \__,_||___/
#
# Commands

sub inviteMe {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;

	my $request = mysqlGetAllOne("users", "username", $who);
	for my $channel (@channels) {
		if ($request->{access_id} >= $channelPermissions{$channel}) {
			$self->joinUserOnChannel($who, $channel);
		}
	}
	return;
}

sub reputationChange {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;
	my $toRep = shift;

	if (isEmpty($toRep)) {
		$self->noticeUser($who, bold(red("Syntax: $command <nick>")));
		return;
	}

	my $userRequest = mysqlGetAllOne("users", "username", $who);

	my $lastGame = notNull($userRequest->{lastgame_id});
	my $lastRepGame = notNull($userRequest->{lastgame_rep_id});

	my $gameRequest = mysqlGetAllOne("games", "game_id", $lastGame);

	if (isEmpty($gameRequest)) {
		$self->noticeUser($who, bold(red("Nie uczestniczyłeś jeszcze w żadnej grze!")));
		return;
	}

	if (isEmpty($gameRequest->{winner})) {
		$self->noticeUser($who, bold(red("Gra o numerze #$lastGame nadal trwa! Reputację możesz przyznać dopiero po zakończeniu gry!")));
		return;
	}

	if ($lastGame <= $lastRepGame) {
		$self->noticeUser($who, bold(red("Przyznałeś już reputację za grę #$lastGame!")));
		return;
	}

	my @repCandidates;
	if (mysqlPlayerPlaysInTeamByNick($who, $gameRequest->{team1_id})) {
		for my $repCandidate (mysqlGetNicknamesOfPlayers(mysqlGetPlayersFromTeam($gameRequest->{team1_id}))) {
			if (!caseInsensitiveEquals($who, $repCandidate)) {
				push(@repCandidates, $repCandidate);
			}
		}
	} else {
		for my $repCandidate (mysqlGetNicknamesOfPlayers(mysqlGetPlayersFromTeam($gameRequest->{team2_id}))) {
			if (!caseInsensitiveEquals($who, $repCandidate)) {
				push(@repCandidates, $repCandidate);
			}
		}
	}

	if (!caseInsensitiveEquals($toRep, @repCandidates)) {
		$self->noticeUser($who, bold(red("Próbowałeś przyznać reputację niepoprawnemu graczowi! Możesz przyznać reputację jedynie: " . arrayToStringWithSpaces(@repCandidates))));
		return;
	}

	my $operator = '+';
	if (stringContainsSubstring($command, '-')) {
		$operator = '-';
	}

	$self->noticeUser($who, defaultColor("Przyznałeś ") . bold(defaultColor($operator)) . defaultColor(" reputację graczowi $toRep!"));

	mysqlUpdate("users", "lastgame_rep_id = $lastGame", "username", $who);
	mysqlUpdate("users", "reputation = reputation $operator 1", "username", $toRep);

	return;
}

sub deleteGame {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	mysqlDeleteGame(@_);
	$self->noticeUser($who, defaultColor("Done!"));
	return;
}

sub vouchQueue {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	my @testedPlayers;
	my @testedPlayersDone;
	for my $request (mysqlGetAllMultiple("users", "access_id", $accessTestUser)) {
		my $totalGames = $request->{wins} + $request->{loses};
		push(@testedPlayers, $request->{username} . "($totalGames)");
		if ($totalGames >= $testGames) {
			push(@testedPlayersDone, $request->{username});
		}
	}

	$self->noticeUser($who, defaultColor("Gracze oczekujący na werdykt: " . arrayToStringWithSpaces(@testedPlayersDone)));
	$self->noticeUser($who, defaultColor("Wszyscy aktualnie testowani gracze: " . arrayToStringWithSpaces(@testedPlayers)));
}

sub vouch {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;
	my @toTestPlayers;

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	if (!@_) {
		$self->noticeUser($who, bold(red("Syntax: $command <nick> <nick2> <nick3>")));
		return;
	}

	my $vouchAccess = $accessVouched;
	if (stringContainsSubstring($command, 'test')) {
		$vouchAccess = $accessTestUser;
	}

	for my $toTest (@_) {
		my $request = mysqlGetAllOne("users", "username", $toTest);
		if (isEmpty($request)) {
			$self->noticeUser($who, bold(red("Gracz $toTest nie istnieje!")));
			next;
		} elsif ($request->{access_id} >= $vouchAccess) {
			$self->noticeUser($who, bold(red("Gracz $toTest jest już zvouchowany!")));
			next;
		} elsif ($request->{access_id} <= $accessTimeBanned) {
			$self->noticeUser($who, bold(red("Gracz $toTest jest zbanowany!")));
			next;
		} else {
			push(@toTestPlayers, $toTest);
		}
	}

	if (!@toTestPlayers) {
		return;
	}

	mysqlVouchPlayersByNick($vouchAccess, @toTestPlayers);
	$self->noticeUser($who, defaultColor("Następujący gracze zostali zvouchowani: " . arrayToStringWithSpaces(@toTestPlayers)));
	return;
}

sub season {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	my $currentSeason = mysqlGetSeason(mysqlGetLastSeasonID());

	if (isEmpty($currentSeason->{lastgame_id})) {
	$self->sayToChannel($channel, defaultColor("Aktualnie trwa sezon: " . bold($currentSeason->{season_id})));
	$self->sayToChannel($channel, defaultColor("Pierwszą grą tego sezonu jest gra o numerze: " . bold("#" .  $currentSeason->{firstgame_id})));
	} else {
		$self->sayToChannel($channel, bold(defaultColor("Aktualnie nie jest rozgrywany żaden sezon")));
		$self->sayToChannel($channel, defaultColor("Ostatni rozegrany sezon: " . $currentSeason->{season_id}));
		$self->sayToChannel($channel, defaultColor("Pierwszą grą tego sezonu jest gra o numerze: " . bold("#" . $currentSeason->{firstgame_id})));
		$self->sayToChannel($channel, defaultColor("Ostatnią grą tego sezonu jest gra o numerze: " . bold("#" . $currentSeason->{lastgame_id})));
	}
	return;
}

sub newSeason {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	if ($seasonIsActive) {
		$self->noticeUser($who, bold(red("Nowy sezon już trwa!")));
		return;
	}

	# Start new season
	$seasonIsActive = 1;
	#mysqlInsert("seasons", "firstgame_id", mysqlGetLastGame() + 1);
	mysqlInsert("seasons");
	mysqlUpdate("users", "points = 1000, wins = 0, loses = 0, draws = 0, streak = 0");
	$self->sayToChannel($channel, bold(green("Nowy sezon rozpoczął się!")));
	return;
}

sub endSeason {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	if (!$seasonIsActive) {
		$self->noticeUser($who, bold(red("Nie trwa aktualnie żaden sezon!")));
		return;
	}

	# End current season
	$seasonIsActive = 0;
	mysqlUpdate("seasons", "lastgame_id = " . mysqlGetLastGame(), "season_id", mysqlGetLastSeasonID());
	$self->sayToChannel($channel, bold(red("Aktualny sezon zakończył się!")));

	for my $singleChannel (@channels) {
		$self->abortGame($nick, $singleChannel);
	}

	$self->sayToChannel($channel, bold(green("Top 10:")));
	for my $request (mysqlGetAllMultiple("users ORDER BY points DESC LIMIT 10")) {
		$self->sayToChannel($channel, playerColor($request->{username}) . defaultColor("[") . bold(green($request->{points})) . defaultColor("]"));
	}
	return;
}

sub shutdownBot {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	$self->shutdownIRC();
	exit;
}

sub restartBot {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	$self->shutdownIRC();
	exec($^X, $0, @ARGV); # yolo
}

sub getActivegames {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	my $activegames = arrayToStringWithSpaces(mysqlGetActivegames());
	if (isEmpty($activegames)) {
		$self->noticeUser($who, defaultColor("Brak aktualnie rozgrywanych gier"));
	} else {
		$self->noticeUser($who, defaultColor("Aktualne gry w toku: "), bold(defaultColor($activegames)));
	}
	return;
}

sub setPlayercolor {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;
	my $color = shift;
	my @tocolor;

	if (isEmpty($color)) {
		$self->noticeUser($who, bold(red("Nieprawidłowy syntax! .pc <kolor> <gracze>")));
		return;
	}

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	if (!@_) {
		push(@tocolor, $who);
	} else {
		push(@tocolor, @_);
	}

	for my $tocolorOne (@tocolor) {
		if (!mysqlPlayerExistsByNick($tocolorOne)) {
			$self->noticeUser($who, bold(red("Błąd: Użytkownik $tocolorOne nie istnieje")));
			next;
		}
		mysqlUpdatePlayerColor($tocolorOne, $color);
		$self->sayToChannel($channel, defaultColor("Gracz $tocolorOne posiada teraz "), bold(customColor($color, "taki oto niestandardowy kolor nicka")), defaultColor("!"));
		}
	return;
}

sub signPlayer {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;
	my @toSign;

	if (!$seasonIsActive) {
		$self->noticeUser($who, bold(red("Nie trwa aktualnie żaden sezon!")));
		return;
	}

	if (!@_) {
		push(@toSign, $who);
	} elsif (mysqlPlayerIsAdminByNick($who)) {
		push(@toSign, @_);
	} else {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	my $playerCount;
	for my $toSignOne (@toSign) {
		$playerCount = $#{$players{$channel}}+1;
		if ($phase{$channel} != 0 || $playerCount >= $maxPlayers) {
			$self->noticeUser($who, bold(red("Zapisy są zamknięte! To oznacza, że aktualna gra osiagnęła limit graczy i zaraz się rozpocznie. Zapisy do następnej gry zostaną otwarte po rozpoczęciu się aktualnej!")));
			next;
		}

		#addPlayerIfNeeded($toSignOne); # NOTICE: I disabled that because website adds users, so no need for overhead, enable this if you need

		my $request = mysqlGetAllOne("users", "username", $toSignOne);
		# If player doesn't exist, return
		if (isEmpty($request)) {
			$self->noticeUser($who, bold(red("Gracz $toSignOne nie istnieje!")));
			next;
		}
		# If player is banned, return
		if ($request->{access_id} <= $accessTimeBanned) {
			$self->noticeUser($who, bold(red("Jesteś ZBANOWANY!")));
			next;
		}
		# Check if player is able to sign
		if ($request->{access_id} < $channelPermissions{$channel}) {
			$self->noticeUser($who, bold(red("Nie masz dostępu do grania na tym kanale!")));
			next;
		}
		# Check if player is being tested
		if ($request->{access_id} == $accessTestUser && $channelPermissions{$channel} == $accessTestUser) {
			my $totalGames = $request->{wins} + $request->{loses};
			if ($totalGames >= $testGames) {
				$self->noticeUser($who, bold(red("Zakończył Ci się już okres testowy!")));
				next;
			}
		}
		# If player is already playing, return
		if (!isEmpty($request->{lastgame_id})) {
			my $myCurrentGame = $request->{lastgame_id};
			if (mysqlGameIsActive($myCurrentGame)) {
				$self->noticeUser($who, bold(red("Juz uczestniczysz w grze $myCurrentGame!")));
				next;
			}
		}
		# Check if already signed
		if (playerIsSigned($toSignOne)) {
			$self->noticeUser($who, bold(red("Jesteś już zapisany!")));
			next;
		}
		# Add the player on the playerlist
		push(@{$players{$channel}}, $toSignOne);
		$playerCount++;

		$self->sayToChannel($channel, playerColor($toSignOne) . defaultColor(" zapisał się! ") . bold(defaultColor($playerCount)) . defaultColor(" / ") . bold(defaultColor($maxPlayers)) . defaultColor(" zapisanych graczy!"));
		$self->noticeUser($toSignOne, bold(green("Pamiętaj, aby zagłosować na tryb gry oraz kapitanów! Użyj .vm oraz .vc")));
		$self->updateTopic($channel);
		# If this was the first to sign up
		if ($playerCount == 1) {
			$self->voidGameVotes($channel);
			$canVoteOnCaptains{$channel} = 1;
			$canVoteOnMode{$channel} = 1;
		}
		# Initialize player's votes and requests
		$self->voidUserVotes($channel, $toSignOne);
	}
	# If there aren't enough players to start the game, return
	if ($playerCount < $maxPlayers) {
		$self->printPlayers($nick, $channel);
		return;
	}

	$gamePassword{$channel} = randomGamePassword();
	$self->printPasswordForAll($channel);
	$self->setCounter($channel, 1);
	return;
}

sub outPlayer {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;
	my @toOut;

	if (!@_) {
		push(@toOut, $who);
	} elsif (mysqlPlayerIsAdminByNick($who)) {
		push(@toOut, @_);
	} else {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	my $playerCount;
	for my $toOutOne (@toOut) {
		$playerCount = $#{$players{$channel}}+1;
		if ($phase{$channel} != 0 || $playerCount >= $maxPlayers) {
			$self->noticeUser($who, bold(red("Wypisanie się z gry nie jest możliwe w aktualnym momencie! To oznacza, że gra uzbierała już $maxPlayers graczy i zaraz się rozpocznie!")));
			return;
		}
		if ($toOutOne eq $captain1{$channel} || $toOutOne eq $captain2{$channel}) {
			$self->noticeUser($who, bold(red("Nie możesz opuścić gry będąc kapitanem! Najpierw użyj .uc")));
			next;
		}
		if (!playerIsSigned($toOutOne)) {
			$self->noticeUser($who, bold(red("$toOutOne nie jest zapisany!")));
			next;
		}
		$self->removePlayer($channel, $toOutOne);
		$playerCount--;
		$self->sayToChannel($channel, playerColor($toOutOne) . defaultColor(" wypisał się! ") . bold(defaultColor("$playerCount / $maxPlayers")) . defaultColor(" zapisanych graczy!"));
	}
	if ($playerCount > 0) {
		$self->printPlayers($nick, $channel);
	}
	return;
}

sub becomeCaptain {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	if ($phase{$channel} >= 3 || ($captain1{$channel} ne '' && $captain2{$channel} ne '')) {
		$self->noticeUser($who, bold(red("Zgłoszenia na kapitana są niemożliwe w aktualnym momencie!")));
		return;
	}
	my $toCaptain = $who;
	if ($#_ > 0) { # If player is signing somewhere else
		if (mysqlPlayerIsAdminByNick($who)) {
			if ($#_ == 1) { # If player is signing one player
				$toCaptain = $_[1];
			} else { # If player is signing multiple players
				my $command = shift;
				foreach(@_) {
					$self->becomeCaptain($who, $command, $_);
				}
				$self->updateTopic();
				return;
			}
		} else {
			$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
			return;
		}
	}
	if ($toCaptain eq $captain1{$channel} || $toCaptain eq $captain2{$channel}) {
		$self->noticeUser($who, bold(red("$toCaptain jest już kapitanem!")));
		return;
	}
	if (!playerIsSignedOrPlaying($toCaptain)) {
		$self->noticeUser($who, bold(red("$toCaptain nie jest zapisany do aktualnej gry!")));
		return;
	}
	if (!$selfCaptains && !mysqlPlayerIsAdminByNick($who)) {
		$self->voteCaptain($who, $channel, ".vc", $toCaptain);
		return;
	}
	if ($captain1{$channel} eq '') {
		$captain1{$channel} = $toCaptain;
	} else {
		$captain2{$channel} = $toCaptain;
	}
	$self->sayToChannel($channel, playerColor($toCaptain) . defaultColor(" jest teraz kapitanem!"));
	$self->updateTopic();
	return;
}

sub loseCaptain {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $toUncaptain = $who;
	if ($#_ > 0) { # If player is signing somewhere else
		if (mysqlPlayerIsAdminByNick($who)) {
			if ($#_ == 1) { # If player is signing one player
				$toUncaptain = $_[1];
			} else { # If player is signing multiple players
				my $command = shift;
				foreach(@_) {
					$self->becomeCaptain($who, $command, $_);
				}
				$self->updateTopic();
				return;
			}
		} else {
			$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
			return;
		}
	}
	if ($toUncaptain ne $captain1{$channel} && $toUncaptain ne $captain2{$channel}) {
		$self->noticeUser($who, bold(red("$toUncaptain nie jest kapitanem!")));
		return;
	}
	if ($phase{$channel} >= 4) {
		$self->noticeUser($who, bold(red("Gra już wystartowała!")));
		return;
	}
	if ($captain1{$channel} eq $toUncaptain) {
		$captain1{$channel} = "";
	} else {
		$captain2{$channel} = "";
	}
	$self->sayToChannel($channel, "$toUncaptain nie jest już kapitanem!");
	$self->updateTopic();
	return;
}

sub changeCaptain {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $currentCaptain = $_[1];
	my $newCaptain = $_[2];
	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->sayToChannel($channel, "Nie jesteś administratorem!");
		return;
	}
	if ($currentCaptain ne $captain1{$channel} && $currentCaptain ne $captain2{$channel}) {
		$self->sayToChannel($channel, "$currentCaptain nie jest kapitanem!");
		return;
	}
	if (!playerIsSigned($newCaptain)) {
		$self->sayToChannel($channel, "$newCaptain nie jest zapisany!");
		return;
	}
	if ($newCaptain eq $captain1{$channel} || $newCaptain eq $captain2{$channel}) {
		$self->sayToChannel($channel, "$newCaptain jest już kapitanem!");
		return;
	}
	# If picking hasn't started yet
	if ($phase{$channel} < 4) {
		if ($currentCaptain eq $captain1{$channel}) {
			$captain1{$channel} = $newCaptain;
		} else {
			$captain2{$channel} = $newCaptain;
		}
		$self->updateTopic();
	# If picking started already
	} else {
		if ($currentCaptain eq $captain1{$channel}) {
			changeCaptain1($newCaptain);
		} else {
			changeCaptain2($newCaptain);
		}
	}
	$self->sayToChannel($channel, "$newCaptain zastąpił $currentCaptain jako nowy kapitan!");
	return;
}

sub viewcaptainVotes {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	if (!$canVoteOnCaptains{$channel}) {
		$self->sayToChannel($channel, "Głosowanie na kapitanów jest aktualnie niemożliwe!");
		return;
	}
	if ($totalcaptainVotes{$channel} == 0) {
		$self->sayToChannel($channel, "Nikt jeszcze nie głosował!");
		return;
	}
	my $text = ("Aktualne wyniki głosowania: ");
	for my $player (@{$players{$channel}}) {
		if ($captainVotes{$channel}{$player} > 0) {
			$text .= "$player\[$captainVotes{$channel}{$player}\], ";
		}
	}
	chop $text;
	chop $text;
	$self->sayToChannel($channel, $text);
	return;
}

sub viewModeVotes {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	if (!$canVoteOnMode{$channel}) {
		$self->sayToChannel($channel, "Głosowanie na kapitanów jest aktualnie niemożliwe!");
		return;
	}
	if ($totalModeVotes{$channel} == 0) {
		$self->sayToChannel($channel, "Nikt jeszcze nie głosował!");
		return;
	}
	my $text = ("Aktualne wyniki głosowania: ");
	for my $mode (keys %modes) {
		if ($modeVotes{$channel}{$mode} > 0) {
			$text .= "$mode\[$modeVotes{$channel}{$mode}\], ";
		}
	}
	chop $text;
	chop $text;
	$self->sayToChannel($channel, $text);
	return;
}

sub voteCaptain {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	if (!$canVoteOnCaptains{$channel}) {
		$self->sayToChannel($channel, "Głosowanie na kapitanów jest aktualnie niemożliwe!");
		return;
	}
	if (! exists $captainVoters{$channel}{$who}) {
		$captainVoters{$channel}{$who} = "";
	}
	if ($#_ < 1) {
		if ($captainVoters{$channel}{$who} ne '') {
			if (exists $captainVotes{$channel}{$captainVoters{$channel}{$who}} && $captainVotes{$channel}{$captainVoters{$channel}{$who}} > 0) {
				$captainVotes{$channel}{$captainVoters{$channel}{$who}} -= 1;
				$totalcaptainVotes{$channel}--;
			}
			$self->sayToChannel($channel, "$who anulował swój poprzedni głos na $captainVoters{$channel}{$who}");
			$captainVoters{$channel}{$who} = '';
		}
		return;
	}
	my $vote = $_[1];
	# Get a list of potential captains
	my @votablePlayers;
	my $points;
	for my $i (0 .. $#{$players{$channel}}) {
		if (@{$players{$channel}}[$i] ne $captain1{$channel} && @{$players{$channel}}[$i] ne $captain2{$channel}) {
			push @votablePlayers, @{$players{$channel}}[$i];
		}
	}
	my $players = arrayToStringWithSpaces(@votablePlayers);
	if (!playerIsSigned($who)) {
		$self->sayToChannel($channel, "Musisz być zapisany do gry, aby głosować na kapitanów!");
		return;
	}
	my $validVote = 0;
	for my $player (@votablePlayers) {
		if ($vote eq $player || caseInsensitiveEquals($vote, $player)) {
			$validVote = 1;
			$vote = $player; # For case insensitive
			last;
		}
	}
	if (!$validVote) {
		if ($vote ne '?') {
		$self->noticeUser($who, defaultColor("Zagłosowałeś na niepoprawnego gracza!"));
		}
		$self->noticeUser($who, defaultColor("Możliwi gracze do zagłosowania to: " . arrayToStringWithSpaces(@votablePlayers)));
		return;
	}
	my $alreadyVoted = 0;
	if ($captainVoters{$channel}{$who} ne '') {
		$alreadyVoted = 1;
	}
	my $sameVote = 0;
	if ($alreadyVoted) {
		if ($captainVoters{$channel}{$who} eq $vote) {
			$sameVote = 1;
		}
	}
	if ($alreadyVoted && !$sameVote) {
		$self->sayToChannel($channel, "Gracz $who zmienił swój głos z $captainVoters{$channel}{$who} na $vote");
		$captainVotes{$channel}{$captainVoters{$channel}{$who}} -= 1;
		$totalcaptainVotes{$channel}--;
	} elsif (!$alreadyVoted) {
		$self->sayToChannel($channel, "Gracz $who zagłosował na $vote");
	} else {
		$self->sayToChannel($channel, "$who - Już oddałeś głos na $vote!");
		return;
	}
	$captainVotes{$channel}{$vote} += 1;
	$captainVoters{$channel}{$who} = $vote;
	$totalcaptainVotes{$channel}++;
	$self->viewcaptainVotes($who, $channel);
	return;
}

sub voteMode {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	if (!$canVoteOnMode{$channel}) {
		$self->sayToChannel($channel, "Głosowanie na tryb gry jest aktualnie niemożliwe!");
		return;
	}
	if (!playerIsSigned($who)) {
		$self->sayToChannel($channel, "Musisz być zapisany do gry, aby głosować na tryb gry!");
		return;
	}
	if (! exists $modeVoters{$channel}{$who}) {
		$modeVoters{$channel}{$who} = "";
	}
	if ($#_ < 1) {
		if ($modeVoters{$channel}{$who} ne '') {
			if (exists $modeVotes{$channel}{$modeVoters{$channel}{$who}} && $modeVotes{$channel}{$modeVoters{$channel}{$who}} > 0) {
				$modeVotes{$channel}{$modeVoters{$channel}{$who}} -= 1;
				$totalModeVotes{$channel}--;
			}
			$self->sayToChannel($channel, "$who anulował swój poprzedni głos na $modeVoters{$channel}{$who}");
			$modeVoters{$channel}{$who} = '';
		}
		return;
	}
	my $vote = $_[1];
	my $validVote = 0;
	for my $mode (keys %modes) {
		if ($vote eq $mode || caseInsensitiveEquals($vote, $mode)) {
			$validVote = 1;
			$vote = $mode; # For case insensitive
			last;
		}
	}

	if (!$validVote) {
		$self->noticeUser($who, bold(red("Zagłosowałeś na nieprawidłowy tryb gry. Możliwe tryby to: " . getStringModes())));
		return;
	}

	my $alreadyVoted = 0;
	if ($modeVoters{$channel}{$who} ne '') {
		$alreadyVoted = 1;
	}

	my $sameVote = 0;
	if ($alreadyVoted) {
		if ($modeVoters{$channel}{$who} eq $vote) {
			$sameVote = 1;
		}
	}

	if ($alreadyVoted && !$sameVote) {
		$self->sayToChannel($channel, "Gracz $who zmienił swój głos na tryb rozgrywki z $modeVoters{$channel}{$who} na $vote");
		$modeVotes{$channel}{$modeVoters{$channel}{$who}} -= 1;
		$totalModeVotes{$channel}--;
	} elsif (!$alreadyVoted) {
		$self->sayToChannel($channel, "Gracz $who zagłosował na tryb: $vote");
	} else {
		$self->sayToChannel($channel, "$who - Już oddałeś głos na tryb: $vote!");
		return;
	}

	$modeVotes{$channel}{$vote} += 1;
	$modeVoters{$channel}{$who} = $vote;
	$totalModeVotes{$channel}++;
	$self->viewModeVotes($who, $channel);

	return;
}

sub printStats {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;

	my $top10 = bold(green("Top 10:"));
	for my $request (mysqlGetAllMultiple("users ORDER BY points DESC LIMIT 10")) {
		$top10 .= " " . playerColor($request->{username}, $request->{color}) . defaultColor("[") . bold(green($request->{points})) . defaultColor("]");
	}
	$self->noticeUser($who, $top10);
	return;
}

sub printPassword {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;
	my @toPass;

	if (!@_) {
		push(@toPass, $who);
	} else {
		push(@toPass, @_);
	}

	if (playerIsSignedOrPlaying($who, $channel)) {
		if ($#{$players{$channel}} + 1 + $#{$team1{$channel}} + 1 + $#{$team2{$channel}} + 1 >= $maxPlayers) {
			for my $toPassOne (@toPass) {
				$self->noticeUser($toPassOne, red(bold("UWAGA!")) . defaultColor(" Hasło do startującej gry na kanale $channel: ") . bold(defaultColor($gamePassword{$channel})));
				#$self->sayToUser($toPassOne, red(bold("UWAGA!")) . defaultColor(" Hasło do startującej gry na kanale $channel: ") . bold(defaultColor($gamePassword{$channel})));
			}
		} else {
			$self->noticeUser($who, red(bold("Gra jeszcze nie wystartowała!")));
		}
	} else {
		$self->noticeUser($who, bold(red("Nie jesteś zapisany do aktualnej gry!")));
	}
	return;
}

sub pickPlayer {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;
	my @toPick;

	if ($phase{$channel} < 4) {
		$self->noticeUser($who, bold(red("Gra jeszcze się nie rozpoczęła!")));
		return;
	}

	if (!@_) {
		return;
	}

	push(@toPick, @_);

	my $nextpicker;
	for my $toPickOne (@toPick) {
		if (!mysqlPlayerIsAdminByNick($who)) { # If picker is not an admin, check if it's his turn
			if ($who ne $captain1{$channel} && $who ne $captain2{$channel}) {
				$self->noticeUser($who, bold(red("Nie jesteś kapitanem!")));
				return;
			}

			if ($who eq $captain1{$channel} && $turn{$channel} != 1) {
				$self->noticeUser($who, bold(red("Teraz jest kolej kapitana $captain2{$channel}!")));
				return;
			}
			
			if ($who eq $captain2{$channel} && $turn{$channel} != 2) {
				$self->noticeUser($who, bold(red("Teraz jest kolej kapitana $captain1{$channel}!")));
				return;
			}
		}

		# Smart detect
		my $found = 0;
		my $foundIndex;

		my $lcToPick = lc($toPickOne);
		for my $i (0 .. $#{$players{$channel}}) {
			my $lcPlayer = lc(@{$players{$channel}}[$i]);
			if (@{$players{$channel}}[$i] eq $toPickOne || $lcPlayer eq $lcToPick) {
				$found = 1;
				$toPickOne = @{$players{$channel}}[$i];
				$foundIndex = $i;
				last;
			} elsif (stringContainsSubstring($lcPlayer, $lcToPick)) {
				$found++;
				$toPickOne = @{$players{$channel}}[$i];
				$foundIndex = $i;
			}
		}

		if ($found == 0) {
			$self->noticeUser($who, bold(red("Gracz $toPickOne nie znajduje się w puli!")));
			return;
		} elsif ($found == 1) {
			splice(@{$players{$channel}}, $foundIndex, 1);
		} else {
			$self->noticeUser($who, bold(red("Ten wybór jest niejednoznaczny!")));
			return;
		}

		if ($turn{$channel} == 1) {
			push(@{$team1{$channel}}, $toPickOne);
			if ($lastTurn{$channel} == 1) {
				$turn{$channel} = 2;
			}
			$lastTurn{$channel} = 1;
		} else {
			push(@{$team2{$channel}}, $toPickOne);
			if ($lastTurn{$channel} == 2) {
				$turn{$channel} = 1;
			}
			$lastTurn{$channel} = 2;
		}
		
		$self->sayToChannel($channel, playerColor($who) . defaultColor(" wybrał gracza: ") . playerColor($toPickOne));
		$self->updateTopic($channel);
		
		my $giveplayerlist = 0;
		my $lastpickwasauto = 0;
		
		# If there are more than 1 picks remaining, or
		# there are more than one player left in the pool,
		# give output regarding the next picker		
		if ($turn{$channel} == 1) {
			$nextpicker = $captain1{$channel};
		} else {
			$nextpicker = $captain2{$channel};
		}
	}

	my $remainingplayerCount = $#{$players{$channel}} + 1;
	my $pickedplayerCount = $#{$team1{$channel}}+1 + $#{$team2{$channel}}+1;
	
	if ($maxPlayers - $pickedplayerCount > 1 || $remainingplayerCount > 1) {
		$self->printPlayers($nick, $channel);
		$self->sayToChannel($channel, defaultColor("Teraz wybiera: ") . playerColor($nextpicker));
		$self->sayToChannel($channel, defaultColor("W przypadku braku wyboru, po ") . bold(red($pickPlayerTime)) . defaultColor(" sekundach, losowy gracz z puli zostanie przydzielony automatycznie"));
	
	# Else, do the last pick automatically
	} else {
		my $lastPick = @{$players{$channel}}[0];
		if ($#{$team1{$channel}} < $#{$team2{$channel}}) {
			push(@{$team1{$channel}}, $lastPick);
		} else {
			push(@{$team2{$channel}}, $lastPick);
		}
		splice(@{$players{$channel}}, 0, 1);
		$pickedplayerCount++;
		$self->sayToChannel($channel, playerColor($lastPick) . defaultColor(" został automatycznie przydzielony do drużyny kapitana ") . playerColor($nextpicker));
		
	}
	
	# Return if not ready yet, otherwise go on
	if ($pickedplayerCount < $maxPlayers) {
		$self->setCounter($channel, $pickPlayerTime);
		return;
	}
	
	# End picking and start the game
	$self->startGame($channel);
	return;
}

sub abortGame {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->sayToChannel($channel, "Nie jesteś administratorem!");
		return;
	}

	my $playerCount = $#{$players{$channel}} + 1;
	if ($playerCount == 0) {
		$self->sayToChannel($channel, "Nikt nie jest zapisany!");
		return;
	}

	$captain1{$channel} = "";
	$captain2{$channel} = "";
	$chosenMode{$channel} = "";
	$self->voidGameVotes($channel);
	@{$players{$channel}} = ();
	@{$team1{$channel}} = ();
	@{$team2{$channel}} = ();

	$canVoteOnCaptains{$channel} = 0;
	$canVoteOnMode{$channel} = 0;
	$phase{$channel} = 0;
	$self->setCounter($channel, 0);

	$self->sayToChannel($channel, "Aktualna gra została anulowana, a lista graczy wyczyszczona!");
	$self->updateTopic();

	return;
}

sub changeScore {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $game = 0;
	my $result = '';

	if ($#_ < 2) {
		$self->sayToChannel($channel, "Zły syntax! .cr Wynik ID");
		return;
	} elsif ($#_ == 2) { # Player is reporting a score for specific game
		$result = $_[1];
		$game = $_[2];
	} else {
		my $command = shift;
		$result = shift;
		foreach(@_) {
			$self->changeScore($who, $command, $result, $_);
		}
	}

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->sayToChannel($channel, "$who nie jest administratorem!");
		return;
	}

	if ($result ne $team1 && !caseInsensitiveEquals($result, $team1) &&
		$result ne $team2 && !caseInsensitiveEquals($result, $team2) &&
		$result ne $draw && !caseInsensitiveEquals($result, $draw)) {
		$self->sayToChannel($channel, "Wynikiem meczu może być wyłącznie $team1, $team2 lub $draw!");
		return;
	}

	if (!mysqlGameExists($game)) {
		$self->sayToChannel($channel, "Gra $game nie została znaleziona!");
		return;
	}

	if (mysqlGameIsActive($game)) {
		$self->sayToChannel($channel, "Gra $game wciąż jest aktywna!");
		return;
	}

	# Modify $result to proper one if case insensitive mode is enabled
	# AND user actually used this variant
	if (caseInsensitiveEquals($result, $team1)) {
		$result = $team1;
	} elsif (caseInsensitiveEquals($result, $team2)) {
		$result = $team2;
	} elsif (caseInsensitiveEquals($result, $draw)) {
		$result = $draw;
	}

	# Get the players who played in this game
	my @team1Players = mysqlGetPlayersFromTeam(mysqlGetTeam1ID($game));
	my @team2Players = mysqlGetPlayersFromTeam(mysqlGetTeam2ID($game));
	my @playerList = (@team1Players, @team2Players);
	my $team1ID = mysqlGetTeam1ID($game);
	my $team2ID = mysqlGetTeam2ID($game);
	my $winnerTeamID = mysqlGetwinnerOfGame($game);

	if ($winnerTeamID == 1) {
		$winnerTeamID = $team1ID;
	} elsif ($winnerTeamID == 2) {
		$winnerTeamID = $team2ID;
	}

	# Handle same score
	if (($result eq $team1 && $winnerTeamID == $team1ID) || ($result eq $team2 && $winnerTeamID == $team2ID) || ($result eq $draw && $winnerTeamID == 0)) {
		$self->sayToChannel($channel, "Podany wynik jest identyczny z już istniejącym!");
		return;
	}

	my $deltaPoints = mysqlGetDeltaOfGame($game);

	# If we don't have draw yet, we must make it so
	if ($winnerTeamID != 0) {
		# Replace winner with loser and forward points, this will "zero" them
		if ($winnerTeamID == $team1ID) {
			mysqlForwardpointsToteams($deltaPoints, $team2ID, $team1ID, 1);
		} else {
			mysqlForwardpointsToteams($deltaPoints, $team1ID, $team2ID, 1);
		}
		mysqlSetwinnerOfGame(0, $game);
	}

	# We now have a draw, check if we're done
	if ($result eq $draw) {
		$self->sayToChannel($channel, "Gra $game została oznaczona jako nierozstrzygnięta!");
		return;
	}

	# We're not done yet, this means that we need to forward points *again*
	# Just with a small addition of setting winner to proper team this time
	if ($winnerTeamID == $team1ID) {
		mysqlForwardpointsToteams($deltaPoints, $team2ID, $team1ID);
		mysqlSetwinnerOfGame(2, $game);
	} else {
		mysqlForwardpointsToteams($deltaPoints, $team1ID, $team2ID);
		mysqlSetwinnerOfGame(1, $game);
	}


	# Now we're truly done
	$self->sayToChannel($channel, "Wynik gry $game został zmieniony na korzyść $result!");

	return;
}

sub win {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	my $game = mysqlGetLastGameOfPlayerByNick($who);
	if (mysqlPlayerPlaysInTeamByNick($who, mysqlGetTeam1ID($game))) {
		$self->reportScore($who, $channel, ".r", $team1, $game);
	} else {
		$self->reportScore($who, $channel, ".r", $team2, $game);
	}
	return;
}

sub lose {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	my $game = mysqlGetLastGameOfPlayerByNick($who);
	if (mysqlPlayerPlaysInTeamByNick($who, mysqlGetTeam1ID($game))) {
		$self->reportScore($who, $channel, ".r", $team2, $game);
	} else {
		$self->reportScore($who, $channel, ".r", $team1, $game);
	}
	return;
}

sub draw {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	my $game = mysqlGetLastGameOfPlayerByNick($who);
	$self->reportScore($who, $channel, ".r", $draw, $game);
	return;
}

sub reportScore {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;
	my $result = shift;
	my @toReport;

	if (!@_) {
		return;
	}

	push (@toReport, @_);

	if (!caseInsensitiveEquals($result, $team1) && !caseInsensitiveEquals($result, $team2)&& !caseInsensitiveEquals($result, $draw)) {
		$self->sayToChannel($channel, "Wynikiem meczu może być wyłącznie $team1, $team2 lub $draw!");
		return;
	}

	for my $toReportOne (@toReport) {
		my $request = mysqlGetAllOne("games", "game_id", $toReportOne); # TODO
		if (!mysqlGameExists($toReportOne)) {
			$self->sayToChannel($channel, "Gra $toReportOne nie została znaleziona!");
			next;
		}

		if (!mysqlGameIsActive($toReportOne)) {
			$self->sayToChannel($channel, "Gra $toReportOne została już zamknięta!");
			next;
		}

		# Modify $result to proper one if case insensitive mode is enabled
		if (caseInsensitiveEquals($result, $team1)) {
			$result = $team1;
		} elsif (caseInsensitiveEquals($result, $team2)) {
			$result = $team2;
		} else {
			$result = $draw;
		}

		# Get the players who played in this game
		my @team1Players = mysqlGetNicknamesOfPlayers(mysqlGetPlayersFromTeam(mysqlGetTeam1ID($toReportOne)));
		my @team2Players = mysqlGetNicknamesOfPlayers(mysqlGetPlayersFromTeam(mysqlGetTeam2ID($toReportOne)));
		my @playerList = (@team1Players, @team2Players);

		if (!mysqlPlayerIsAdminByNick($who)) {
			# Find out if the player even played in the game
			my $wasPlaying = 0;
			for my $i (0 .. $#playerList) {
				if ($playerList[$i] eq $who) {
					$wasPlaying = 1;
					last;
				}
			}
			if (!$wasPlaying) {
				$self->sayToChannel($channel, playerColor($who) . defaultColor(" nie uczestniczył w grze #$toReportOne!"));
				next;
			}

			# Initialize %gameResult value if necessary
			if (! exists $gameResult{$toReportOne}) {
				$gameResult{$toReportOne} = '';
			}

			my @requests = split ',', $gameResult{$toReportOne};
			my @requesters;
			my @scores;

			# Fill requesters and scores with actual data
			for my $i (0 .. $#requests) {
				my @arr = split ':', $requests[$i];
				push @requesters, $arr[0];
				push @scores, $arr[1];
			}

			# Check if user already voted
			my $alreadyRequested = 0;
			for my $i (0 .. $#requesters) {
				if ($requesters[$i] eq $who) {
					$alreadyRequested = 1;
					$scores[$i] = $result;
					last;
				}
			}
			if (!$alreadyRequested) {
				# If not, add him
				push @requesters, $who;
				push @scores, $result;
			}


			# Update to %gameResult
			my @arr=();
			for my $i (0 .. $#requesters) {
				push @arr, "$requesters[$i]:$scores[$i]";
			}
			$gameResult{$toReportOne} = join ',', @arr;
			
			# Find out who have requested this particular score
			my @sameRequesters;
			for my $i (0 .. $#scores) {
				if ($scores[$i] eq $result) {
					push @sameRequesters, $requesters[$i];
				}
			}
			
			my $requestsSoFar = $#sameRequesters+1;
			my $requestersline = join ', ', @sameRequesters;

			$self->sayToChannel($channel, defaultColor("Wynik dla gry $toReportOne: $result. Poparli: $requestersline. Brakujące głosy: " . ($requestsNeeded - $requestsSoFar)));
			if ($requestsSoFar < $requestsNeeded) {
				next;
			}
		}
		
		# - GOING TO ACCEPT THE SCORE -

		# Delete score requests related to this game
		delete($gameResult{$toReportOne});

		$self->sayToChannel($channel, "Gra $toReportOne zakończyła się!");
		my $winnerTeamID = mysqlGetTeam1ID($toReportOne);
		my $loserTeamID = mysqlGetTeam2ID($toReportOne);
		if ($result eq $team1) {
			$self->sayToChannel($channel, "Wygrała drużyna: $team1!");
			mysqlSetwinnerOfGame(1, $toReportOne);
		} elsif ($result eq $team2) {
			$self->sayToChannel($channel, "Wygrała drużyna: $team2!");
			my $replace = $winnerTeamID;
			$winnerTeamID = $loserTeamID;
			$loserTeamID = $replace;
			mysqlSetwinnerOfGame(2, $toReportOne);
		} else {
			mysqlSetwinnerOfGame(0, $toReportOne);
			$self->sayToChannel($channel, "Gra nie została rozstrzygnięta!");
			mysqlForwardpointsToteams(0, $winnerTeamID, $loserTeamID);
			next;
		}

		# Calculate delta
		my $deltaPoints = mysqlGetModePoints($request->{mode_id});
		my $minDelta = int($deltaPoints / $variationDelta);
		my $maxDelta = int($deltaPoints + ($minDelta * ($variationDelta - 1)));

		my $winnerpoints = mysqlGetTeamTotalPoints($winnerTeamID);
		my $loserpoints = mysqlGetTeamTotalPoints($loserTeamID);

		if ($winnerpoints > $loserpoints) {
			# They had easy win
			$deltaPoints -= int(($winnerpoints - $loserpoints) / $justiceDelta);
		} elsif ($winnerpoints < $loserpoints) {
			# They had tough win
			$deltaPoints += int(($loserpoints - $winnerpoints) / $justiceDelta);
		}

		# Correct min/max of delta
		if ($deltaPoints < $minDelta) {
			$deltaPoints = $minDelta;
		} elsif ($deltaPoints > $maxDelta) {
			$deltaPoints = $maxDelta;
		}

		mysqlSetDeltaOfGame($deltaPoints, $toReportOne);

		my $totalWinPoints = $deltaPoints;
		my $totalLosePoints = $deltaPoints;

		# Killstreaks
		my $streakPoints = 0;
		for my $request (mysqlGetAllMultiple("users", "user_id", returnGroupForMysql(mysqlGetPlayersFromTeam($loserTeamID)))) {
			my $streak = $request->{streak};
			if ($streak >= 3) {
				my $extraPoints = $streak * $justiceStreak;
				my $sadPlayer = $request->{username};
				$self->sayToChannel($channel, green("Drużyna $result otrzymała dodatkowo $extraPoints punktów za ukrócenie graczowi ") . playerColor($sadPlayer, $request->{color}) . " " . bold(green($streak)) . green(" zwycięstw z rzędu!"));
				$streakPoints += $extraPoints;
			}
		}
		if ($streakPoints > 0) {
			mysqlRewardPlayersByID($streakPoints, mysqlGetPlayersFromTeam($winnerTeamID));
			$totalWinPoints += $streakPoints;
		}

		mysqlForwardpointsToteams($deltaPoints, $winnerTeamID, $loserTeamID);

		if ($result eq $team1) {
			$self->sayToChannel($channel, "$team1 ", bold(green("[+$totalWinPoints]")), " : ", arrayToStringWithSpaces(mysqlGetNicknamesOfPlayers(mysqlGetPlayersFromTeam($winnerTeamID))));
			$self->sayToChannel($channel, "$team2 ", bold(red("[-$totalLosePoints]")), " : ", arrayToStringWithSpaces(mysqlGetNicknamesOfPlayers(mysqlGetPlayersFromTeam($loserTeamID))));
		} else {
			$self->sayToChannel($channel, "$team1 ", bold(red("[-$totalLosePoints]")), " : ", arrayToStringWithSpaces(mysqlGetNicknamesOfPlayers(mysqlGetPlayersFromTeam($loserTeamID))));
			$self->sayToChannel($channel, "$team2 ", bold(green("[+$totalWinPoints]")), " : ", arrayToStringWithSpaces(mysqlGetNicknamesOfPlayers(mysqlGetPlayersFromTeam($winnerTeamID))));
		}
	}

	# Update the topic
	$self->updateTopic();

	return;
}

sub statPlayer {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	my $toStat = $who;
	if ($#_ > 0) { # If player is calling someone else
		if ($#_ == 1) { # If player is calling one player
			$toStat = $_[1];
		} else { # If player is calling multiple players
			my $command = shift;
			foreach(@_) {
				$self->statPlayer($who, $command, $_);
			}
			return;
		}
	}

	if (!mysqlPlayerExistsByNick($toStat)) {
		$self->sayToChannel($channel, "Gracz $toStat nie został znaleziony!");
		return;
	}

	my $request = mysqlGetAllOne("users", "username", $toStat);
	my $winratio = 0;
	my $totalgames = $request->{wins} + $request->{loses};
	if ($totalgames > 0) {
		$winratio = 100 * $request->{wins} / $totalgames;
	}

	$self->noticeUser($who, defaultColor("Gracz ") . playerColor($toStat, $request->{color}) . defaultColor(" posiada ") . bold(lgrey($request->{points})) . defaultColor(" punktów, ") . bold(defaultColor($request->{reputation})) . defaultColor(" reputacji, ") . bold(green($request->{wins})) . defaultColor(" zwycięstw, ") . bold(red($request->{loses})) . defaultColor( " porażek oraz ") . bold(lgrey($request->{draws})) . defaultColor( " gier nierozstrzygniętych. Aktualny streak to: ") . bold(lgrey($request->{streak})) . parseStreak($request->{streak}) . defaultColor(" Najdłuższy streak to: ") . bold(lgrey($request->{longest_streak})) . parseStreak($request->{longest_streak}) . defaultColor(" Aktualne winratio: ") . bold(lgrey(nearest(.01, $winratio) . "%.")) . defaultColor(" Poziom dostepu: ") . bold(red(mysqlGetAccessByID($request->{access_id}))));
	return;
}

sub statGame {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	my $toStat = -1;
	if ($#_ == 0) { # Player is calling his last game
		$toStat = mysqlGetLastGameOfPlayerByNick($who);
	} elsif ($#_ == 1) { # If player is calling specifc ID
		$toStat = $_[1];
	} else { # If player is calling multiple IDs
		my $command = shift;
		foreach(@_) {
			$self->statGame($who, $command, $_);
		}
		return;
	}

	if (!mysqlGameExists($toStat)) {
		$self->noticeUser($who, defaultColor("Gra $toStat nie została znaleziona!"));
		return;
	}

	my $request = mysqlGetAllOne("games", "game_id", $toStat);
	my $team1ID = $request->{team1_id};
	my $team2ID = $request->{team2_id};
	my $modeID = $request->{mode_id};
	my $GameTimestamp = $request->{timestamp};

	my @team1Players;
	foreach (mysqlGetNicknamesOfPlayers(mysqlGetPlayersFromTeam($team1ID))) {
		push(@team1Players, playerColor($_));
	}
	my @team2Players;
	foreach (mysqlGetNicknamesOfPlayers(mysqlGetPlayersFromTeam($team2ID))) {
		push(@team2Players, playerColor($_));
	}

	$self->noticeUser($who, defaultColor("Gra ") . bold(defaultColor("#$toStat:")));
	$self->noticeUser($who, defaultColor("Data: ") . bold(defaultColor($GameTimestamp)));
	$self->noticeUser($who, defaultColor("Tryb gry: ") . bold(defaultColor(mysqlGetNameOfMode($modeID))));
	$self->noticeUser($who, bold(green($team1)) . defaultColor("[") . bold(defaultColor(mysqlGetTeamTotalPoints($team1ID))) . defaultColor("]: ") . arrayToStringWithSpaces(@team1Players));
	$self->noticeUser($who, bold(red($team2)) . defaultColor("[") . bold(defaultColor(mysqlGetTeamTotalPoints($team2ID))) . defaultColor("]: ") . arrayToStringWithSpaces(@team2Players));

	if (mysqlGameIsActive($toStat)) {
		my $gameTime = int((str2time(mysqlGetCurrentDate()) - str2time($GameTimestamp)) / 60);
		$self->noticeUser($who, defaultColor("Status: ") . bold(defaultColor("Aktywna")));
		$self->noticeUser($who, defaultColor("Trwa już: ") . bold(defaultColor("$gameTime minut")));
	} else {
		$self->noticeUser($who, defaultColor("Status: ") . bold(defaultColor("Zakończona")));
		my $winner = mysqlGetwinnerOfGame($toStat);
		if ($winner == 1) {
			$self->noticeUser($who, defaultColor("Zwycięzca: ") . bold(green($team1)));
		} elsif ($winner == 2) {
			$self->noticeUser($who, defaultColor("Zwycięzca: ") . bold(red($team2)));
		} else {
			$self->noticeUser($who, defaultColor("Zwycięzca: ") . bold(defaultColor("Remis")));
		}
	}

	return;
}

sub checkTimeBans {
	my $self = shift;
	my $currentTimestamp = mysqlGetCurrentTimestamp();

	for my $request (mysqlGetAllMultiple("users", "banned_until", "IS NOT NULL")) {
		if (mysqlDateToTimestamp($request->{banned_until}) < $currentTimestamp) {
			$self->unbanPlayer($nick, ".unban", $request->{username});
		}
	}

	return;
}

sub banPlayer {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;
	my $time = shift; # Time in hours
	# Rest of the args are toBan players

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	if (isEmpty($time)) {
		return;
	}

	my @toBanPlayers = @_;

	if (!isANumber($time)) {
		# This is perma ban
		push(@toBanPlayers, $time);
		$time = 0;
	}

	for my $i (0.. $#toBanPlayers) {
		my $toBan = $toBanPlayers[$i];
		if (!mysqlPlayerExistsByNick($toBan)) {
			$self->noticeUser($who, bold(red("Gracz $toBan nie istnieje!")));
			splice(@toBanPlayers, $i, 1);
		}
	}

	if (!@toBanPlayers) {
		return;
	}

	if (@toBanPlayers == 1) {
		$self->sayToChannel($channel, (defaultColor("Gracz ") . arrayToStringWithSpaces(@toBanPlayers) . defaultColor(" został ") . bold(red("ZBANOWANY")) . defaultColor(" przez ")) . playerColor($who) . (defaultColor(" na czas $time godzin!")));
	} else {
		$self->sayToChannel($channel, (defaultColor("Gracze ") . arrayToStringWithSpaces(@toBanPlayers) . defaultColor(" zostali ") . bold(red("ZBANOWANI")) . defaultColor(" przez ")) . playerColor($who) . (defaultColor(" na czas $time godzin!")));
	}

	mysqlBanPlayerByNick($time, @toBanPlayers);
	$self->banUser($channel, @toBanPlayers);
	$self->kickUser($channel, @toBanPlayers);
	return;
}

sub unbanPlayer {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	if ($#_ < 1) {
		$self->noticeUser($who, bold(red("Nie podałeś żadnego gracza!")));
		return;
	}

	my $toUnban;
	if ($#_ == 1) { # If player is calling one player
		$toUnban = $_[1];
	} else { # If player is calling multiple players
		my $command = shift;
		foreach(@_) {
			$self->unbanPlayer($who, $command, $_);
		}
		return;
	}

	if (!mysqlPlayerExistsByNick($toUnban)) {
		$self->noticeUser($who, bold(red("Gracz $toUnban nie istnieje!")));
		return;
	}

	$self->sayToChannel($channel, (defaultColor("Gracz ") . playerColor($toUnban) . defaultColor(" został ") . bold(green("ODBANOWANY")) . defaultColor(" przez ")) . playerColor($who) . (defaultColor("!")));
	mysqlUnbanPlayerByNick($toUnban);
	$self->unbanUser($channel, $toUnban);
	return;
}

sub rewardPlayer {
	my $self = shift;
	my $who = shift;
	my $channel = shift;

	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->sayToChannel($channel, "Nie jesteś administratorem!");
		return;
	}

	if ($#_ == 0) {
		$self->sayToChannel($channel, "Musisz podać liczbę!");
		return;
	}

	my $reward = $_[1];
	my $toReward = $who;

	if (!isANumber($reward)) {
		$self->sayToChannel($channel, "$reward nie jest poprawną liczbą!");
		return;
	}

	if ($#_ > 1) { # If player is calling someone else
		if ($#_ == 2) { # If player is calling one player
			$toReward = $_[2];
		} else { # If player is calling multiple players
			my $command = shift;
			$reward = shift;
			foreach(@_) {
				$self->rewardPlayer($who, $command, $reward, $_);
			}
			return;
		}
	}

	if (!mysqlPlayerExistsByNick($toReward)) {
		$self->sayToChannel($channel, "Gracz $toReward nie istnieje!");
		return;
	}

	$self->sayToChannel($channel, "Gracz $toReward otrzymał dodatkowe $reward punktów premii");
	mysqlRewardPlayerByNick($reward, $toReward);
	return;
}

sub IFeelLucky {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $luckyPlayer = $who;

	$self->checkDay();

	if ($#_ > 0) { # If player is calling someone else
		if (mysqlPlayerIsAdminByNick($who)) {
			if ($#_ == 1) { # If player is calling one player
				$luckyPlayer = $_[1];
			} else { # If player is calling multiple players
				my $command = shift;
				foreach(@_) {
					$self->IFeelLucky($who, $command, $_);
				}
				return;
			}
		} else {
			$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
			return;
		}
	}

	if (exists($luckyPlayers{$luckyPlayer})) {
		$self->noticeUser($who, bold(red("Próbowałeś już swojego szczęścia tego dnia!")));
		return;
	}

	$luckyPlayers{$luckyPlayer} = 1;
	my $luck = 0;
	while ($luck == 0) {
		$luck = int(rand(3)) - 1;
	}

	if ($luck <= 0) {
		$self->noticeUser($luckyPlayer, defaultColor("Dzisiaj Ci się nie poszczęściło ") . playerColor($luckyPlayer) . defaultColor("! Straciłeś ") . bold(defaultColor(abs($luck))) . defaultColor(" punktów!" ));
	} else {
		$self->noticeUser($luckyPlayer, defaultColor("Masz farta ") . playerColor($luckyPlayer) . defaultColor("! Zyskałeś ") . bold(defaultColor($luck)) . defaultColor(" punktów!"));
	}
	mysqlRewardPlayerByNick($luck, $luckyPlayer);

	$luck = int(rand(100)) + 1;
	if ($luck == 33) {
		my $randomColor = randomColor();
		$self->sayToChannel($channel, defaultColor("Gratulacje $luckyPlayer! Wygrałeś "), customColor($randomColor, "taki oto niestandardowy kolor nicka"), defaultColor(" jako nagrodę specjalną! :)"));
		mysqlUpdatePlayerColor($luckyPlayer, $randomColor);
	} else {
		$self->noticeUser($luckyPlayer, defaultColor("Niestety nie udało Ci się zdobyć żadnej nagrody specjalnej! :("));
	}
	return;
}

sub challengePlayer {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;
	my $toChallenge = shift;

	# TODO
	if (!mysqlPlayerIsAdminByNick($who)) {
		$self->noticeUser($who, bold(red("Nie jesteś administratorem!")));
		return;
	}

	my $lcWho = lc($who);

	if (isEmpty($toChallenge)) {
		if (exists($oneVersusOne{$lcWho})) {
			$self->noticeUser($who, bold(green("Anulowałeś wyzwanie gracza " . $oneVersusOne{$lcWho})));
			$self->noticeUser($oneVersusOne{$lcWho}, bold(green("Wyzwanie gracza $who nie jest już aktywne!")));
			delete($oneVersusOne{$lcWho});
		} else {
			$self->noticeUser($who, bold(red("Musisz wpisać nick gracza!")));
		}
		return;
	}

	my $lcToChallenge = lc($toChallenge);

	if (!mysqlPlayerExistsByNick($toChallenge)) {
		$self->noticeUser($who, bold(red("Gracz $toChallenge nie istnieje!")));
		return;
	}

	if (exists($oneVersusOne{$lcWho})) {
		$self->noticeUser($oneVersusOne{$lcWho}, bold(green("Wyzwanie z graczem $who nie jest już aktywne!")));
	}

	$oneVersusOne{$lcWho} = $lcToChallenge;

	if (!exists($oneVersusOne{$lcToChallenge}) || $oneVersusOne{$lcToChallenge} ne $lcWho) {
		$self->noticeUser($who, bold(green("Powiadomienie do $toChallenge zostało wysłane!")));
		$self->noticeUser($toChallenge, bold(green("Gracz $who wyzwał Cię na pojedynek 1v1!")));
		$self->noticeUser($toChallenge, bold(green("Aby zaakceptować, wpisz komendę .1v1 $who")));
		#return; # TODO
	}

	$self->insertGame($channel, 'CM', $who, $toChallenge); # TODO

	delete($oneVersusOne{$lcWho});
	delete($oneVersusOne{$lcToChallenge});
	return;
}

sub tradecolor {
	my $self = shift;
	my $who = shift;
	my $channel = shift;
	my $command = shift;
	my $toTrade = shift;

	my $lcWho = lc($who);

	if (isEmpty($toTrade)) {
		if (exists($colorTrades{$lcWho})) {
			$self->noticeUser($who, bold(green("Anulowałeś swoją ofertę wymiany z graczem " . $colorTrades{$lcWho})));
			$self->noticeUser($colorTrades{$lcWho}, bold(green("Oferta wymiany z graczem $who nie jest już aktywna")));
			delete($colorTrades{$lcWho});
		} else {
			$self->noticeUser($who, bold(red("Musisz wpisać nick gracza!")));
		}
		return;
	}

	my $lcToTrade = lc($toTrade);

	if (!mysqlPlayerExistsByNick($toTrade)) {
		$self->noticeUser($who, bold(red("Gracz $toTrade nie istnieje!")));
		return;
	}

	if (exists($colorTrades{$lcWho})) {
		$self->noticeUser($colorTrades{$lcWho}, bold(green("Oferta wymiany z graczem $who nie jest już aktywna")));
	}

	$colorTrades{$lcWho} = $lcToTrade;

	if (!exists($colorTrades{$lcToTrade}) || $colorTrades{$lcToTrade} ne $lcWho) {
		$self->noticeUser($who, bold(green("Powiadomienie do $toTrade zostało wysłane!")));
		$self->noticeUser($toTrade, bold(green("Gracz $who wysłał Ci ofertę wymiany twojego aktualnego koloru nicka za jego kolor nicka!")));
		$self->noticeUser($toTrade, bold(green("Twój kolor: ")) . playerColor($toTrade));
		$self->noticeUser($toTrade, bold(green("Jego kolor: ")) . playerColor($who));
		$self->noticeUser($toTrade, bold(green("Aby zaakceptować, wpisz komendę .tc $who")));
		return;
	}

	my $color1 = mysqlGetPlayerColorByNick($who);
	my $color2 = mysqlGetPlayerColorByNick($toTrade);

	mysqlUpdatePlayerColor($toTrade, $color1);
	mysqlUpdatePlayerColor($who, $color2);

	$self->noticeUser($who, bold(green("Transakcja z $toTrade powiodła się!")));
	$self->noticeUser($toTrade, bold(green("Transakcja z $who powiodła się!")));

	$self->noticeUser($who, bold(green("Twój nowy kolor nicka: ")) . playerColor($who));
	$self->noticeUser($toTrade, bold(green("Twój nowy kolor nicka: ")) . playerColor($toTrade));

	delete($colorTrades{$lcWho});
	delete($colorTrades{$lcToTrade});
	return;
}

#  _____                     _
# | ____|__   __ ___  _ __  | |_  ___
# |  _|  \ \ / // _ \| '_ \ | __|/ __|
# | |___  \ V /|  __/| | | || |_ \__ \
# |_____|  \_/  \___||_| |_| \__||___/
#
# Events

sub everySecond {
	my $self = shift;
	if ($firstBoot) {
		archiPrint("DEBUG: FIRSTBOOT");
		my @channelUsers;
		my $channelData = $self->channel_data($mainChannel);
		for my $channelUser (keys %$channelData) {
			if ($channelUser ne $nick) {
				archiPrint("DEBUG: ADD $channelUser");
				push(@channelUsers, $channelUser);
			}
		}
		archiPrint("DEBUG: CU: " . arrayToStringWithSpaces(@channelUsers));
		$self->inviteUsersToChannels(@channelUsers);
		$firstBoot = 0;
	}

	return;
}

sub everyMinute {
	my $self = shift;
	$self->checkTimeBans();
	return;
}

sub everyHour {
	my $self = shift;
	return;
}

sub tick {
	my $self = shift;

	# Handle time
	$second++;
	$self->everySecond();
	if ($second >= 60) {
		$minute++;
		$second = 0;
		$self->everyMinute();
	}
	if ($minute >= 60) {
		$minute = 0;
		$self->everyHour();
	}

	for my $channel (@channels) {
		if ($counter{$channel} > 0) {
			$counter{$channel}--;
			if ($counter{$channel} <= 0) {
				$phase{$channel}++;
				if ($phase{$channel} == 1) {
					$self->startVotingOnMode($channel);
				} elsif ($phase{$channel} == 2) {
					$self->endVotingOnMode($channel)
				} elsif ($phase{$channel} == 3) {
					$self->startVotingOnCaptains($channel);
				} elsif ($phase{$channel} == 4) {
					$self->endVotingOnCaptains($channel);
				} else {
					$self->pickRandomPlayer($nick, $channel);
				}
			}
		}
	}

	return 1;
}

# Topic has been changed
sub topic {
	my $self = shift;
	my $message = shift;
	my $who = "";
	my $topic = "";

	if (!isEmpty($message->{who})) {
		$who = $message->{who};
	}

	if (!isEmpty($message->{topic})) {
		$topic = $message->{topic};
	}

	return;
}

# Someone leaves the channel
sub chanpart {
	my $self = shift;
	my $message = shift;
	my $who = $message->{who};
	my $quitChannel = $message->{channel};

	if ($who eq $nick) {
		return;
	}

	for my $channel (@channels) {
		if ($phase{$channel} == 0) {
			$self->removePlayer($channel, $who);
		}
	}
	return;
}

# Someone quits the IRC
sub userquit {
	my $self = shift;
	my $message = shift;
	my $who = $message->{who};
	
	# If the player is signed, remove him but only if game is not started yet
	for my $channel (@channels) {
		if ($phase{$channel} == 0) {
			$self->removePlayer($channel, $who);
		}
	}
	return;
}

# Bot connects to the channel
sub connected {
	my $self = shift;

	if (!isEmpty($operPassword)) {
		$self->getOper($nick, $operPassword);
		$self->ojoinChannel($mainChannel);
		for my $channel (@channels) {
			$self->ojoinChannel($channel);
			$self->modeChannel($channel . ' +i');
		}
	}

	#$self->sayToChannel($channel, bold(red("Witajcie śmiertelnicy!")));
	$self->updateTopic();
	return;
}

# Someone joins the channel
sub chanjoin {
	my $self = shift;
	my $message = shift;
	my $who = $message->{who};
	my $channel = $message->{channel};

	# If this is a bot, return
	if ($who eq $nick) {
		return;
	}

	if ($channel eq $mainChannel) {
		$self->inviteUsersToChannels($who);
	}

	return;
}

# Bot receives a message
sub said {
	my $self = shift;
	my $message = shift;
	my $who = $message->{who};
	my $saidChannel = $message->{channel};
	my $body = $message->{body};
	my $address = $message->{address};

	my @commands = returnArraySplitOnSpaces(stripIRCFormatting($body));

	if (isEmpty($commands[0])) {
		return;
	} elsif (substr($commands[0], 0, 1) ne '.') {
		return;
	}

	my $canPlay = 0;
	for my $channel (@channels) {
		if ($saidChannel eq $channel) {
			$canPlay = 1;
			last;
		}
	}

	my $request = $commands[0];

	my @commandArguments;
	push(@commandArguments, ($who, $saidChannel, @commands));

	# command .architest
	if (caseInsensitiveEquals($request, '.architest'))  {
		$self->archiTest(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.rep', '.rep+', '.rep-')) {
		$self->reputationChange(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.invite', '.inviteme')) {
		$self->inviteMe(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.playerColor', '.pc')) {
		$self->setPlayercolor(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.changeresult', '.cr')) {
		$self->changeScore(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.stats', '.whois', '.whoami')) {
		$self->statPlayer(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.top', '.top10')) {
		$self->printStats(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.info', '.lastgame', '.lg', '.gameinfo')) {
		$self->statGame(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.reward')) {
		$self->rewardPlayer(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.luck', '.ifeellucky', '.tryluck', '.kolofortuny', '.kolobiedy')) {
		$self->IFeelLucky(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.replace')) {
		$self->replacePlayer(@commandArguments);
	} elsif (caseInsensitiveEquals($request, '.games')) {
		$self->getActivegames(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.tc', '.tradecolor')) {
		$self->tradecolor(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.season')) {
		$self->season(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.newseason')) {
		$self->newSeason(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.endseason')) {
		$self->endSeason(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.shutdown')) {
		$self->shutdownBot(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.restart')) {
		$self->restartBot(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.vouch', '.vouchtest')) {
		$self->vouch(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.vouchqueue')) {
		$self->vouchQueue(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.ban')) {
		$self->banPlayer(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.unban')) {
		$self->unbanPlayer(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.deletegame')) {
		$self->deleteGame(@commandArguments);
		return;


	} elsif (!$canPlay) {
		$self->noticeUser($who, bold(red("Nie możesz użyć tej komendy na tym kanale!")));
		return;
	} elsif (caseInsensitiveEquals($request, '.sign', '.s')) {
		$self->signPlayer(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.out', '.o')) {
		$self->outPlayer(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.1v1', '.challenge')) {
		$self->challengePlayer(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.pass', '.password', '.haslo')) {
		$self->printPassword(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.pick', '.p')) {
		$self->pickPlayer(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.pickrandom', '.pr')) {
		$self->pickRandomPlayer(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.captain', '.c')) {
		$self->becomeCaptain(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.uncaptain', '.uc')) {
		$self->loseCaptain(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.changecaptain', '.cc')) {
		$self->changeCaptain(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.abort')) {
		$self->abortGame(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.result', '.report', '.r', '.score')) {
		$self->reportScore(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.win', '.w')) {
		$self->win(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.lose', '.l')) {
		$self->lose(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.draw', '.d')) {
		$self->draw(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.captainVotes', '.cv')) {
		$self->viewcaptainVotes(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.votecaptain', '.vc')) {
		$self->voteCaptain(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.votemode', '.vm')) {
		$self->voteMode(@commandArguments);
		return;
	} elsif (caseInsensitiveEquals($request, '.listplayers', '.lp', '.list', '.l', '.pool', '.lt', '.listteams', '.teams', '.captains', '.players')) {
		$self->printPlayers(@commandArguments);
		return;
	} else {
		return;
	}
}

#  ____                                       _             _
# |  _ \   ___  _ __   _ __  ___   ___  __ _ | |_  ___   __| |
# | | | | / _ \| '_ \ | '__|/ _ \ / __|/ _` || __|/ _ \ / _` |
# | |_| ||  __/| |_) || |  |  __/| (__| (_| || |_|  __/| (_| |
# |____/  \___|| .__/ |_|   \___| \___|\__,_| \__|\___| \__,_|
#              |_|



#  ___         _  _
# |_ _| _ __  (_)| |_
#  | | | '_ \ | || __|
#  | | | | | || || |_
# |___||_| |_||_| \__|

initArchiBot();
