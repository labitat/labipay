
DROP TABLE IF EXISTS person, account, card, transfer, shop, shop_admin, category, product, purchase, terminal, terminal_group, terminal_group_member, sold_by CASCADE;

SET storage_engine=INNODB;


CREATE TABLE person (
       id    	      int		primary key auto_increment,
       name  	      varchar(255)	null,
       username	      varchar(255)      null
);


CREATE TABLE account (
       number	      int		primary key auto_increment,
       owner	      int		not null,
       name	      varchar(255)	not null default 'Unnamed account',
       balance	      decimal(10,2)	not null default 0,

       CONSTRAINT FOREIGN KEY (owner) REFERENCES person (id)
);


CREATE TABLE card (
       id	      int		primary key auto_increment,
       account	      int		not null,
       hash	      varchar(256)	not null default '',
       name	      varchar(255)	not null default 'Unnamed card',

       INDEX (hash),
       CONSTRAINT FOREIGN KEY (account) REFERENCES account (number)
);


CREATE TABLE transfer (
       id    	      int		primary key auto_increment,
       time	      timestamp		not null default CURRENT_TIMESTAMP,
       from_account   int		null comment 'Account number, NULL for cash',
       to_account     int               null comment 'Account number, NULL for cash',
       amount	      decimal(10,2)	not null default 0,

       INDEX (from_account),
       INDEX (to_account),
       INDEX (time),
       CONSTRAINT FOREIGN KEY (from_account) REFERENCES account (number),
       CONSTRAINT FOREIGN KEY (to_account) REFERENCES account (number)
);


CREATE TABLE shop (
       id	      int		primary key auto_increment,
       name	      varchar(255)	not null,
       account	      int		not null,
       gamble_account int		null,

       INDEX (name),
       CONSTRAINT FOREIGN KEY (account) REFERENCES account (number),
       CONSTRAINT FOREIGN KEY (gamble_account) REFERENCES account (number)

);


CREATE TABLE shop_admin (
       shop  	      int               not null references shop (id),
       person	      int		not null references person (id),
       
       PRIMARY KEY (shop, person),
       CONSTRAINT FOREIGN KEY (shop) REFERENCES shop (id),
       CONSTRAINT FOREIGN KEY (person) REFERENCES person (id)
);


CREATE TABLE category (
       id    	      int		primary key auto_increment,
       name	      varchar(255)	not null default 'Unnamed',
       parent	      int		null,
       
       INDEX (parent),
       CONSTRAINT FOREIGN KEY (parent) REFERENCES parent (id)
);


CREATE TABLE product (
       id    	      int		primary key auto_increment,
       shop	      int		not null,
       name	      varchar(255)	not null,
       ean	      int		null,
       unit	      varchar(20)	not null default 'piece',
       category	      int		not null,
       price	      decimal(10,5)	not null comment 'Price per unit',
       int_amount     bit		not null default 1 comment 'Is purchase amount restricted to integer amounts (e.g. pieces)?',
       stock          decimal(10,5)	not null default 0,
       thumbnail      varchar(255)	null,
       picture	      varchar(255)	null,
       discount_amt   decimal(10,3)	null comment 'The amount of this product to buy in order to get mass discount',
       discount_price decimal(10,5)	null comment 'The price per unit when buying more than discount_amt',

       INDEX (ean),
       INDEX (category),
       INDEX (shop),
       INDEX (name),
       CONSTRAINT FOREIGN KEY (shop) REFERENCES shop (id),
       CONSTRAINT FOREIGN KEY (category) REFERENCES category (id),
);


CREATE TABLE purchase (
       id    	      int		primary key auto_increment,
       product	      int		not null,
       time	      timestamp		not null default CURRENT_TIMESTAMP,
       amount	      decimal(10,3)	not null,
       price	      decimal(10,2)	not null,

       INDEX (product),
       INDEX (time),
       CONSTRAINT FOREIGN KEY (product) REFERENCES product (id),
);


CREATE TABLE terminal (
       id    	      int		primary key auto_increment,
       name	      varchar(255)	not null,
       has_barcode    bit		not null default 0,
       has_menu	      bit		not null default 0,
       has_cardreader bit		not null default 0,
       secret	      varchar(255)	not null
);


CREATE TABLE terminal_group (
       id             int		primary key auto_increment,
       name	      varchar(255)	not null,
       auto_insert    varchar(255)	null comment 'Comma-separated list of criteria. A pattern of 0,1,* will make all new terminals added without barcode, with menu and regardless of cardreader be added to this group by the software'
);

CREATE TABLE terminal_group_member (
       terminal	      int,
       terminal_group int,

       PRIMARY KEY (terminal, terminal_group),
       CONSTRAINT FOREIGN KEY (terminal) REFERENCES terminal (id),
       CONSTRAINT FOREIGN KEY (terminal_group) REFERENCES terminal_group (id)
);


CREATE TABLE sold_by (
       product	      int,
       terminals      int,

       PRIMARY KEY (product, terminals),
       CONSTRAINT FOREIGN KEY (product) REFERENCES product (id),
       CONSTRAINT FOREIGN KEY (terminals) REFERENCES terminal_group (id)
);  
