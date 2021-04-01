
ods pdf file = "D:/kp_pa.pdf"
contents = yes pdftoc = 2;
proc document name = temp(write);
import textfile = "D:/KP_SAS_Programmer_Code Challenge Umesh Singh.sas" to ^;
replay;
run;

/*********************************************************
IMPORTING THE 'people' TABLE FROM THE ESCEL FILE
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
title "First 5 obs from the 'people' table";
run;

/*printing the contents of the 'people' table*/
ods select Variables;
proc contents data = people; 
title "Contents of the 'people' table ";
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
IMPORTING THE 'location_periods' TABLE FROM THE ESCEL FILE
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
title "First 5 obs from the 'location_periods' table";
run;

/*printing the contents of the 'location_periods' SAS data*/
ods select Variables;
proc contents data = location_periods; 
title "Table contents for the 'location_periods' table";
run;


/*********************************************************************************
MERGING THE 'people' AND 'location_periods' AS 'people_location' BY 'person' as ID
**********************************************************************************/
proc sort data = people; 
	by person;
run;
proc sort data = location_periods; 
	by person; 
run;
data people_location; 
	merge  people (in = in1) location_periods (in=in2); 
	by person; 
run;

/*printing the first 5 observations from 'people_location' SAS data*/
proc print data = people_location (obs = 5); 
title "First 5 obs from the 'people_location' table";
run;

/*printing the contents of the 'people_location' SAS data*/
ods select Variables;
proc contents data = people_location;
title "Table contents for the 'people_location' table";
run;




/***********************     RESPONSE TO QUESTIONS        *************************/																										
/*Q1. 
How many individuals do we have address info for?
*************************************************/
proc sql;
title 'Count of Unique Individuals in the "location_periods" Table';
select count(distinct(person)) as count_unique_persons
	from location_periods;
quit;


/* Q2
Is there anybody we have birth_date for, but no address info? Who?
******************************************************************/
proc sql;
title 'Count of individuals with birth_date info, but no address info';
select 
	count(distinct(person)) 'Total Count'
	from people_location
	where bdate is not null and street_address is null;
quit;

proc sql;
title 'Individuals with birth_date info, but no address info';
select 
	person 'Name', 
	bdate 'Birth Date', 
	street_address 'Address'
	from people_location
	where bdate is not null and street_address is null;
quit;


/* Q3.
Is there anybody we have address info on, but no birth_date? Who?
******************************************************************/
proc sql;
title 'Count of individuals without birth_date info, but with address info';
select 
	count(distinct(person)) 'Total Count'
	from people_location
	where bdate is null and street_address is not null;
quit;

proc sql;
title 'Individuals without birth_date info, but with address info';
select 
	person 'Name', 
	bdate 'Birth Date', 
	street_address 'Address'
	from people_location
	where bdate is null and street_address is not null;
quit;


/* Q4.
What's the longest time a person lived at the same address? Who and where was that?
***********************************************************************************/
proc sql outobs=1;
TITLE 'Longest time a person lived at the same address';
SELECT *
FROM 	(
		SELECT 
		a.person, a.street_address, a.start_date, a.end_date,
		b.person, b.street_address, b.start_date, b.end_date, (b.end_date-a.start_date) AS duration 'Duration (days)'
		FROM location_periods a 
		INNER JOIN location_periods b 
			ON a.person = b.person 
			AND a.street_address = b.street_address 
			AND b.start_date < a.end_date
			AND b.end_date < today()
		)
ORDER BY duration DESC 
;
quit;


/*Q5.
Are there any addresses that more than one person lived at?*/
proc sql;
TITLE 'Addresses that more than one person lived at';
SELECT 
	a.person, a.street_address, a.start_date, a.end_date
FROM location_periods a 
INNER JOIN location_periods b 
	ON a.person <> b.person  
		AND a.street_address=b.street_address  
		;
quit;

proc sql;
TITLE 'Count of addresses that more than one person lived at';
SELECT DISTINCT  
	street_address, 
	 person,
	start_date, 
	end_date,
	COUNT(street_address) AS NumOccurrences
FROM location_periods
GROUP BY street_address
HAVING (COUNT(street_address) > 1 )
;
quit;


/*Q6.
Are there any addresses that more than one person lived at AT THE SAME TIME?*/
proc sql;
TITLE 'Addresses that more than one person lived at AT THE SAME TIME';
SELECT 
	a.person, a.street_address, a.start_date, a.end_date,
	b.person, b.street_address, b.start_date, b.end_date
FROM location_periods a 
INNER JOIN location_periods b 
	ON a.person <> b.person  
		AND a.street_address=b.street_address  
		AND b.start_date between a.start_date  
		AND a.end_date;
quit;


/*Q7.
For whom do we have multiple inconsistent addresses over the same time period (however short)?*/
proc sql;
TITLE 'Inconsistent addresses over the same time period';
SELECT 
	person, street_address, start_date, end_date
FROM location_periods  
WHERE 
	start_date>end_date  
	OR end_date > today();
quit;


/*Q8.
Of the people appearing in location_periods, who has the longest gap in address info?*/
proc sql outobs=1;
TITLE 'Person with the longest gap in address info (including ambiguous dates)';
SELECT *
FROM 	(
		SELECT 
		a.person, a.street_address, a.start_date, a.end_date,
		b.person, b.street_address, b.start_date, b.end_date, (b.start_date-a.end_date) AS gap 'address gaps (days)'
		FROM location_periods a 
		INNER JOIN location_periods b 
			ON a.person = b.person 
			AND a.street_address <> b.street_address 
			AND b.start_date > a.end_date
		)
ORDER BY gap DESC 
;
quit;

proc sql outobs=1;
TITLE 'Person with the longest gap in address info (ambiguous dates removed)';
SELECT *
FROM (
		SELECT 
		a.person, a.street_address, a.start_date, a.end_date,
		b.street_address, b.start_date, b.end_date, (b.start_date-a.end_date) AS gap 'address gaps (days)'
		FROM location_periods a 
		INNER JOIN location_periods b 
			on a.person = b.person 
			and a.street_address <> b.street_address 
			and b.start_date > a.end_date
			and b.start_date < today() 
		)
order by gap desc 
;
quit;


/*Q9a.
How would you go about adding a new variable to location_periods that tells you how many different addresses 
the person lived at in the prior 6 months. */

proc sql;
title 'Recent 6-month addresses';
/*CREATE TABLE recent_address as*/
SELECT 	person, 
		start_date, 
		end_date, 
		street_address as recent_address 'Recent Address',
		count(distinct(street_address)) as count
FROM location_periods
WHERE 
	start_date between today() and today()-180 or
	end_date between today() and today()-180
group by person
;
quit;

/*Q9b.
How would you go about creating that variable?*/

proc sql ;
title 'Creating a variable "Recent 6-month Addresses"';
SELECT *
FROM 	(
		SELECT 
		a.person, a.street_address, a.start_date, a.end_date,
		b.street_address as ra 'Recent (6 month) Addresses'
		FROM location_periods a 
		LEFT JOIN location_periods b 
			ON a.person = b.person 
			WHERE 
			b.start_date between today() and today()-180 or
			b.end_date between today() and today()-180
		)
;
quit;

ods pdf close;

proc sql;
select person from location_periods
where street_address is null;
quit;
