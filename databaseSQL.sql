DROP TABLE IF EXISTS Account CASCADE;
DROP TABLE IF EXISTS LoginAttempts CASCADE;
DROP TABLE IF EXISTS Organization CASCADE;
DROP TABLE IF EXISTS OrgAuthorization CASCADE;
DROP TABLE IF EXISTS PrivatePayer CASCADE;
DROP TABLE IF EXISTS EntityPayer CASCADE;
DROP TABLE IF EXISTS Speciality
CASCADE;
DROP TABLE IF EXISTS Professional CASCADE;
DROP TABLE IF EXISTS ProcedureType CASCADE;
DROP TABLE IF EXISTS Procedure CASCADE;
DROP TABLE IF EXISTS ProcedureProfessional CASCADE;
DROP TABLE IF EXISTS ProcedureProcedureType CASCADE;
DROP TABLE IF EXISTS KSpeciality CASCADE;
DROP DOMAIN IF EXISTS Email CASCADE;
DROP DOMAIN IF EXISTS NIF CASCADE;
DROP DOMAIN IF EXISTS LicenseId CASCADE;
DROP TYPE IF EXISTS ProcedurePaymentStatus CASCADE;
DROP TYPE IF EXISTS EntityType CASCADE;
DROP TYPE IF EXISTS OrgAuthorizationType CASCADE;

------------------------------------------------------------------------

CREATE TYPE ProcedurePaymentStatus AS ENUM ('Recebi', 'Paguei', 'Nada');
CREATE TYPE EntityType AS ENUM ('Privado', 'Hospital', 'Seguro');
CREATE TYPE OrgAuthorizationType AS ENUM ('Administrador', 'Visível', 'Invisível');

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
  idAccount INTEGER     NOT NULL REFERENCES Account (idAccount),
  time      VARCHAR(30) NOT NULL
);

CREATE TABLE Organization (
  idOrganization SERIAL PRIMARY KEY,
  name           VARCHAR(40) NOT NULL UNIQUE
);

CREATE TABLE OrgAuthorization (
  idOrganization   INTEGER NOT NULL REFERENCES Organization (idOrganization),
  idAccount        INTEGER NOT NULL REFERENCES Account (idAccount),
  orgAuthorization OrgAuthorizationType,
  PRIMARY KEY (idOrganization, idAccount)
);

CREATE TABLE PrivatePayer (
  idPrivatePayer SERIAL PRIMARY KEY,
  idAccount      INTEGER NOT NULL REFERENCES Account (idAccount),
  name           VARCHAR(40) NOT NULL
);

CREATE TABLE EntityPayer (
  idEntityPayer SERIAL PRIMARY KEY,
  idAccount     INTEGER NOT NULL REFERENCES Account (idAccount),
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
  paymentStatus  ProcedurePaymentStatus NOT NULL DEFAULT 'Nada',
  idAccount      INTEGER REFERENCES Account (idAccount),
  idPrivatePayer INTEGER REFERENCES PrivatePayer (idPrivatePayer), -- Ou um, ou outor
  idEntityPayer  INTEGER REFERENCES EntityPayer (idEntityPayer),
  date           DATE                   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  code           CHAR(32)               NOT NULL DEFAULT 'Nada',
  totalValue     FLOAT
);

CREATE TABLE ProcedureProcedureType (
  idProcedure     INTEGER NOT NULL REFERENCES Procedure (idProcedure),
  idProcedureType INTEGER NOT NULL REFERENCES ProcedureType (idProcedureType),
  PRIMARY KEY (idProcedure, idProcedureType)
);

CREATE TABLE ProcedureProfessional (
  idProcedure    INTEGER NOT NULL REFERENCES Procedure (idProcedure),
  idProfessional INTEGER NOT NULL REFERENCES Professional (idProfessional),
  remuneration   FLOAT,
  PRIMARY KEY (idProcedure, idProfessional)
);

CREATE TABLE KSpeciality (
  idSpeciality    INTEGER NOT NULL REFERENCES Speciality (idSpeciality),
  idProcedureType INTEGER NOT NULL REFERENCES ProcedureType (idProcedureType),
  k               INTEGER NOT NULL,
  PRIMARY KEY (idSpeciality, idProcedureType)
);
