
create database hospital;
use hospital;


create table department(
dept_id int primary key auto_increment,
department_name varchar(80) not null);


create table doctors(
doctor_id int auto_increment,
dept_id int,
doctor_name varchar(100) not null,
doctor_details json,
primary key(doctor_id , dept_id),
foreign key (dept_id) references department(dept_id));


create table patients(
patient_id int primary key auto_increment,
doctor_id int not null,
patient_name varchar(50) not null,
patient_details json ,
reason varchar(100), 
foreign key (doctor_id) references doctors(doctor_id));

create table inventory(
inventory_id int primary key auto_increment,
inventory_item varchar(100) not null, 
quantity int not null check(quantity > 0) default 1,
price int not null check(price >= 0),
ordered_date datetime default current_timestamp);

create table pharmacy(
medicine_id int  auto_increment,
medicine_name varchar(100) not null,
dosage varchar(10) not null,
stock int not null check(stock > 0),
price int not null check(price > 0),
used_for varchar(100),
supplier varchar(100),
primary key (medicine_id, dosage) 
);

create table appointments(
appointment_id int primary key auto_increment,
patient_id int not null,
doctor_id int not null,
patient_name varchar(50),
appointment_timming date default (current_date),
foreign key (doctor_id) references doctors(doctor_id),
foreign key (patient_id) references patients(patient_id) on update cascade);



create table orders(
order_id int primary key auto_increment,
order_type enum("machines", "beds", "surgery items", "medicines", "equipments"),
quantity int not null check(quantity > 0),
price int not null check(price > 0),
order_details json,
payment_method varchar(80),
ordered_date datetime default current_timestamp);

create table payment(
payment_id int primary key auto_increment,
payment_method varchar(100), 
payment_details json,
payment_made_date datetime default current_timestamp);







