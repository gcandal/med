DROP TABLE IF EXISTS OrgAuthorization;
DROP TABLE IF EXISTS Organization;
DROP TABLE IF EXISTS ProcedureProcedureType;
DROP TABLE IF EXISTS KSpeciality;
DROP TABLE IF EXISTS ProcedureType;
DROP TABLE IF EXISTS ProcedureProfessional;
DROP TABLE IF EXISTS Procedure;
DROP TABLE IF EXISTS Professional;
DROP TABLE IF EXISTS LoginAttempts;
DROP TABLE IF EXISTS PrivatePayer;
DROP TABLE IF EXISTS EntityPayer;
DROP TABLE IF EXISTS Account;
DROP TABLE IF EXISTS Speciality;
DROP DOMAIN IF EXISTS Email;
DROP DOMAIN IF EXISTS NIF;
DROP DOMAIN IF EXISTS LicenseId;
DROP TYPE IF EXISTS ProcedurePaymentStatus;
DROP TYPE IF EXISTS EntityType;
DROP TYPE IF EXISTS OrgAuthorizationType;

------------------------------------------------------------------------

CREATE TYPE ProcedurePaymentStatus AS ENUM ('Received', 'Payed', 'Nothing');
CREATE TYPE EntityType AS ENUM ('Private', 'Hospital', 'Insurance');
CREATE TYPE OrgAuthorizationType AS ENUM ('Admin', 'Visible', 'Invisible');

------------------------------------------------------------------------

CREATE DOMAIN Email VARCHAR(254)
CONSTRAINT validEmail
CHECK (VALUE ~ '^[a-zA-Z0-9._%+-]+\@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');

CREATE DOMAIN NIF VARCHAR(9)
CONSTRAINT validNIF
CHECK (VALUE ~ '\d{9}');

CREATE DOMAIN LicenseId VARCHAR(9)
CONSTRAINT validLicenseId
CHECK (VALUE ~ '\d{9}');

------------------------------------------------------------------------

CREATE TABLE Account (
  idAccount SERIAL PRIMARY KEY,
  name      VARCHAR(40) NOT NULL,
  email     Email       NOT NULL UNIQUE,
  password  CHAR(128)   NOT NULL,
  salt      CHAR(128)   NOT NULL,
  licenseId LicenseId   NOT NULL UNIQUE
);

CREATE TABLE LoginAttempts (
  idAttempt SERIAL PRIMARY KEY,
  idAccount INTEGER     NOT NULL REFERENCES Account (idAccount) ON DELETE CASCADE,
  time      VARCHAR(30) NOT NULL
);

CREATE TABLE Organization (
  idOrganization SERIAL PRIMARY KEY,
  name           VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE OrgAuthorization (
  idOrganization   INTEGER NOT NULL REFERENCES Organization (idOrganization) ON DELETE CASCADE,
  idAccount        INTEGER NOT NULL REFERENCES Account (idAccount) ON DELETE CASCADE,
  orgAuthorization OrgAuthorizationType,
  PRIMARY KEY (idOrganization, idAccount)
);

CREATE TABLE PrivatePayer (
  idPrivatePayer SERIAL PRIMARY KEY,
  idAccount      INTEGER     NOT NULL REFERENCES Account (idAccount) ON DELETE CASCADE,
  name           VARCHAR(40) NOT NULL
);

CREATE TABLE EntityPayer (
  idEntityPayer SERIAL PRIMARY KEY,
  idAccount     INTEGER     NOT NULL REFERENCES Account (idAccount) ON DELETE CASCADE,
  name          VARCHAR(40) NOT NULL,
  contractStart DATE,
  contractEnd   DATE,
  type          EntityType,
  nif           NIF         NOT NULL,
  valuePerK     REAL
);

CREATE TABLE Speciality (
  idSpeciality SERIAL PRIMARY KEY,
  name         VARCHAR(50),
  defaultK     INTEGER NOT NULL
);

CREATE TABLE Professional (
  idProfessional SERIAL PRIMARY KEY,
  idSpeciality   INTEGER NOT NULL REFERENCES Speciality (idSpeciality),
  name           VARCHAR(40),
  nif            NIF     NOT NULL,
  licenseId      LicenseId UNIQUE
);

CREATE TABLE ProcedureType (
  idProcedureType SERIAL PRIMARY KEY,
  name            VARCHAR(80) NOT NULL
);

CREATE TABLE Procedure (
  idProcedure    SERIAL PRIMARY KEY,
  paymentStatus  ProcedurePaymentStatus NOT NULL DEFAULT 'Nothing',
  idAccount      INTEGER REFERENCES Account (idAccount) ON DELETE CASCADE,
  idPrivatePayer INTEGER REFERENCES PrivatePayer (idPrivatePayer), -- Ou um, ou outro
  idEntityPayer  INTEGER REFERENCES EntityPayer (idEntityPayer),
  date           DATE                   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  code           CHAR(32)               NOT NULL DEFAULT 'Nothing',
  totalValue     FLOAT
);

CREATE TABLE ProcedureProcedureType (
  idProcedure     INTEGER NOT NULL REFERENCES Procedure (idProcedure) ON DELETE CASCADE,
  idProcedureType INTEGER NOT NULL REFERENCES ProcedureType (idProcedureType) ON DELETE CASCADE,
  PRIMARY KEY (idProcedure, idProcedureType)
);

CREATE TABLE ProcedureProfessional (
  idProcedure    INTEGER NOT NULL REFERENCES Procedure (idProcedure) ON DELETE CASCADE,
  idProfessional INTEGER NOT NULL REFERENCES Professional (idProfessional) ON DELETE CASCADE,
  remuneration   FLOAT,
  PRIMARY KEY (idProcedure, idProfessional)
);

CREATE TABLE KSpeciality (
  idSpeciality    INTEGER NOT NULL REFERENCES Speciality (idSpeciality),
  idProcedureType INTEGER NOT NULL REFERENCES ProcedureType (idProcedureType),
  k               INTEGER NOT NULL,
  PRIMARY KEY (idSpeciality, idProcedureType)
);
