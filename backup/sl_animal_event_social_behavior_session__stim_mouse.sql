-- MySQL dump 10.13  Distrib 8.0.20, for macos10.15 (x86_64)
--
-- Host: localhost    Database: sl
-- ------------------------------------------------------
-- Server version	8.0.20

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `animal_event_social_behavior_session__stim_mouse`
--

DROP TABLE IF EXISTS `animal_event_social_behavior_session__stim_mouse`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `animal_event_social_behavior_session__stim_mouse` (
  `event_id` int unsigned NOT NULL,
  `arm` enum('A','B','C') NOT NULL COMMENT 'location of the mouse in the arena',
  `stimulus_mouse` int unsigned NOT NULL COMMENT 'unique animal id',
  PRIMARY KEY (`event_id`,`arm`,`stimulus_mouse`),
  KEY `h24c1YRU` (`stimulus_mouse`),
  CONSTRAINT `h24c1YRU` FOREIGN KEY (`stimulus_mouse`) REFERENCES `animal` (`animal_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `Owmb9LiF` FOREIGN KEY (`event_id`) REFERENCES `animal_event_social_behavior_session` (`event_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `animal_event_social_behavior_session__stim_mouse`
--

LOCK TABLES `animal_event_social_behavior_session__stim_mouse` WRITE;
/*!40000 ALTER TABLE `animal_event_social_behavior_session__stim_mouse` DISABLE KEYS */;
/*!40000 ALTER TABLE `animal_event_social_behavior_session__stim_mouse` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-07-06 20:55:45
