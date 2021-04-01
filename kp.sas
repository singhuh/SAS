/*How many individuals do we have address info for?*/
/*Is there anybody we have birth_date for, but no address info? Who?*/
/*Is there anybody we have address info on, but no birth_date? Who?*/
/*What's the longest time a person lived at the same address? Who and where was that?*/
/*Are there any addresses that more than one person lived at?*/
/*Are there any addresses that more than one person lived at AT THE SAME TIME?*/
/*For whom do we have multiple inconsistent addresses over the same time period (however short)?*/
/*Of the people appearing in location_periods, who has the longest gap in address info?*/
/*How would you go about adding a new variable to location_periods that tells you how many different addresses the person lived at in the prior 6 months. How would you go about creating that variable?*/
/*Open-ended:  What kind of data quality checks would you want to do for people? For location_periods? Do any records fail them? Tell us the problems in these tables.*/

ods pdf file = "D:/kp_pa.pdf"
contents = yes pdftoc = 2;

/*********************************************************
IMPORTING AND DATA QUALITY CHECKING FOR THE 'people' TABLE
*********************************************************/

/*Importing the 'people' sheet from the Excel file*/
proc import out = people
datafile = "D:\PA_TechnicalQuestions.xlsx"
dbms = excel replace;
sheet = "people";
getnames = YES;
mixed = YES;
scantext = YES;
usedate = YES;
scantime = YES;
run;

/*printing the first 5 observations from 'people' SAS file*/
proc print data = people (obs = 5); 
run;

/*printing the contents of the 'people' table*/
ods select Variables;
proc contents data = people; 
title " ";
run;

/*Changing the character format of birth_date to date format*/
data people; set people;
format bdate mmddyy10.;
bdate = input(birth_date, ANYDTDTE21.); /*ANYDTDTEw. format attempts to convert a character string into a date*/
run;

/*Reprinting the contents of the 'people' dataset after converting char format of birth_date to date format*/
ods select Variables;
proc contents data = people; 
title "Contents of the 'people' dataset after converting char format to date format";
run;


/*******************************************************************
IMPORTING AND DATA QUALITY CHECKING FOR THE 'location_periods' TABLE
*******************************************************************/

/*Importing the 'location_periods' sheet from the Excel file*/
proc import out = location_periods
datafile = "D:\PA_TechnicalQuestions.xlsx"
dbms = excel replace;
sheet = "location_periods";
getnames = YES;
mixed = YES;
scantext = YES;
usedate = YES;
scantime = YES;
run;

/*printing the first 5 observations from 'location_periods' SAS file*/
proc print data = location_periods (obs = 5); 
run;

/*printing the contents of the 'location_periods' table*/
ods select Variables;
proc contents data = location_periods; 
title "Table contents";
run;


ods pdf close;


proc freq data=people;
   tables _character_;
run;





proc print data = lp; run;

proc sort data = people; by person; run;
proc sort data = lp; by person; run;
data people_places; merge  people (in = in1) lp (in=in2); by person; run;


proc sql;
select count(distinct(person)) as person_count
	from people_places
	where bdate is not null and street_address is null;
quit;

proc sql;
select person as person_name, 
	bdate, 
	street_address
	from people_places
	where bdate is not null and street_address is null;
quit;



proc sql;
select count(distinct(person)) as person_count
	from people_places
	where street_address is not null and bdate is null;
quit;

proc sql;
select person as person_name, 
	bdate, 
	street_address
	from people_places
	where street_address is not null and bdate is null;
quit;



proc sql;
select person, 
count(distinct street_address) as total_addresses,
count(*) as NObs
from people_places
group by person;
quit;

proc sql;
select * from
(select person, 
count(distinct street_address) as total_addresses,
count(*) as NObs
from people_places
group by person)
having total_addresses < NObs and total_addresses > 0;
quit;
proc contents data = people_places short; run;
proc sort data = people_places;
by person start_date street_address;
run;

data people_places2; retain add_count;set people_places;
by person start_date street_address;
if first.person & first.start_date & first.street_address then do;
add_count=0; 
end;
add_count+1;
output;
run;



data people_places2; set people_places2;
retain prev_street_address;
output;
prev_street_address = street_address;
run;
data people_places2; set people_places2;
by person;
if first.person = 0 and prev_street_address ne " " and prev_street_address = street_address then dup_add="Yes";
else dup_add="No";
if first.person then prev_street_address = " " ;
if first.person then dup_add="NA";
run;
proc print; run;
proc print data = people_places2; 
where dup_add = "Yes"; run;
proc freq data = people_places2;
table dup_add;
run;



proc sql;
select distinct person, street_address, 
start_date, end_date,
COUNT(street_address) AS NumOccurrences
FROM people_places2
GROUP BY street_address
HAVING (COUNT(street_address) > 1 )
;
quit;

proc sql;
select distinct person, street_address, 
start_date, end_date,
COUNT(street_address) AS NumOccurrences
FROM people_places2
GROUP BY street_address
HAVING (COUNT(street_address) > 1 ) and start_date
;
quit;

data lp2 ; set lp;
run;


proc sql; 
select a.person
from lp as a
join lp as b
on a.person = b.person
where a.street_address = b.street_address
	and a.start_date <> b.start_date
	and a.person <> b.person;
quit;

proc sql; 
select a.person
from lp as a
join lp as b
on a.person = b.person
where a.street_address = b.street_address
	and a.start_date = b.start_date
	and a.person ^= b.person;
quit;


proc sql; 
SELECT person, street_address
/* COUNT(person) AS NumOccurrences*/
FROM lp
GROUP BY start_date
HAVING (count(street_address) = 1 ) and (count(person) = 1 ) 
;
quit;

proc sql;
SELECT 
a.person, a.street_address, a.start_date 
from sheet2 a 
inner join sheet2 b 
on a.person=b.person and a.street_address=b.street_address and a.start_date<>b.start_date;
quit;

proc sql;
SELECT 
a.person, a.street_address, a.start_date 
from lp a 
inner join lp b 
on a.person<>b.person and a.street_address=b.street_address and a.start_date=b.start_date;
quit;


proc sql;
SELECT 
a.person, a.street_address, a.start_date 
from sheet2 a 
inner join sheet2 b 
on a.person <> b.person and a.street_address=b.street_address and a.start_date<>b.start_date;
quit;

proc sql;
SELECT 
a.person, a.street_address, a.start_date 
from sheet2 a 
inner join sheet2 b 
on a.person <> b.person and a.street_address=b.street_address and a.start_date=b.start_date;
quit;

/*Are there any addresses that more than one person lived at AT THE SAME TIME?*/
proc sql;
SELECT 
a.person, a.street_address, a.start_date, a.end_date,
b.person, b.street_address, b.start_date, b.end_date
from sheet2 a 
inner join sheet2 b 
on a.person <> b.person and a.street_address=b.street_address and b.start_date between a.start_date and a.end_date;
quit;

/*For whom do we have multiple inconsistent addresses over the same time period (however short)?*/
proc sql;
SELECT 
person, street_address, start_date, end_date
from sheet2  
where start_date>end_date or end_date > today();
quit;


/*Of the people  appearing in location_periods, who has the longest gap in address info?*/

/*proc sql ;*/
/*SELECT **/
/*from (*/
/*SELECT */
/*a.person, a.street_address, a.start_date, a.end_date,*/
/*b.person, b.street_address, b.start_date, b.end_date, (b.start_date-a.end_date) as gap*/
/*from sheet2 a */
/*inner join sheet2 b */
/*on a.person = b.person and a.street_address <> b.street_address and b.start_date > a.end_date)*/
/*order by gap desc */
/*;*/
/*quit;*/

proc sql outobs=1;
title 'Person with the longest gap in address info (including ambiguous dates)';
SELECT *
from (
SELECT 
a.person, a.street_address, a.start_date, a.end_date,
b.person, b.street_address, b.start_date, b.end_date, (b.start_date-a.end_date) as gap
from sheet2 a 
inner join sheet2 b 
on a.person = b.person and a.street_address <> b.street_address and b.start_date > a.end_date)
order by gap desc 
;
quit;

proc sql outobs=1;
title 'Person with the longest gap in address info (ambiguous dates removed)';
SELECT *
from (
SELECT 
a.person, a.street_address, a.start_date, a.end_date,
b.street_address, b.start_date, b.end_date, (b.start_date-a.end_date) as gap 'address gaps (days)'
from sheet2 a 
inner join sheet2 b 
on a.person = b.person and a.street_address <> b.street_address and b.start_date > a.end_date
	and b.start_date < today() )
order by gap desc 
;
quit;


/*How would you go about adding a new variable to location_periods that tells you how many different addresses 
the person lived at in the prior 6 months. How would you go about creating that variable?*/
proc sql;
title 'Recent 6-month addresses';
select person, start_date, end_date, street_address as Recent_Address 'Recent Address'
from sheet2
where 
start_date between today() and today()-180 or
end_date between today() and today()-180
;
quit;


/*Open-ended:  What kind of data quality checks would you want to do for people? For location_periods? 
Do any records fail them? Tell us the problems in these tables.*/



/*ods html body = 'd:body1.html'*/
/*        contents = 'd:contents.html'*/
/*	frame = 'd:main.html';*/
