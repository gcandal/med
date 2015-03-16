DROP TABLE IF EXISTS OrgInvitation;
DROP TABLE IF EXISTS ProcedureInvitation;
DROP TABLE IF EXISTS OrgAuthorization;
DROP TABLE IF EXISTS ProcedureOrganization;
DROP TABLE IF EXISTS Organization;
DROP TABLE IF EXISTS ProcedureProcedureType;
DROP TABLE IF EXISTS ProcedureAccount;
DROP TABLE IF EXISTS ProcedureType;
DROP TABLE IF EXISTS Procedure;
DROP TABLE IF EXISTS Professional;
DROP TABLE IF EXISTS LoginAttempts;
DROP TABLE IF EXISTS PrivatePayer;
DROP TABLE IF EXISTS EntityPayer;
DROP TABLE IF EXISTS Patient;
DROP TABLE IF EXISTS Account;
DROP TABLE IF EXISTS Speciality;

DROP DOMAIN IF EXISTS Email;
DROP DOMAIN IF EXISTS NIF;
DROP DOMAIN IF EXISTS LicenseId;
DROP DOMAIN IF EXISTS Cellphone;

DROP TYPE IF EXISTS ProcedurePaymentStatus;
DROP TYPE IF EXISTS EntityType;
DROP TYPE IF EXISTS OrgAuthorizationType;
DROP TYPE IF EXISTS RoleInProcedureType;
DROP TYPE IF EXISTS UserTitle;

------------------------------------------------------------------------

CREATE TYPE ProcedurePaymentStatus AS ENUM ('Recebi', 'Paguei', 'Pendente');
CREATE TYPE EntityType AS ENUM ('Hospital', 'Insurance');
CREATE TYPE OrgAuthorizationType AS ENUM ('AdminVisible', 'AdminNotVisible', 'Visible', 'NotVisible');
CREATE TYPE RoleInProcedureType AS ENUM ('General', 'FirstAssistant', 'SecondAssistant', 'Anesthetist', 'Instrumentist');
CREATE TYPE UserTitle AS ENUM ('Dr.', 'Dra.');

------------------------------------------------------------------------

CREATE DOMAIN Email VARCHAR(254)
CONSTRAINT validEmail
CHECK (VALUE ~ '^[a-zA-Z0-9._%+-]+\@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');

CREATE DOMAIN NIF CHAR(9)
CONSTRAINT validNIF
CHECK (VALUE ~ '\d{9}');

CREATE DOMAIN LicenseId CHAR(9)
CONSTRAINT validLicenseId
CHECK (VALUE ~ '\d+');

CREATE DOMAIN Cellphone VARCHAR(14)
CONSTRAINT validCellphone
CHECK (VALUE ~ '^((\+|00)\d{1,3})?\d{9}$');

------------------------------------------------------------------------

CREATE TABLE Speciality (
  idSpeciality SERIAL PRIMARY KEY,
  name         VARCHAR(50)
);

CREATE TABLE Account (
  idAccount     SERIAL PRIMARY KEY,
  name          VARCHAR(40) NOT NULL,
  email         Email       NOT NULL UNIQUE,
  password      CHAR(128)   NOT NULL,
  salt          CHAR(128)   NOT NULL,
  licenseId     LicenseId   NOT NULL UNIQUE,
  speciality    INTEGER     NOT NULL REFERENCES Speciality (idSpeciality) ON DELETE SET DEFAULT DEFAULT 3,
  validUntil    DATE        NOT NULL                                                            DEFAULT CURRENT_DATE +
                                                                                                        INTERVAL '1 year',
  freeRegisters INTEGER     NOT NULL                                                            DEFAULT -1,
  title         UserTitle   NOT NULL                                                            DEFAULT 'Dr.',
  CHECK (freeRegisters >= -1)
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
  name           VARCHAR(40) NOT NULL,
  valuePerK      REAL
);

CREATE TABLE Professional (
  idProfessional SERIAL PRIMARY KEY,
  idSpeciality   INTEGER NOT NULL REFERENCES Speciality (idSpeciality),
  idAccount      INTEGER NOT NULL REFERENCES Account (idAccount),
  name           VARCHAR(40),
  email          EMAIL,
  nif            NIF,
  licenseId      LicenseId,
  createdOn      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Patient (
  idPatient     SERIAL PRIMARY KEY,
  idAccount     INTEGER NOT NULL REFERENCES Account (idAccount),
  name          VARCHAR(40),
  nif           NIF,
  cellphone     CELLPHONE,
  beneficiaryNr VARCHAR(40)
);

CREATE TABLE ProcedureType (
  idProcedureType SERIAL PRIMARY KEY,
  name            VARCHAR(256)              NOT NULL,
  K               FLOAT                     NOT NULL,
  C               FLOAT                     NOT NULL,
  code            CHAR(11) UNIQUE           NOT NULL
);

CREATE TABLE Procedure (
  idProcedure          SERIAL PRIMARY KEY,
  paymentStatus        ProcedurePaymentStatus NOT NULL                                               DEFAULT 'Pendente',
  idPrivatePayer       INTEGER REFERENCES PrivatePayer (idPrivatePayer),
  idPatient            INTEGER REFERENCES Patient (idPatient),
  idGeneral            INTEGER REFERENCES Professional (idProfessional),
  idFirstAssistant     INTEGER REFERENCES Professional (idProfessional),
  idSecondAssistant    INTEGER REFERENCES Professional (idProfessional),
  idAnesthetist        INTEGER REFERENCES Professional (idProfessional),
  idInstrumentist      INTEGER REFERENCES Professional (idProfessional),
  date                 DATE                   NOT NULL                                               DEFAULT CURRENT_DATE,
  valuePerK            FLOAT                  NOT NULL                                               DEFAULT 0,
  totalRemun           FLOAT                  NOT NULL                                               DEFAULT 0,
  generalRemun         FLOAT                  NOT NULL                                               DEFAULT 0,
  firstAssistantRemun  FLOAT                  NOT NULL                                               DEFAULT 0,
  secondAssistantRemun FLOAT                  NOT NULL                                               DEFAULT 0,
  anesthetistRemun     FLOAT                  NOT NULL                                               DEFAULT 0,
  instrumentistRemun   FLOAT                  NOT NULL                                               DEFAULT 0,
  hasManualK           BOOLEAN                NOT NULL                                               DEFAULT FALSE,
  localAnesthesia      BOOLEAN                NOT NULL                                               DEFAULT FALSE,
  generalK             FLOAT                  NOT NULL                                               DEFAULT 0,
  firstAssistantK      FLOAT                  NOT NULL                                               DEFAULT 0,
  secondAssistantK     FLOAT                  NOT NULL                                               DEFAULT 0,
  anesthetistK         FLOAT                  NOT NULL                                               DEFAULT 0,
  instrumentistK       FLOAT                  NOT NULL                                               DEFAULT 0
);

CREATE TABLE ProcedureAccount (
  idProcedure   INTEGER             NOT NULL REFERENCES Procedure (idProcedure) ON DELETE CASCADE,
  idAccount     INTEGER             NOT NULL REFERENCES Account (idAccount) ON DELETE CASCADE,
  role          RoleInProcedureType NOT NULL,
  readOnly      BOOLEAN             NOT NULL DEFAULT TRUE,
  personalremun FLOAT               NOT NULL DEFAULT 0,
  PRIMARY KEY (idProcedure, idAccount)
);

CREATE TABLE ProcedureOrganization (
  idProcedure    INTEGER NOT NULL REFERENCES Procedure (idProcedure) ON DELETE CASCADE,
  idOrganization INTEGER NOT NULL REFERENCES Organization (idOrganization) ON DELETE CASCADE,
  idAccount      INTEGER NOT NULL REFERENCES Account (idAccount) ON DELETE CASCADE,
  PRIMARY KEY (idProcedure, idAccount, idOrganization)
);

CREATE TABLE ProcedureProcedureType (
  idProcedure     INTEGER NOT NULL REFERENCES Procedure (idProcedure) ON DELETE CASCADE,
  idProcedureType INTEGER NOT NULL REFERENCES ProcedureType (idProcedureType) ON DELETE CASCADE,
  quantity        INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (idProcedure, idProcedureType)
);

CREATE TABLE OrgInvitation (
  idOrganization    INTEGER   NOT NULL REFERENCES Organization (idOrganization) ON DELETE CASCADE,
  idInvitingAccount INTEGER   NOT NULL REFERENCES Account (idAccount) ON DELETE CASCADE,
  licenseIdInvited  LicenseId NOT NULL, -- Não tem referência para manter anonimato, ON DELETE CASCADE
  forAdmin          BOOL      NOT NULL,
  wasRejected       BOOL      NOT NULL DEFAULT FALSE,
  date              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (idOrganization, idInvitingAccount, licenseIdInvited)
);

CREATE TABLE ProcedureInvitation (
  idProcedure       INTEGER             NOT NULL REFERENCES Procedure (idProcedure) ON DELETE CASCADE,
  idInvitingAccount INTEGER             NOT NULL REFERENCES Account (idAccount) ON DELETE CASCADE,
  licenseIdInvited  LicenseId           NOT NULL, -- Não tem referência para manter anonimato, ON DELETE CASCADE
  wasRejected       BOOL                NOT NULL DEFAULT FALSE,
  role              roleinproceduretype NOT NULL,
  personalRemun     FLOAT               NOT NULL,
  PRIMARY KEY (idProcedure, idInvitingAccount, licenseIdInvited)
);