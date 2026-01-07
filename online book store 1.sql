create database online_book_store;
use online_book_store;

-- creating customer with details

create table customer(
customer_id int primary key auto_increment,
customer_name varchar(50) not null,
phn_num varchar(15),
email_id varchar(50) not null unique,
address varchar(100),
customer_gender enum('M', 'F') default null,
preferences json, -- favriotes, most_read book
is_active bool default 0);

-- genre table

create table genre(
genre_id int primary key auto_increment,
genre_name varchar(50) not null unique);

-- author details

create table author(
author_id int primary key auto_increment,
author_name varchar(50) not null unique,
author_age int,
author_dob date,
nationality varchar(20),
bio json);

-- books and its details

create table books(
book_id int primary key auto_increment,
title varchar(50) not null,
author_id int not null,
genre_id int ,
book_price decimal(10,2),
publish_date date,
stock_quantity int check(stock_quantity >= 0),
book_details json, -- edition, language, format, publisher, keywords
foreign key (genre_id) references genre(genre_id) on delete set null,
foreign key (author_id) references author(author_id) on delete cascade,
index idx_title (title));

-- shopping cart that customer uses to store 

create table shopping_cart(
shop_cart_id int primary key auto_increment,
customer_id int not null,
created_at datetime default current_timestamp,
foreign key (customer_id) references customer(customer_id) on delete cascade);

-- items in the cart that custoer stored

create table cart_item(
cart_item_id int primary key auto_increment,
shop_cart_id int not null,
book_id int not null,
quantity int not null check (quantity > 0),
customization json, -- store gift-wrapping, personalization messages
foreign key (shop_cart_id) references shopping_cart(shop_cart_id) on delete cascade,
foreign key (book_id) references books(book_id));


-- orders placed by customer

create table orders(
order_id int primary key auto_increment,
customer_id int,
order_status enum('pending','confirmed','shipped','delivered','cancelled') default 'pending',
delivery_address varchar(100),
order_date date not null default(curdate()),
foreign key (customer_id) references customer(customer_id));


-- items purchased by customer

create table order_item(
    order_item_id int primary key auto_increment,
    order_id int not null,
    book_id int not null,
    quantity int not null check (quantity > 0),
    final_price decimal(10,2) not null, -- locked price at checkout
    customization json, -- copy gift-wrap/personalization
    foreign key (order_id) references orders(order_id) on delete cascade,
    foreign key (book_id) references books(book_id)
);

-- reviews on the books given by customer

create table book_review(
review_id int primary key auto_increment,
customer_id int,
book_id int not null,
rating int check (rating between 0 and 5),
review_text varchar(100),
created_date datetime default current_timestamp,
foreign key (customer_id) references customer(customer_id) on delete set null,
foreign key (book_id) references books(book_id));

-- customer's subscription

create table subscription(
subscription_id int primary key auto_increment,
customer_id int not null,
start_date datetime not null default current_timestamp,
end_date datetime not null,
subscription_type enum('basic', 'plus', 'premium'),
subscription_benefits json, -- access level, perks, freebooks/month
foreign key (customer_id) references customer(customer_id) on delete cascade);

-- promo_code --> discounts

create table promotion(
promotion_id int primary key auto_increment,
promo_code varchar(15) unique,
discount decimal(4,2) check(discount <= 100),
start_date datetime default current_timestamp,
end_date datetime );


-- payments done by customer and its details

create table payment(
payment_id int primary key auto_increment,
customer_id int,
order_id int not null,
payment_method enum('cash on delivery', 'google-pay', 'debit-card', 'credit-card') not null,
amount decimal(10,2) not null check(amount > 0),
promotion_id int,
discount decimal (4,2) check(discount <= 100),
payment_status enum('completed', 'pending', 'failed', 'cancelled') default 'pending',
payment_details json, -- UPI ref, card last digits, bank info
payment_done_date datetime not null default current_timestamp,
foreign key (order_id) references orders(order_id) ,
foreign key (customer_id) references customer(customer_id),
foreign key (promotion_id) references promotion (promotion_id));

-- adding payment method --> wallet 

alter table payment
modify column payment_method enum('cash on delivery', 'google-pay', 'debit-card', 'credit-card', 'wallet') not null;


-- logs on everything happening in book store

create table activity_log(
log_id int primary key auto_increment,
customer_id int,
book_id int ,
order_id int null,
user_activity varchar(50),
created_at datetime default current_timestamp,
foreign key (customer_id)references customer(customer_id),
foreign key (order_id) references orders(order_id),
foreign key (book_id) references books(book_id));

-- changing the character length for user_activity

alter table activity_log
modify column user_activity varchar(200);


-- customer wallet to store stored-points as balance to redeem

create table wallet (
wallet_id int primary key auto_increment,
customer_id int unique,
balance decimal(10,2) check (balance > 0) default 0,
lastly_updated datetime default now(),
foreign key (customer_id) references customer(customer_id));

-- adding reward_points in wallet for each customer

alter table wallet
add column reward_points decimal (10,2) check (reward_points >= 0) default 0;

-- delivery details

create table shipment(
shipment_id int primary key auto_increment,
order_id int not null,
shipment_status enum('delivered', 'delayed', 'pending', 'shipped','cancelled'),
created_at datetime default current_timestamp,
delivery_date datetime,
foreign key (order_id) references orders(order_id));


 -- fetching customer details
 
delimiter &&
create procedure customer_details(in cust_id int)
begin
select group_concat(distinct concat( c.customer_name, '-->' , c.email_id, '-->', c.customer_gender, '-->', c.preferences, '-->', c.is_active) separator '\n') customer_bio, 
sb.subscription_type, group_concat(distinct b.title separator '\n ') books_purchased, 
sum(oi.quantity) total_quantity, sum(oi.quantity * oi.final_price) amount_spent, group_concat(distinct al.user_activity separator '\n') log_on_history
from customer c 
join subscription sb on sb.customer_id = c.customer_id
join activity_log al on al.customer_id = c.customer_id
join orders o on o.customer_id = c.customer_id
join order_item oi on oi.order_id = o.order_id
join books b on b.book_id = oi.book_id
join book_review br on br.book_id = b.book_id
where c.customer_id = cust_id
group by c.customer_id,sb.subscription_type;
end &&
delimiter ;

call customer_details(3);

-- fetching author details

delimiter &&
create procedure author_details(in author_id int)
begin
select a.author_name, a.author_age, a.author_dob, a.nationality, a.bio,
group_concat(distinct b.title separator '\n') books_written, count(oi.book_id) books_sold, sum(oi.quantity * oi.final_price) total_revenue
from author a
join books b on b.author_id = a.author_id
join order_item oi on oi.book_id = b.book_id
where a.author_id = author_id
group by a.author_id,a.author_name, a.author_age, a.author_dob, a.nationality;
end &&
delimiter ;

call author_details(5);


-- ranking the author based on book's sold

create view author_rank as
select 
dense_rank() over (order by books_sold desc) as ranks,
author_name, books_written, books_sold, total_revenue
from (
select a.author_name, group_concat(distinct b.title separator '\n') books_written, 
count(oi.book_id) books_sold, sum(oi.quantity * oi.final_price) total_revenue
from author a
join books b on b.author_id = a.author_id
join order_item oi on oi.book_id = b.book_id
group by a.author_id, a .author_name) as subsitute;

select * from author_rank order by ranks ;

 
 
 -- fetching order details
 
delimiter &&
create procedure order_details(in cust_no int)
begin
select o.order_id, o.order_status, 
sum(oi.quantity) total_quantity , sum(oi.quantity * oi.final_price) amount_spent,
group_concat(concat(pm.payment_method, ' -> ', pm.payment_status, ' -> ', pm.payment_done_date)
order by pm.payment_done_date separator '\n ')  payments_summary, sh.shipment_status
from orders o 
join order_item oi on o.order_id = oi.order_id
join payment pm on pm.order_id = o.order_id
join shipment sh on sh.order_id = o.order_id
where o.customer_id = cust_no
group by o.order_id, sh.shipment_status;
end &&
delimiter ;

call order_details(1);


-- creating procedure for payment update/insert triggers

delimiter &&
create procedure set_order_status(
in payment_order_no int, 
in payment_stat enum('completed','pending','failed','cancelled'))
begin
case payment_stat
when 'failed' then 
update orders
set order_status = 'pending'
where order_id = payment_order_no;
when 'completed'then
update orders
set order_status = 'confirmed'
where order_id = payment_order_no;
when 'cancelled'then
update orders
set order_status = 'cancelled'
where order_id = payment_order_no;
end case;
end &&
delimiter ;


-- using trigger on payment inserts and updates

delimiter &&
create trigger tg_after_insert_payment_update_order
after insert on payment
for each row
begin
call set_order_status(new.order_id, new.payment_status);
end &&

create trigger tg_after_update_payment_update_order
after update on payment
for each row
begin
call set_order_status(new.order_id, new.payment_status);
end &&
delimiter ;


-- setting event_scheduler ON
set global event_scheduler = on;


-- checking expiration on subscription on every day

delimiter &&
create event daily_expiration_check
on schedule every 1 day
starts now() + interval 1 day
do
begin

update subscription
set subscription_type = null
where end_date < current_timestamp() and subscription_type is not null;

insert into activity_log (customer_id, user_activity) 
select sb.customer_id, 'expired subscription' from subscription sb
where subscription_type is null and end_date < current_timestamp() and 
customer_id not in (select customer_id from activity_log where user_activity = 'expired subscription');

end &&
delimiter ;

-- auto apply discount when payment inserted

delimiter &&
create trigger tg_before_insert_payment_apply_discount
before insert on payment
for each row
begin
if new.promotion_id is not null then
set new.discount = ( select discount from promotion where promotion_id = new.promotion_id );
end if;
end &&
delimiter ;


-- checks if stocks are enough for placing order

delimiter &&
create trigger tg_before_insert_order_item_check_stocks
before insert on order_item
for each row
begin
declare stocks_available int ;

select stock_quantity into stocks_available from books 
where books.book_id = new.book_id;

if stocks_available < new.quantity or stocks_available < 0 then
signal sqlstate '45000' set message_text = 'not enough stocks';
end if;
end &&
delimiter ;


-- auto - inverntory update check after placing an order

delimiter &&
create trigger tg_after_insert_order_item_update_stocks
after insert on order_item 
for each row
begin
update books
set stock_quantity = stock_quantity - new.quantity
where books.book_id = new.book_id;
end &&
delimiter ;


-- if the order is cancelled then re-stocks and refunds

delimiter &&
create trigger tg_after_delete_order_item_update_stocks
after delete on order_item
for each row
begin
declare cust_id int;

select o.customer_id into cust_id from orders o
where order_id = old.order_id;

update books
set stock_quantity = stock_quantity + old.quantity
where book_id  = old.book_id;

update wallet
set balance = balance + old.final_price
where customer_id = cust_id;
end &&
delimiter ;

-- altering books table to add column for auto_price increase

alter table books 
add column last_price_increase int default 0;


-- price increase of 10% for every 50 books that sold

delimiter &&
create trigger tg_after_50_books_sold_price_update
after insert on order_item
for each row
begin
declare quantity_sold int;
select coalesce(sum(quantity), 0) into quantity_sold from order_item 
where book_id = new.book_id;
if  quantity_sold - (select last_price_increase from books where book_id = new.book_id) >= 50 then
update books
set book_price = book_price * 1.10,
last_price_increase = quantity_sold
where book_id = new.book_id;
end if;
end &&
delimiter ;

-- if payment method is through wallet auto-deduct in balance and complete the payment

delimiter &&
create trigger tg_if_payment_method_is_wallet_then_deduct
before insert on payment
for each row
begin
declare wallet_balance decimal(10,2);

if new.payment_method = 'wallet' then
select balance into wallet_balance from wallet 
where customer_id = new.customer_id; 

	if  wallet_balance < new.amount then
    signal sqlstate '45000' set message_text = 'not enough wallet - balance to make payment';
    else
    update wallet
    set balance = balance - new.amount,
    lastly_updated = now()
    where customer_id = new.customer_id;
    
    set new.payment_status = 'completed';
    end if;
end if;
end &&
delimiter ;


-- for every 100 ruppees 1 reward_point and cashback added to wallet

delimiter &&
create trigger tg_after_order_item_update_balance_for_every_100_1_point
after insert on order_item
for each row
begin
declare cust_id int;
declare store_points int;
declare cashback decimal(10,2);

select customer_id into cust_id from orders where order_id = new.order_id;

set store_points = floor(new.final_price / 100);
set cashback = round(store_points / 10 , 2);

update wallet
set reward_points = reward_points + store_points,
balance = balance +  cashback
where customer_id = cust_id;

insert into activity_log (customer_id, book_id, order_id, user_activity, created_at) values (
cust_id, new.book_id, new.order_id, 
concat('reward-points (' , store_points , ' points ) and cashback in the amount of (', cashback ,')' ), 
now());

end &&
delimiter ;


