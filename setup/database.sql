

CREATE TABLE `account` (
  `number` int(11) NOT NULL,
  `owner` int(11) NOT NULL,
  `name` varchar(255) NOT NULL DEFAULT 'Unnamed account',
  `balance` decimal(10,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`number`),
  KEY `owner` (`owner`),
  CONSTRAINT `account_ibfk_1` FOREIGN KEY (`owner`) REFERENCES `person` (`id`)
);



CREATE TABLE `card` (
  `id` int(11) NOT NULL,
  `account` int(11) NOT NULL,
  `hash` varchar(256) NOT NULL DEFAULT '',
  `name` varchar(255) NOT NULL DEFAULT 'Unnamed card',
  PRIMARY KEY (`id`),
  KEY `hash` (`hash`),
  KEY `account` (`account`),
  CONSTRAINT `card_ibfk_1` FOREIGN KEY (`account`) REFERENCES `account` (`number`)
);



CREATE TABLE `category` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL DEFAULT 'Unnamed',
  `parent` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `parent` (`parent`),
  CONSTRAINT `category_ibfk_1` FOREIGN KEY (`parent`) REFERENCES `category` (`id`)
);



CREATE TABLE `person` (
  `id` int(11) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
);





CREATE TABLE `purchase` (
  `id` int(11) NOT NULL,
  `product` int(11) NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `amount` decimal(10,3) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `product` (`product`),
  KEY `time` (`time`),
  CONSTRAINT `purchase_ibfk_1` FOREIGN KEY (`product`) REFERENCES `product` (`id`)
);



CREATE TABLE `shop` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `account` int(11) NOT NULL,
  `gamble_account` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`),
  KEY `account` (`account`),
  KEY `gamble_account` (`gamble_account`),
  CONSTRAINT `shop_ibfk_2` FOREIGN KEY (`gamble_account`) REFERENCES `account` (`number`),
  CONSTRAINT `shop_ibfk_1` FOREIGN KEY (`account`) REFERENCES `account` (`number`)
);



CREATE TABLE `shop_admin` (
  `shop` int(11) NOT NULL,
  `person` int(11) NOT NULL,
  PRIMARY KEY (`shop`,`person`),
  KEY `person` (`person`),
  CONSTRAINT `shop_admin_ibfk_2` FOREIGN KEY (`person`) REFERENCES `person` (`id`),
  CONSTRAINT `shop_admin_ibfk_1` FOREIGN KEY (`shop`) REFERENCES `shop` (`id`)
);



CREATE TABLE `sold_by` (
  `product` int(11) NOT NULL DEFAULT '0',
  `terminals` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`product`,`terminals`),
  KEY `terminals` (`terminals`),
  CONSTRAINT `sold_by_ibfk_2` FOREIGN KEY (`product`) REFERENCES `product` (`id`),
  CONSTRAINT `sold_by_ibfk_1` FOREIGN KEY (`terminals`) REFERENCES `terminal_group` (`id`)
);


CREATE TABLE `product` (
  `id` int(11) NOT NULL,
  `shop` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `ean` int(11) DEFAULT NULL,
  `unit` varchar(20) NOT NULL DEFAULT 'piece',
  `category` int(11) NOT NULL,
  `price` decimal(10,5) NOT NULL COMMENT 'Price per unit',
  `int_amount` bit(1) NOT NULL DEFAULT '1' COMMENT 'Is purchase amount restricted to integer amounts (e.g. pieces)?',
  `stock` decimal(10,5) NOT NULL DEFAULT '0.00000',
  `thumbnail` varchar(255) DEFAULT NULL,
  `picture` varchar(255) DEFAULT NULL,
  `discount_amt` decimal(10,3) DEFAULT NULL COMMENT 'The amount of this product to buy in order to get mass discount',
  `discount_price` decimal(10,5) DEFAULT NULL COMMENT 'The price per unit when buying more than discount_amt',
  PRIMARY KEY (`id`),
  KEY `ean` (`ean`),
  KEY `category` (`category`),
  KEY `shop` (`shop`),
  KEY `name` (`name`),
  CONSTRAINT `product_ibfk_2` FOREIGN KEY (`category`) REFERENCES `category` (`id`),
  CONSTRAINT `product_ibfk_1` FOREIGN KEY (`shop`) REFERENCES `shop` (`id`)
);


CREATE TABLE `terminal` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `has_barcode` bit(1) NOT NULL DEFAULT '0',
  `has_menu` bit(1) NOT NULL DEFAULT '0',
  `has_cardreader` bit(1) NOT NULL DEFAULT '0',
  `secret` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
);



CREATE TABLE `terminal_group` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `auto_insert` varchar(255) DEFAULT NULL COMMENT 'Comma-separated list of criteria. A pattern of 0,1,* will make all new terminals added without barcode, with menu and regardless of cardreader be added to this group by the software',
  PRIMARY KEY (`id`)
);



CREATE TABLE `terminal_group_member` (
  `terminal` int(11) NOT NULL DEFAULT '0',
  `terminal_group` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`terminal`,`terminal_group`),
  KEY `terminal_group` (`terminal_group`),
  CONSTRAINT `terminal_group_member_ibfk_2` FOREIGN KEY (`terminal_group`) REFERENCES `terminal_group` (`id`),
  CONSTRAINT `terminal_group_member_ibfk_1` FOREIGN KEY (`terminal`) REFERENCES `terminal` (`id`)
);



CREATE TABLE `transfer` (
  `id` int(11) NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `from_account` int(11) DEFAULT NULL COMMENT 'Account number, NULL for cash',
  `to_account` int(11) DEFAULT NULL COMMENT 'Account number, NULL for cash',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`),
  KEY `from_account` (`from_account`),
  KEY `to_account` (`to_account`),
  KEY `time` (`time`),
  CONSTRAINT `transfer_ibfk_2` FOREIGN KEY (`to_account`) REFERENCES `account` (`number`),
  CONSTRAINT `transfer_ibfk_1` FOREIGN KEY (`from_account`) REFERENCES `account` (`number`)
);

