
drop database crypto_project;
create database crypto_project;
use crypto_project;
create table users (uid int primary key auto_increment,
username varchar(50) not null unique,
email varchar(100) not null unique,
password_hash varchar(255) not null,
created_at datetime default current_timestamp);

create table wallets(
wallet_id int primary key auto_increment,
uid int not null,
wallet_name varchar(50) not null,
wallet_type varchar(30),
created_at datetime default current_timestamp,
foreign key(uid)references users(uid)
ON UPDATE CASCADE
ON DELETE RESTRICT);

create table coins(
coin_id int primary key auto_increment,
symbol varchar(10) not null unique,
name varchar(50) not null,
current_price decimal(18,8) not null,
metadata json,
created_at datetime default current_timestamp);

create table wallet_coins(
wallet_id int not null,
coin_id int not null,
balance decimal(24,8) not null default 0,
average_buy_price decimal(24,8) not null default 0,
updated_at datetime default current_timestamp on update current_timestamp, 
primary key(wallet_id,coin_id),
foreign key(coin_id) references coins(coin_id)
ON UPDATE CASCADE
ON DELETE RESTRICT,
foreign key(wallet_Id)references wallets(wallet_id)
ON UPDATE CASCADE
ON DELETE RESTRICT
);

create table orders(
order_id int primary key auto_increment,
wallet_id int not null,
uid int not null,
coin_id int not null,
order_type enum('market','limit') not null,
side enum('buy','sell') not null,
price decimal(18,8),
quantity decimal(24,6) not null,
status enum('pending','filled','cancelled') default 'pending',
created_at datetime default current_timestamp,
foreign key(uid) references users(uid)
ON UPDATE CASCADE
ON DELETE RESTRICT,
foreign key (wallet_id) references wallets(wallet_id)
ON UPDATE CASCADE
ON DELETE RESTRICT,
foreign key(coin_id) references coins(coin_id)
ON UPDATE CASCADE
ON DELETE RESTRICT
);

create table trades(
trade_id int primary key auto_increment,
order_id int not null,
uid int not null,
wallet_id int not null,
coin_id int not null,
trade_price decimal(18,8) not null,
trade_quantity decimal(24,8) not null,
trade_type enum('buy','sell') not null,
trade_time datetime default current_timestamp,
foreign key(order_id) references orders(order_id)
ON UPDATE CASCADE
ON DELETE RESTRICT,
foreign key(uid) references users(uid)
ON UPDATE CASCADE
ON DELETE RESTRICT,
foreign key(wallet_id) references wallets(wallet_id)
on update cascade
on delete restrict,
foreign key(coin_id) references coins(coin_id)
ON UPDATE CASCADE
ON DELETE RESTRICT);

INSERT INTO users (username, email, password_hash)
VALUES 
('frank', 'frank@example.com', 'hashed_password_1'),
('alice', 'alice@example.com', 'hashed_password_2');

INSERT INTO wallets (uid, wallet_name, wallet_type)
VALUES
(1, 'Frank Spot Wallet', 'spot'),
(1, 'Frank Funding Wallet', 'funding'),
(2, 'Alice Spot Wallet', 'spot');

INSERT INTO coins (symbol, name, current_price, metadata)
VALUES
('BTC', 'Bitcoin', 65000.00000000, '{"network": "Bitcoin", "rank": 1}'),
('ETH', 'Ethereum', 3200.00000000, '{"network": "Ethereum", "rank": 2}'),
('BNB', 'BNB', 600.00000000, '{"network": "BNB Chain", "rank": 4}');

INSERT INTO wallet_coins (wallet_id, coin_id, balance, average_buy_price)
VALUES
(1, 1, 0.50000000, 60000.00000000),
(1, 2, 10.00000000, 3000.00000000),
(2, 3, 5.00000000, 550.00000000);

INSERT INTO orders (wallet_id, uid, coin_id, order_type, side, price, quantity, status)
VALUES
(1,1, 1, 'limit', 'buy', 62000.00000000, 0.10000000, 'pending'),
(1,1, 2, 'market', 'sell', NULL, 1.00000000, 'filled');

INSERT INTO trades (order_id, uid, wallet_id, coin_id, trade_price, trade_quantity, trade_type)
VALUES
(2, 1, 1,2, 3180.00000000, 1.00000000, 'sell');


SELECT * FROM users;
SELECT * FROM coins;
SELECT * FROM wallets;
SELECT * FROM wallet_coins;
SELECT * FROM orders;
SELECT * FROM trades;
insert into wallets(uid,wallet_name,wallet_type)
values (999,'fake wallet','spot')

-- 查询用户的钱包资产
select u.uid, w.wallet_name, c.symbol, wc.balance, c.current_price, 
wc.balance*c.current_price as total_value
from users u
join wallets w  using(uid)
join wallet_coins wc using (wallet_id)
join coins c using(coin_id)

-- 查询某个用户的订单
select u.uid, c.symbol, o.order_type, o.side, o.price, o.quantity, o.status , o.created_at
from orders o
join users u using (uid)
join coins c using(coin_id)
where u.uid=1;

-- 查询交易记录
select t.trade_id, u.uid, c.symbol, t.trade_type, t.trade_price, t.trade_quantity, 
t.trade_price*t.trade_quantity as trade_value, 
t.trade_time 
from trades t
join users u using(uid)
join coins c using(coin_id)

-- 查询每个钱包总价值
select w.wallet_name, sum(wc.balance*c.current_price) as wallet_total_value
from wallets w
join wallet_coins wc using(wallet_id)
join coins c using(coin_id)
group by w.wallet_id, w.wallet_name;

-- about the trigger 自动更新余额


delimiter $$
drop trigger if exists buy_coins;
create trigger buy_coins
after insert on trades 
for each row
begin
update wallet_coins set balance=balance+ new.trade_quantity
where wallet_id=new.wallet_id and coin_id=new.coin_id;
end$$ 
delimiter ;

-- procedure 统计盈利
delimiter $$
drop procedure if exists get_user_total_asset;
create procedure get_user_total_asset(input_uid int)
begin select u.username, sum(wc.balance*c.current_price) as total_asset_value
from users u
join wallets w using(uid)
join wallet_coins wc using(wallet_id)
join coins c using(coin_id)
where u.uid=input_uid
group by u.uid, u.username;
end $$
delimiter ;
call get_user_total_asset(1);

-- 测试json查询
select symbol, name, metadata->>'$.network' as network,
                     metadata->>'$.rank' as coin_rank
from coins;
