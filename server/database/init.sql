DROP TABLE IF EXISTS PCSAdmin CASCADE;
DROP TABLE IF EXISTS PetOwner CASCADE;
DROP TABLE IF EXISTS CareTaker CASCADE;
DROP TABLE IF EXISTS FullTimer CASCADE;
DROP TABLE IF EXISTS PartTimer CASCADE;
DROP TABLE IF EXISTS Category CASCADE;
DROP TABLE IF EXISTS Has_Availability CASCADE;
DROP TABLE IF EXISTS Cares CASCADE;
DROP TABLE IF EXISTS Owned_Pet_Belongs CASCADE;
DROP TABLE IF EXISTS Bid CASCADE;
DROP VIEW IF EXISTS Users CASCADE;
DROP VIEW IF EXISTS Accounts CASCADE;
DROP PROCEDURE IF EXISTS add_bid(character varying,character varying,character varying,character varying,date,date);


CREATE TABLE PCSAdmin (
    username VARCHAR(50) PRIMARY KEY,
    adminName VARCHAR(50) NOT NULL,
    age   INTEGER DEFAULT NULL
);

CREATE TABLE PetOwner (
    username VARCHAR(50) PRIMARY KEY,
    ownerName VARCHAR(50) NOT NULL,
    age   INTEGER DEFAULT NULL
);

CREATE TABLE CareTaker (
    username VARCHAR(50) PRIMARY KEY,
    carerName VARCHAR(50) NOT NULL,
    age   INTEGER DEFAULT NULL,
    rating INTEGER DEFAULT NULL,
    salary INTEGER DEFAULT NULL
);

CREATE TABLE FullTimer (
    username VARCHAR(50) PRIMARY KEY REFERENCES CareTaker(username),
    period1  VARCHAR(50) DEFAULT NULL,
    period2  VARCHAR(50) DEFAULT NULL
);

CREATE TABLE PartTimer (
    username VARCHAR(50) PRIMARY KEY REFERENCES CareTaker(username)
);

CREATE TABLE Category (
    pettype VARCHAR(20) PRIMARY KEY
);

CREATE TABLE Has_Availability (
    ctuname VARCHAR(50) REFERENCES CareTaker(username) ON DELETE CASCADE,
    s_time DATE,
    e_time DATE,
    PRIMARY KEY(ctuname, s_time, e_time)
);

CREATE TABLE Cares (
    ctuname VARCHAR(50) REFERENCES CareTaker(username),
    pettype VARCHAR(20) REFERENCES Category(pettype),
    price INTEGER NOT NULL,
    PRIMARY KEY (ctuname, pettype)
);

CREATE TABLE Owned_Pet_Belongs (
    pouname VARCHAR(50) NOT NULL REFERENCES PetOwner(username) ON DELETE CASCADE,
    pettype VARCHAR(20) NOT NULL REFERENCES Category(pettype),
    petname VARCHAR(20) NOT NULL,
    petage INTEGER NOT NULL,
    requirements VARCHAR(50) DEFAULT NULL,
    PRIMARY KEY (pouname, petname, pettype)
);

/* TODO: reference has_availability */ 
CREATE TABLE Bid (
    pouname VARCHAR(50),
    petname VARCHAR(20), 
    pettype VARCHAR(20),
    ctuname VARCHAR(50),
    s_time DATE,
    e_time DATE,
    cost INTEGER,
    is_win BOOLEAN DEFAULT NULL,
    rating INTEGER CHECK((rating IS NULL) OR (rating >= 0 AND rating <= 5)),
    review VARCHAR(100),
    pay_type VARCHAR(50) CHECK((pay_type IS NULL) OR (pay_type = 'credit card') OR (pay_type = 'cash')),
    pay_status BOOLEAN DEFAULT FALSE,
    pet_pickup VARCHAR(50) CHECK(pet_pickup = 'poDeliver' OR pet_pickup = 'ctPickup' OR pet_pickup = 'transfer'),
    FOREIGN KEY (pouname, petname, pettype) REFERENCES Owned_Pet_Belongs(pouname, petname, pettype),
    FOREIGN KEY (ctuname, s_time, e_time) REFERENCES Has_Availability (ctuname, s_time, e_time),
    PRIMARY KEY (pouname, petname, pettype, ctuname, s_time, e_time),
    CHECK (pouname <> ctuname)
);

/*TRIGGERS AND PROCEDURE*/
CREATE OR REPLACE PROCEDURE
    add_petOwner(uName VARCHAR(50), oName VARCHAR(50), oAge INTEGER, pType VARCHAR(20), pName VARCHAR(20),
        pAge INTEGER, req VARCHAR(50)) AS
        $$
        DECLARE ctx NUMERIC;
        BEGIN
            SELECT COUNT(*) INTO ctx FROM PetOwner
                WHERE PetOwner.username = uName;
            IF ctx = 0 THEN
                INSERT INTO PetOwner VALUES (uName, oName, oAge);
            END IF;
            INSERT INTO Owned_Pet_Belongs VALUES (uName, pType, pName, pAge, req);
        END;
        $$
    LANGUAGE plpgsql;

/* Insert into fulltimers, will add into caretakers table */
CREATE OR REPLACE PROCEDURE add_fulltimer(
    ctuname VARCHAR(50),
    aname VARCHAR(50),
    age   INTEGER,
    pettype VARCHAR(20),
    price INTEGER,
    rating INTEGER DEFAULT NULL,
    salary INTEGER DEFAULT NULL,
    period1  VARCHAR(50) DEFAULT NULL, 
    period2  VARCHAR(50) DEFAULT NULL
    )  AS $$
    DECLARE ctx NUMERIC;
    BEGIN
            SELECT COUNT(*) INTO ctx FROM FullTimer
                WHERE FullTimer.username = ctuname;
            IF ctx = 0 THEN
                INSERT INTO CareTaker VALUES (ctuname, aname, age, rating, salary);
                INSERT INTO FullTimer VALUES (ctuname, period1, period2);
            END IF;
            INSERT INTO Cares VALUES (ctuname, pettype, price);
    END;$$
LANGUAGE plpgsql;

/* add parttime */
CREATE OR REPLACE PROCEDURE add_parttimer(
    ctuname VARCHAR(50),
    aname VARCHAR(50),
    age   INTEGER,
    pettype VARCHAR(20),
    price INTEGER,
    rating INTEGER DEFAULT NULL,
    salary INTEGER DEFAULT NULL
    )  AS $$
    DECLARE ctx NUMERIC;
    BEGIN
        SELECT COUNT(*) INTO ctx FROM PartTimer
                WHERE PartTimer.username = ctuname;
        IF ctx = 0 THEN
            INSERT INTO CareTaker VALUES (ctuname, aname, age, rating, salary);
            INSERT INTO PartTimer VALUES (ctuname);
        END IF;
        INSERT INTO Cares VALUES (ctuname, pettype, price);
    END;$$
LANGUAGE plpgsql;

/* check if caretaker is not already part of PartTimer or FullTimer. To fulfill the no-overlap constraint */
CREATE OR REPLACE FUNCTION not_parttimer_or_fulltimer()
RETURNS TRIGGER AS
$$ DECLARE Pctx NUMERIC;
    DECLARE Fctx NUMERIC;
    BEGIN
        SELECT COUNT(*) INTO Pctx 
        FROM PartTimer P
        WHERE NEW.username = P.username;

        SELECT COUNT(*) INTO Fctx 
        FROM FullTimer F
        WHERE NEW.username = F.username;

        IF (Pctx > 0 OR Fctx > 0) THEN
            RAISE EXCEPTION 'This username belongs to an existing caretaker.';
        ELSE 
            RETURN NEW;
        END IF; END; $$
LANGUAGE plpgsql;

CREATE TRIGGER check_fulltimer
BEFORE INSERT OR UPDATE ON CareTaker
FOR EACH ROW EXECUTE PROCEDURE not_parttimer_or_fulltimer();

/* check if parttimer that is being added is not a fulltimer. To fulfill the no-overlap constraint */
CREATE OR REPLACE FUNCTION not_fulltimer()
RETURNS TRIGGER AS
$$ DECLARE ctx NUMERIC;
    BEGIN
        SELECT COUNT(*) INTO ctx 
        FROM FullTimer F
        WHERE NEW.username = F.username;

        IF ctx > 0 THEN
            RAISE EXCEPTION 'This username belongs to an existing fulltimer.';
        ELSE 
            RETURN NEW;
        END IF; END; $$
LANGUAGE plpgsql;

CREATE TRIGGER check_parttimer
BEFORE INSERT OR UPDATE ON PartTimer
FOR EACH ROW EXECUTE PROCEDURE not_fulltimer();

/* check if fulltimer that is being added is not a parttimer. To fulfill the no-overlap constraint */
CREATE OR REPLACE FUNCTION not_parttimer()
RETURNS TRIGGER AS
$$ DECLARE ctx NUMERIC;
    BEGIN
        SELECT COUNT(*) INTO ctx 
        FROM PartTimer P
        WHERE NEW.username = P.username;

        IF ctx > 0 THEN
            RAISE EXCEPTION 'This username belongs to an existing parttimer.';
        ELSE 
            RETURN NEW;
        END IF; END; $$
LANGUAGE plpgsql;

CREATE TRIGGER check_fulltimer
BEFORE INSERT OR UPDATE ON FullTimer
FOR EACH ROW EXECUTE PROCEDURE not_parttimer();


CREATE OR REPLACE FUNCTION mark_bid()
RETURNS TRIGGER AS
$$
DECLARE ctx NUMERIC;
DECLARE care NUMERIC;
DECLARE rate NUMERIC;
    BEGIN
        SELECT COUNT(*) INTO ctx
            FROM FullTimer F
            WHERE NEW.ctuname = F.username;
        SELECT COUNT(*) INTO care
            FROM Bid
            WHERE NEW.ctuname = Bid.ctuname AND Bid.is_win AND (NEW.s_time, NEW.e_time) OVERLAPS (Bid.s_time, Bid.e_time);

        IF ctx > 0 THEN -- If CT is a fulltimer
            IF care >= 5 THEN
                RAISE EXCEPTION 'This caretaker has exceeded their capacity.';
            ELSE
                RETURN NEW;
            END IF;
        ELSE -- If CT is a parttimer
            SELECT AVG(rating) INTO rate
                FROM Caretaker AS C
                WHERE NEW.ctuname = C.username;
            IF rate IS NULL OR rate < 4 THEN
                IF care >= 2 THEN
                    RAISE EXCEPTION 'This caretaker has exceeded their capacity.';
                ELSE
                    RETURN NEW;
                END IF;
            ELSE
                IF care >= 5 THEN
                    RAISE EXCEPTION 'This caretaker has exceeded their capacity.';
                ELSE
                    RETURN NEW;
                END IF;
            END IF;
        END IF;
    END; $$
LANGUAGE plpgsql;

CREATE TRIGGER mark_other_bids
BEFORE UPDATE ON Bid
FOR EACH ROW EXECUTE PROCEDURE mark_bid();


CREATE OR REPLACE PROCEDURE add_bid(
   _pouname VARCHAR(50),
   _petname VARCHAR(20),
   _pettype VARCHAR(20),
   _ctuname VARCHAR(50),
   _s_time DATE,
   _e_time DATE
   ) AS
       $$
       DECLARE care NUMERIC;
       DECLARE avail NUMERIC;
       DECLARE cost NUMERIC;
       BEGIN
            -- Ensures that the ct can care for this pet type
            SELECT COUNT(*) INTO care FROM Cares
            WHERE Cares.ctuname = _ctuname AND Cares.pettype = _pettype;
            IF care = 0 THEN
               RAISE EXCEPTION 'Caretaker is unable to care for this pet type.';
            END IF;
            -- Ensures that ct has availability at this time period
            SELECT COUNT(*) INTO avail FROM Has_Availability
            WHERE Has_Availability.ctuname = _ctuname AND (_s_time, _e_time) OVERLAPS (Has_Availability.s_time, Has_Availability.e_time);
            if avail = 0 THEN
                RAISE EXCEPTION 'Caretaker is unavailable for this period.';
            END IF;
            SELECT (Cares.price * (_e_time - _s_time)) INTO cost
            FROM Cares
            WHERE Cares.ctuname = _ctuname AND Cares.pettype = _pettype;
            -- Must ensure that a Bid cannot be created for the same Petowner and Pet with overlapping time periods.
            INSERT INTO Bid(pouname, petname, pettype, ctuname, s_time, e_time, cost)
               VALUES (_pouname, _petname, _pettype, _ctuname, _s_time, _e_time, cost);
       END;
       $$
   LANGUAGE plpgsql;

/* Views */
CREATE OR REPLACE VIEW Users AS (
   SELECT username, carerName, age, rating, salary, true AS is_carer FROM CareTaker
   UNION ALL
   SELECT username, ownerName, age, NULL AS rating, NULL AS salary, false AS is_carer FROM PetOwner
);

CREATE OR REPLACE VIEW Accounts AS (
   SELECT username, adminName, age, NULL AS rating, NULL AS salary, false AS is_carer, true AS is_admin FROM PCSAdmin
   UNION ALL
   SELECT username, carerName, age, rating, salary, true AS is_carer, false AS is_admin FROM CareTaker
   UNION ALL
   SELECT username, ownerName, age, NULL AS rating, NULL AS salary, false AS is_carer, false AS is_admin FROM PetOwner
);

/* SEED */
INSERT INTO PCSAdmin(username, adminName) VALUES ('Red', 'red');

INSERT INTO Category VALUES ('dog'),('cat'),('rabbit'),('big dogs'),('lizard'),('bird');

CALL add_fulltimer('yellowchicken', 'chick', 22, 'bird', 50);
CALL add_fulltimer('purpledog', 'purple', 25, 'dog', 60);
CALL add_fulltimer('redduck', 'ducklings', 20, 'rabbit', 35);

CALL add_parttimer('yellowbird', 'bird', 35, 'cat', 60);

CALL add_petOwner('johnthebest', 'John', 50, 'dog', 'Fido', 10, NULL);
CALL add_petOwner('marythemess', 'Mary', 25, 'dog', 'Fido', 10, NULL);

INSERT INTO Owned_Pet_Belongs VALUES ('marythemess', 'dog', 'Champ', 10, NULL);
INSERT INTO Owned_Pet_Belongs VALUES ('marythemess', 'cat', 'Meow', 10, NULL);

INSERT INTO Cares VALUES ('yellowchicken', 'rabbit', 40);
INSERT INTO Cares VALUES ('yellowchicken', 'big dogs', 70);
INSERT INTO Cares VALUES ('yellowchicken', 'cat', 50);
INSERT INTO Cares VALUES ('redduck', 'big dogs', 80);
INSERT INTO Cares VALUES ('yellowbird', 'dog', 50);

INSERT INTO Has_Availability VALUES ('yellowchicken', '2020-01-01', '2020-03-04');
INSERT INTO Has_Availability VALUES ('yellowbird', '2020-06-02', '2020-06-08');
INSERT INTO Has_Availability VALUES ('yellowbird', '2020-12-04', '2020-12-20');
INSERT INTO Has_Availability VALUES ('yellowbird', '2020-08-08', '2020-08-10');

CALL add_bid('marythemess', 'Meow', 'cat', 'yellowchicken', '2020-01-01', '2020-03-04');

-- INSERT INTO Bid VALUES ('johnthebest', 'Fido', 'dog', 'yellowchicken', to_timestamp('1000000'), to_timestamp('2000000'));
-- INSERT INTO Bid VALUES ('marythemess', 'Fido', 'dog', 'yellowbird', to_timestamp('1000000'), to_timestamp('4000000'));
-- INSERT INTO Bid VALUES ('marythemess', 'Fido', 'dog', 'yellowbird', to_timestamp('2000000'), to_timestamp('4000000'));
-- INSERT INTO Bid VALUES ('marythemess', 'Fido', 'dog', 'yellowbird', to_timestamp('3000000'), to_timestamp('4000000'));
-- UPDATE Bid SET is_win = True WHERE ctuname = 'yellowbird' AND pouname = 'marythemess' AND s_time = to_timestamp('1000000') AND e_time = to_timestamp('4000000');
-- UPDATE Bid SET is_win = True WHERE ctuname = 'yellowbird' AND pouname = 'marythemess' AND s_time = to_timestamp('2000000') AND e_time = to_timestamp('4000000');