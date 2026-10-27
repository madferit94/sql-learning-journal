-- Schema only; obtain source data separately. CREATE DATABASE requires an unused database name.
SET NAMES utf8mb4;
SET SESSION sql_mode='STRICT_ALL_TABLES,NO_BACKSLASH_ESCAPES';
CREATE DATABASE f1_study CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE f1_study;
CREATE TABLE drivers (
`meeting_key` INT NOT NULL,
`session_key` INT NOT NULL,
`driver_number` INT NOT NULL,
`broadcast_name` VARCHAR(100),
`full_name` VARCHAR(100),
`name_acronym` VARCHAR(10),
`team_name` VARCHAR(100),
`team_colour` VARCHAR(10),
`first_name` VARCHAR(100),
`last_name` VARCHAR(100),
`headshot_url` TEXT,
`country_code` VARCHAR(10),
PRIMARY KEY (`session_key`, `driver_number`)
) ENGINE=InnoDB;
CREATE TABLE laps (
`meeting_key` INT NOT NULL,
`session_key` INT NOT NULL,
`driver_number` INT NOT NULL,
`lap_number` INT NOT NULL,
`date_start` VARCHAR(40),
`duration_sector_1` DECIMAL(12,3),
`duration_sector_2` DECIMAL(12,3),
`duration_sector_3` DECIMAL(12,3),
`i1_speed` DECIMAL(8,3),
`i2_speed` DECIMAL(8,3),
`is_pit_out_lap` BOOLEAN,
`lap_duration` DECIMAL(12,3),
`segments_sector_1` JSON,
`segments_sector_2` JSON,
`segments_sector_3` JSON,
`st_speed` DECIMAL(8,3),
PRIMARY KEY (`session_key`, `driver_number`, `lap_number`),
FOREIGN KEY (session_key, driver_number) REFERENCES drivers(session_key, driver_number)
) ENGINE=InnoDB;
CREATE TABLE stints (
`meeting_key` INT NOT NULL,
`session_key` INT NOT NULL,
`stint_number` INT NOT NULL,
`driver_number` INT NOT NULL,
`lap_start` INT,
`lap_end` INT,
`compound` VARCHAR(20),
`tyre_age_at_start` INT,
PRIMARY KEY (`session_key`, `driver_number`, `stint_number`),
FOREIGN KEY (session_key, driver_number) REFERENCES drivers(session_key, driver_number)
) ENGINE=InnoDB;

CREATE VIEW lap_details AS
SELECT l.*, d.full_name, d.name_acronym, d.team_name
FROM laps l JOIN drivers d
ON l.session_key=d.session_key AND l.driver_number=d.driver_number;

-- Added for 2026 multi-race result exercises; schema only.
CREATE TABLE sessions (
`session_key` INT NOT NULL,
`meeting_key` INT NOT NULL,
`year` INT NOT NULL,
`session_name` VARCHAR(40),
`session_type` VARCHAR(40),
`country_name` VARCHAR(100),
`country_code` VARCHAR(10),
`country_key` INT,
`location` VARCHAR(100),
`circuit_key` INT,
`circuit_short_name` VARCHAR(100),
`date_start` VARCHAR(40),
`date_end` VARCHAR(40),
`gmt_offset` VARCHAR(20),
`is_cancelled` BOOLEAN,
`grand_prix_name` VARCHAR(100),
`official_result_url` TEXT,
PRIMARY KEY (`session_key`)
) ENGINE=InnoDB;

CREATE TABLE race_results (
`meeting_key` INT NOT NULL,
`session_key` INT NOT NULL,
`driver_number` INT NOT NULL,
`position` INT,
`completed_laps` INT,
`status` VARCHAR(20),
`points` DECIMAL(8,2),
`dnf` BOOLEAN,
`dns` BOOLEAN,
`dsq` BOOLEAN,
`duration` DECIMAL(15,3),
`gap_to_leader` VARCHAR(40),
`official_position_label` VARCHAR(20),
`official_time_or_retired` VARCHAR(100),
`source_url` TEXT,
PRIMARY KEY (`session_key`,`driver_number`),
FOREIGN KEY (session_key) REFERENCES sessions(session_key),
FOREIGN KEY (session_key,driver_number) REFERENCES drivers(session_key,driver_number)
) ENGINE=InnoDB;
