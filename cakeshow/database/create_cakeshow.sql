DROP DATABASE IF EXISTS cakeshow;
CREATE DATABASE `cakeshow` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `cakeshow`;

DROP TABLE IF EXISTS `registrants`;
CREATE TABLE IF NOT EXISTS `registrants` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `firstname` varchar(120) NOT NULL,
  `lastname` varchar(120) NOT NULL,
  `address` text NOT NULL,
  `city` varchar(255) NOT NULL,
  `state` varchar(255) NOT NULL,
  `zipcode` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(30) NOT NULL,
  `dateregistered` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `password` varchar(20) default NULL,
  `lat` float(10,6) NOT NULL,
  `lng` float(10,6) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2183 ;

DROP TABLE IF EXISTS `signups`;
CREATE TABLE IF NOT EXISTS `signups` (
	`id` int unsigned NOT NULL auto_increment,
	`registrantid` int(10) NOT NULL,
	`year` YEAR NOT NULL,
	`registrationTime` ENUM('early','late','student','child') NULL,
	`class` ENUM('adultint','culstudent','adultbeg','professional','junior','adultadv','child','teen','masters') NULL,
	`childage` int,
	`paid` tinyint unsigned,
	`totalfee` int,
	`signupshowcase` tinyint unsigned,
	`hotelinfo` tinyint unsigned,
	`electricity` tinyint unsigned,
	`paymentmethod` ENUM('instore','mail','paypal') NULL,
	PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `entries`;
CREATE TABLE IF NOT EXISTS `entries` (
	`id` int unsigned NOT NULL auto_increment,
	`registrantid` int(10) NOT NULL,
	`signupid` int NOT NULL,
	`year` YEAR NOT NULL,
	`category` ENUM('showcase','style1','style2','style3','style4','style5','style6','style7','special1','special2','special3','special4','special5','cupcakes','tasting') NOT NULL,
	`didBring` tinyint unsigned,
	`styleChange` tinyint unsigned,
	PRIMARY KEY (`id`)
);

