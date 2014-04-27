DROP TABLE IF EXISTS Account CASCADE;
DROP TABLE IF EXISTS LoginAttempts CASCADE;
DROP TABLE IF EXISTS Organization CASCADE;
DROP TABLE IF EXISTS OrganizationAccount CASCADE;
DROP TABLE IF EXISTS Professional CASCADE;
DROP TABLE IF EXISTS PrivatePayer CASCADE;
DROP TABLE IF EXISTS EntityPayer CASCADE;
DROP TABLE IF EXISTS Patient CASCADE;
DROP TABLE IF EXISTS ProcedureType CASCADE;
DROP TABLE IF EXISTS Procedure CASCADE;
DROP TABLE IF EXISTS SubProcedure CASCADE;
DROP DOMAIN IF EXISTS Email CASCADE;
DROP DOMAIN IF EXISTS NIF CASCADE;
DROP TYPE IF EXISTS ProcedurePaymentStatus CASCADE;
DROP TYPE IF EXISTS EntityType CASCADE;
DROP TYPE IF EXISTS Specialty CASCADE;

CREATE TYPE ProcedurePaymentStatus AS ENUM ('Recebi', 'Paguei', 'Nada');
CREATE TYPE EntityType AS ENUM ('Privado', 'Hospital', 'Seguro');
CREATE TYPE Specialty AS ENUM ('Cirurgião', 'Anestesista', 'Enfermeiro');

CREATE DOMAIN Email VARCHAR(254)
    CONSTRAINT validEmail
    CHECK (VALUE ~ '^[a-zA-Z0-9._%+-]+\@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');

CREATE DOMAIN NIF VARCHAR(9)
    CONSTRAINT validNIF
    CHECK (VALUE ~ '\d{9}');

--Username + email?
CREATE TABLE Account (
    idAccount SERIAL PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    username VARCHAR(40) NOT NULL UNIQUE,
    email Email NOT NULL UNIQUE,
    password CHAR(128) NOT NULL,
    salt CHAR(128) NOT NULL
);

CREATE TABLE LoginAttempts (
    idAttempt SERIAL PRIMARY KEY,
    idAccount INTEGER NOT NULL REFERENCES Account(idAccount) ON DELETE CASCADE,
    time VARCHAR(30) NOT NULL
);

CREATE TABLE Organization (
    idOrganization SERIAL PRIMARY KEY,
    name VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE OrganizationAccount (
    idOrganization INTEGER NOT NULL REFERENCES Organization(idOrganization) ON DELETE CASCADE,
    idAccount INTEGER NOT NULL REFERENCES Account(idAccount) ON DELETE CASCADE,
    PRIMARY KEY(idOrganization, idAccount)
);

CREATE TABLE Professional (
    idProfessional SERIAL PRIMARY KEY,
    name VARCHAR(40),                           -- Ou um, ou outro
    idAccount INTEGER REFERENCES Account(idAccount) ON DELETE SET NULL,
    nif NIF NOT NULL
);

CREATE TABLE PrivatePayer (
    idPrivatePayer SERIAL PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    codParticular INTEGER NOT NULL UNIQUE --WTF
);

CREATE TABLE EntityPayer (
    idEntityPayer SERIAL PRIMARY KEY,
    name VARCHAR(40) NOT NULL,
    contractStart DATE NOT NULL,
    contractEnd DATE NOT NULL,
    type EntityType NOT NULL,
    nif NIF NOT NULL UNIQUE,
    valuePerK REAL NOT NULL
);

CREATE TABLE Patient(
    idPatient SERIAL PRIMARY KEY
);

CREATE TABLE ProcedureType (
    idProcedureType SERIAL PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    k REAL NOT NULL
);

CREATE TABLE Procedure (
    idProcedure SERIAL PRIMARY KEY,
    idPatient INTEGER NOT NULL REFERENCES Patient(idPatient),
    paymentStatus ProcedurePaymentStatus NOT NULL,
    idPrivatePayer INTEGER REFERENCES PrivatePayer(idPrivatePayer) ON DELETE SET NULL,   -- Ou um, ou outro, ou ambos
    idEntityPayer INTEGER REFERENCES EntityPayer(idEntityPayer) ON DELETE SET NULL,
    date DATE NOT NULL
);

CREATE TABLE SubProcedure (
    idSubProcedure SERIAL PRIMARY KEY,
    idProcedure INTEGER NOT NULL REFERENCES Procedure(idProcedure),
    idProcedureType INTEGER NOT NULL REFERENCES ProcedureType(idProcedureType)
);