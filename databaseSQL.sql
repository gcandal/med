DROP TABLE IF EXISTS OrgInvitation;
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

CREATE TYPE ProcedurePaymentStatus AS ENUM ('Received Payment', 'Concluded', 'Payment Pending');
CREATE TYPE EntityType AS ENUM ('Hospital', 'Insurance');
CREATE TYPE OrgAuthorizationType AS ENUM ('Admin', 'Visible', 'NotVisible');

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
  valuePerK     REAL,
  CHECK (contractStart < contractEnd)
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
  defaultK        INTEGER NOT NULL
);

CREATE TABLE Procedure (
  idProcedure    SERIAL PRIMARY KEY,
  paymentStatus  ProcedurePaymentStatus NOT NULL DEFAULT 'Payment Pending',
  idAccount      INTEGER REFERENCES Account (idAccount) ON DELETE CASCADE,
  idPrivatePayer INTEGER REFERENCES PrivatePayer (idPrivatePayer), -- Ou um, ou outro
  idEntityPayer  INTEGER REFERENCES EntityPayer (idEntityPayer),
  date           DATE                   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  code           CHAR(32)               NOT NULL DEFAULT 'Payment Pending',
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

CREATE TABLE OrgInvitation (
  idOrganization    INTEGER NOT NULL REFERENCES Organization (idOrganization) ON DELETE CASCADE,
  idInvitingAccount INTEGER NOT NULL REFERENCES Account (idAccount) ON DELETE CASCADE,
  idInvitedAccount  INTEGER NOT NULL REFERENCES Account (idAccount) ON DELETE CASCADE,
  forAdmin          BOOL    NOT NULL,
  date              DATE    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (idOrganization, idInvitingAccount, idInvitedAccount)
);

INSERT INTO Organization VALUES (DEFAULT, 'Org');

INSERT INTO Account VALUES (DEFAULT, 'a', 'a@a.pt',
                            '445fff776df2293d242b261ba0f0d35be6c5b5a5110394fe8942a21e4d7af759fa277f608c3553ee7b3f8f64fce174b31146746ca8ef67dd37eedf70fe79ef9d',
                            'bea95c126335da5b92c91de01635311ede91a58f0ca0d9cb0344462333c35c9ef12977e976e2e8332861cff2c4efa42c653214b626ed96a76ba19ed0e414b71a',
                            '123456789');
INSERT INTO PrivatePayer VALUES (DEFAULT, 1, 'Aquele Mano');
INSERT INTO EntityPayer VALUES (DEFAULT, 1, 'Seguro', NULL, NULL, 'Insurance', '123456789', NULL);
INSERT INTO EntityPayer VALUES (DEFAULT, 1, 'Hospital', '2014-07-01', '2014-07-02', 'Hospital', '123456789', 10);
INSERT INTO OrgAuthorization VALUES (1, 1, 'Admin');

INSERT INTO Account VALUES (DEFAULT, 'b', 'b@b.pt',
                            '6b9f904771f21b6d9d017582d9a001c41eef2dd5128ff80fd1985d8f1f2e62fe5e23b4e77c16adea3e86eaf8353acc55e93f982419c9f87356e3a805ef7fae16',
                            'beb281b875e9c11fb6f8290fb7952e6da45dcd50f903299b374c6d8c816eca7dfa66c9d2b70bd3900a0b9c666eaf656505739c370ca2f2a788c33e1ff16a4736',
                            '987654321');
INSERT INTO OrgAuthorization VALUES (1, 2, 'Visible');

INSERT INTO Account VALUES (DEFAULT, 'c', 'c@c.pt',
                            'b13188a1fb01f1b9c41e9229dacf2c030d6ea18bd14c0d462dc488e5bbe7fb28d7a33ac16a8bc5989ea7e1af2d4a0476cfeea2b3e4c82253cd70e42688e60988',
                            '6deba07b456d9594d85baa07c911bd7ae9ca659ed2b16760d78b6c443252ac0d2357b8363780b1dc47eccc49b12989a61da2727d4519b241a5eb5768046a72e1',
                            '012345678');
INSERT INTO OrgAuthorization VALUES (1, 2, 'Invisible');
