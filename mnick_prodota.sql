-- phpMyAdmin SQL Dump
-- version 4.2.10.1deb1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Czas generowania: 22 Lis 2014, 00:09
-- Wersja serwera: 10.0.14-MariaDB-2
-- Wersja PHP: 5.6.2-1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Baza danych: `mnick_prodota`
--

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `accesses`
--

CREATE TABLE IF NOT EXISTS `accesses` (
  `access_id` int(10) unsigned NOT NULL,
  `name` varchar(20) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `games`
--

CREATE TABLE IF NOT EXISTS `games` (
`game_id` int(10) unsigned NOT NULL,
  `mode_id` int(10) unsigned NOT NULL,
  `team1_id` int(10) unsigned NOT NULL,
  `team2_id` int(10) unsigned NOT NULL,
  `winner` tinyint(4) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `delta` tinyint(3) unsigned NOT NULL DEFAULT '0'
) ENGINE=InnoDB AUTO_INCREMENT=439 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `migrations`
--

CREATE TABLE IF NOT EXISTS `migrations` (
  `migration` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `modes`
--

CREATE TABLE IF NOT EXISTS `modes` (
`mode_id` int(10) unsigned NOT NULL,
  `name` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `points` tinyint(3) unsigned NOT NULL DEFAULT '0'
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `positions`
--

CREATE TABLE IF NOT EXISTS `positions` (
`position_id` int(10) unsigned NOT NULL,
  `name` varchar(20) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `position_user`
--

CREATE TABLE IF NOT EXISTS `position_user` (
  `position_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `seasons`
--

CREATE TABLE IF NOT EXISTS `seasons` (
`season_id` int(10) unsigned NOT NULL,
  `firstgame_id` int(10) unsigned DEFAULT NULL,
  `lastgame_id` int(10) unsigned DEFAULT NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `teams`
--

CREATE TABLE IF NOT EXISTS `teams` (
`team_id` int(10) unsigned NOT NULL,
  `total_points` smallint(5) unsigned NOT NULL DEFAULT '0'
) ENGINE=InnoDB AUTO_INCREMENT=877 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `team_user`
--

CREATE TABLE IF NOT EXISTS `team_user` (
  `team_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Struktura tabeli dla tabeli `users`
--

CREATE TABLE IF NOT EXISTS `users` (
`user_id` int(10) unsigned NOT NULL,
  `username` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `password` varchar(60) COLLATE utf8_unicode_ci NOT NULL,
  `steamid` bigint(20) NOT NULL DEFAULT '0',
  `avatar_url` varchar(200) COLLATE utf8_unicode_ci NOT NULL,
  `hours_played` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `updated_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `remember_token` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `access_id` int(10) unsigned NOT NULL DEFAULT '10',
  `color` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `banned_until` timestamp NULL DEFAULT NULL,
  `points` smallint(5) unsigned NOT NULL DEFAULT '1000',
  `total_points` smallint(5) unsigned NOT NULL DEFAULT '1000',
  `wins` smallint(5) unsigned NOT NULL DEFAULT '0',
  `total_wins` smallint(5) unsigned NOT NULL DEFAULT '0',
  `loses` smallint(5) unsigned NOT NULL DEFAULT '0',
  `total_loses` smallint(5) unsigned NOT NULL DEFAULT '0',
  `draws` smallint(5) unsigned NOT NULL DEFAULT '0',
  `total_draws` smallint(5) unsigned NOT NULL DEFAULT '0',
  `streak` smallint(5) unsigned NOT NULL DEFAULT '0',
  `longest_streak` smallint(5) unsigned NOT NULL DEFAULT '0',
  `lastgame_id` int(10) unsigned DEFAULT NULL,
  `reputation` smallint(6) NOT NULL DEFAULT '0',
  `lastgame_rep_id` int(11) DEFAULT NULL,
  `banned_counter` tinyint(4) NOT NULL DEFAULT '0'
) ENGINE=InnoDB AUTO_INCREMENT=665 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Indeksy dla zrzutów tabel
--

--
-- Indexes for table `accesses`
--
ALTER TABLE `accesses`
 ADD PRIMARY KEY (`access_id`);

--
-- Indexes for table `games`
--
ALTER TABLE `games`
 ADD PRIMARY KEY (`game_id`), ADD KEY `games_mode_id_foreign` (`mode_id`), ADD KEY `games_team1_id_foreign` (`team1_id`), ADD KEY `games_team2_id_foreign` (`team2_id`);

--
-- Indexes for table `modes`
--
ALTER TABLE `modes`
 ADD PRIMARY KEY (`mode_id`);

--
-- Indexes for table `positions`
--
ALTER TABLE `positions`
 ADD PRIMARY KEY (`position_id`);

--
-- Indexes for table `position_user`
--
ALTER TABLE `position_user`
 ADD KEY `position_user_position_id_foreign` (`position_id`), ADD KEY `position_user_user_id_foreign` (`user_id`);

--
-- Indexes for table `seasons`
--
ALTER TABLE `seasons`
 ADD PRIMARY KEY (`season_id`), ADD KEY `seasons_firstgame_id_foreign` (`firstgame_id`), ADD KEY `seasons_lastgame_id_foreign` (`lastgame_id`);

--
-- Indexes for table `teams`
--
ALTER TABLE `teams`
 ADD PRIMARY KEY (`team_id`);

--
-- Indexes for table `team_user`
--
ALTER TABLE `team_user`
 ADD KEY `team_user_team_id_foreign` (`team_id`), ADD KEY `team_user_user_id_foreign` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
 ADD PRIMARY KEY (`user_id`), ADD UNIQUE KEY `users_username_unique` (`username`), ADD KEY `users_access_id_foreign` (`access_id`), ADD KEY `users_lastgame_id_foreign` (`lastgame_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT dla tabeli `games`
--
ALTER TABLE `games`
MODIFY `game_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=439;
--
-- AUTO_INCREMENT dla tabeli `modes`
--
ALTER TABLE `modes`
MODIFY `mode_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=5;
--
-- AUTO_INCREMENT dla tabeli `positions`
--
ALTER TABLE `positions`
MODIFY `position_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT dla tabeli `seasons`
--
ALTER TABLE `seasons`
MODIFY `season_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT dla tabeli `teams`
--
ALTER TABLE `teams`
MODIFY `team_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=877;
--
-- AUTO_INCREMENT dla tabeli `users`
--
ALTER TABLE `users`
MODIFY `user_id` int(10) unsigned NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=665;
--
-- Ograniczenia dla zrzutów tabel
--

--
-- Ograniczenia dla tabeli `games`
--
ALTER TABLE `games`
ADD CONSTRAINT `games_mode_id_foreign` FOREIGN KEY (`mode_id`) REFERENCES `modes` (`mode_id`),
ADD CONSTRAINT `games_team1_id_foreign` FOREIGN KEY (`team1_id`) REFERENCES `teams` (`team_id`),
ADD CONSTRAINT `games_team2_id_foreign` FOREIGN KEY (`team2_id`) REFERENCES `teams` (`team_id`);

--
-- Ograniczenia dla tabeli `position_user`
--
ALTER TABLE `position_user`
ADD CONSTRAINT `position_user_position_id_foreign` FOREIGN KEY (`position_id`) REFERENCES `positions` (`position_id`),
ADD CONSTRAINT `position_user_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Ograniczenia dla tabeli `team_user`
--
ALTER TABLE `team_user`
ADD CONSTRAINT `team_user_team_id_foreign` FOREIGN KEY (`team_id`) REFERENCES `teams` (`team_id`),
ADD CONSTRAINT `team_user_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Ograniczenia dla tabeli `users`
--
ALTER TABLE `users`
ADD CONSTRAINT `users_access_id_foreign` FOREIGN KEY (`access_id`) REFERENCES `accesses` (`access_id`),
ADD CONSTRAINT `users_lastgame_id_foreign` FOREIGN KEY (`lastgame_id`) REFERENCES `games` (`game_id`);

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
