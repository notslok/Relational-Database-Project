--library to encrypt user password
create extension pgcrypto;
--Pl/pgSql to calculate age
CREATE OR REPLACE FUNCTION get_age( birthday date )
RETURNS interval
AS $CODE$
BEGIN
    RETURN age(birthday);
END
$CODE$
LANGUAGE plpgsql IMMUTABLE;
--gender domain
create domain user_gender as text check (
    value ~* 'male'
    or value ~* 'female'
    or value ~* 'trans'
    );

--Table Users

CREATE TABLE Users(
    name VARCHAR(100) NOT NULL ,
    username VARCHAR(100) NOT NULL UNIQUE,
    dob DATE NOT NULL,
    age INTERVAL GENERATED ALWAYS AS ( get_age(dob) ) STORED,--derived
    password VARCHAR(20) NOT NULL,
    id VARCHAR(100) NOT NULL UNIQUE ,
    email VARCHAR(320) UNIQUE,
    gender USER_GENDER NOT NULL,--user defined domain
    --constraints
    PRIMARY KEY(id),
    CHECK (age>INTERVAL '0'),
    CHECK(email ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')
);

CREATE TABLE contact_credentials(
    id VARCHAR(100) NOT NULL,
    contact_num INTEGER NOT NULL UNIQUE,
    FOREIGN KEY (id) REFERENCES Users(id),
    CHECK (contact_num<=9999999999 AND contact_num>=999999)
);

--BATCH BETWEEN 1950 AND CURRENT YEAR + 4
--ASSUMING COLLEGE STARTED IN 1950 AND OFFERS 4 YEAR PROGRAMS
CREATE TABLE Student(
    batch INTEGER NOT NULL,
    cgpa REAL,
    CHECK (batch >= 1954 AND batch <= date_part('year', CURRENT_DATE)+4),
    CHECK (cgpa>=0.0 AND cgpa<=10.0)
)INHERITS (Users);


--Create Faculty
CREATE TABLE Faculty(
    fac_title VARCHAR(100) NOT NULL,
    fac_salary REAL NOT NULL,
    CHECK (fac_salary >= 200000)
    --Assuming min wage is 200k/annum
)INHERITS (Users);


--DOMAIN DEGREE_TYPE
create domain degree_type as text check (
    value ~* 'bachelors'
    or value ~* 'masters'
    or value ~* 'doctoral'
    or value ~* 'diploma'
    or value ~* 'certification'
    or value ~* 'post-doctoral'
    );

--Table DEGREE
CREATE TABLE Degree(
    deg_seats INTEGER NOT NULL,
    deg_duration INTEGER NOT NULL,
    deg_name VARCHAR(100) NOT NULL UNIQUE,
    deg_type degree_type NOT NULL,
    deg_id VARCHAR(100) NOT NULL UNIQUE,
    --Constraints
    PRIMARY KEY (deg_id),
    CHECK (deg_duration >= 1 AND deg_duration <= 4),
    --ASSUMING A DEGREE SHOULD HAVE ATLEAST 50 SEATS AND DOES NOT EXCEED 300
    CHECK (deg_seats >= 50 AND deg_seats<=300)
);

--ADMITTED TO RELATION
CREATE TABLE admitted_to(
    id varchar(100) NOT NULL,
    deg_id VARCHAR(100) NOT NULL,
    --ASSUMING SOME TEACHERS ARE STUDENTS TOO
    FOREIGN KEY (id) REFERENCES Users(id),
    FOREIGN KEY (deg_id) REFERENCES Degree(deg_id)
);

--TABLE DEPARTMENT
CREATE TABLE Department(
    d_name VARCHAR(100) NOT NULL UNIQUE,
    d_address VARCHAR(100) NOT NULL,
    d_email VARCHAR(320) NOT NULL,
    --CONSTRAINTS
    PRIMARY KEY (d_name),
    CHECK ( d_email ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$' )

);

--BELONGS TO RELATION
CREATE TABLE belongs_to(
    --AS A STUDENT CAN PURSUE MULTIPLE DEGREES SIMULTANEOUSLY OFFERED BY DIFFERENT DEPARTMENTS
    id VARCHAR(100) NOT NULL REFERENCES Users(id),
    d_name VARCHAR(100) NOT NULL REFERENCES Department(d_name)
);

--OFFERED-BY RELATION
CREATE TABLE offered_by(
    --EACH DEGREE IS OFFERED BY A SINGLE DEPARTMENT
    d_name VARCHAR(100) NOT NULL REFERENCES Department(d_name),
    deg_id VARCHAR(100) NOT NULL UNIQUE REFERENCES degree(deg_id)
);


--DOMAIN COURSE_TYPE FOR TYPES OF COURSES
CREATE DOMAIN course_type as text check(
    value ~* 'core'
    or value ~* 'elective'
    );


--TABLE COURSE
CREATE TABLE Course(
    c_id VARCHAR(100) NOT NULL UNIQUE PRIMARY KEY,
    --C_NAME IS NOT UNIQUE AS TWO COURSES CAN HAVE THE SAME NAME BUT CAN BE OFFERED BY TWO DIFFERENT DEPARTMENTS
    c_name VARCHAR(100) NOT NULL,
    credits REAL,
    c_type course_type NOT NULL,
    --CONSTRAINTS
    --MAX CREDITS IS 6
    CHECK (credits>=0 AND credits<=6)
);

--TAUGHT_BY RELATION
CREATE TABLE taught_by(
    c_id VARCHAR(100) NOT NULL REFERENCES Course(c_id),
    id VARCHAR(100) NOT NULL REFERENCES Users(id)
);

--ENROLLED_IN RELATION
CREATE TABLE enrolled_in(
    c_id VARCHAR(100) NOT NULL REFERENCES Course(c_id),
    id VARCHAR(100) NOT NULL REFERENCES Users(id)
);


--OFFERS RELATION
CREATE TABLE offers(
    deg_id VARCHAR(100) NOT NULL REFERENCES Degree(deg_id),
    c_id VARCHAR(100) NOT NULL REFERENCES Course(c_id),
    semester INTEGER NOT NULL,
    --CONSTRAINTS
    CHECK (semester >= 1 AND semester <=8)
);

--EMPLOYS RELATION
CREATE TABLE employs(
    d_name VARCHAR(100) NOT NULL REFERENCES Department(d_name),
    id VARCHAR(100) NOT NULL UNIQUE REFERENCES Users(id)
);


--MANAGED_BY RELATION
CREATE TABLE managed_by(
    d_name VARCHAR(100) NOT NULL UNIQUE REFERENCES Department(d_name),
    id VARCHAR(100) NOT NULL UNIQUE REFERENCES Users(id)
);

commit;
