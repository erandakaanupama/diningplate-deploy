-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema diningplate
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema diningplate
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `diningplate` DEFAULT CHARACTER SET utf8mb3 ;
USE `diningplate` ;

-- -----------------------------------------------------
-- Table `diningplate`.`customer`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `diningplate`.`customer` (
  `id` BINARY(16) NOT NULL,
  `name` VARCHAR(45) NOT NULL,
  `contact_no` VARCHAR(45) NOT NULL,
  `map_location` VARCHAR(2048) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `diningplate`.`item`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `diningplate`.`item` (
  `id` BINARY(16) NOT NULL,
  `name` VARCHAR(45) NOT NULL,
  `price` DECIMAL(10,2) NOT NULL,
  `description` VARCHAR(512) NULL DEFAULT NULL,
  `category` TINYINT NOT NULL,
  `available` TINYINT(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `diningplate`.`order`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `diningplate`.`order` (
  `id` BINARY(16) NOT NULL,
  `date_time` DATETIME NOT NULL,
  `customer_id` BINARY(16) NOT NULL,
  `status` TINYINT NOT NULL,
  `version` INT NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  INDEX `fk_customer_id_idx` (`customer_id` ASC) VISIBLE,
  CONSTRAINT `fk_customer_id`
    FOREIGN KEY (`customer_id`)
    REFERENCES `diningplate`.`customer` (`id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


-- -----------------------------------------------------
-- Table `diningplate`.`order_item`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `diningplate`.`order_item` (
  `order_id` BINARY(16) NOT NULL,
  `item_id` BINARY(16) NOT NULL,
  `count` INT NOT NULL,
  PRIMARY KEY (`order_id`, `item_id`),
  INDEX `fk_order_id_idx` (`order_id` ASC) VISIBLE,
  INDEX `fk_item_id_idx` (`item_id` ASC) VISIBLE,
  CONSTRAINT `fk_item_id`
    FOREIGN KEY (`item_id`)
    REFERENCES `diningplate`.`item` (`id`),
  CONSTRAINT `fk_order_id`
    FOREIGN KEY (`order_id`)
    REFERENCES `diningplate`.`order` (`id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
