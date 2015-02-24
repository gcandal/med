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

DROP TYPE IF EXISTS ProcedurePaymentStatus;
DROP TYPE IF EXISTS EntityType;
DROP TYPE IF EXISTS OrgAuthorizationType;
DROP TYPE IF EXISTS RoleInProcedureType;
DROP TYPE IF EXISTS Cellphone;

------------------------------------------------------------------------

CREATE TYPE ProcedurePaymentStatus AS ENUM ('Recebi', 'Paguei', 'Pendente');
CREATE TYPE EntityType AS ENUM ('Hospital', 'Insurance');
CREATE TYPE OrgAuthorizationType AS ENUM ('AdminVisible', 'AdminNotVisible', 'Visible', 'NotVisible');
CREATE TYPE RoleInProcedureType AS ENUM ('General', 'FirstAssistant', 'SecondAssistant', 'Anesthetist', 'Instrumentist');

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
  paymentStatus        ProcedurePaymentStatus NOT NULL DEFAULT 'Pendente',
  idPrivatePayer       INTEGER REFERENCES PrivatePayer (idPrivatePayer),
  idPatient            INTEGER REFERENCES Patient (idPatient),
  idGeneral            INTEGER REFERENCES Professional (idProfessional),
  idFirstAssistant     INTEGER REFERENCES Professional (idProfessional),
  idSecondAssistant    INTEGER REFERENCES Professional (idProfessional),
  idAnesthetist        INTEGER REFERENCES Professional (idProfessional),
  idInstrumentist      INTEGER REFERENCES Professional (idProfessional),
  date                 DATE                   NOT NULL DEFAULT CURRENT_DATE,
  valuePerK            FLOAT,
  totalRemun           FLOAT                           DEFAULT 0,
  generalRemun         FLOAT                           DEFAULT 0,
  firstAssistantRemun  FLOAT                           DEFAULT 0,
  secondAssistantRemun FLOAT                           DEFAULT 0,
  anesthetistRemun     FLOAT                           DEFAULT 0,
  instrumentistRemun   FLOAT                           DEFAULT 0,
  hasManualK           BOOLEAN                NOT NULL DEFAULT FALSE,
  localAnesthesia      BOOLEAN                NOT NULL DEFAULT FALSE,
  anesthetistK         VARCHAR(5)
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

CREATE OR REPLACE FUNCTION share_procedure_with_all(idp INTEGER, ida INTEGER)
  RETURNS VOID AS $$
DECLARE
BEGIN
  INSERT INTO ProcedureInvitation (idprocedure, idinvitingaccount, licenseidinvited, role, personalremun)
    SELECT
      idp,
      ida,
      licenseid,
      CASE WHEN Professional.idProfessional = idgeneral THEN 'General'
      WHEN Professional.idProfessional = idfirstassistant THEN 'FirstAssistant'
      WHEN Professional.idProfessional = idsecondassistant THEN 'SecondAssistant'
      WHEN Professional.idProfessional = idanesthetist THEN 'Instrumentist'
      ELSE 'Anesthetist' END :: roleinproceduretype,
      CASE WHEN Professional.idProfessional = idgeneral THEN generalRemun
      WHEN Professional.idProfessional = idfirstassistant THEN firstAssistantRemun
      WHEN Professional.idProfessional = idsecondassistant THEN secondAssistantRemun
      WHEN Professional.idProfessional = idanesthetist THEN instrumentistRemun
      ELSE anesthetistRemun END
    FROM Procedure, Professional
    WHERE
      Procedure.idprocedure = idp
      AND (Professional.idProfessional = idgeneral
           OR Professional.idProfessional = idfirstassistant
           OR Professional.idProfessional = idsecondassistant
           OR Professional.idProfessional = idanesthetist
           OR Professional.idProfessional = idinstrumentist)
      AND licenseid IS NOT NULL
      AND NOT EXISTS(SELECT *
                     FROM procedureinvitation
                     WHERE procedureinvitation.idprocedure = idp AND
                           procedureinvitation.idInvitingAccount = ida AND
                           procedureinvitation.licenseidinvited = licenseid)
      AND NOT EXISTS(SELECT *
                     FROM account, procedureaccount
                     WHERE procedureaccount.idprocedure = idp AND
                           procedureaccount.idaccount = account.idaccount AND
                           account.licenseid = Professional.licenseid);
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_procedureaccount_trigger()
  RETURNS TRIGGER AS $$
DECLARE
BEGIN
  IF NOT EXISTS(SELECT idprocedure
                FROM ProcedureAccount
                WHERE idProcedure = OLD.idProcedure)
  THEN
    DELETE FROM Procedure
    WHERE idProcedure = OLD.idProcedure;
  END IF;

  RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_procedureaccount_trigger()
  RETURNS TRIGGER AS $$
DECLARE
BEGIN
  INSERT INTO Professional (idSpeciality, idAccount, name, nif, licenseid)
    SELECT
      idSpeciality,
      NEW.idAccount,
      Professional.name,
      Professional.nif,
      Professional.licenseid
    FROM Professional, Procedure, Account
    WHERE idProcedure = NEW.idProcedure AND Account.idAccount = NEW.idAccount AND (
      idProfessional = idgeneral OR idProfessional = idfirstassistant OR idProfessional = idsecondassistant OR
      idProfessional = idinstrumentist OR idProfessional = idanesthetist) AND Professional.idAccount != NEW.idAccount
          AND Professional.licenseid != Account.licenseid;

  INSERT INTO PrivatePayer (idaccount, name, valuePerK)
    SELECT
      NEW.idaccount,
      name,
      PrivatePayer.valueperk
    FROM PrivatePayer, Procedure
    WHERE idProcedure = NEW.idProcedure AND Procedure.idPrivatePayer > 6 AND PrivatePayer.idPrivatePayer = Procedure.idPrivatePayer AND
          idAccount != NEW.idAccount;

  RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_professional_trigger()
  RETURNS TRIGGER AS $$
DECLARE
BEGIN
  IF EXISTS(SELECT 1
            FROM Professional
            WHERE Professional.idAccount = NEW.idAccount
                  AND Professional.name = NEW.name)
  THEN
    UPDATE Professional
    SET licenseId = NEW.licenseId, idSpeciality = NEW.idSpeciality
    WHERE Professional.idAccount = NEW.idAccount
          AND Professional.name = NEW.name;

    RETURN NULL;
  END IF;

  RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION edit_procedure_trigger()
  RETURNS TRIGGER AS $$
DECLARE
  arow RECORD;
BEGIN
  DELETE FROM ProcedureInvitation
  WHERE idProcedure = NEW.idProcedure
        AND licenseIdInvited NOT IN
            (SELECT licenseid
             FROM Professional
             WHERE (Professional.idProfessional = NEW.idgeneral
                    OR Professional.idProfessional = NEW.idfirstassistant
                    OR Professional.idProfessional = NEW.idsecondassistant
                    OR Professional.idProfessional = NEW.idanesthetist
                    OR Professional.idProfessional = NEW.idinstrumentist)
                   AND licenseid IS NOT NULL);

  FOR arow IN SELECT
                idProfessional,
                Account.idAccount,
                Account.licenseId
              FROM Procedure, Professional, Account
              WHERE
                Procedure.idprocedure = NEW.idProcedure
                AND (Professional.idProfessional = idgeneral
                     OR Professional.idProfessional = idfirstassistant
                     OR Professional.idProfessional = idsecondassistant
                     OR Professional.idProfessional = idanesthetist
                     OR Professional.idProfessional = idinstrumentist)
                AND Professional.licenseid IS NOT NULL
                AND Account.licenseid = Professional.licenseid
  LOOP
    UPDATE ProcedureAccount
    SET
      role          = CASE WHEN arow.idProfessional = NEW.idgeneral THEN 'General'
                      WHEN arow.idProfessional = NEW.idfirstassistant THEN 'FirstAssistant'
                      WHEN arow.idProfessional = NEW.idsecondassistant THEN 'SecondAssistant'
                      WHEN arow.idProfessional = NEW.idanesthetist THEN 'Instrumentist'
                      ELSE 'Anesthetist' END :: roleinproceduretype,

      personalRemun = CASE WHEN arow.idProfessional = NEW.idgeneral THEN NEW.generalRemun
                      WHEN arow.idProfessional = NEW.idfirstassistant THEN NEW.firstAssistantRemun
                      WHEN arow.idProfessional = NEW.idsecondassistant THEN NEW.secondAssistantRemun
                      WHEN arow.idProfessional = NEW.idanesthetist THEN NEW.instrumentistRemun
                      ELSE NEW.anesthetistRemun END
    WHERE idAccount = arow.idAccount AND idProcedure = NEW.idProcedure;

    UPDATE ProcedureInvitation
    SET
      role          = CASE WHEN arow.idProfessional = NEW.idgeneral THEN 'General'
                      WHEN arow.idProfessional = NEW.idfirstassistant THEN 'FirstAssistant'
                      WHEN arow.idProfessional = NEW.idsecondassistant THEN 'SecondAssistant'
                      WHEN arow.idProfessional = NEW.idanesthetist THEN 'Instrumentist'
                      ELSE 'Anesthetist' END :: roleinproceduretype,

      personalRemun = CASE WHEN arow.idProfessional = NEW.idgeneral THEN NEW.generalRemun
                      WHEN arow.idProfessional = NEW.idfirstassistant THEN NEW.firstAssistantRemun
                      WHEN arow.idProfessional = NEW.idsecondassistant THEN NEW.secondAssistantRemun
                      WHEN arow.idProfessional = NEW.idanesthetist THEN NEW.instrumentistRemun
                      ELSE NEW.anesthetistRemun END
    WHERE licenseIdinvited = arow.licenseId;
  END LOOP;


  RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_account_trigger()
  RETURNS TRIGGER AS $$
DECLARE
BEGIN
  INSERT INTO PrivatePayer VALUES (DEFAULT, NEW.idAccount, 'Médis', 3);
  INSERT INTO PrivatePayer VALUES (DEFAULT, NEW.idAccount, 'Multicare', 3.75);
  INSERT INTO PrivatePayer VALUES (DEFAULT, NEW.idAccount, 'Advancecare', 3.5);
  INSERT INTO PrivatePayer VALUES (DEFAULT, NEW.idAccount, 'Allianz', 3.75);
  INSERT INTO PrivatePayer VALUES (DEFAULT, NEW.idAccount, 'SSCGD', 2.8);
  INSERT INTO PrivatePayer VALUES (DEFAULT, NEW.idAccount, 'SAMS Quadros', 4);

  RETURN NEW;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS delete_procedureaccount_trigger ON ProcedureAccount;
CREATE TRIGGER delete_procedureaccount_trigger
AFTER DELETE ON ProcedureAccount
FOR EACH ROW EXECUTE PROCEDURE delete_procedureaccount_trigger();

DROP TRIGGER IF EXISTS insert_procedureaccount_trigger ON ProcedureAccount;
CREATE TRIGGER insert_procedureaccount_trigger
AFTER INSERT ON ProcedureAccount
FOR EACH ROW EXECUTE PROCEDURE insert_procedureaccount_trigger();

DROP TRIGGER IF EXISTS edit_procedure_trigger ON ProcedureAccount;
CREATE TRIGGER edit_procedure_trigger
AFTER UPDATE ON Procedure
FOR EACH ROW EXECUTE PROCEDURE edit_procedure_trigger();

DROP TRIGGER IF EXISTS insert_professional_trigger ON Professional;
CREATE TRIGGER insert_professional_trigger
BEFORE INSERT ON Professional
FOR EACH ROW EXECUTE PROCEDURE insert_professional_trigger();

DROP TRIGGER IF EXISTS insert_account_trigger ON Account;
CREATE TRIGGER insert_account_trigger
AFTER INSERT ON Account
FOR EACH ROW EXECUTE PROCEDURE insert_account_trigger();

INSERT INTO Speciality VALUES (DEFAULT, 'Anestesiologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Enfermagem');
INSERT INTO Speciality VALUES (DEFAULT, 'Nenhuma');
INSERT INTO Speciality VALUES (DEFAULT, 'Anatomia Patológica');
INSERT INTO Speciality VALUES (DEFAULT, 'Angiologia e Cirurgia Vascular');
INSERT INTO Speciality VALUES (DEFAULT, 'Cardiologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Cardiologia Pediátrica');
INSERT INTO Speciality VALUES (DEFAULT, 'Cirurgia Cardiotorácica');
INSERT INTO Speciality VALUES (DEFAULT, 'Cirurgia Geral');
INSERT INTO Speciality VALUES (DEFAULT, 'Cirurgia Maxilo-Facial');
INSERT INTO Speciality VALUES (DEFAULT, 'Cirurgia Pediátrica');
INSERT INTO Speciality VALUES (DEFAULT, 'Cirurgia Plástica Reconstrutiva e Estética');
INSERT INTO Speciality VALUES (DEFAULT, 'Dermato-Venereologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Doenças Infecciosas');
INSERT INTO Speciality VALUES (DEFAULT, 'Endocrinologia e Nutrição');
INSERT INTO Speciality VALUES (DEFAULT, 'Estomatologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Gastrenterologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Genética Médica');
INSERT INTO Speciality VALUES (DEFAULT, 'Ginecologia/Obstetrícia');
INSERT INTO Speciality VALUES (DEFAULT, 'Imunoalergologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Imunohemoterapia');
INSERT INTO Speciality VALUES (DEFAULT, 'Farmacologia Clínica');
INSERT INTO Speciality VALUES (DEFAULT, 'Hematologia Clínica');
INSERT INTO Speciality VALUES (DEFAULT, 'Medicina Desportiva');
INSERT INTO Speciality VALUES (DEFAULT, 'Medicina do Trabalho');
INSERT INTO Speciality VALUES (DEFAULT, 'Medicina Física e de Reabilitação');
INSERT INTO Speciality VALUES (DEFAULT, 'Medicina Geral e Familiar');
INSERT INTO Speciality VALUES (DEFAULT, 'Medicina Interna');
INSERT INTO Speciality VALUES (DEFAULT, 'Medicina Legal');
INSERT INTO Speciality VALUES (DEFAULT, 'Medicina Nuclear');
INSERT INTO Speciality VALUES (DEFAULT, 'Medicina Tropical');
INSERT INTO Speciality VALUES (DEFAULT, 'Nefrologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Neurocirurgia');
INSERT INTO Speciality VALUES (DEFAULT, 'Neurologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Neurorradiologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Oftalmologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Oncologia Médica');
INSERT INTO Speciality VALUES (DEFAULT, 'Ortopedia');
INSERT INTO Speciality VALUES (DEFAULT, 'Otorrinolaringologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Patologia Clínica');
INSERT INTO Speciality VALUES (DEFAULT, 'Pediatria');
INSERT INTO Speciality VALUES (DEFAULT, 'Pneumologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Psiquiatria');
INSERT INTO Speciality VALUES (DEFAULT, 'Psiquiatria da Infância e da Adolescência');
INSERT INTO Speciality VALUES (DEFAULT, 'Radiologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Radioncologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Reumatologia');
INSERT INTO Speciality VALUES (DEFAULT, 'Saúde Pública');
INSERT INTO Speciality VALUES (DEFAULT, 'Urologia');

INSERT INTO ProcedureType
VALUES (DEFAULT, 'Consultas no Consultório - Não Especialista-1a. Consulta', 10, 0, '01.00.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Consultas no Consultório - Não Especialista-2a. Consulta', 8, 0, '01.00.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Consultas no Consultório - Especialista-1a. Consulta', 12, 0, '01.00.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Consultas no Consultório - Especialista-2a. Consulta', 10, 0, '01.00.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Consultas no Consultório - Psiquiatria e Oftalmologia-1a. consulta', 14, 0, '01.00.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Consultas no Consultório - Psiquiatria e Oftalmologia-2a. consulta', 12, 0, '01.00.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Consultas no Domicílio - Não Especialista-1a. consulta', 15, 0, '01.01.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Consultas no Domicílio - Não Especialista-2a. consulta', 12, 0, '01.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Domicílio - Especialista-1a. Consulta', 18, 0, '01.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Domicílio - Especialista-2a. Consulta', 15, 0, '01.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Domicílio - Psiquiatria-1a. Consulta', 21, 0, '01.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Domicílio - Psiquiatria-2a. Consulta', 18, 0, '01.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Não Especialista-1a. Consulta', 20, 0, '01.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Não Especialista-2a. Consulta', 15, 0, '01.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Especialista-1a. Consulta', 24, 0, '01.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Especialista-2a. consulta', 20, 0, '01.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Psiquiatria-1a. consulta', 28, 0, '01.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Psiquiatria-2a. consulta', 24, 0, '01.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame pericial com relatório', 40, 0, '01.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame pericial em testamento', 60, 0, '01.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Relatório do processo clínico', 6, 0, '01.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Deslocação', 0, 0, '01.03.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acompanhamento permanente do doente (por dia)', 100, 0, '01.03.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação do tratamento inicial do doente em condição crítica (até 1a. hora)', 30, 0, '01.03.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Assistência permanente adicional (cada 1 hora)', 20, 0, '01.03.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame sob anestesia geral (como acto médico)', 12, 0, '01.03.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Assistência a actos operatórios (por hora)', 20, 0, '01.03.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Observação de um recém-nascido', 25, 0, '01.03.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Assistência pediátrica ao parto, e observação de recém-nascido', 30, 0, '01.03.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Algaliação na Mulher', 1, 0, '02.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Algaliação no Homem', 3, 0, '02.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Paracentese', 5, 0, '02.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pericardiocentese', 20, 0, '02.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Torancentese', 15, 0, '02.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção testicular', 6, 0, '02.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção articular', 6, 0, '02.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção da bolsa sub-deltoideia', 6, 0, '02.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção prostática', 6, 0, '02.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção lombar-terapêutica ou exploradora', 8, 0, '02.00.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Punção com drenagem de derrame pleural ou peritoneal', 10, 0, '02.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aspiração de abcesso, hematoma, seroma ou quisto', 6, 0, '02.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colpocentese', 6, 0, '02.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de cateter umbilical no RN', 6, 0, '02.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento arterial ou venoso', 20, 0, '02.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exanguíneo transfusão', 60, 0, '02.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transfusão fetal intra-uterina', 80, 0, '02.00.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Punção femoral, jugular ou do seio longitudinal superior', 3, 0, '02.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transfusão ou perfusão intravenosa (Aplicação)', 3, 0, '02.00.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perfusão epicraniana', 3, 0, '02.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colheita de sangue fetal', 20, 0, '02.00.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intubação gástrica', 3, 0, '02.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intubação duodenal', 9, 0, '02.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lavagem gástrica', 6, 0, '02.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção arterial', 3, 0, '02.00.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pensos', 0, 2, '02.00.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infusão para quimioterapia', 5, 0, '03.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção intracavitária para quimioterapia', 8, 0, '03.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção intratecal para quimioterapia', 10, 0, '03.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção esclerosante de varizes (por sessão)', 10, 0, '03.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras injecções', 5, 0, '03.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consulta de grupo', 3, 0, '04.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica convulsivante (electrochoque)', 8, 0, '04.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica insulínica', 8, 0, '04.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testes psicológicos', 8, 0, '04.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bateria de testes psicológicos, com relatório', 30, 0, '04.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Relatório médico-legal', 80, 0, '04.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemodiálise aguda', 10, 180, '05.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemodiálise crónica com filtro novo', 6, 180, '05.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemodiálise crónica com filtro reutilizado', 6, 160, '05.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemodiálise com bicarbonato acresce', 0, 15, '05.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemodiálise pediátrica acresce', 0, 15, '05.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemodiálise em doentes HBs Ag positivos acresce', 0, 15, '05.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemofiltração contínua arteriovenosa', 6, 320, '05.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemoperfusão', 6, 320, '05.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plasmaferese', 6, 320, '05.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação esofágica (cada sessão)', 10, 5, '06.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação esofágica (por endoscopia)', 30, 27, '06.00.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de varizes por via endoscópica (esclerose)', 30, 25, '06.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho por via endoscópica', 30, 25, '06.00.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colocação de prótese esofágica (excluindo a prótese)', 65, 27, '06.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tamponamento de varizes esofágicas', 25, 0, '06.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia por cápsula', 10, 15, '06.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Manometria esofágica', 20, 10, '06.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quimismo gástrico, basal', 3, 0, '06.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quimismo gástrico, com estimulação', 6, 0, '06.00.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Pancreatografia e/ou colangiografia retrógada (CPRE)', 40, 50, '06.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esfincterotomia transendoscópica', 50, 80, '06.00.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Esfincterotomia transendoscópica com extracção de cálculo', 60, 80, '06.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de cálculo por via transendoscópica', 50, 50, '06.00.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colocação transcutânea de prótese de drenagem biliar', 50, 0, '06.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colangiografia percutânea (CPT)', 30, 0, '06.00.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Implantação endoscópica da prótese de drenagem biliar', 50, 50, '06.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento esclerosante de hemorróidas (por sessão)', 6, 0, '06.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção sub-fissurária', 5, 0, '06.00.00.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de hemorróidas por laqueação elástica (por sessão)', 6, 0, '06.00.00.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Polipectomia do rectosigmoide com tubo rígido (incluindo exame endoscópico)', 20, 10, '06.00.00.21');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Polipectomia do tubo digestivo a adicionar ao respectivo exame endoscópico', 10, 30, '06.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colheita de material para citologia esfoliativa', 3, 0, '06.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Determinação do pH por eléctrodo no tubo digestivo', 10, 20, '06.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pneumoperitoneo', 20, 0, '06.00.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retropneumoperitoneo', 25, 0, '06.00.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrostomia por via endoscópica', 50, 30, '06.00.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hemorróidas por infravermelhos', 6, 5, '06.00.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hemorróidas por criocoagulação', 10, 10, '06.00.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecoendoscopia', 50, 200, '06.00.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Manometria ano-rectal', 30, 25, '06.00.00.31');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Terapêutica hemostática (não varicosa) a adicionar ao respectivo exame endoscópico', 20, 10,
   '06.00.00.32');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Terapêutica por raio laser a adicionar ao respectivo exame endoscópico (cada sessão)', 30, 100,
   '06.00.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Litotripsia biliar extracorporal', 50, 250, '06.00.00.34');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Teste Respiratório com Carbono 13 (diagnóstico da infecção pelo Helicobacter pylori)', 3, 35,
   '06.00.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame oftalmológico completo sob anestesia geral, com ou sem manipulação do globo ocular, para diagnóstico inicial, relatório médico',
                                  30, 0, '07.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gonioscopia', 6, 2, '07.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo moto-sensorial efectuado ao sinoptóforo', 12, 7, '07.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sessão de tratamento ortóptico ou pleóptico', 4, 4, '07.00.00.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Avaliação da visão binocular de perto e longe com testes subjectivos de fixação', 6, 2, '07.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gráfico sinoptométrico', 18, 5, '07.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gráfico de Hess', 10, 5, '07.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Campo visual binocular', 16, 5, '07.00.00.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Adaptação de lentes de contacto com fins terapêuticos (não inclui o preço da lente)', 12, 0,
   '07.00.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação de campos visuais, exame limitado (estimulos simples/equivalentes)', 12, 5, '07.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Avaliação dos campos visuais, exame intermédio (estimulos múltiplos, compo completo, vária esoptéras no perímetro Goldmann/equivalente)',
                                  18, 5, '07.00.00.11');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Avaliação dos campos visuais, exame extenso (perimetria quantitativa, estática ou cinética)', 30, 8,
   '07.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perimetria computadorizada', 15, 20, '07.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Curva tonométrica de 24 horas', 30, 0, '07.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tonografia', 15, 10, '07.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tonografia com testes de provocação de glaucoma', 18, 10, '07.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testes de provocação de glaucoma sem tonografia', 8, 0, '07.00.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Elaboração de relatório médico com base nos elementos do processo clínico', 12, 0, '07.00.00.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exame oftalmológico para fins médico legais com relatório', 20, 0, '07.00.00.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Conferência médica interdisciplinar ou inter-serviços', 20, 0, '07.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Oftalmoscopia indirecta completa (inclui interposição lente, desenho/esquema e/ou biomicroscopia do fundo)',
                                  20, 2, '07.00.00.21');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Angioscopia fluoresceínica, fotografias seriadas, relatório médico', 40, 30, '07.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oftalmodinamometria', 10, 1, '07.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retinorrafia', 10, 20, '07.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia scan laser oftalmológico', 25, 80, '07.00.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinevideoangiografia', 35, 40, '07.00.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia com verde indocianina', 45, 40, '07.00.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Eco Doppler “Duplex Scan” Carótideo/Oftalmológico', 30, 120, '07.00.00.28');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electro-oculomiografia, 1 ou mais músculos extraoculares, relatório', 40, 40, '07.00.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electro-oculografia com registo e relatório', 40, 40, '07.00.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electro-retinografia com registo e relatório', 40, 40, '07.00.00.31');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo dos potenciais occipitais evocados e relatório', 40, 40, '07.00.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo elaborado da visão cromática', 25, 10, '07.00.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Adaptometria', 20, 10, '07.00.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotografia de aspetos oculares externos', 10, 10, '07.00.00.35');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fotografia especial do segmento anterior, com ou sem microscopia especular', 25, 10, '07.00.00.36');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fotografia do segmento anterior com angiografia fluoresceínica', 40, 40, '07.00.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fluofotometria do segmento anterior', 30, 20, '07.00.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fluofotometria do segmento posterior', 30, 20, '07.00.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Avaliação da acuidade visual por técnicas diferenciadas (interferometria, visão de sensibilidade ao contraste, visão mesópica e escotópica/outras)',
                                  15, 20, '07.00.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratoscopia fotográfia', 15, 15, '07.00.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratoscopia computorizada', 25, 15, '07.00.00.42');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Electronistagmografia e/ou electro-oculograma dinâmico com teste de nistagmo optocinético', 35, 20,
   '07.00.00.43');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biomicroscopia especular', 15, 20, '07.00.00.44');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prescrição e adaptação de próteses oculares (olho artificial)', 10, 0, '07.00.00.45');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prescrição de auxiliares ópticos em situação de subvisâo', 25, 20, '07.00.00.46');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia oftalmica A+B', 20, 30, '07.00.00.47');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ecografia oftalmica linear, análise espectral com quantificação da amplitude', 15, 20, '07.00.00.48');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia oftalmica bidimensional de contacto', 15, 20, '07.00.00.49');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biometria oftalmica por ecografia linear', 10, 20, '07.00.00.50');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Biometria oftalmica por ecografia linear com cálculo de potência da lente intraocular', 15, 20,
   '07.00.00.51');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Biometria oftalmica por ecografia linear com cálculo da espessura da córnea, paquimetria', 15, 20,
   '07.00.00.52');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ecografia oftalmica para localização de corpos estranhos', 15, 20, '07.00.00.53');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Localização radiológica de corpo estranho da região orbitária (anel Comberg/equivalente)', 15, 50,
   '07.00.00.54');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Biomicroscopia do fundo ocular ou visão camerular com lente de Goldmann', 10, 2, '07.00.00.55');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Audiograma tonal simples', 8, 10, '08.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Audiograma vocal', 10, 20, '08.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Audiometria automática (Beckesy)', 5, 8, '08.00.00.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Estudo auditivo completo (audiometria tonal e vocal, impedância, prova de fadiga e recobro)', 30, 50,
   '08.00.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Testes suplementares de audiometria (Tone Decay, Sisi, recobro, etc.) cada', 8, 10, '08.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acufenometria', 5, 10, '08.00.00.06');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Optimização do ganho auditivo de performance electro-acústica das próteses auditivas ""in situ"""', 10,
   40, '08.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rastreio da surdez do recém nascido', 5, 10, '08.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Audiometria tonal até 5 anos de idade', 25, 12, '08.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Audiometria tonal até 8 anos de idade', 20, 12, '08.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Audiometria vocal até 10 anos de idade', 20, 20, '08.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'ERA (incluindo BER e ECOG ou outra prova global)', 60, 140, '08.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrococleografia - traçado e protocolo', 60, 100, '08.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Respostas de tronco cerebral - traçado e protocolo', 50, 90, '08.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Respostas semi precoces - traçado e protocolo', 50, 90, '08.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Respostas auditivas corticais', 50, 90, '08.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Otoemissões', 10, 40, '08.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Teste do promontório', 60, 100, '08.02.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Timpanograma, incluindo a medição de compliance e volume do conduto externo', 8, 10, '08.03.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Pesquisa de reflexos acústicos ipsi-laterais ou contra-laterais', 5, 10, '08.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa do “Decay” do reflexo bilateral', 5, 10, '08.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de reflexos não acústicos', 5, 10, '08.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reflexograma de Metz', 5, 10, '08.03.00.05');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Estudo timpanométrico do funcionamento da trompa de Eustáquio (medição feita com ponte de admitância)', 5,
   10, '08.03.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Provas suplementares de timpanometria', 5, 10, '08.03.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Impedância ou admitância (incluindo timpanograma, medição de compliance, volume do conduto externo, reflexos acústicos ipsi e contra-laterais)',
                                  15, 25, '08.03.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame vestibular sumário (provas térmicas)', 10, 3, '08.04.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exame vestibular por electronistagmografia (E.N.G.)', 50, 90, '08.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'E.N.G. computorizada', 60, 140, '08.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Craniocorpografia', 10, 10, '08.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Posturografia estática', 50, 90, '08.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Posturografia dinâmica', 60, 200, '08.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electroneuronomiografia de superfície com auxílio de equipamento computorizado e.no.m.g (três avaliações sucessivas)',
                                  40, 90, '08.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electroneuronografia', 20, 60, '08.05.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estroboscopia', 20, 60, '08.06.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sonografia', 15, 10, '08.06.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glotografia', 10, 10, '08.06.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fonetograma', 10, 10, '08.06.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrogustometria', 10, 3, '08.07.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento método de PROETZ', 3, 3, '08.08.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rinodebitomanometria', 15, 20, '08.08.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames realizados sob indução medicamentosa', 10, 0, '08.09.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames realizados sob anestesia geral', 30, 0, '08.09.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Observação e tratamento sob microscopia', 5, 0, '08.09.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Fonocardiograma com registo simultâneo duma derivação electrocardiográfica e dum mecanograma de referência',
                                  9, 9, '09.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apexocardiograma', 7, 7, '09.00.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electrocardiograma simples de 12 derivações com interpretação e relatório', 6, 4, '09.00.00.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Electrocardiograma simples de 12 derivações com interpretação e relatório, no domicílio', 9, 9,
   '09.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Prova de esforço máxima ou submáxima em tapete rolante ou cicloergómetro com monitorização electrocardiográfica contínua, sob supervisão médica, com interpretação e relatório',
                                  40, 60, '09.00.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Vectocardiograma, com ou sem ECG, com interpretação e relatório', 10, 13, '09.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Monitorização electrocardiográfica contínua prolongada por método de Holter com gravação contínua, ""scanning"" por sobreposição ou impressão total miniaturizada e análise automática, efectuada sob supervisão médica, com interpretação e relatório"',
                                  20, 80, '09.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Monitorização electrocardiográfica contínua prolongada por método de Holter, com análise de dados em tempo real, gravação não contínua e registo intermitente, efectuada sob supervisão médica, com interpretação e relatório',
                                  12, 40, '09.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Monitorização electrocardiográfica prolongada com registo de eventos activado pelo doente com memorização pré e pós-sintomática, efectuada sob supervisão médica, com intrepretação',
                                  10, 20, '09.00.00.09');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Registo electrocardiográfico de alta resolução, com ou sem ECG de 12 derivações', 9, 10, '09.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Análise da variabilidade do intervalo RR', 9, 9, '09.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fluoroscopia cardíaca', 7, 20, '09.00.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Registo ambulatório prolongado (24h ou mais) da pressão arterial incluindo gravação, análise por ""scanning"", interpretação e relatório"',
                                  20, 80, '09.00.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Teste baroreflexo da função cardiovascular com mesa basculante (“tilt table”), com ou sem intervenção farmacológica',
                                  20, 50, '09.00.02.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ecocardiografia em tempo real (bidimensional), com registo de imagem, com ou sem registo em modo-M', 20,
   80, '09.00.03.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Idem, associada a ecografia Doppler, pulsada ou contínua, com análise espectral', 40, 190, '09.00.03.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ecocardiografia transesofágica em tempo real (bidimensional), com ou sem registo em modo-m, com inclusão de posicionamento da sonda, aquisição de imagem, interpretação e relatório',
                                  80, 220, '09.00.03.03');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ecocardiog. de sobrecarga em tempo real (bidim.), c/ou sem registo em modo-M, durante repouso e prova cardiov., c/ teste máx. ou submáx. em tap. rolante, cicloergométrico e/ou sobrec. farmac., incluindo monitorização electrocardiog., c/ interpret. e relat.',
                                  80, 240, '09.00.03.04');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ecocardiografia intra-operatória em tempo real (bidimensional), com registo de imagem, com ou sem registo em modo-M, com estudo Doppler, pulsado ou contínuo, com análise espectral, estudo completo, com interpretação e relatório',
                                  80, 200, '09.00.03.05');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Fonocardiograma com registo simultâneo duma derivação electrocardiográfica e dum mecanograma de referência',
                                  14, 14, '09.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apexocardiograma', 10, 7, '09.01.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electrocardiograma simples de 12 derivações com interpretação e relatório', 8, 6, '09.01.00.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Electrocardiograma simples de 12 derivações com interpretação e relatório, no domicílio', 14, 14,
   '09.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Prova de esforço máxima ou submáxima em tapete rolante ou cicloergómetro com monitorização electrocardiográfica contínua, sob supervisão médica, com interpretação e relatório',
                                  30, 75, '09.01.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Vectocardiograma, com ou sem ECG, com interpretação e relatório', 15, 20, '09.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Monitorização electrocardiográfica contínua prolongada por método de Holter com gravação contínua, ""scanning"" por sobreposição ou impressão total miniaturizada e análise automática, efectuada sob supervisão médica, com interpretação e relatório"',
                                  30, 100, '09.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Monitorização electrocardiográfica contínua prolongada por método de Holter, com análise de dados em tempo real, gravação não contínua e registo intermitente, efectuada sob supervisão médica, com interpretação e relatório',
                                  16, 35, '09.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Monitorização electrocardiográfica prolongada com registo de eventos activado pelo doente com memorização pré e pós sintomática, efectuada sob supervisão médica, com intrepretação',
                                  15, 20, '09.01.00.09');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Registo electrocardiográfico de alta resolução, com ou sem ECG de 12 derivações', 12, 10, '09.01.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Análise da variabilidade do intervalo RR', 12, 10, '09.01.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fluoroscopia cardíaca', 10, 20, '09.01.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Registo ambulatório prolongado (24h ou mais) da pressão arterial incluindo gravação, análise por ""scanning"", interpretação e relatório"',
                                  20, 40, '09.01.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Teste baroreflexo da função cardiovascular com mesa basculante (“tilt table”), com ou sem intervenção farmacológica',
                                  20, 50, '09.01.02.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ecocardiografia em tempo real (bidimensional), com registo de imagem, com ou sem registo em modo-M', 30,
   120, '09.01.03.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Idem, associada a ecografia Doppler, pulsada ou contínua, com análise espectral', 50, 16, '09.01.03.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ecocardiografia transesofágica em tempo real (bidimensional), com ou sem registo em modo-m, com inclusão de posicionamento da sonda, aquisição de imagem, interpretação e relatório',
                                  120, 190, '09.01.03.03');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ecocardiog. de sobrecarga em tempo real (bidim.), c/ou sem registo em modo-M, durante repouso e prova cardiov., c/ teste máx. ou submáx. em tap. rolante, cicloergométrico e/ou sobrec. farmac., incluindo monitorização electrocardiog., c/ interpret. e relat.',
                                  50, 100, '09.01.03.04');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ecocardiografia em tempo real (bidimensional), com registo de imagem, com ou sem registo em modo-M, com estudo Doppler, pulsado ou contínuo, com análise espectral, intra-operatória, estudo completo, com interpretação e relatório',
                                  45, 100, '09.01.03.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecocardiografia de contraste', 60, 150, '09.01.03.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecocardiografia fetal', 50, 190, '09.01.03.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo Doppler cardíaco fetal', 50, 190, '09.01.03.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco direito', 60, 0, '09.02.00.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Implantação e posicionamento de catéter de balão por cateterismo direito para monitorização (Swan-Ganz)',
   50, 0, '09.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo', 60, 0, '09.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo por via trans-septal', 105, 0, '09.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco direito e esquerdo', 105, 0, '09.02.00.05');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo cardíaco direito com angiografia (ventrículo direito ou artéria pulmonar)', 100, 0,
   '09.02.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia esquerda', 100, 0, '09.02.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com coronariografia selectiva', 110, 0, '09.02.00.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva', 115, 0,
   '09.02.00.09');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva e aortografia', 120,
   0, '09.02.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Cateterismo cardíaco esquerdo com ventriculografia esquerda, coronariografia selectiva, aortografia e cateterismo direito',
                                  145, 0, '09.02.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Cateterismo cardíaco esquerdo com ventriculografia esquerda, coronariografia selectiva, aortografia e cateterismo direito e visualização de ""bypasses"" aorto-coronários"',
                                  155, 0, '09.02.00.12');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Cateterismo cardíaco esquerdo com visualização de ""bypasses"" aorto-coronários"', 110, 0, '09.02.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova de provocação de espasmo coronário (ergonovina)', 75, 0, '09.02.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Estudos de medição de débito cardíaco com corantes indicadores ou por termodiluição, incluindo cateterismo arterial ou venoso',
                                  75, 0, '09.02.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, medições subsequentes', 15, 0, '09.02.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Registo electrocardiográfico transesofágico', 13, 0, '09.02.01.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Registo electrocardiográfico transesofágico com estimulação eléctrica (""pacing"")"', 18, 0,
   '09.02.01.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Registo do electrograma intra-auricular, do feixe de His, do ventrículo direito ou do ventrículo esquerdo',
   25, 0, '09.02.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Mapeamento intraventricular e/ou intra-auricular de focos de taquicardia com registo multifocal, para identificação da origem da taquicardia',
                                  35, 0, '09.02.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, '"Indução de arritmia por ""pacing"""', 45, 0, '09.02.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, '"""Pacing"" intra-auricular ou intraventricular"', 25, 0, '09.02.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Estudo electrofisiológico completo com ""pacing"" e/ou registo de auricula direita, ventrículo direito e feixe de His, com indução de arritmias, incluindo implantação e reposicionamento de múltiplos electro-catéteres"',
                                  130, 0, '09.02.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com indução de arritmias', 175, 0, '09.02.01.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Idem, com regiso de aurícula esquerda, seio coronário ou ventrículo esquerdo com ou sem ""pacing"""', 200,
   0, '09.02.01.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, '"Estimulação programada e ""pacing"" após infusão intravenosa de fármacos"', 70, 0, '09.02.01.10');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Estudo electrofisiológico de ""follow-up"" com ""pacing"" e registo para teste de eficácia de terapêutica, incluindo indução ou tentativa de indução de arritmia"',
                                  70, 0, '09.02.01.11');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo cardíaco esquerdo com coronariografia selectiva e angioscopia coronária', 130, 0,
   '09.02.02.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo cardíaco esquerdo com coronariografia selectiva e ultrassonografia intracoronária', 130, 0,
   '09.02.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia endomiocárdica', 55, 0, '09.02.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco direito (venoso)', 100, 0, '09.03.00.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Implantação e posicionamento de catéter de balão por cateterismo direito para monitorização (Swan-Ganz)',
   75, 0, '09.03.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo (por punção arterial)', 125, 0, '09.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo (por desbridamento)', 150, 0, '09.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo por via transeptal', 220, 0, '09.03.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco direito e esquerdo', 220, 0, '09.03.00.06');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo cardíaco direito com angiografia (ventrículo direito ou artéria pulmonar)', 120, 0,
   '09.03.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia esquerda', 150, 0, '09.03.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia e aortografia', 175, 0, '09.03.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com coronariografia selectiva', 200, 0, '09.03.00.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva', 220, 0,
   '09.03.00.11');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva e aortografia', 130,
   0, '09.03.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Cateterismo cardíaco esquerdo com ventriculografia esquerda, coronariografia selectiva, aortografia e cateterismo direito',
                                  300, 0, '09.03.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Cateterismo cardíaco esquerdo com ventriculografia esquerda, coronariografia selectiva, aortografia e cateterismo direito e visualização de ""bypasses"" aorto-coronários"',
                                  300, 0, '09.03.00.14');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Cateterismo cardíaco esquerdo com visualização de ""bypasses"" aorto-coronários"', 225, 0, '09.03.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Estudos de medição de débito cardíaco com corantes indicadores ou por termodiluição, incluindo cateterismo arterial ou venoso',
                                  125, 0, '09.03.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, medições subsequentes', 15, 0, '09.03.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Registo electrocardiográfico transesofágico', 30, 0, '09.03.01.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Registo electrocardiográfico transesofágico com estimulação eléctrica (""pacing"")"', 40, 0,
   '09.03.01.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Registo do electrograma intra-auricular, do feixe de His, do ventrículo direito ou do ventrículo esquerdo',
   50, 0, '09.03.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Mapeamento intraventricular e/ou intra-auricular de focos de taquicardia com registo multifocal, para identificação da origem da taquicardia',
                                  75, 0, '09.03.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, '"Indução de arritmia por ""pacing"""', 75, 0, '09.03.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, '"""Pacing"" intra-auricular ou intraventricular"', 50, 0, '09.03.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Estudo electrofisiológico completo com ""pacing"" e/ou registo de auricula direita, ventrículo direito e feixe de His, com indução de arritmias, incluindo implantação e reposicionamento de múltiplos electro-catéteres"',
                                  150, 0, '09.03.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com indução de arritmias', 175, 0, '09.03.01.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Idem, com registo de aurícula esquerda, seio coronário ou ventrículo esquerdo com ou sem ""pacing"""',
   180, 0, '09.03.01.09');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo cardíaco esquerdo com coronariografia selectiva e angioscopia coronária', 250, 0,
   '09.03.02.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo cardíaco esquerdo com coronariografia selectiva e ultrassonografia intracoronária', 250, 0,
   '09.03.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia endomiocárdica', 200, 0, '09.03.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cardioversão eléctrica externa, electiva', 45, 0, '09.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressuscitação cardio-respiratória', 35, 0, '09.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Colocação percutânea de dispositivo de assistência cardio-circulatória, v.g. balão intra-aórtico para contrapulsão',
                                  105, 0, '09.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, remoção', 55, 0, '09.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, controle', 30, 0, '09.04.00.05');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Trombólise coronária por infusão intracoronária, incluindo coronariografia selectiva', 80, 0,
   '09.04.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trombólise coronária por infusão intravenosa', 70, 0, '09.04.01.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Angioplastia coronária percutânea transluminal de um vaso', 250, 0, '09.04.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, por cada vaso adicional', 125, 0, '09.04.01.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, '"Implantação de prótese intracoronária (""stent"")"', 210, 0, '09.04.01.05');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Aterectomia percutânea trasluminal direccional coronária de Simpson de um vaso', 210, 0, '09.04.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, por cada vaso adicional', 80, 0, '09.04.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia pulmunar percutânea de balão', 230, 0, '09.04.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia tricúspide percutânea de balão', 195, 0, '09.04.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia aórtica percutânea de balão', 260, 0, '09.04.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia mitral percutânea de balão', 355, 0, '09.04.02.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação percutânea de coarctação da aorta', 195, 0, '09.04.02.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Atrioseptostomia transvenosa por balão, do tipo Rashkind', 230, 0, '09.04.02.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem por lâmina, do tipo Park', 230, 0, '09.04.02.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Encerramento percutâneo de canal arterial persistente', 310, 0, '09.04.02.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Encerramento percutâneo de comunicação interauricular', 310, 0, '09.04.02.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de comunicação interventricular', 310, 0, '09.04.02.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação de ramos da artéria pulmonar', 230, 0, '09.04.02.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação de estenoses de veias pulmonares', 230, 0, '09.04.02.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Embolização vascular', 230, 0, '09.04.02.13');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electrofisiologia de intervenção terapêutica, com ablacção de vias anómalas, por energia de radiofrequência',
                                  235, 0, '09.04.03.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electrofisiologia de intervenção terapêutica, com ablacção ou modulação da junção auriculo-ventricular, por energia de radiofrequência',
                                  200, 0, '09.04.03.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electrofisiologia de intervenção terapêutica, com ablacção de focos de taquidisritmia ventricular, por energia de radiofrequência',
                                  250, 0, '09.04.03.03');
INSERT INTO ProcedureType VALUES (DEFAULT, '"""Pacing"" temporário percutâneo"', 45, 0, '09.04.04.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Implantação de pacemaker permanente com eléctrodo transvenoso, auricular', 180, 0, '09.04.04.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Implantação de pacemaker permanente com eléctrodo transvenoso, ventricular', 180, 0, '09.04.04.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Implantação de pacemaker permanente com eléctrodo transvenoso, de dupla câmara', 195, 0, '09.04.04.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, '"Substituição de gerador ""pacemaker"", de uma ou duas câmaras"', 85, 0, '09.04.04.05');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Passagem de sistema ""pacemaker"" de câmara única a dupla câmara, (incluindo explantação do gerador anterior, teste do eléctrodo existente e implantação de novo eléctrodo e de novo gerador)"',
                                  185, 0, '09.04.04.06');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Revisão cirúrgica de sistema ""pacemaker"", sem substituição de gerador (incluindo substituição, reposicionamento ou reparação de eléctrodos transvenosos permanentes), cinco ou mais dias após implantação inicial"',
                                  70, 0, '09.04.04.07');
INSERT INTO ProcedureType VALUES (DEFAULT, '"Remoção de sistema ""pacemaker"""', 70, 0, '09.04.04.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Controlo electrónico do sistema ""pacemaker"" permanente de uma câmara, sem programação"', 4.5, 0,
   '09.04.04.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com programação', 6, 0, '09.04.04.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Controlo electrónico de sistema ""pacemaker"" permanente de dupla câmara, sem programação"', 6, 0,
   '09.04.04.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com programação', 8, 0, '09.04.04.12');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Implantação de cardioversor-desfibrilhador automático com eléctrodos (sensores e cardioversores-desfibrilhadores) transvenosos',
                                  360, 0, '09.04.05.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Substituição de gerador cardioversor-desfibrilhador', 120, 0, '09.04.05.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Revisão de loca de gerador cardioversor-desfibrilhador', 115, 0, '09.04.05.03');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Revisão, reposicionamento ou explantação de eléctrodos (sensores e cardioversores-desfibrilhadores) transvenosos de sistema cardioversor-desfibrilhador',
                                  315, 0, '09.04.05.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Controlo electrónico de cardioversor-desfibrilhador automático, sem programação', 5, 0, '09.04.05.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com programação', 8, 0, '09.04.05.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação electrofisiológica de cardioversor desfibrilhador automático', 75, 0, '09.04.05.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pericardiocentese', 20, 0, '09.04.06.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Explantação de corpos estranhos por cateterismo percutâneo', 75, 0, '09.04.06.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cardioversão eléctrica externa, electiva', 75, 0, '09.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressuscitação cardio-respiratória', 50, 0, '09.05.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Colocação percutânea de dispositivo de assistência cardio-circulatória, v.g. balão intra-aórtico para contrapulsão',
                                  120, 0, '09.05.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, remoção', 55, 0, '09.05.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, controle', 30, 0, '09.05.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia pulmonar percutânea de balão', 200, 0, '09.05.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia aórtica percutânea de balão', 250, 0, '09.05.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia mitral percutânea de balão', 300, 0, '09.05.01.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Dilatação percutânea de coarctação ou recoartação da aorta', 250, 0, '09.05.01.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Atrioseptostomia transvenosa por balão, do tipo Rashkind', 250, 0, '09.05.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem por lâmina, do tipo Park', 300, 0, '09.05.01.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Encerramento percutâneo de canal arterial persistente', 300, 0, '09.05.01.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Encerramento percutâneo de comunicação interauricular', 350, 0, '09.05.01.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de comunicação interventricular', 350, 0, '09.05.01.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Dilatação (angioplastia) de ramos da artéria pulmonar', 300, 0, '09.05.01.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Dilatação (angioplastia) de estenoses de veias pulmonares', 300, 0, '09.05.01.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Embolização vascular, arterial, venosa ou arteriovenosa', 300, 0, '09.05.01.12');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electrofisiologia de intervenção terapêutica, com ablacção de vias anómalas, por energia de radiofrequência',
                                  320, 0, '09.05.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electrofisiologia de intervenção terapêutica, com ablacção ou modulação da junção auriculo-ventricular, por energia de radiofrequência',
                                  320, 0, '09.05.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electrofisiologia de intervenção terapêutica, com ablacção de focos de taquidisritmia ventricular, por energia de radiofrequência',
                                  320, 0, '09.05.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, '"""Pacing"" temporário percutâneo"', 120, 0, '09.05.03.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Implantação de ""pacemaker"" permanente com eléctrodo transvenoso, auricular"', 150, 0, '09.05.03.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Implantação de ""pacemaker"" permanente com eléctrodo transvenoso, ventricular"', 120, 0, '09.05.03.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Implantação de ""pacemaker"" permanente com eléctrodos transvenosos, de dupla câmara"', 270, 0,
   '09.05.03.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, '"Substituição de gerador ""pacemaker"", de uma ou duas câmaras"', 100, 0, '09.05.03.05');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Passagem de sistema ""pacemaker"" de câmara única a dupla câmara, (incluindo explantação do gerador anterior, teste do eléctrodo existente e implantação de novo eléctrodo e de novo gerador)"',
                                  185, 0, '09.05.03.06');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  '"Revisão cirúrgica de sistema ""pacemaker"", sem substituição de gerador (incluindo substituição, reposicionamento ou reparação de eléctrodos transvenosos permanentes), cinco ou mais dias após implantação inicial"',
                                  150, 0, '09.05.03.07');
INSERT INTO ProcedureType VALUES (DEFAULT, '"Remoção de sistema ""pacemaker"""', 150, 0, '09.05.03.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Controlo electrónico do sistema ""pacemaker"" permanente de uma câmara, sem programação"', 4.5, 0,
   '09.05.03.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com programação', 6, 0, '09.05.03.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Controlo electrónico de sistema ""pacemaker"" permanente de dupla câmara, sem programação"', 6, 0,
   '09.05.03.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com programação', 8, 0, '09.05.03.12');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Implantação de cardioversor-desfibrilhador automático com eléctrodos (sensores e cardioversores-desfibrilhadores) transvenosos',
                                  360, 0, '09.05.04.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Substituição de gerador cardioversor-desfibrilhador', 120, 0, '09.05.04.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Revisão de loca de gerador cardioversor-desfibrilhador', 115, 0, '09.05.04.03');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Revisão, reposicionamento ou explantação de eléctrodos (sensores e cardioversores-desfibrilhadores) transvenosos de sistema cardioversor-desfibrilhador',
                                  315, 0, '09.05.04.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Controlo electrónico de cardioversor-desfibrilhador automático, sem programação', 5, 0, '09.05.04.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com programação', 8, 0, '09.05.04.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação electrofisiológica de cardioversor desfibrilhador automático', 75, 0, '09.05.04.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pericardiocentese', 50, 0, '09.05.05.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Explantação de corpos estranhos por cateterismo percutâneo', 75, 0, '09.05.05.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem pleural contínua', 15, 0, '10.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exsuflação de pneumotórax expontâneo', 20, 0, '10.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pleurodese', 5, 0, '10.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção transtraqueal', 15, 0, '10.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção transtorácica', 25, 0, '10.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espirometria simples (estudo dos volumes e débitos)', 10, 0, '10.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espirometria simples com prova de broncodilatação', 13, 14, '10.01.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Espirometria simples com prova de provocação inalatória inespecífica', 20, 19, '10.01.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Espirometria simples com prova de provocação inalatória específica', 20, 24, '10.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Mecânica ventilatória simples (estudo de volumes, incluindo o volume residual+débitos+resistência das vias aéreas)',
                                  22, 36, '10.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mecânica ventilatória com prova de broncodilatação', 25, 40, '10.01.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Mecânica ventilatória com prova de provocação inalatória inespecífica', 25, 45, '10.01.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Mecânica ventilatória com prova de provocação inalatória específica', 25, 50, '10.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, '"""Compliance"" pulmonar"', 10, 30, '10.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Difusão', 10, 30, '10.01.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oximetria transcutânea', 5, 10, '10.01.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Registo poligráfico do sono com avaliação terapêutica (CPAP)', 150, 340, '10.01.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aspirado brônquico, para bacteriologia, micologia, parasitologia e citologia', 5, 0, '10.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Citologia por escovado', 5, 0, '10.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Citologia por punção aspirativa (transbrônquica)', 15, 0, '10.02.00.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Escovado brônquico duplamente protegido para pesquisa de germens (aeróbios e anaeróbios) e fungos', 5, 20,
   '10.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lavagem bronco-alveolar', 10, 0, '10.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lavagens brônquicas dirigidas', 5, 0, '10.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncografia (introdução do produto de contraste)', 9, 0, '10.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoaspiração de secreções', 5, 0, '10.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia por Laser ( fotocoagulação)', 30, 75, '10.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho', 20, 0, '10.03.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Instilação de soro gelado e/ou adrenalina em hemoptises', 5, 0, '10.03.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Intubações endotraqueais (conduzidas por broncofibroscópio)', 20, 0, '10.03.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tamponamento de hemoptises', 15, 0, '10.03.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioterapia endobrônquica', 20, 25, '10.03.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese enduminal', 20, 200, '10.03.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação de colas biológicas', 5, 0, '10.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coagulação por Laser', 10, 75, '10.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocauterização', 10, 0, '10.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pleurodese', 5, 0, '10.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aerossóis (por sessão)', 1, 1, '10.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aerossóis ultra-sónicos', 1, 2, '10.05.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'IPPB (Ventilação por pressão positiva intermitente)', 1, 3, '10.05.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Oxigenoterapia (a utilizar durante as sessões de readaptação)', 1, 1, '10.05.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinesiterapia Respiratória (Ver Fisiatria Cod. 90)', 0, 0, '10.05.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imunoalergologia (Ver Cod. 11)', 0, 0, '10.05.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Por picada (no mínimo série standard)', 12, 18, '11.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intradérmica (no mínimo série standard)', 12, 18, '11.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Por contacto (no mínimo série standard)', 12, 40, '11.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da imunidade celular por testes múltiplos', 12, 30, '11.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Inespecíficas', 5, 5, '11.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Específicas', 5, 5, '11.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Inespecíficas', 15, 25, '11.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Específicas', 15, 25, '11.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cada alergeno', 15, 15, '11.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cada alergeno', 15, 15, '11.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espirometria simples (estudo dos volumes e débitos)', 10, 0, '11.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncodilatadoras por espirometria simples', 13, 14, '11.05.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Broncoconstritoras inespecíficas por espirometria simples', 20, 19, '11.05.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Broncoconstritoras específicas (cada) por espirometria simples', 20, 24, '11.05.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Mecânica ventilatória simples (estudo de volumes, incluindo volume residual+débitos+resistência das vias aéreas)',
                                  22, 36, '11.05.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncodilatadoras por mecânica ventilatória', 25, 40, '11.05.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Broncoconstritoras inespecíficas por mecânica ventilatória', 25, 45, '11.05.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoconstritoras', 25, 50, '11.05.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção (sob vigilância médica)', 5, 0, '11.06.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aerossóis (cada)', 3, 3, '11.07.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Introdução de pessário', 10, 0, '12.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Introdução do DIU', 10, 0, '12.00.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção do DIU por via abdominal (laparotomia ou celioscopia)', 70, 0, '12.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Manobras para exame radiográfico do útero e anexos', 20, 0, '12.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Secção de sinéquias por histeroscopia', 50, 0, '12.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Teste de Huhner', 5, 0, '12.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Inseminação artificial', 20, 100, '12.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclo G.I.F.T.', 175, 700, '12.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclo F.I.V.', 150, 1000, '12.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclo Z.I.F.T.', 175, 1000, '12.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclo I.C.S.I.', 150, 2000, '12.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Monitorização da ovulação', 15, 0, '12.00.00.12');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento de condilomas vulvares (cauterização química, eléctrica ou criocoagulação)', 15, 0,
   '12.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amniocentese (2o. Trimestre)', 25, 0, '13.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amniocentese (3o. Trimestre)', 20, 0, '13.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Teste de stress à ocitocina', 20, 0, '13.00.00.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Iniciação e/ou supervisão de monitorização fetal interna durante o trabalho de parto', 40, 0,
   '13.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Injecção intra-amniótica (amniocentese) de solução hipertónica e/ou prostaglandinas para indução do trabalho de parto',
                                  20, 0, '13.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Injecção intra-uterina extra amniótica de solução hipertónica e/ou prostaglandinas para indução do trabalho de parto',
                                  10, 0, '13.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Monitorização fetal externa, com protocolos e extractos dos cardiotocogramas (fora ou durante o trabalho de parto) . Teste de reatividade fetal',
                                  8, 0, '13.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia do corion', 20, 0, '13.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cordocentese', 30, 0, '13.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traçado diurno com provas de activação (HPP e ELI)', 6, 44, '14.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traçado de sono diurno', 6, 48, '14.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traçado fora do laboratório', 12, 110, '14.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traçado poligráfico', 38, 156, '14.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocorticografia', 36, 156, '14.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Teste de latência múltipla do sono', 60, 200, '14.00.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Registo prolongado de EEG e Video (monitorização no laboratório)', 80, 200, '14.00.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Registo prolongado de EEG e Video (monitorização em ambulatório)', 12, 110, '14.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traçado de sono em ambulatório', 12, 110, '14.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Registo poligráfico de sono nocturno', 100, 250, '14.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cartografia do EEG', 60, 120, '14.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cartografia de potenciais evocados visuais', 60, 120, '14.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cartografia de potenciais evocados auditivos', 60, 120, '14.00.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cartografia de potenciais evocados somatosensitivos', 60, 120, '14.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cartografia do P300', 60, 120, '14.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados visuais', 50, 90, '14.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados auditivos', 50, 90, '14.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados somatosensitivos', 50, 90, '14.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados do nervo pudendo', 50, 90, '14.01.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Potenciais evocados por estimulação de pares cranianos', 60, 100, '14.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados por estimulação paraespinhal', 60, 100, '14.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados por estimulação de dermatomas', 60, 100, '14.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reflexo bulbocavernoso', 50, 90, '14.01.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electromiografia (incluindo velocidades de condução)', 25, 35, '14.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electromiografia de fibra única', 45, 55, '14.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reflexo de encerramento ocular (Blink reflex)', 45, 35, '14.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da condução do nervo frénico', 45, 55, '14.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Resposta simpática cutânea', 50, 90, '14.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da variação R-R', 50, 90, '14.03.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estimulação magnética motora com captação a níveis diversos', 60, 100, '14.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioterapia com neve carbónica (por sessão)', 8, 4, '15.00.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Crioterapia, com azoto liquido, de lesões benignas (por sessão)', 8, 4, '15.00.00.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Crioterapia, com azoto liquido, de lesões malignas, excepto face e região frontal', 30, 4, '15.00.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Crioterapia, com azoto liquido, de lesões malignas da face e região frontal', 40, 4, '15.00.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electrocoagulação ou electrólise de pêlos (por sessão)', 8, 4, '15.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocoagulação de lesões cutâneas', 15, 4, '15.00.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia pelo método de Mohs (microscopicamente controlada)', 50, 30, '15.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto de cabelo (técnica', 3, 1, '15.00.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Terapêutica intralesional com corticóides ou citostáticos', 6, 0, '15.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'P.U.V.A. (por sessão) banho prévio com psolareno', 12, 5, '15.00.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'P.U.V.A. (por sessão) terapêutica oral ou tópica com psolareno', 8, 5, '15.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quimio cirurgia com pasta de zinco', 20, 10, '15.00.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Laserterapia cirúrgica por laser de CO2 de lesões cutâneas', 50, 20, '15.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diagnóstico pela luz de Wood', 2, 2, '15.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laser pulsado de contraste (até 10 cm2)', 40, 230, '15.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, > 10 cm2 < 20 cm2', 60, 250, '15.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, maior que 20 cm2', 80, 320, '15.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testes imunológicos, (Ver Imunoalergologia, Cód. 11)', 0, 0, '15.00.00.18');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Exames bacteriológicos, micológicos e parasitológicos (Ver Patologia Clínica, Cód. 70)', 0, 0,
   '15.00.00.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exames citológicos, (Ver Anatomia Patológica, Cód. 80)', 0, 0, '15.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Redução manual de parafimose', 15, 0, '16.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fulguração e cauterização nos genitais externos', 15, 0, '16.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calibração e dilatação da uretra', 15, 0, '16.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Instilação intravesical', 10, 0, '16.00.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Substituição não cirúrgica de sondas cateteres ou tubos de drenagem', 10, 0, '16.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fluxometria', 5, 15, '16.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistografia (água ou gás)', 15, 25, '16.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electromiografia esfincteriana', 25, 25, '16.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perfil uretral', 5, 15, '16.01.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exame urodinâmico completo do aparelho urinário baixo', 50, 80, '16.01.00.05');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Exame urodinâmico do aparelho urinário alto-estudo de perfusão renal (exclui nefrostomia)', 25, 25,
   '16.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rigiscan', 25, 40, '16.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Doppler peniano', 15, 15, '16.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cavernosometria', 10, 40, '16.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cavernosografia dinâmica', 15, 40, '16.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Test. PGE com papaverina ou prostaglandina', 5, 5, '16.02.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electromiografia da fibra muscular do corpo cavernoso', 25, 25, '16.02.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Potenciais evocados somato-sensitivos do nervo pudendo', 50, 90, '16.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagoscopia', 20, 25, '17.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Endoscopia Alta (Esofagogastroduodenoscopia)', 30, 25, '17.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enteroscopia', 30, 25, '17.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coledoscopia peroral', 50, 35, '17.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colonoscopia Total', 50, 40, '17.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colonoscopia esquerda', 35, 35, '17.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fibrosigmoidoscopia', 15, 30, '17.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rectosigmoidoscopia (tubo rígido)', 10, 5, '17.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anuscopia', 5, 0, '17.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rinoscopia posterior endoscópica', 15, 30, '17.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinuscopia', 15, 30, '17.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laringoscopia', 15, 30, '17.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Microlaringoscopia em suspensão', 25, 30, '17.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoscopia', 30, 25, '17.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pleuroscopia', 35, 15, '17.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoscopia com broncovideoscopia', 30, 40, '17.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mediastinoscopia cervical', 75, 15, '17.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hiloscopia', 40, 15, '17.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretroscopia', 30, 50, '17.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistoscopia simples', 30, 50, '17.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterorrenoscopia de diagnóstico', 110, 200, '17.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefroscopia percutânea', 140, 200, '17.02.00.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Endoscopia flexivel (a acrescentar ao valor do custo real da endoscopia do orgão)', 50, 100,
   '17.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Peniscopia', 15, 30, '17.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laparoscopia Diagnóstica', 35, 20, '17.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colposcopia', 15, 15, '17.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Culdoscopia', 40, 15, '17.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histeroscopia', 25, 20, '17.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amnioscopia', 5, 0, '17.03.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amnioscopia intra ovular ( fetoscopia)', 50, 20, '17.03.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroscopia', 50, 15, '17.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gânglio', 5, 3, '18.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gengival', 5, 3, '18.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fígado', 20, 3, '18.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mama', 5, 3, '18.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tecidos Moles', 5, 3, '18.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osso', 15, 3, '18.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pénis', 5, 3, '18.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Próstata', 25, 3, '18.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rim', 30, 3, '18.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testículo', 10, 3, '18.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiróide', 10, 3, '18.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pulmão', 25, 3, '18.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pleura', 10, 3, '18.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mediastino', 30, 3, '18.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vulva', 5, 3, '18.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vagina', 5, 3, '18.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colo do útero', 5, 3, '18.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Recto', 5, 3, '18.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orofaringe', 8, 3, '18.00.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nasofaringe', 10, 3, '18.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laringe', 10, 3, '18.00.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nariz', 5, 3, '18.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Baço', 20, 3, '18.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Baço, com manometria', 25, 3, '18.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pele', 5, 3, '18.00.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mucosa', 5, 3, '18.00.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Endométrio', 10, 3, '18.00.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia endoscópica (acresce ao valor da endoscopia)', 5, 3, '18.00.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antebraço', 20, 0, '19.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Braço e antebraço', 25, 0, '19.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cervicotorácico (Minerva)', 40, 0, '19.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dedos da mão ou pé', 15, 0, '19.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mão e antebraço distal (luva gessada)', 20, 0, '19.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tóraco-braquial', 40, 0, '19.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Torácico (colete gessado)', 40, 0, '19.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colar', 15, 0, '19.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Velpeau', 30, 0, '19.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pelvi-podálico unilateral', 30, 0, '19.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pelvi-podálico bilateral', 40, 0, '19.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Halopelvico', 50, 0, '19.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coxa, perna e pé', 25, 0, '19.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perna e pé', 20, 0, '19.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coxa e perna (joelheira gessada)', 25, 0, '19.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Leito gessado', 40, 0, '19.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toda a coluna vertebral com correcção de escoliose', 50, 0, '19.00.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colocação de tala tipo Denis Browne em pé ou mão bôta', 5, 0, '19.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cutânea à cabeça', 10, 0, '19.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cutânea à bacia', 10, 0, '19.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cutânea aos membros', 10, 0, '19.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esquelética ao crânio', 25, 0, '19.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esquelética aos membros', 35, 0, '19.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esquelética aos dedos', 25, 0, '19.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Halopélvica', 50, 0, '19.01.00.07');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Escleroterapia ambulatória de varizes do membro inferior (por sessão e por membro)', 15, 5, '20.00.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Escleroterapia de varizes do membroinferior sob anestesia geral', 80, 5, '20.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Limpeza ou curetagem de úlcera de perna', 20, 10, '20.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto cutâneo de úlcera de perna', 70, 0, '20.00.00.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Aplicação de aparelho de compressão permanente (bota una, cola de zinco, kompress, etc.)', 10, 20,
   '20.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Compressão pneumática sequencial', 5, 20, '20.00.00.06');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Drenagem linfática de membro por correntes farádicas em sincronismo cardíaco, com massagem associada', 5,
   30, '20.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laserterapia de varizes', 40, 30, '20.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Simpatólise lombar', 50, 0, '20.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aspiração de bolsas sinoviais', 6, 0, '21.00.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aspiração de bolsas sinoviais sob controlo ecográfico', 16, 0, '21.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrocentese diagnóstica', 8, 0, '21.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrocentese diagnóstica sob controlo ecográfico', 18, 0, '21.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia sinovial fechada do joelho', 20, 0, '21.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia sinovial fechada da coxo-femoral', 40, 0, '21.00.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Biópsia sinovial fechada de outras articulações sem intensificador de imagem', 20, 0, '21.00.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Biópsia sinovial fechada de outras articulações com intensificador de imagem', 35, 0, '21.00.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Biópsia sinovial sob artroscopia (acresce ao valor da artroscopia)', 5, 0, '21.00.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Biópsia óssea da crista ilíaca - Ver Cód. 18.00.00.06', 0, 0, '21.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia das glândulas salivares', 20, 0, '21.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia de nódulo sub-cutâneo - Ver Cód 18.', 0, 0, '21.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia de músculo - Ver Cód. 18.', 0, 0, '21.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia de fascia muscular - Ver Cód. 18.', 0, 0, '21.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Condroscopia', 40, 0, '21.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrografia', 15, 0, '21.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Discografia', 50, 0, '21.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração de partes moles', 6, 0, '21.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração de partes moles sob controlo ecográfico', 16, 0, '21.00.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração articular', 8, 0, '21.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração articular sob controlo ecográfico', 18, 0, '21.00.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração articular sob intensificador de imagem', 23, 0, '21.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroclise', 35, 0, '21.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio de nervo periférico', 10, 0, '21.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração epidural', 10, 0, '21.00.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção intratecal', 25, 0, '21.00.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinoviortese com hexacetonido', 15, 0, '21.00.00.27');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sinoviortese com hexacetonido sob controlo ecográfico', 15, 20, '21.00.00.28');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sinoviortese com hexacetonido sob intensificador de imagem', 15, 20, '21.00.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinoviortese com ácido ósmico', 25, 0, '21.00.00.30');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sinoviortese com ácido ósmico sob controlo ecográfico', 15, 20, '21.00.00.31');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sinoviortese com ácido ósmico sob intensificador de imagem', 30, 20, '21.00.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinoviortese com radioisótopos Itrium 90', 30, 0, '21.00.00.33');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sinoviortese com radioisótopos Renium 186 (com controlo ecográfico)', 30, 20, '21.00.00.34');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sinoviortese com radioisótopos Renium 186 (com intensificador de imagem)', 30, 20, '21.00.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quimionucleólise', 150, 0, '21.00.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nucleólise percutânea', 150, 0, '21.00.00.37');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Artroscopia terapêutica simples (extração de corpos livres, desbridamentos, secções, etc)', 90, 0,
   '21.00.00.38');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artroscopia terapêutica de lesões articulares circunscritas', 130, 0, '21.00.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Capilaroscopia da prega cutânea periungueal', 6, 0, '21.00.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de abcesso subcutâneo', 15, 4, '30.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de abcesso profundo', 25, 4, '30.00.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Incisão e drenagem de quisto sebáceo, quisto pilonidal ou fúrunculo', 15, 4, '30.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de oníquia ou perioníquia', 15, 4, '30.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de hematoma', 15, 4, '30.00.00.05');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Excisão de pequenos tumores benignos ou quistos subcutâneos excepto região frontal e face', 30, 0,
   '30.00.00.06');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Excisão de lesões benignas da região frontal da face e mão, passíveis de encerramento directo', 40, 0,
   '30.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumor profundo', 100, 0, '30.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Excisão de lesões benignas ou malignas só passíveis de encerramento com plastia complexa, na região frontal, face e mão',
                                  200, 0, '30.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Excisão de lesões benignas ou malignas só passíveis de encerramento com plastia complexa, excepto região frontal, face e mão',
                                  150, 0, '30.00.00.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Excisão de cicatrizes da face, pescoço ou mão e plastia por retalhos locais (Z, W, LLL, etc)', 100, 0,
   '30.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Curetagem de verrugas ou condilomas', 15, 3, '30.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de quisto ou fístula pilonidal', 75, 8, '30.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de quisto ou fístula branquial', 110, 8, '30.00.00.14');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Sutura de ferida da face e região frontal até 5 cm (adultos) e 2,5 cm (crianças)', 30, 8, '30.00.00.15');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Sutura de ferida da face e região frontal maior do que 5 cm (adultos) e 2,5 cm(crianças)', 60, 8,
   '30.00.00.16');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Sutura de ferida cutânea até 5 cm (adultos) ou 2,5 cm (crianças) excepto face e região frontal', 15, 8,
   '30.00.00.17');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Sutura de ferida cutânea maior do que 5 cm (adultos) ou 2,5 cm (crianças), excepto face e região frontal',
   20, 8, '30.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da unha encravada', 15, 8, '30.00.00.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de cicatrizes da face, pescoço ou mão e sutura directa', 50, 0, '30.00.00.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de cicatrizes de pregas de flexão e plastia por retalhos locais', 75, 0, '30.00.00.21');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de cicatrizes, excepto face, pescoço ou mão e sutura directa', 50, 0, '30.00.00.22');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Excisão de cicatrizes, excepto face, pescoço ou mão e plastia por retalhos locais', 60, 0, '30.00.00.23');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de cicatriz e plastia por enxerto de pele total', 120, 0, '30.00.00.24');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção de corpo estranho supra-aponevrótico excepto face ou mão', 20, 8, '30.00.00.25');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção de corpo estranho subaponevrótico excepto face ou mão', 40, 8, '30.00.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho da face ou mão', 40, 8, '30.00.00.27');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Desbridamento cirúrgico de ulceração até 3% da superfície corporal', 15, 0, '30.00.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento cirúrgico de ulceração entre 3% e 10%', 40, 0, '30.00.00.29');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Desbridamento cirúrgico de ulceração entre 10% e 30%', 60, 0, '30.00.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento cirúrgico de ulceração acima de 30%', 80, 0, '30.00.00.31');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Desbridamento cirúrgico de queimaduras da face, pescoço ou mão', 40, 0, '30.01.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Desbridamento cirúrgico de queimadura até 3% excepto face, pescoço e mão', 20, 0, '30.01.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Desbridamento cirúrgico de queimaduras entre 3% e 10%', 40, 0, '30.01.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Desbridamento cirúrgico de queimaduras entre 10% e 30%', 60, 0, '30.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento cirúrgico de queimaduras acima de 30%', 80, 0, '30.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso cirúrgico de queimadura até 3%', 10, 0, '30.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso cirúrgico de queimadura entre 3% e 10%', 15, 0, '30.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso cirúrgico de queimadura entre 10% e 30%', 25, 0, '30.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso cirúrgico de queimadura com mais de 30%', 35, 0, '30.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso inicial de queimadura até 3%', 10, 0, '30.01.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso inicial de queimadura entre 3% e 10%', 20, 0, '30.01.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso inicial de queimadura entre 10% e 30%', 30, 0, '30.01.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso inicial de queimadura mais de 30%', 35, 0, '30.01.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pensos ulteriores entre 3% e 10%', 15, 0, '30.01.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pensos ulteriores entre 10% e 30%', 25, 0, '30.01.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pensos ulteriores mais de 30%', 30, 0, '30.01.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia da calvície com expansor tecidular - cada tempo', 150, 0, '30.02.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia da calvície, enxertos pilosos, com Laser (cada sessão)', 200, 0, '30.02.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia da calvície, enxertos pilosos, com microcirurgia (cada sessão)', 200, 0, '30.02.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia da calvície, enxertos pilosos, cada sessão', 100, 0, '30.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dermabrasão cirúrgica total da face', 100, 0, '30.02.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Dermabrasão cirúrgica parcial da face por unidade estética', 45, 0, '30.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dermabrasão cirúrgica em qualquer outra área', 30, 0, '30.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dermabrasão química total da face', 90, 0, '30.02.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Dermabrasão química parcial da face por unidade estética', 40, 0, '30.02.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ritidectomia cervicofacial', 300, 0, '30.02.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ritidectomia frontal', 150, 0, '30.02.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ritidectomia cervicofacial e frontal', 350, 0, '30.02.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ritidectomia das pálpebras (por pálpebra)', 40, 0, '30.02.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ritidectomia das pálpebras (por pálpebra) com ressecção das bolsas adiposas', 60, 0, '30.02.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rinoplastia completa', 125, 0, '30.02.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rinoplastia da ponta', 100, 0, '30.02.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rinoplastia das asas', 100, 0, '30.02.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução nasal parcial, tempo principal', 120, 0, '30.02.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução nasal parcial, tempo complementar', 60, 0, '30.02.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução nasal total, tempo principal', 180, 0, '30.02.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução nasal total, tempo complementar', 80, 0, '30.02.00.21');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução nasal por retalho pré-fabricado (1o. tempo)', 300, 0, '30.02.00.22');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção do nariz em sela com enxerto ósseo ou cartilagens', 200, 0, '30.02.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução auricular (ver Cod. 47)', 0, 0, '30.02.00.24');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de orelhas descoladas (otoplastia) unilateral', 60, 0, '30.02.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução total da orelha, tempo principal', 200, 0, '30.02.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução total da orelha, tempo complementar', 80, 0, '30.02.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução parcial da orelha, tempo principal', 100, 0, '30.02.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução parcial da orelha, tempo complementar', 50, 0, '30.02.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queilopastia estética', 100, 0, '30.02.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mentoplastia estética com endopróteses', 100, 0, '30.02.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mentoplastia estética com osteotomias', 120, 0, '30.02.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção do duplo queixo', 80, 0, '30.02.00.33');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Modelação estética malar-zigomática com endoprótese', 100, 0, '30.02.00.34');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Modelação estética malar-zigomática com osteotomias', 130, 0, '30.02.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abdominoplastia (simples ressecção)', 100, 0, '30.02.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abdominoplastia, com transposição do umbigo', 120, 0, '30.02.00.37');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Abdominoplastia, com transposição do umbigo e reparação músculo-aponevrótica', 150, 0, '30.02.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dermolipectomiabraquial (unilateral)', 70, 0, '30.02.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ritidectomia da mão (unilateral)', 70, 0, '30.02.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia estética da região glutea(unilateral)', 70, 0, '30.02.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dermolipectomia da coxa (unilateral)', 70, 0, '30.02.00.42');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração do pescoço', 50, 0, '30.02.00.43');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração do tórax (zonas limitadas)', 30, 0, '30.02.00.44');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração do abdómen', 75, 0, '30.02.00.45');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração do membro superior(unilateral)', 50, 0, '30.02.00.46');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração da região glútea(unilateral)', 60, 0, '30.02.00.47');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração trocantérica (unilateral)', 60, 0, '30.02.00.48');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração da coxa (unilateral)', 75, 0, '30.02.00.49');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração da perna', 50, 0, '30.02.00.50');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remodelação corporal por auto-enxertos', 100, 0, '30.02.00.51');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Remodelação corporal por inclusão de material biológico conservado, por unidade estética', 50, 0,
   '30.02.00.52');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tatuagem estética por sessão ou unidade anatómica', 50, 0, '30.02.00.53');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção cirúrgica de tatuagem, cada tempo', 50, 0, '30.02.00.54');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia da calvície, com retalhos, cada tempo operatório', 100, 0, '30.02.00.55');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mentoplastia estética com retalhos locais', 120, 0, '30.02.00.56');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto dermoepidérmico até 10 cm2 ou de 0,5% da superfície corporal das crianças, excepto face, boca, pescoço, genitais ou mão',
                                  40, 0, '30.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto dermoepidérmico até 100 cm2 ou de 1% da superfície corporal das crianças excepto face, boca, pescoço, genitais ou mão',
                                  60, 0, '30.03.00.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Enxerto dermoepidérmico maior que 100 cm2 ou de 1% da superfície corporal das crianças', 100, 0,
   '30.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto dermoepidérmico maior que 100 cm2 ou de 1% da superfície corporal das crianças por cada área de 100 cm2 a mais',
                                  50, 0, '30.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxertos em rede', 80, 0, '30.03.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto dermoepidérmico até 100 cm2 ou de 1% da superfície corporal das crianças, face, boca, pescoço, genitais ou mão',
                                  100, 0, '30.03.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto dermoepidérmico maior que 100 cm2 ou de 1% da superfície corporal das crianças na face, boca, genitais ou mão',
                                  150, 0, '30.03.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto de clivagem, ou de pele total na região frontal, face, boca, pescoço, axila, genitais, mãos e pés até 20 cm2',
                                  100, 0, '30.03.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto de clivagem, ou de pele total na região frontal, face, boca, pescoço, axila, genitais, mãos e pés maior que 20cm2',
                                  140, 0, '30.03.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Enxerto de clivagem de pele total até 20 cm2 noutras regiões', 80, 0, '30.03.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Enxerto de clivagem em pele total maior que 20 cm2 noutras regiões', 100, 0, '30.03.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Enxertos adiposos ou dermo-adiposos fascia, cartilagem, ósseo, periósteo', 100, 0, '30.03.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos locais, em Z,U,W,V, Y, etc.', 50, 0, '30.03.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos locais, plastias em Z, múltiplas, etc.', 90, 0, '30.03.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Retalhos de tecidos adjacentes na região frontal face, boca, pescoço, axila, genitais mãos, pés até 10 cm2',
                                  140, 0, '30.03.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Retalhos de tecidos adjacentes na região frontal, face, boca, pescoço, axila, genitais, mãos, pés, maior que 10 cm2',
                                  150, 0, '30.03.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Retalhos de tecidos adjacentes noutras regiões menores que 10 cm2', 50, 0, '30.03.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Retalhos de tecidos adjacentes noutras regiões de 10 cm2 a 30 cm2', 80, 0, '30.03.00.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Formação de retalhos pediculados, à distância, 1o. tempo', 110, 0, '30.03.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cada tempo complementar', 80, 0, '30.03.00.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Retalhos de tecidos adjacentes noutras regiões maior que 30 cm2', 100, 0, '30.03.00.21');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Retalhos miocutâneos sem pedículo vascular identificado', 150, 0, '30.03.00.22');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Retalhos cutâneos, miocutâneos ou musculares com pedículo vascular ou vasculo nervoso identificado', 200,
   0, '30.03.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos fasciocutâneos', 120, 0, '30.03.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos musculares ou miocutâneos', 150, 0, '30.03.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos osteomiocutâneos ou osteo-musculares', 170, 0, '30.03.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalho livre com microanastomoses vasculares', 250, 0, '30.03.00.27');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Retalhos de tecidos adjacentes no couro cabeludo, tronco e membros (excepto mãos e pés) menores que 10cm2',
   100, 0, '30.03.00.28');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Retalhos de tecidos adjacentes no couro cabeludo, tronco e membros (excepto mãos e pés) de 10cm2 a 30cm2',
   120, 0, '30.03.00.29');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Retalhos de tecidos adjacentes no couro cabeludo, tronco e membros (excepto mãos e pés) maior que 30cm2',
   150, 0, '30.03.00.30');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Retalhos miocutâneos, musculares, ou fasciocutâneos sem pedículo vascular indentificado', 150, 0,
   '30.03.00.31');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Retalhos cutâneos, miocutâneos ou musculares com pedículo vascular ou vasculo nervoso identificado', 200,
   0, '30.03.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalho livre com microanastomoses', 400, 0, '30.03.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução osteoplástica de dedos, cada tempo', 150, 0, '30.03.00.34');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Expansão tissular para correcção de anomalias várias, por cada expansor e cada tempo operatório', 100, 0,
   '30.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento de escara de decúbito', 50, 0, '30.04.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Desbridamento de escara de decúbito com plastia local', 130, 0, '30.04.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Transferência de dedo à distância por microcirurgia', 450, 0, '30.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de abcesso profundo', 20, 0, '31.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de fibroadenomas e quisto', 40, 0, '31.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia parcial (quadrantectomia)', 60, 0, '31.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia simples', 110, 0, '31.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia subcutânea', 110, 0, '31.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia por ginecomastia, unilateral', 100, 0, '31.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia radical', 160, 0, '31.00.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Mastectomia radical com linfadenectomia da mamária interna', 200, 0, '31.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia superradical (Urban)', 280, 0, '31.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia radical modificada', 160, 0, '31.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia parcial com esvasiamento axilar', 140, 0, '31.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia mamária de redução unilateral', 175, 0, '31.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia mamária de aumento unilateral', 100, 0, '31.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção ou substituição de material de prótese', 50, 0, '31.00.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de encapsulação de material de prótese', 70, 0, '31.00.00.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução mamária pós mastectomia ou agenesia com utilização de expansor', 150, 0, '31.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução mamária com retalhos adjacentes', 150, 0, '31.00.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução mamária com retalhos miocutâneos à distância', 250, 0, '31.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução do complexo areolo-mamilar', 100, 0, '31.00.00.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução mamária com retalho miocutâneo do grande dorsal', 250, 0, '31.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução mamária com Tram-Flap', 350, 0, '31.00.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de mamilos invertidos (unilateral)', 100, 0, '31.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de mamilos supranumerários', 50, 0, '31.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de mama supranumerária', 70, 0, '31.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução mamária com retalho livre', 400, 0, '31.00.00.25');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de lesão infraclínica da mama com marcação prévia', 100, 0, '31.00.00.26');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de lesão da mama (com ou sem marcação) e com esvaziamento axilar', 140, 0, '31.00.00.27');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reexcisão da área da biópsia prévia e esvasiamento axilar', 140, 0, '31.00.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de canais galactóforos', 60, 0, '31.00.00.29');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Esvasiamento axilar como 2o. tempo de cirurgia conservadora do carcinoma da mama (cirurgia diferida)', 140,
   0, '31.00.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reimplantes do braço ou antebraço, completos', 500, 0, '32.00.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reimplantes do braço e antebraço incompletos (com pedículo de tecidos moles)', 450, 0, '32.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reimplantes da mão, completa', 450, 0, '32.00.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reimplantes da mão, incompleta (com pedículo de tecidos moles)', 400, 0, '32.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reimplantes de dedos, completa', 200, 0, '32.00.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reimplantes de dedos, incompleta (com pedículo de tecidos moles)', 150, 0, '32.00.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de craniosinostose por via extracraniana', 200, 0, '33.00.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de craniosinostose por via intracraniana', 300, 0, '33.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de teleorbitismo por via extracraniana', 200, 0, '33.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de teleorbitismo por via intracraniana', 250, 0, '33.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cranioplastias (ver Cod. 45)', 0, 0, '33.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia têmporo-mandíbular', 70, 0, '33.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coronoidectomia (operação isolada)', 140, 0, '33.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do condilo mandíbular', 110, 0, '33.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Meniscectomia têmporo-mandíbular', 100, 0, '33.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de quisto ou tumor benigno da mandíbula', 60, 0, '33.00.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção parcial da mandíbula, sem perda de continuidade', 75, 0, '33.00.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção parcial da mandíbula com perda de continuidade', 150, 0, '33.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção total da mandíbula', 200, 0, '33.00.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção total da mandíbula com reconstrução imediata', 300, 0, '33.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção parcial do maxilar superior', 110, 0, '33.00.00.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção parcial do maxilar superior com reconstrução imediata', 200, 0, '33.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção total do maxilar superior', 200, 0, '33.00.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de outros ossos da face por quisto ou tumor', 110, 0, '33.00.00.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução parcial da mandíbula com material aloplástico', 100, 0, '33.00.00.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução parcial da mandíbula com enxerto osteo-cartilagineo', 150, 0, '33.00.00.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução total da mandíbula com material aloplástico', 120, 0, '33.00.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução total da mandíbula com enxerto ósseo', 200, 0, '33.00.00.22');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteoplastia mandíbular por prognatismo ou retroprognatismo', 300, 0, '33.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteoplastia da mandíbula segmentar', 200, 0, '33.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteoplastia da mandíbula, total', 300, 0, '33.00.00.25');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteoplastia do maxilar superior, segmentar tipo Le Fort I', 200, 0, '33.00.00.26');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteoplastia maxilo-facial, com osteotomia tipo Le Fort II', 300, 0, '33.00.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Condiloplastia mandíbular programada unilateral', 140, 0, '33.00.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia têmporo-mandíbular (cada lado)', 140, 0, '33.00.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cranioplastia complexa com enxerto ósseo', 450, 0, '33.00.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia segmentar do maxilar superior', 150, 0, '33.00.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cranioplastia simples com enxerto ósseo', 250, 0, '33.00.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Disfunção intermaxilar', 150, 0, '33.00.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cranioplastia simples com material aloplastico', 170, 0, '33.00.00.34');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ablação de tumor por dupla abordagem (intra e extracraniana)', 450, 0, '33.00.00.35');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento da fractura de nariz por redução simples fechada', 30, 0, '33.00.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de fractura instável de nariz', 50, 0, '33.00.01.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento de fractura do complexo nasoetmoide, incluindo reparação dos ligamentos centrais epicantais',
   150, 0, '33.00.01.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de fractura nasomaxilar (tipo Le Fort III)', 150, 0, '33.00.01.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento da fractura-disjunção cranio-facial (tipo Le Fort III)', 160, 0, '33.00.01.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de fractura do maxilar superior, por método simples', 75, 0, '33.00.01.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de fractura do maxilar superior, com fixação interna ou externa', 140, 0, '33.00.01.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento da fractura do complexo zigomático malar sem fixação', 75, 0, '33.00.01.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento da fractura do complexo zigomático malar com fixação', 150, 0, '33.00.01.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, '"Tratamento de fractura do pavimento da órbita, tipo ""blow-out"""', 120, 0, '33.00.01.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Tratamento de fractura do pavimento da òrbita, tipo ""blow-out"" com endoprotese de ""Silastic"""', 150,
   0, '33.00.01.11');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Tratamento de fractura do pavimento da órbita, tipo ""blow-out"", com enxerto ósseo"', 150, 0,
   '33.00.01.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio intermaxilar (operação isolada)', 70, 0, '33.00.01.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento da fractura da mandíbula por método simples', 75, 0, '33.00.01.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento ortopédico da fractura mandíbular por fixação intermaxilar', 110, 0, '33.00.01.15');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento cirúrgico e osteossíntese da fractura mandíbular (1 osteossíntese)', 150, 0, '33.00.01.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de luxação têmporo-maxilar por manipulação externa', 15, 0, '33.00.01.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de luxação têmporo-maxilar por método cirúrgico', 110, 0, '33.00.01.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de fractura tipo Le Fort I ou Le Fort II', 100, 0, '33.00.01.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico com osteossínteses múltiplas de fracturas mandíbulares', 200, 0, '33.00.01.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de fractura do maxilar superior, por bloqueio intermaxilar', 75, 0, '33.00.01.21');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de fractura do maxilar superior com osteossíntese', 100, 0, '33.00.01.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com suspensão', 75, 0, '33.00.01.23');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de fractura mandíbular por bloqueio intermaxilar', 110, 0, '33.00.01.24');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento cirúrgico de fractura mandíbular por osteossíntese e bloqueio intermaxilar', 150, 0,
   '33.00.01.25');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de luxação têmporo-mandíbular por manipulação externa', 30, 0, '33.00.01.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia dos escalenos', 90, 0, '33.01.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia muscular dinâmica por transferência muscular', 150, 0, '33.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxertos musculares livres', 250, 0, '33.01.00.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia estética para estabilização funcional das comissuras (suspensões) mioneurotomias selectivas', 150,
   0, '33.01.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Torcicolo congénito, mioplastia de alongamento ou miectomia', 110, 0, '33.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Celulectomia cervical unilateral', 200, 0, '33.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Celulectomia cervical bilateral', 300, 0, '33.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurorrafia do nervo facial', 200, 0, '33.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto nervoso do nervo facial', 250, 0, '33.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto nervoso cruzado do nervo facial', 300, 0, '33.01.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurotização a partir de outro nervo craniano', 300, 0, '33.01.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do esterno (osteossíntese)', 110, 0, '33.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fracturas de costelas (fixação)', 75, 0, '33.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de costelas', 75, 0, '33.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação da parede torácica com prótese', 120, 0, '33.02.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, '"Tratamento cirúrgico de ""pectus excavatum"" ou ""carinatum"""', 260, 0, '33.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura ou luxação vertebral', 100, 0, '33.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apófises espinhosas cervicais', 50, 0, '33.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apófises transversas lombares', 40, 0, '33.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sacro e cóccix', 40, 0, '33.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna cervical, via transoral ou lateral', 180, 0, '33.03.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna cervical, via anterior ou anterolateral', 180, 0, '33.03.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna cervical, via posterior', 160, 0, '33.03.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna dorsal, via anterior', 220, 0, '33.03.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna dorsal, via anterolateral', 200, 0, '33.03.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna dorsal, via posterior', 160, 0, '33.03.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna lombar, via anterior', 160, 0, '33.03.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna lombar, via anterolateral', 160, 0, '33.03.01.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna lombar, via posterior', 160, 0, '33.03.01.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da occípito vertebral', 200, 0, '33.03.01.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna cervical, via anterior', 220, 0, '33.03.01.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna cervical, via posterior', 180, 0, '33.03.01.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna dorsal, via anterior', 270, 0, '33.03.01.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna dorsal, via posterior', 180, 0, '33.03.01.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna lombar, via anterior', 240, 0, '33.03.01.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna lombar, via posterior', 180, 0, '33.03.01.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna lombossagrada, via anterior', 250, 0, '33.03.01.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna lombossagrada, via posterior', 180, 0, '33.03.01.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna lombossagrada, via combinada', 300, 0, '33.03.01.19');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Fracturas ou fractura luxação da coluna cervical, via transoral, sem artrodese ou osteossíntese', 180, 0,
   '33.03.01.20');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Fracturas ou fractura luxação da coluna cervical, via transoral, com artrodese ou osteossíntese', 220, 0,
   '33.03.01.21');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Fracturas ou fractura luxação da coluna cervical, via anterior ou anterolateral sem artrodese', 180, 0,
   '33.03.01.22');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Fracturas ou fractura luxação da coluna cervical, via anterior ou anterolateral com artrodese', 220, 0,
   '33.03.01.23');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Fracturas ou fractura luxação da coluna cervical, via posterior sem artrodese', 160, 0, '33.03.01.24');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Fracturas ou fractura luxação da coluna cervical, via posterior com artrodese', 180, 0, '33.03.01.25');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna dorsal, via anterior', 220, 0, '33.03.01.26');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna dorsal, via anterior com artrodese', 270, 0, '33.03.01.27');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna dorsal, via posterior sem artrodese', 160, 0, '33.03.01.28');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna dorsal, via posterior com artrodese', 180, 0, '33.03.01.29');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna lombar, via anterior sem artrodese', 160, 0, '33.03.01.30');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna lombar, via anterior com artrodese', 240, 0, '33.03.01.31');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna lombar, via posterior sem artrodese', 160, 0, '33.03.01.32');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna lombar, via posterior com artrodese', 180, 0, '33.03.01.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espondilolistese via anterior', 240, 0, '33.03.01.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espondilolistese via posterior', 180, 0, '33.03.01.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espondilolistese via combinada', 300, 0, '33.03.01.36');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Escoliose, cifose ou em associação - Artrodese posterior', 270, 0, '33.03.01.37');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Escoliose, cifose ou em associação - Artrodese anterior', 350, 0, '33.03.01.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Escoliose, cifose ou em associação - Via combinada', 400, 0, '33.03.01.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteótomia da coluna vertebral', 350, 0, '33.03.01.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do cóccix', 50, 0, '33.03.01.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de apofises transversas lombares', 60, 0, '33.03.01.42');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lamínectomia descompressiva (até duas vértebras)', 140, 0, '33.03.01.43');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Laminectomia descompressiva (mais de duas vértebras)', 180, 0, '33.03.01.44');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Realinhamento de canal estreito', 250, 0, '33.03.01.45');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corporectomia cervical por via anterior', 300, 0, '33.03.01.46');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Foraminectomia', 250, 0, '33.03.01.47');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extirpação de hérnia discal cervical', 250, 0, '33.03.01.48');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extirpação de hérnia discal dorsal', 300, 0, '33.03.01.49');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extirpação de hérnia discal lombar', 180, 0, '33.03.01.50');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nucleolise percutânea', 150, 0, '33.03.01.51');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da clavícula', 40, 0, '33.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da omoplata', 45, 0, '33.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do troquíter', 40, 0, '33.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da epífise umeral ou do colo do úmero', 60, 0, '33.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da diáfise do úmero', 60, 0, '33.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação esternoclavicular', 25, 0, '33.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação acromioclavicular', 25, 0, '33.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação gleno-umeral', 40, 0, '33.04.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação do ombro', 65, 0, '33.04.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura da clavícula', 75, 0, '33.04.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da pseudoartrose da clavícula', 100, 0, '33.04.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da omoplata', 100, 0, '33.04.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura-avulsão do troquíter', 120, 0, '33.04.01.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese do colo do úmero com ou sem fractura do troquíter', 140, 0, '33.04.01.05');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento de fractura cominutiva ou fractura-luxação da extremidade proximal do úmero', 160, 0,
   '33.04.01.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese da diáfise umeral (com ou sem exploração do nervo radial)', 140, 0, '33.04.01.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento da pseudoartrose do úmero (colo ou diáfise)', 160, 0, '33.04.01.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação esternoclavicular (aguda)', 75, 0, '33.04.01.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Luxação esternoclavicular (recidivante ou inveterada)', 90, 0, '33.04.01.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação acrómioclavicular', 75, 0, '33.04.01.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Redução da luxação do ombro (inveterada)', 110, 0, '33.04.01.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da luxação recidivante do ombro', 150, 0, '33.04.01.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de osteomielite (clavícula omoplata, úmero)', 120, 0, '33.04.01.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de pequenos tumores benignos (exostoses inclusive, 1 ou 2)', 90, 0, '33.04.01.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de tumores osteoperiósticos extensos', 180, 0, '33.04.01.16');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção óssea segmentar de tumores invasivos com reconstituição por prótese ou enxerto homólogo', 280, 0,
   '33.04.01.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação interescápulotorácica', 280, 0, '33.04.01.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desarticulação do ombro', 160, 0, '33.04.01.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação pelo braço', 120, 0, '33.04.01.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção parcial da omoplata', 140, 0, '33.04.01.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção total da omoplata', 160, 0, '33.04.01.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cleidectomia parcial', 100, 0, '33.04.01.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cleidectomia total', 130, 0, '33.04.01.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da extremidade proximal do úmero', 120, 0, '33.04.01.25');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteotomia com osteossíntese do úmero (colo ou diáfise)', 140, 0, '33.04.01.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do acromion', 90, 0, '33.04.01.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia parcial com prótese', 140, 0, '33.04.01.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total', 200, 0, '33.04.01.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese do ombro', 140, 0, '33.04.01.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia simples', 50, 0, '33.04.01.31');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas', 120, 0, '33.04.01.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinovectomia', 120, 0, '33.04.01.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da elevação congénita da omoplata', 210, 0, '33.04.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de tendinopatia calcificante', 120, 0, '33.04.02.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento do síndroma de conflito infra-acromiocoracoideu', 140, 0, '33.04.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia dos músculos do ombro', 90, 0, '33.04.02.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da rotura da coifa', 140, 0, '33.04.02.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da rotura do supraespinhoso', 120, 0, '33.04.02.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura do tendão ou tendões do bicípite ou de um longo músculo do ombro', 75, 0, '33.04.02.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Transposição tendinosa por paralisia dos flexores do cotovelo', 160, 0, '33.04.02.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção de sequelas de paralisia obstétrica no ombro', 120, 0, '33.04.02.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção das sequelas da paralisia braquial no ombro do adulto', 160, 0, '33.04.02.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção das sequelas da paralisia braquial no cotovelo (dinamização)', 150, 0, '33.04.02.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do plexo braquial, exploração cirúrgica', 160, 0, '33.04.02.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do plexo braquial, neurólise', 200, 0, '33.04.02.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia do plexo braquial, reconstrução com enxertos nervosos', 320, 0, '33.04.02.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura supracondiliana do úmero', 70, 0, '33.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura dos côndilos umerais', 70, 0, '33.05.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da epitróclea ou epicôndilo', 30, 0, '33.05.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do olecrâneo', 40, 0, '33.05.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da tacícula radial', 30, 0, '33.05.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da diáfise do rádio ou do cúbito', 50, 0, '33.05.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura das diáfises do rádio e cúbito', 60, 0, '33.05.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteoclasia por fractura em consolidação viciosa', 90, 0, '33.05.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação do cotovelo', 40, 0, '33.05.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação do cotovelo', 80, 0, '33.05.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pronação dolorosa', 10, 0, '33.05.00.11');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Osteossíntese percutânea ou cruenta da fractura supracondiliana do úmero na criança', 130, 0,
   '33.05.01.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese da fractura supracondiliana no adulto', 120, 0, '33.05.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese supra e intercondiliana no adulto', 140, 0, '33.05.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese de um côndilo umeral', 90, 0, '33.05.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da epitróclea', 90, 0, '33.05.01.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese da fractura-luxação complexa do cotovelo', 140, 0, '33.05.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do côndilo umeral', 90, 0, '33.05.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese do olecrâneo', 80, 0, '33.05.01.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do olecrâneo', 90, 0, '33.05.01.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese ou Exérese da tacícula radial', 100, 0, '33.05.01.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução do ligamento anular do colo do rádio', 120, 0, '33.05.01.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da diáfise do rádio ou do cúbito', 110, 0, '33.05.01.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese diafisária dos dois ossos do antebraço', 180, 0, '33.05.01.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, '"Osteossíntese a ""céu fechado"" da diáfise do rádio ou do cúbito"', 110, 0, '33.05.01.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, '"Osteossíntese a ""céu fechado"" diafisária dos dois ossos do antebraço"', 180, 0, '33.05.01.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese da fractura-luxação de Monteggia ou Galeazzi', 120, 0, '33.05.01.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação do cotovelo (inveterada)', 110, 0, '33.05.01.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pseudartrose supracondiliana do úmero', 160, 0, '33.05.01.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pseudartrose de um osso do antebraço', 130, 0, '33.05.01.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pseudartrose dos dois ossos do antebraço', 200, 0, '33.05.01.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de osteíte ou osteomielite no cotovelo ou antebraço', 120, 0, '33.05.01.21');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de pequenos tumores benignos (exostoses inclusive, 1 ou 2)', 90, 0, '33.05.01.22');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de tumores sinoviais ou osteoperiósticos extensos no cotovelo', 180, 0, '33.05.01.23');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ressecção óssea segmentar de tumores invasivos com reconstituição por prótese ou enxerto homólogo no cotovelo',
                                  220, 0, '33.05.01.24');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção óssea segmentar no antebraço com reconstituição', 150, 0, '33.05.01.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação do cotovelo', 120, 0, '33.05.01.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação pelo antebraço', 120, 0, '33.05.01.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Krukenberg', 200, 0, '33.05.01.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrolise do cotovelo', 160, 0, '33.05.01.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total do cotovelo', 200, 0, '33.05.01.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia protésica da tacícula', 100, 0, '33.05.01.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese do cotovelo', 140, 0, '33.05.01.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia do rádio ou do cúbito', 110, 0, '33.05.01.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia dos dois ossos do antebraço', 130, 0, '33.05.01.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de sinostose rádiocubital', 150, 0, '33.05.01.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia simples', 40, 0, '33.05.01.36');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas', 110, 0, '33.05.01.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinovectomia', 110, 0, '33.05.01.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição do nervo cubital', 110, 0, '33.05.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da epicondilite ou epitrocleíte', 80, 0, '33.05.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de higroma ou bursite', 40, 0, '33.05.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia reparadora da retracção de Wolkman', 200, 0, '33.05.02.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tenotomia dos músculos flexores ou extensores do punho e dedos', 75, 0, '33.05.02.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tenodese dos músculos do antebraço em um ou vários tempos', 120, 0, '33.05.02.06');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Transposição dos tendões por paralisia dos extensores (paralisia do nervo radial)', 120, 0, '33.05.02.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Transposição dos tendões por paralisia dos flexores dos dedos', 120, 0, '33.05.02.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da extremidade distal do rádio ou cúbito', 60, 0, '33.06.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do escafóide', 70, 0, '33.06.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de outros ossos do carpo', 40, 0, '33.06.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do 1o. Metacarpiano', 30, 0, '33.06.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de outros metacarpianos', 25, 0, '33.06.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de uma falange', 20, 0, '33.06.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de duas ou mais falanges', 30, 0, '33.06.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação rádio-cárpica', 60, 0, '33.06.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação semilunar', 70, 0, '33.06.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação de dedos da mão (cada)', 20, 0, '33.06.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da extremidade distal do rádio', 110, 0, '33.06.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação rádiocubital distal', 75, 0, '33.06.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do escafóide', 100, 0, '33.06.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pseudartrose do escafóide', 130, 0, '33.06.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação do semilunar', 100, 0, '33.06.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação do punho', 110, 0, '33.06.01.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fractura-luxação do carpo ou instabilidade traumática', 120, 0, '33.06.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação de Bennet', 110, 0, '33.06.01.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de um ou dois metacarpianos', 80, 0, '33.06.01.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação metacarpofalângica', 60, 0, '33.06.01.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de uma falange', 60, 0, '33.06.01.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de várias falanges', 80, 0, '33.06.01.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação interfalângica', 50, 0, '33.06.01.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Várias luxações interfalângicas', 75, 0, '33.06.01.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Curetagem (osteíte, encondromas) ou biópsia', 40, 0, '33.06.01.15');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção de pequenas lesões ou tumores ósseos circunscritos com preenchimento ósseo', 80, 0,
   '33.06.01.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção da extremidade distal do rádio com reconstrução', 130, 0, '33.06.01.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da apófise estiloideia do rádio', 70, 0, '33.06.01.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da extremidade distal do cúbito', 70, 0, '33.06.01.19');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção parcial do escafóide cárpico ou semilunar com artroplastia de interposição', 140, 0,
   '33.06.01.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da 1a. fileira do carpo', 100, 0, '33.06.01.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de um metacarpiano', 70, 0, '33.06.01.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de dois ou mais', 100, 0, '33.06.01.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção artroplástica metacarpofalângica (cada)', 70, 0, '33.06.01.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação e desarticulação pelo punho', 120, 0, '33.06.01.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação e desarticulação de metacarpiano', 70, 0, '33.06.01.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação e desarticulação de dedo', 50, 0, '33.06.01.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação de dois ou mais', 80, 0, '33.06.01.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia distal do rádio', 120, 0, '33.06.01.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia do 1o. metacarpiano', 90, 0, '33.06.01.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia de um metacarpiano excepto 1o.', 70, 0, '33.06.01.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia de uma falange', 40, 0, '33.06.01.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total do punho', 200, 0, '33.06.01.33');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artroplastia de substituição do escafóide ou semilunar', 140, 0, '33.06.01.34');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artroplastia do grande osso para tratamento de doença Kienboeck', 150, 0, '33.06.01.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total carpometacarpiana do polegar', 140, 0, '33.06.01.36');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artroplastia metacarpofalângica ou interfalângica (uma)', 110, 0, '33.06.01.37');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artroplastia metacarpofalângica ou interfalângica (mais de uma)', 150, 0, '33.06.01.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese do punho', 130, 0, '33.06.01.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese intercárpica', 100, 0, '33.06.01.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese carpometacarpiana', 90, 0, '33.06.01.41');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrodese metacarpofalângica ou interfalângica (cada)', 50, 0, '33.06.01.42');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alongamento de um metacarpiano ou falange', 180, 0, '33.06.01.43');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Falangização do 1o. metacarpiano', 110, 0, '33.06.01.44');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polegarização', 250, 0, '33.06.01.45');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polegarização por transplante', 300, 0, '33.06.01.46');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução do polegar num só tempo (Gillies)', 110, 0, '33.06.01.47');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Reconstrução do polegar em vários tempos com plastia abdominal ou torácica e enxerto ósseo', 230, 0,
   '33.06.01.48');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Reconstrução do polegar em vários tempos com plastia abdominal ou torácica, enxerto ósseo e pedículo neurovascular de Littler',
                                  300, 0, '33.06.01.49');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia', 40, 0, '33.06.01.50');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com sinovectomia', 50, 0, '33.06.01.51');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia ou artroscopia para tratamento de lesões articulares', 50, 0, '33.06.01.52');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura dos tendões extensores dos dedos (um tendão)', 50, 0, '33.06.02.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura dos tendões extensores dos dedos (mais de um tendão)', 80, 0, '33.06.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura dos tendões flexores dos dedos (um tendão)', 90, 0, '33.06.02.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura dos tendões flexores dos dedos (mais de um tendão)', 130, 0, '33.06.02.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Plastia tendinosa para oponência ou para a extensão do polegar', 120, 0, '33.06.02.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenosinovectomia do punho e mão', 150, 0, '33.06.02.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da tenosinovite de DuQuervain', 60, 0, '33.06.02.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Operação da bainha tendinosa dos dedos (dedo em gatilho)', 40, 0, '33.06.02.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras tenolises', 30, 0, '33.06.02.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fasciotomia limitada por retracção da aponevrose palmar', 90, 0, '33.06.02.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fasciotomia total por retracção da aponevrose palmar', 120, 0, '33.06.02.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fasciotomia total com enxerto cutâneo por retracção da aponevrose palmar', 160, 0, '33.06.02.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção da deformidade em botoeira ou em colo de cisne', 80, 0, '33.06.02.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Libertação da aderência dos tendões flexores dos dedos (Howard)', 100, 0, '33.06.02.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Libertação da aderência dos tendões extensores dos dedos (Howard)', 80, 0, '33.06.02.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura de ligamento metacarpofalângico ou interfalângico', 40, 0, '33.06.02.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ligamentoplastia metacarpofalângica ou interfalângica', 80, 0, '33.06.02.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção da paralisia dos músculos intrinsecos por lesão do nervo cubital', 120, 0, '33.06.02.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção da paralisia dos músculos intrinsecos por lesão do nervo mediano', 160, 0, '33.06.02.19');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Correcção cirúrgica do síndrome do canal cárpico ou do de Guyon (Ver Cód.45.09.00.05)', 0, 0,
   '33.06.02.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção cirúrgica de sindactilia (uma) sem enxerto', 75, 0, '33.06.02.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, cada comissura a mais, sem enxerto', 30, 0, '33.06.02.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com enxerto', 100, 0, '33.06.02.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com enxerto por cada uma a mais', 50, 0, '33.06.02.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção da sindactilia com sinfalangismo', 120, 0, '33.06.02.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mão bota radial (partes moles)', 75, 0, '33.06.02.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mão bota radial (com centralização do cúbito)', 150, 0, '33.06.02.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de polidactilia', 75, 0, '33.06.02.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de clinodactilia', 90, 0, '33.06.02.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de malformações congénitas do polegar', 120, 0, '33.06.02.30');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tenoplastia por enxerto ou prótese de tendão da mão (um)', 140, 0, '33.06.02.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, dois', 170, 0, '33.06.02.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, três ou mais', 200, 0, '33.06.02.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução osteoplástica dos dedos (Cada tempo)', 75, 0, '33.06.02.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução dos dedos por transferência', 250, 0, '33.06.02.35');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura ou tenólise dos tendões, extensores dos dedos da mão 1 tendão', 40, 0, '33.06.02.36');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura ou tenólise dos tendões extensores dos dedos da mão: mais de um tendão', 80, 0, '33.06.02.37');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura tenólise dos tendões flexores dos dedos da mão 1 tendão', 70, 0, '33.06.02.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenoplastia por enxerto de tendão da mão 1', 120, 0, '33.06.02.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenoplastia por enxerto de tendão da mão 2', 140, 0, '33.06.02.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenoplastia por enxerto de tendão da mão 3 ou mais', 160, 0, '33.06.02.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fasciotomia por retracção da aponevrose palmar', 40, 0, '33.06.02.42');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fasciectomia regional por retracção da aponevrose palmar', 80, 0, '33.06.02.43');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fasciectomia total por retracção da aponevrose palmar', 120, 0, '33.06.02.44');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fasciectomia parcial com enxerto cutâneo por retracção da aponevrose palmar', 100, 0, '33.06.02.45');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fasciectomia total com enxerto cutâneo por retracção da aponevrose palmar', 160, 0, '33.06.02.46');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção de sequelas reumatismais da mão (artroplastia) por cada articulação', 90, 0, '33.06.02.47');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia por cada articulação', 70, 0, '33.06.02.48');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Correcção da sindroma do canal cárpico e outras sindromes compressivos do membro superior', 80, 0,
   '33.06.02.49');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de sindactília sem sinfalangismo', 100, 0, '33.06.02.50');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exploração nervosa cirúrgica', 70, 0, '33.06.02.51');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurorrafia sem microcirurgia', 100, 0, '33.06.02.52');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto nervoso', 200, 0, '33.06.02.53');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição nervosa', 160, 0, '33.06.02.54');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do ílion, púbis ou ísquion', 60, 0, '33.07.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com desvios ou luxações', 80, 0, '33.07.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação congénita da anca (LCA)', 90, 0, '33.07.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação coxofemoral', 100, 0, '33.07.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da cavidade cotiloideia', 80, 0, '33.07.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação traumática da anca', 90, 0, '33.07.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do colo do fémur e fractura trocantérica', 90, 0, '33.07.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Redução cirúrgica da luxação traumática da anca', 120, 0, '33.07.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese do rebordo posterior do acetábulo', 170, 0, '33.07.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese das colunas acetabulares', 200, 0, '33.07.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da sínfise púbica', 120, 0, '33.07.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese sacro-íliaca', 150, 0, '33.07.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação Malgaigne', 200, 0, '33.07.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura do colo ou trocantérica', 140, 0, '33.07.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de osteomielite', 120, 0, '33.07.01.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Biópsia a ""céu aberto"" ou ressecção de pequenos tumores benignos (exostoses inclusive, 1 ou 2)"', 90, 0,
   '33.07.01.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de tumores osteoperiósticos extensos', 200, 0, '33.07.01.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção óssea segmentar de tumores invasivos com reconstituição por prótese ou enxerto homólogo', 300, 0,
   '33.07.01.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação interílio-abdominal', 300, 0, '33.07.01.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desarticulação coxofemoral', 180, 0, '33.07.01.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção da extremidade superior do fémur (Girdlestone)', 150, 0, '33.07.01.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia com osteossíntese, do colo do fémur', 160, 0, '33.07.01.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, trocantérica ou subtrocantérica, na criança', 160, 0, '33.07.01.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, trocantérica ou subtroncatérica, no adulto', 160, 0, '33.07.01.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomias tipo Salter, Chiari ou Pemberton', 200, 0, '33.07.01.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tectoplastia cotiloideia', 180, 0, '33.07.01.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Redução cirúrgica de LCA com duas ou mais osteotomias', 220, 0, '33.07.01.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição do grande trocânter', 110, 0, '33.07.01.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queilectomia', 120, 0, '33.07.01.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia parcial (Moore, Tompson)', 180, 0, '33.07.01.23');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artroplastia total em coxartrose ou revisão de hemiartroplastia', 220, 0, '33.07.01.24');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Artroplastia total em revisão de prótese total, de artrodese, de LCA ou após Girdlestone', 260, 0,
   '33.07.01.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese sacro-ilíaca (Unilateral)', 120, 0, '33.07.01.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da anca sem osteossíntese', 180, 0, '33.07.01.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com osteossíntese', 200, 0, '33.07.01.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fixação in situ de epifisiolise', 140, 0, '33.07.01.29');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de epifísiolise com osteotomia e osteossíntese', 180, 0, '33.07.01.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia simples', 70, 0, '33.07.01.31');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas', 140, 0, '33.07.01.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinovectomia', 140, 0, '33.07.01.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia dos adutores com ou sem neurectomia', 75, 0, '33.07.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição dos adutores', 120, 0, '33.07.02.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tenotomia dos adutores com neurectomia intrapélvica', 100, 0, '33.07.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia ou alongamento dos flexores', 90, 0, '33.07.02.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia dos rotatores', 90, 0, '33.07.02.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Plastia músculo-aponevrótica por paralisia dos glúteos em 1 ou vários tempos', 150, 0, '33.07.02.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição dos glúteos em 1 ou vários tempos', 150, 0, '33.07.02.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição do psoas-iliaco', 160, 0, '33.07.02.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da bolsa subglútea incluindo trocânter', 75, 0, '33.07.02.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da anca de ressalto', 100, 0, '33.07.02.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da pubalgia', 100, 0, '33.07.02.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da diáfise do fémur', 90, 0, '33.08.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura supracondiliana ou intercondiliana', 100, 0, '33.08.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura ou luxação da rótula', 40, 0, '33.08.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação do joelho', 100, 0, '33.08.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fractura da extremidade proximal da tíbia ou dos planaltos tibiais', 70, 0, '33.08.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lesão ligamentar', 50, 0, '33.08.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação femorotibial', 50, 0, '33.08.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, '"Osteossíntese diafisária a ""céu aberto"""', 140, 0, '33.08.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, '"Osteossíntese diafisária a ""céu fechado"""', 140, 0, '33.08.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotaxia da fractura do fémur', 140, 0, '33.08.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura supracondiliana', 140, 0, '33.08.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura supra e intercondiliana', 150, 0, '33.08.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura unicondiliana', 110, 0, '33.08.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da rótula (osteossíntese ou patelectomia)', 75, 0, '33.08.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da espinha da tíbia', 110, 0, '33.08.01.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de um planalto tibial', 110, 0, '33.08.01.09');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Osteossíntese da fractura bituberositária ou da fractura cominutiva da extremidade proximal', 130, 0,
   '33.08.01.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese das fracturas osteocondrais', 110, 0, '33.08.01.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação do joelho : Ver Cód. 33.08.02 e 33.08.03', 0, 0, '33.08.01.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteomielite', 120, 0, '33.08.01.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pseudartrose do fémur', 160, 0, '33.08.01.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrite séptica', 70, 0, '33.08.01.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de pequenos tumores benignos (exostoses, 1 ou 2)', 90, 0, '33.08.01.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de tumores osteoperiósticos extensos', 140, 0, '33.08.01.17');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção óssea segmentar de tumores invasivos com reconstituição por prótese ou enxerto homólogo', 300, 0,
   '33.08.01.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Idem, com reconstituição da continuidade óssea por artrodese', 220, 0, '33.08.01.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação pela coxa', 130, 0, '33.08.01.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação pelo joelho', 130, 0, '33.08.01.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia diafisária ou distal do fémur', 140, 0, '33.08.01.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia proximal da tíbia', 100, 0, '33.08.01.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia da tíbia e peróneo', 110, 0, '33.08.01.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Epifisiodese (cada osso)', 60, 0, '33.08.01.25');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução focal da superfície articular com enxerto osteocartilagíneo', 120, 0, '33.08.01.26');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artroplastia total por artrose ou revisão de prótese unicompartimental', 220, 0, '33.08.01.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total por revisão de prótese total', 300, 0, '33.08.01.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia unicompartimental femorotibial', 160, 0, '33.08.01.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia femoropatelar', 100, 0, '33.08.01.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese do joelho', 160, 0, '33.08.01.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Meniscectomia convencional ou artroscópica', 90, 0, '33.08.01.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reinserção meniscal convencional ou artroscópica', 120, 0, '33.08.01.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Um dos ligamentos cruzados', 120, 0, '33.08.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Um dos ligamentos periféricos', 100, 0, '33.08.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, '"Reparação das lesões da ""tríada"""', 200, 0, '33.08.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, '"Reparação das lesões da ""pêntada"""', 240, 0, '33.08.02.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ligamento cruzado (cada)', 150, 0, '33.08.03.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ligamento periférico (cada)', 120, 0, '33.08.03.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extrarticulares ou de compensação (acto cirúrgico isolado)', 100, 0, '33.08.03.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extrarticulares ou de compensação (acto cirúrgico associado)', 75, 0, '33.08.03.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quadriciplastia', 150, 0, '33.08.04.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia pararotuliana convencional ou artroscópica (suturas, plicaduras, secções)', 90, 0, '33.08.04.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação recidivante da rótula', 150, 0, '33.08.04.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação congénita da rótula', 150, 0, '33.08.04.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tendinite rotuliana', 90, 0, '33.08.04.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Rotura do tendão quadricipital, rotuliano, ou fractura-avulsão tuberositária', 90, 0, '33.08.04.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Alongamento ou encurtamento do aparelho extensor a qualquer nível', 130, 0, '33.08.04.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrolise simples convencional ou artroscópica', 110, 0, '33.08.04.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia simples e artroscopia diagnóstica', 60, 0, '33.08.04.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas', 130, 0, '33.08.04.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinovectomia', 130, 0, '33.08.04.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operações sobre os tendões (Eggers)', 110, 0, '33.08.05.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transferência dos isquiotibiais para a rótula', 130, 0, '33.08.05.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras transferências', 120, 0, '33.08.05.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intervenções múltiplas para correcção do flexo', 130, 0, '33.08.05.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fasciotomia (Yount)', 80, 0, '33.08.05.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bursite ou higroma rotuliano', 50, 0, '33.08.05.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quisto poplíteu, outros quistos e bursites', 70, 0, '33.08.05.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da diáfise da tíbia e peróneo', 75, 0, '33.09.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da diáfise da tíbia', 60, 0, '33.09.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da diáfise do peróneo', 30, 0, '33.09.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da extremidade distal da tíbia', 60, 0, '33.09.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação do tornozelo', 90, 0, '33.09.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura monomaleolar', 40, 0, '33.09.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura bimaleolar', 60, 0, '33.09.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura trimaleolar', 80, 0, '33.09.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação do tornozelo', 40, 0, '33.09.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Entorse ou rotura ligamentar externa do tornozelo', 30, 0, '33.09.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, '"Osteossíntese da fractura diafisária da tíbia a ""céu aberto"""', 110, 0, '33.09.01.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, '"Osteossíntese da fractura diafisária da tíbia a ""céu fechado"""', 120, 0, '33.09.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da tíbia e peróneo', 120, 0, '33.09.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotaxia da fractura da tíbia', 110, 0, '33.09.01.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento da pseudoartrose da diáfise da tíbia após fractura (com ou sem enxerto ósseo)', 160, 0,
   '33.09.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da pseudoartrose congénita da tíbia', 220, 0, '33.09.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da diáfise do peróneo', 80, 0, '33.09.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação tibiotársica', 110, 0, '33.09.01.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese de um ou dois maléolos ou equivalentes ligamentares', 110, 0, '33.09.01.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese trimaleolar ou equivalentes ligamentares', 120, 0, '33.09.01.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese da fractura cominutiva do pilão tibial', 140, 0, '33.09.01.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção da consolidação viciosa da fractura de um maleolo', 120, 0, '33.09.01.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção da consolidação viciosa das fracturas bi ou trimaleolares', 150, 0, '33.09.01.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteomielite (tratamento em um tempo)', 110, 0, '33.09.01.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteomielite (tratamento em dois ou mais tempos)', 200, 0, '33.09.01.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de pequenos tumores benignos (exostoses inclusive, 1 ou 2)', 110, 0, '33.09.01.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de tumores osteoperiósticos extensos', 120, 0, '33.09.01.17');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção óssea segmentar de tumores invasivos com reconstrução por prótese ou enxerto', 280, 0,
   '33.09.01.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação pela perna', 130, 0, '33.09.01.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia diafisária da tíbia sem osteossíntese', 110, 0, '33.09.01.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia diafisária da tíbia com osteossíntese', 130, 0, '33.09.01.21');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Osteotomia diafisária do peróneo (isolada, não adjuvante de osteotomia da tíbia)', 90, 0, '33.09.01.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da cabeça do peróneo', 75, 0, '33.09.01.23');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteotomia da extremidade distal da tíbia e peróneo', 130, 0, '33.09.01.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total do tornozelo', 160, 0, '33.09.01.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese do tornozelo', 140, 0, '33.09.01.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia simples e artroscopia diagnóstica', 50, 0, '33.09.01.27');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas', 110, 0, '33.09.01.28');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia por osteotomia maleolar com tratamento de lesões articulares', 110, 0, '33.09.01.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinovectomia total', 110, 0, '33.09.01.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia subcutânea do tendão de Aquiles', 30, 0, '33.09.02.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Alongamento a “céu aberto” do tendão de Aquiles ou tratamento da tendinite', 90, 0, '33.09.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação da rotura do tendão de Aquiles', 90, 0, '33.09.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação da rotura de outros tendões na região', 60, 0, '33.09.02.04');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Tratamento do síndrome do canal társico e das neuropatias estenosantes dos ramos do nervo tibial posterior',
                                  110, 0, '33.09.02.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da luxação dos peroniais', 110, 0, '33.09.02.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reparação de instabilidade ligamentar crónica do tornozelo', 120, 0, '33.09.02.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Transposição tendinosa para a insuficiência tricipital', 130, 0, '33.09.02.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do astrágalo', 70, 0, '33.10.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação do astrágalo', 90, 0, '33.10.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do calcâneo', 60, 0, '33.10.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de outros ossos do tarso', 40, 0, '33.10.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de um metatarso', 30, 0, '33.10.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de mais que um metatarso', 40, 0, '33.10.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de um ou mais dedos', 20, 0, '33.10.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação mediotársica ou tarsometatársica', 40, 0, '33.10.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação de dedos (cada)', 10, 0, '33.10.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese da fractura ou fractura luxação do astrágalo', 110, 0, '33.10.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura do calcâneo', 110, 0, '33.10.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do tarso', 80, 0, '33.10.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese de um ou dois metatarsianos', 50, 0, '33.10.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese de mais de dois metatarsianos', 70, 0, '33.10.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese de uma ou duas falanges de dedos', 40, 0, '33.10.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese de mais de duas falanges', 60, 0, '33.10.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação tarsometatársica', 110, 0, '33.10.01.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação tarsometatársica', 90, 0, '33.10.01.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação de dedo (cada)', 40, 0, '33.10.01.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de osteomielite no retropé', 100, 0, '33.10.01.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de osteomielite no mediopé ou antepé', 80, 0, '33.10.01.12');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção de pequenas lesões ou tumores ósseos circunscritos com preenchimento ósseo', 80, 0,
   '33.10.01.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação de Syme', 120, 0, '33.10.01.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação transmetatarsiana', 90, 0, '33.10.01.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação do 1o. Raio (metatarsiano+hallux)', 90, 0, '33.10.01.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação de raio do 2o. Ao 5o. (metatarsiano+dedo)', 70, 0, '33.10.01.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação de dedo', 50, 0, '33.10.01.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do astrágalo', 120, 0, '33.10.01.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de um ou mais ossos do tarso', 110, 0, '33.10.01.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de um metatarsiano', 70, 0, '33.10.01.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dois ou mais metatarsianos', 100, 0, '33.10.01.22');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de exostose ou ossículo supranumerário no retro ou mediopé', 60, 0, '33.10.01.23');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção artroplástica de uma metatarsofalângica, excepto a 1a. Ou de uma ou duas interfalângicas', 60, 0,
   '33.10.01.24');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção artroplástica de duas metatarsifalângicas, excepto a 1a. Ou de várias interfalângicas', 60, 0,
   '33.10.01.25');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção artroplástica múltipla para realinhamento metatarsofalângico', 110, 0, '33.10.01.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia do calcâneo', 100, 0, '33.10.01.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia mediotársica', 120, 0, '33.10.01.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese subastragaliana (intra ou extrarticular)', 120, 0, '33.10.01.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Triciple artrodese', 130, 0, '33.10.01.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese mediotársica', 120, 0, '33.10.01.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese tarsometatarsiana', 120, 0, '33.10.01.32');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrorrisis subastragaliana no pé plano infantil (via interna e externa)', 120, 0, '33.10.01.33');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Artrorrisis subastragaliana no pé plano infantil por ""calcâneo stop"" bilateral"', 120, 0,
   '33.10.01.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alongamento de um metatarsiano', 120, 0, '33.10.01.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alongamento de dois ou mais metatarsianos', 140, 0, '33.10.01.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia', 30, 0, '33.10.01.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com sinovectomia', 40, 0, '33.10.01.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção simples de exostose no 1o.metatarsiano', 60, 0, '33.10.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção simples de exostose no 5o.metatarsiano', 50, 0, '33.10.02.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artroplastia de ressecção metatarsofalângica (tipo Op. de Keller)', 100, 0, '33.10.02.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Realinhamento da 1o. metatarso falângica (tipo Op. de Silver)', 100, 0, '33.10.02.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteotomia da base do 1o. metatarsiano ou artrodese cuneometatarsiana', 80, 0, '33.10.02.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteotomia diafisária do 1o. metatarsiano (tipo Qp. Wilson ou de Helal)', 80, 0, '33.10.02.06');
INSERT INTO ProcedureType VALUES
  (DEFAULT, '"Osteotomia distal do 1o. Matatarsiano (tipo Op. de Mitchell ou de ""chevron"")"', 110, 0, '33.10.02.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Transposição do tendão conjunto (tipo Op. de McBride)', 100, 0, '33.10.02.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artroplastia de interposição da 1a. metatarsofalângica', 120, 0, '33.10.02.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese metatarsofalângica do 1o.raio', 60, 0, '33.10.02.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteotomia de um ou de dois metatarsianos, excepto o 1o.', 60, 0, '33.10.02.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteotomia de três ou de mais metatarsianos, excepto o 1o.', 80, 0, '33.10.02.12');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Uma ou duas artroplastias de interposição protésica metarsofalângica, excepto no 1o. raio, ou interfalângicas',
                                  100, 0, '33.10.02.13');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Três ou mais artroplastias de interposição protésica metarsofalângica, excepto no 1o. raio, ou interfalângicas',
                                  120, 0, '33.10.02.14');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Uma ou duas artroplastias de ressecção ou artrodeses interfalângicas, excepto no 1o. raio', 50, 0,
   '33.10.02.15');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Três ou mais artroplastias de ressecção ou artrodeses interfalângicas, excepto no 1o. raio', 70, 0,
   '33.10.02.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteotomia cuneiforme ou de encurtamento da 1a. falange no hallux', 40, 0, '33.10.02.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese ou tenodese interfalângica no hallux', 40, 0, '33.10.02.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento do 5o. dedo aduto', 70, 0, '33.10.02.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transferência do tendão do tibial posterior', 130, 0, '33.10.03.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Transferência de tendão do tibial anterior, peroniais ou do longo extensor comum', 110, 0, '33.10.03.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Transferência do longo extensor ao colo do 1o. metatarsiano (Op. de Jones)', 100, 0, '33.10.03.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Transferência do extensor comum ao colo dos metatarsianos', 140, 0, '33.10.03.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tenodeses e outras transferências de tendão da perna ou pé', 100, 0, '33.10.03.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de doença de Morton', 110, 0, '33.10.03.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Secção superficial da fáscia plantar', 40, 0, '33.10.03.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Secção profunda das estruturas plantares (Op. de Steindler)', 90, 0, '33.10.03.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia dum tendão do pé ou dedo', 30, 0, '33.10.03.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, de vários dedos', 40, 0, '33.10.03.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenoplastias com enxerto-1 tendão', 110, 0, '33.10.03.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, 2 tendões', 130, 0, '33.10.03.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, 3 ou mais tendões', 150, 0, '33.10.03.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento do pé boto', 180, 0, '33.10.04.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento do astrágalo vertical congénito', 180, 0, '33.10.04.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento do antepé aduto (metarsus varus)', 130, 0, '33.10.04.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de defeitos congénitos no antepé e dedos', 90, 0, '33.10.04.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento do pé plano valgo', 180, 0, '33.10.04.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colheita de enxerto cortico-esponjoso, como adjuvante de uma cirurgia', 30, 0, '33.11.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Tratamento de quisto, ou outros defeitos ósseos circunscritos, por esvaziamento e preenchimento enxerto ósseo, no ombro e anca',
                                  140, 0, '33.11.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Tratamento de quisto, ou outros defeitos ósseos circunscritos, por esvaziamento e preenchimento enxerto ósseo, na zona média dos membros',
                                  120, 0, '33.11.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Tratamento de quisto, ou outros defeitos ósseos circunscritos, por esvaziamento e preenchimento enxerto ósseo, na mão e no pé',
                                  90, 0, '33.11.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição óssea', 180, 0, '33.11.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trepanação óssea', 70, 0, '33.11.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, '', 0, 0, '33.11.01.');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Por via percutânea (extracção de material de osteossíntese ou de tracção esquelética)', 30, 0,
   '33.11.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Por abordagem do plano ósseo: 40% do valor que lhe corresponde na osteossíntese simples (sem colocação de enxerto)',
                                  0, 0, '33.11.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Redução e fixação percutânea de fracturas, luxações ou fracturas luxações em casos não considerados especificamente: acresce em 50% o valor estipulado no tratamento incruento.',
                                  0, 0, '33.11.01.05');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Alongamento ósseo com fixador externo (Illizarov, Wagner, etc.) (tratamento total)', 250, 0,
   '33.11.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fasciotomias por síndrome de compartimento', 90, 0, '33.11.03.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumores benignos', 75, 0, '33.11.03.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumores malignos de tecidos moles', 180, 0, '33.11.03.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tamponamento nasal anterior', 12, 0, '34.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, posterior', 27, 0, '34.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cauterização da mancha vascular', 8, 0, '34.00.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção de corpos estranhos das fossas nasais com anestesia local', 12, 0, '34.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com anestesia geral', 32, 0, '34.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocoagulação dos cornetos unilateral', 18, 0, '34.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Turbinectomia unilateral', 30, 0, '34.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de papiloma do vestíbulo nasal', 15, 0, '34.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, de pólipo sangrante do septo', 37, 0, '34.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polipectomia nasal unilateral', 37, 0, '34.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 57, 0, '34.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polipectomia nasal com etmoidectomia unilateral', 90, 0, '34.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 120, 0, '34.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polipectomia com Caldwell-Luc unilateral', 100, 0, '34.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 130, 0, '34.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Caldwell-Luc unilateral', 80, 0, '34.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 120, 0, '34.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Caldwell-Luc com etmoidectomìa unilateral', 110, 0, '34.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 160, 0, '34.00.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Ermiro de Lima', 145, 0, '34.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do nervo vidiano', 145, 0, '34.00.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção submucosa do septo', 80, 0, '34.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Septoplastia (operação isolada)', 120, 0, '34.00.00.23');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Microcirurgia endonasal e /ou endoscópica unilateral', 130, 0, '34.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 200, 0, '34.00.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abordagem da hipófise, via transeptal', 300, 0, '34.00.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rino-septoplastia', 200, 0, '34.00.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da ozena', 80, 0, '34.00.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Etmoidectomia externa por via paralateronasal', 125, 0, '34.00.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Etmoidectomia total, via combinada', 260, 0, '34.00.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de quisto naso-vestibular', 40, 0, '34.00.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção da sinéquia nasal', 12, 0, '34.00.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação osteoplástica da sinusite frontal', 180, 0, '34.00.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Maxilectomia sem exenteração da órbita', 180, 0, '34.00.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com exenteração', 250, 0, '34.00.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de angiofibroma naso-faringeo', 220, 0, '34.00.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rinectomia parcial', 75, 0, '34.00.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, total', 120, 0, '34.00.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de rinofima', 80, 0, '34.00.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abordagem cirúrgica do seio esfenoidal', 120, 0, '34.00.00.40');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de imperfuração choanal via endonasal', 65, 0, '34.00.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, outras vias', 160, 0, '34.00.00.42');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de hematoma do septo nasal', 15, 0, '34.00.00.43');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção do seio maxilar', 12, 0, '34.00.00.44');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 18, 0, '34.00.00.45');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Punção do seio maxilar com implantação de tubo de drenagem', 18, 0, '34.00.00.46');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 25, 0, '34.00.00.47');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem do seio frontal', 65, 0, '34.00.00.48');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laringectomia total simples', 270, 0, '34.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laringectomia supra glótica com esvaziamento', 300, 0, '34.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemilaringectomia', 280, 0, '34.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laringofissura com cordectomia', 155, 0, '34.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aritenoidopexia', 155, 0, '34.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aritenoidectomia+ Cordopexia', 155, 0, '34.01.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de estenose laringo-traqueal (1o. Tempo)', 240, 0, '34.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tempos seguintes', 135, 0, '34.01.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Laringectomia (total ou parcíal) com esvaziamento unilateral', 320, 0, '34.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com esvaziamento bilateral', 365, 0, '34.01.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Faringo-laringectomia com esvaziamento sem reconstrução', 365, 0, '34.01.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com reconstrução', 465, 0, '34.01.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Microcirurgia laríngea', 135, 0, '34.01.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Microcirurgia laríngea com laser', 160, 100, '34.01.00.14');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento cirúrgico das malformações congénitas da laringe (bridas, quistos, palmuras)', 100, 0,
   '34.01.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traqueotomia (operação isolada)', 85, 0, '34.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cricotiroidotomia (operação isolada)', 70, 0, '34.02.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Encerramento simples de traqueotomia ou fístula traqueal', 100, 0, '34.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fístula fonatória', 110, 0, '34.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traqueoplastia por estenose traqueal', 250, 0, '34.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoplastia', 250, 0, '34.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncotomia', 200, 0, '34.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anastomose traqueo-brônquica ou bronco-brônquica', 400, 0, '34.02.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de ferida brônquica', 200, 0, '34.02.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fístula traqueo-ou bronco-esofágica, tratamento cirúrgico', 270, 0, '34.02.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpos estranhos por via endoscópica', 60, 0, '34.02.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem pleural', 20, 0, '34.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem pleural por empiema com ressecção costal', 60, 0, '34.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracotomia exploradora', 120, 0, '34.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracotomia por ferida aberta do tórax', 135, 0, '34.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracotomia por pneumotórax espontâneo', 135, 0, '34.03.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Toracotomia por hemorragia traumática ou perda de tecido pulmonar', 135, 0, '34.03.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pneumectomia', 300, 0, '34.03.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Pneumectomia com esvaziamento ganglionar mediastinico', 370, 0, '34.03.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lobectomia', 300, 0, '34.03.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bilobectomia', 300, 0, '34.03.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Segmentectomia ou ressecção em cunha, única ou múltipla', 180, 0, '34.03.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção pulmonar com ressecção de parede torácica', 350, 0, '34.03.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracoplastia (primeiro tempo)', 150, 0, '34.03.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracoplastia (tempo complementar)', 150, 0, '34.03.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor da pleura', 150, 0, '34.03.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Descorticação pulmonar', 250, 0, '34.03.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pleurectomia parietal', 175, 0, '34.03.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracoplastia de indicação pleural (num só tempo)', 200, 0, '34.03.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento do canal arterial', 175, 0, '35.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, '“Banding” da artéria pulmonar', 200, 0, '35.00.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Operação de Blalock e outros shunts sistémico-pulmonares', 200, 0, '35.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Focalização de MAPCAS', 250, 0, '35.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de anel vascular', 200, 0, '35.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Shunt cavo-pulmonar', 250, 0, '35.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Blalock-Hanlon', 300, 0, '35.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de coartação da aorta torácica', 250, 0, '35.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de interrupção do arco aórtico', 300, 0, '35.00.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reparação de aneurisma/rotura traumática da aorta torácica', 400, 0, '35.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvulotomia aórtica', 300, 0, '35.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pericardiotomia - via subxifoideia', 50, 0, '35.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Construção de janela pleuropericárdica', 150, 0, '35.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pericardiectomia', 370, 0, '35.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvulotomia mitral', 355, 0, '35.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de feridas cardíacas', 325, 0, '35.00.00.16');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia de implantação epicárdica de sistemas de pacemaker/disfibrilhação automática', 200, 0,
   '35.00.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Bypass coronário com veia safena e/ou 1 anastomose arterial', 500, 0, '35.00.00.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Bypass coronário com 2 ou mais anastomoses arteriais', 525, 0, '35.00.00.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Bypass coronário com 3 ou mais anastomoses arteriais', 550, 0, '35.00.00.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de aneurisma do VE com ou sem bypass coronário', 600, 0, '35.00.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'rotura do septo IV ou parede livre após enfarte', 650, 0, '35.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição de uma válvula', 450, 0, '35.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição de duas válvulas', 500, 0, '35.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição de três válvulas', 550, 0, '35.00.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia de 1 válvula', 500, 0, '35.00.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia de 2 ou mais válvulas', 550, 0, '35.00.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Ross', 700, 0, '35.00.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumores de coração', 500, 0, '35.00.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de comunicação inter auricular', 250, 0, '35.00.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de comunicação interventricular', 450, 0, '35.00.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de estenose da artéria pulmonar', 350, 0, '35.00.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de canal AV parcial/Ostium Primum', 500, 0, '35.00.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de canal AV completo', 550, 0, '35.00.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de Tetralogia de Fallot simples', 525, 0, '35.00.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de obstrução da câmara de saída VE', 500, 0, '35.00.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dissecção da aorta', 625, 0, '35.00.00.37');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Substituição da aorta ascendente e válvula aórtica c/tubo valvulado ou homoenxerto (op. de Bentall)', 700,
   0, '35.00.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do arco aórtico', 700, 0, '35.00.00.39');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Outras cirurgias para correcção total de cardiopatias congénitas complexas', 700, 0, '35.00.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Troncos supra-aorticos (carótida e TABC)', 150, 0, '35.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias dos membros-incisão única', 110, 0, '35.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias dos membros-incisão múltipla', 150, 0, '35.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bifurcação aórtica', 150, 0, '35.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias viscerais', 200, 0, '35.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria carótida, via cervical', 200, 0, '35.01.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria carótida, via torácica', 250, 0, '35.01.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tronco arterial braquiocefálico', 250, 0, '35.01.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias subclavias, via cervical', 150, 0, '35.01.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias subclavias, via torácica ou combinada', 230, 0, '35.01.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria vertebral', 160, 0, '35.01.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria do membro superior', 120, 0, '35.01.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorta abdominal', 230, 0, '35.01.01.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ramos viscerais da aorta', 280, 0, '35.01.01.09');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Artérias ilíacas: unilateral sem desobstrução aórtica, via abdominal ou extraperitoneal', 150, 0,
   '35.01.01.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artérias ilíacas: unilateral sem desobstrução aórtica, via inguinal (anéis)', 120, 0, '35.01.01.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bilateral, em combinação com a aorta', 280, 0, '35.01.01.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bilateral, sem desobstrução aórtica, via abdominal', 200, 0, '35.01.01.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Bilateral, sem desobstrução aórtica, via inguinal (aneis)', 150, 0, '35.01.01.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria femoral comum ou profunda', 120, 0, '35.01.01.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artérias femoral superficial ou poplitea ou tronco tibioperoneal segmentar', 120, 0, '35.01.01.16');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Artérias femoral superficial ou poplitea ou tronco tibioperoneal, extensa(Edwards)', 180, 0,
   '35.01.01.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Revascularização de artéria cerebral extra-craniana (via cervical)', 230, 0, '35.01.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, via torácica', 250, 0, '35.01.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Subclavio-subclavia ou axilar', 150, 0, '35.01.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-subclavia', 300, 0, '35.01.02.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Revascularização múltipla de troncos supra-aorticos a partir da aorta', 350, 0, '35.01.02.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Axilo-femoral unilateral', 200, 0, '35.01.02.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Axilo-bifemoral', 250, 0, '35.01.02.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revascularização de um ramo visceral da aorta', 350, 0, '35.01.02.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Revascularização múltipla de ramos viscerais da aorta', 460, 0, '35.01.02.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-iliaco unilateral', 200, 0, '35.01.02.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-iliaco bilateral', 250, 0, '35.01.02.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-femoral ou aorto-popliteo unilateral', 200, 0, '35.01.02.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-femoral ou aorto-popliteo bilateral', 250, 0, '35.01.02.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-iliofemoral unilateral', 220, 0, '35.01.02.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-iliofemoral bilateral', 300, 0, '35.01.02.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-femoropopliteo unilateral', 220, 0, '35.01.02.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-femoropopliteo bilateral', 300, 0, '35.01.02.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ilio- femoral via anatómica', 200, 0, '35.01.02.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ilio-femoral via extra anatómica', 230, 0, '35.01.02.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Femoro-popliteo ou femoro- femoral unilateral', 200, 0, '35.01.02.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Femoro- femoral cruzado', 200, 0, '35.01.02.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ilio-iliaco', 200, 0, '35.01.02.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Femoro-distal', 220, 0, '35.01.02.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Popliteo-distal', 220, 0, '35.01.02.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias dos membros superiores', 160, 0, '35.01.02.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias genitais', 160, 0, '35.01.02.26');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Arco aortico, com protecção por C.E.C. ou pontes (incluindo toda a equipa médica)', 800, 0, '35.01.03.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Aorta descendente torácica e/ou abdominal; incluindo ramos viscerais, sem C.E.C. (aorta toracoabdominal)',
   500, 0, '35.01.03.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Aorta descendente torácica e/ou abdominal; incluindo ramos viscerais, com C.E.C. (incluindo a equipa médica)',
                                  600, 0, '35.01.03.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carótidas via cervical', 250, 0, '35.01.03.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carótidas via toracocervical', 350, 0, '35.01.03.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Idem com C.E.C. ou ponte (incluindo toda a equipa médica)', 800, 0, '35.01.03.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tronco braquiocefálico', 430, 0, '35.01.03.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias subclavias, via cervical ou axilar', 200, 0, '35.01.03.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias subclavias, via toracocervical', 300, 0, '35.01.03.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias axilar e restantes do membro superior', 180, 0, '35.01.03.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorta abdominal infra-renal', 350, 0, '35.01.03.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ramos viscerais da aorta', 350, 0, '35.01.03.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias ilíacas', 250, 0, '35.01.03.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias femorais ou popliteas', 200, 0, '35.01.03.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras artérias dos membros', 180, 0, '35.01.03.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reparação das lesões da dissecção da aorta, tipo distal na porta de entrada', 500, 0, '35.01.03.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, nos ramos viscerais da aorta', 400, 0, '35.01.03.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, na circulação dos membros inferiores', 300, 0, '35.01.03.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'No pescoço', 150, 0, '35.01.04.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'No tórax com C.E.C. ou ponte', 400, 0, '35.01.04.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'No tórax sem C.E.C. ou ponte', 250, 0, '35.01.04.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'No abdómen, aorta acima de renais', 250, 0, '35.01.04.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'No abdómen, aorta abaixo de renais ou ilíacas', 180, 0, '35.01.04.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ramos viscerais da aorta', 180, 0, '35.01.04.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nos membros, simples', 120, 0, '35.01.04.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nos membros, quando combinada com sutura venosa', 160, 0, '35.01.04.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias carótidas, exploração simples', 80, 0, '35.01.05.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artérias carótidas, libertação e fixação para tratamento de angulações', 130, 0, '35.01.05.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias do tórax', 150, 0, '35.01.05.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias do abdómen e pelve', 150, 0, '35.01.05.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias dos membros', 80, 0, '35.01.05.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias do pescoço', 190, 0, '35.01.06.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias intratorácicas', 160, 0, '35.01.06.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias abdominais', 120, 0, '35.01.06.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias dos membros', 100, 0, '35.01.06.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria maxilar interna na fossa pterigopalatina', 110, 0, '35.01.07.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria etmoidal anterior, via intraorbitária', 100, 0, '35.01.07.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias do pescoço', 80, 0, '35.01.07.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias do tórax', 150, 0, '35.01.07.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias abdominais', 150, 0, '35.01.07.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de prótese entre a aorta e artérias do membro inferior', 200, 0, '35.01.07.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, entre a aorta e troncos supraaorticos', 200, 0, '35.01.07.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias dos membros', 100, 0, '35.01.07.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da fístula aorto-digestiva ou aortocava', 400, 0, '35.01.07.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Simpaticectomia lombar', 100, 0, '35.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Simpaticectomia cervicodorsal', 120, 0, '35.02.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Simpaticectomia torácica superior (via axilar ou transpleural)', 150, 0, '35.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de costela cervical, unilateral', 120, 0, '35.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da 1a. Costela, unilateral', 120, 0, '35.02.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Veias cava inferior, ilíacas, femorais e popliteas, via abdominal', 150, 0, '35.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Grandes veias do tórax', 250, 0, '35.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias dos membros (via periférica)', 100, 0, '35.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias viscerais abdominais', 200, 0, '35.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias do pescoço', 130, 0, '35.03.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Grandes veias do tórax', 200, 0, '35.03.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veia cava inferior acima das veias renais', 250, 0, '35.03.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Restantes veias do abdómen', 200, 0, '35.03.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias dos membros', 150, 0, '35.03.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto do segmento venoso valvulado', 150, 0, '35.03.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastias', 200, 0, '35.03.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Palma e similares', 150, 0, '35.03.01.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias do pescoço', 120, 0, '35.03.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias dos membros', 100, 0, '35.03.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias do tórax', 200, 0, '35.03.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Grandes veias abdominais e pélvicas', 150, 0, '35.03.02.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laqueação de veias do pescoço', 60, 0, '35.03.03.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Interrupção da veia cava inferior por laqueação, plicatura, ou agrafe', 150, 0, '35.03.03.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Interrupção de veia ilíaca', 90, 0, '35.03.03.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Interrupção de veia femoral', 70, 0, '35.03.03.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Laqueação isolada da crossa da veia safena interna ou externa', 80, 0, '35.03.03.05');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Idem + excisão da veia safena interna ou externa com ou sem laqueação de comunicantes com ou sem excisão de segmentos venosos',
                                  160, 0, '35.03.03.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Idem em ambas as veias de um membro (veia safena interna e externa)', 190, 0, '35.03.03.07');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Excisão da veia safena interna ou externa com ou sem laqueação de comunicantes, com ou sem excisão de segmentos venosos intermédios, sem laqueação de crossas de safena interna ou externa',
                                  130, 0, '35.03.03.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Laqueação de comunicantes com ou sem excisão de segmentos venosos', 75, 0, '35.03.03.09');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Laqueação da crossa da veia safena interna ou externa + laqueação de comunicantes com ou sem excisão de segmentos',
                                  150, 0, '35.03.03.10');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Laqueação das crossas das veias safena interna e externa + laqueação de comunicantes com ou sem excisão venosas',
                                  190, 0, '35.03.03.11');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Revisão de laqueação de crossa de veia safena interna ou externa em recidiva de varizes', 90, 0,
   '35.03.03.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem em ambas as veias de um membro', 140, 0, '35.03.03.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Linton ou Cockett isolada', 110, 0, '35.03.03.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Idem a adicionar a valor de outra cirurgia de varizes', 60, 0, '35.03.03.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Via torácica, intraesofágica', 200, 0, '35.03.04.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Via abdominal, extragastrica', 150, 0, '35.03.04.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Via abdominal, intra e extragastrica', 180, 0, '35.03.04.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Sugiura', 200, 0, '35.03.04.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Via abdominal, transsecção esofágica ou plicatura com anastomose(instrumento mecânico)', 200, 0,
   '35.03.04.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Via abdominal, ressecção gástrica', 200, 0, '35.03.04.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Porto-cava termino-lateral', 250, 0, '35.03.04.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Porto-cava latero-lateral', 250, 0, '35.03.04.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Porto-cava em H', 250, 0, '35.03.04.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esplenorenal proximal (anastomose directa)', 280, 0, '35.03.04.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Esplenorenal distal (op. Warren) ou espleno cava distal', 300, 0, '35.03.04.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esplenorenal em H', 250, 0, '35.03.04.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mesenterico-cava – iliaca-ovarica ou renal', 280, 0, '35.03.04.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mesenterico-cava em H', 250, 0, '35.03.04.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coronário-cava (op. Inokuchi)', 280, 0, '35.03.04.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras anastomoses atípicas', 250, 0, '35.03.04.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arterialização do fígado', 200, 0, '35.03.04.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão-enxerto', 150, 0, '35.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto pediculado', 110, 0, '35.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Thompson', 150, 0, '35.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Epiploplastia', 150, 0, '35.04.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Implantação de fios ou outro material para incrementar a drenagem linfática', 80, 0, '35.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anastomose linfovenosa', 150, 0, '35.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Canal torácico, via cervical', 70, 0, '35.04.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Canal torácico, via torácica', 150, 0, '35.04.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Membros', 50, 0, '35.04.01.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura ou anastomose do canal torácico, via cervical', 100, 0, '35.04.02.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura ou anastomose do canal torácico, via torácica', 150, 0, '35.04.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ponte (Shunt) exterior', 50, 0, '35.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fistula arteriovenosa no punho', 100, 0, '35.05.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fistula arteriovenosa no cotovelo', 130, 0, '35.05.00.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ponte arterio-arterial ou arterio-venosa (não inclui o custo de op. acessória ou de prótese)', 160, 0,
   '35.05.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia das complicações dos acessos vasculares com continuidade do acesso', 120, 0, '35.05.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com sacrifício do acesso vascular', 50, 0, '35.05.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Introdução de cateter i.v. com tunelização ou em posição subcutânea', 50, 0, '35.05.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revascularização da artéria hipogastrica', 180, 0, '35.06.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revascularização do pénis', 150, 0, '35.06.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com microcirurgia', 200, 30, '35.06.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de drenagem venosa do pénis', 120, 0, '35.06.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veia cava superior', 20, 0, '35.07.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coração direito ou artéria pulmonar', 30, 0, '35.07.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias cervicais', 20, 0, '35.07.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias renais', 20, 0, '35.07.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias supra-hepáticas', 30, 0, '35.07.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias intra-hepática', 30, 0, '35.07.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veia aferente do sistema porta', 40, 0, '35.07.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias dos membros', 5, 0, '35.07.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carótida', 20, 0, '35.07.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria vertebral', 20, 0, '35.07.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria do membro superior ou inferior', 10, 0, '35.07.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorta', 20, 0, '35.07.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carótida', 80, 0, '35.07.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria dos membros', 80, 0, '35.07.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Canal torácico', 100, 0, '35.07.03.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Vasos linfáticos de membros (superiores e inferiores)', 50, 0, '35.07.03.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esplenectomia (total ou parcial) ou esplenorrafia', 160, 0, '36.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso ganglionar', 17, 0, '36.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de gânglio linfático superficial', 32, 0, '36.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de gânglio linfático profundo', 42, 0, '36.01.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de linfangioma quistico (Exceptuando parótida)', 155, 0, '36.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de linfangioma quístico cervico-parótideo', 270, 0, '36.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento suprahioideu, unilateral', 115, 0, '36.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento suprahioideu, bilateral', 140, 0, '36.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento cervical radical', 165, 0, '36.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento cervical radical, bilateral', 280, 0, '36.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento cervical conservador, unilateral', 130, 0, '36.01.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento cervical conservador, bilateral', 210, 0, '36.01.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento axilar', 130, 0, '36.01.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento inguinal, unilateral', 130, 0, '36.01.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Esvasiamento inguinal e pélvico em continuidade, unilateral', 160, 0, '36.01.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento pélvico unilateral', 140, 0, '36.01.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento pélvico bilateral', 210, 0, '36.01.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Esvasiamento retroperitoneal (aorto-renal e pélvico)', 250, 0, '36.01.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mediastinotomia transesternal exploradora', 120, 0, '37.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mediastinotomia transtorácica exploradora', 120, 0, '37.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor do mediastino', 300, 0, '37.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia do hiato por via abdominal', 250, 0, '37.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia do hiato por via torácica', 250, 0, '37.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de rotura traumática do diafragma', 250, 0, '37.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia de Bochdalek', 250, 0, '37.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imbricação do diafragma por eventração', 250, 0, '37.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia de Morgagni', 250, 0, '37.00.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de diafragma (por tumor ou perfuração inflamatória)', 250, 0, '37.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação do diafragma com prótese', 250, 0, '37.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Em cavidade com compromisso de 1 só face dentária', 15, 10, '38.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Em cavidade com compromisso 2 faces dentárias', 20, 15, '38.00.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Em cavidade com compromisso de 3 ou mais faces dentárias', 25, 25, '38.00.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Com espigões dentários ou intra-radiculares (cada espigão)', 8, 8, '38.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polimento de restauração metálica', 10, 8, '38.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dente de 1 só canal', 15, 20, '38.00.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dente de 2 canais', 20, 25, '38.00.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dente com 3 canais', 25, 40, '38.00.01.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Endodontio que necessita várias sessões de tratamento (por sessão)', 12, 8, '38.00.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação tópica de fluoretos (por sessão)', 10, 8, '38.00.01.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aplicação de compósitos para selagem de fisuras (por quadrante)', 25, 10, '38.00.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Destartarização (por sessão de 1?2 hora)', 15, 10, '38.01.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Curetagem sub-gengival (por quadrante) sem cirurgia', 15, 15, '38.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gengivectomia (por bloco anterior ou lateral)', 15, 25, '38.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia de retalho', 15, 35, '38.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxertos pediculados', 15, 35, '38.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto da mucosa bucal', 15, 35, '38.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Auto-enxerto ósseo', 15, 35, '38.01.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estabilização de peças dentárias por qualquer técnica', 25, 35, '38.01.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exodontia simples de monorradicular', 12, 8, '38.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exodontia simples de multirradicular', 13, 12, '38.02.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exodontia complicada ou de siso incluso, não complicada (sem osteotomia)', 20, 20, '38.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exodontia de dentes inclusos', 35, 60, '38.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reimplantação dentária', 25, 25, '38.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Germectomia', 30, 50, '38.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transplantação de germes dentários', 40, 50, '38.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exodontias múltiplas sob anestesia geral', 100, 0, '38.02.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exodoptia seguida de sutura', 25, 18, '38.02.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apicectomia de monorradiculares', 25, 35, '38.02.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apicectomia de multirradiculares', 30, 50, '38.02.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aprofundamento do vestíbulo (por quadrante)', 30, 40, '38.02.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desinserção e alongamento do freio labial', 15, 35, '38.02.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de bridas gengivais (por quadrante)', 20, 35, '38.02.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Radiculectomia', 30, 35, '38.02.00.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Quistos paradentários, com anestesia local ou regional', 30, 0, '38.02.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quistos paradentários, com anestesia geral', 75, 0, '38.02.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exérese de ranulas simples ou outros pequenos tumores dos tecidos moles da cavidade oral com anestesia local',
                                  20, 40, '38.02.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exérese de ranulas simples ou outros pequenos tumores dos tecidos moles da cavidade oral com anestesia geral',
                                  50, 0, '38.02.00.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Curetagem de focos de osteite não simultânea com a exodontia', 20, 15, '38.02.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia de tecidos moles', 5, 3, '38.02.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia óssea', 15, 3, '38.02.00.22');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exérese de epulides, hiperplasia do rebordo alveolar', 30, 40, '38.02.00.23');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Redução e contenção do dente luxado por trauma com regularização do bordo alveolar (por quadrante)', 30,
   35, '38.02.00.24');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Incisão e drenagem de abcessos de origem dentária, por via bucal', 20, 5, '38.02.00.25');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Incisão e drenagem de abcessos de origem dentária, por via cutânea', 30, 30, '38.02.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Radiografia apical', 2, 2, '38.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Interpromixal (Bitewing)', 2, 3, '38.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Radiografia oclusal', 2, 5, '38.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ortopantomografia', 2, 22, '38.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aparelhos removíveis', 120, 70, '38.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Controle', 7, 10, '38.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aparelhos fixos', 550, 200, '38.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Controle', 15, 20, '38.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conserto de aparelho removível, sem impressão', 20, 0, '38.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conserto de aparelho removível, com impressão', 30, 20, '38.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conjunção de fixação extra-oral', 100, 25, '38.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Impressões e modelos de estudo', 10, 10, '38.04.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Análise cefalométrica da telerradiografia e panorâmica', 10, 30, '38.04.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotografia e estudo fotográfico', 20, 40, '38.04.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Impressão el alginato e modelo de estudo', 15, 10, '38.05.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Impressão em alginato em moldeira individual e modelo de trabalho', 20, 15, '38.05.00.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Impressão em elastrómero de síntese ou hidrocoloide reversível (com moldeira ajustada ou equivalente)', 45,
   15, '38.05.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Impressão funcional usando base ajustada, material termoplástico e outro', 45, 20, '38.05.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Impressão de preparação com espigões intradentários paralelos', 60, 45, '38.05.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Placa para registo de relação intermaxilar', 5, 10, '38.05.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Registo da relação intermaxilar usando cera em base estabilizada numa arcada', 10, 10, '38.05.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem em duas arcadas em (p.p.)', 10, 10, '38.05.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem numa arcada (P.T.)', 15, 15, '38.05.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, '1 dente', 28, 30, '38.05.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, '2 dentes', 31, 30, '38.05.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, '3 dentes', 35, 35, '38.05.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, '4 dentes', 38, 40, '38.05.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, '5 dentes', 42, 45, '38.05.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, '6 dentes', 46, 45, '38.05.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT, '7 dentes', 50, 50, '38.05.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, '8 dentes', 54, 50, '38.05.01.08');
INSERT INTO ProcedureType VALUES (DEFAULT, '9 dentes', 58, 55, '38.05.01.09');
INSERT INTO ProcedureType VALUES (DEFAULT, '10 dentes', 61, 55, '38.05.01.10');
INSERT INTO ProcedureType VALUES (DEFAULT, '11 dentes', 65, 60, '38.05.01.11');
INSERT INTO ProcedureType VALUES (DEFAULT, '12 dentes', 69, 60, '38.05.01.12');
INSERT INTO ProcedureType VALUES (DEFAULT, '13 dentes', 72, 60, '38.05.01.13');
INSERT INTO ProcedureType VALUES (DEFAULT, '14 dentes', 75, 65, '38.05.01.14');
INSERT INTO ProcedureType VALUES (DEFAULT, '28 dentes', 160, 100, '38.05.01.15');
INSERT INTO ProcedureType VALUES (DEFAULT, '1 dente', 55, 42, '38.05.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, '2 dentes', 68, 54, '38.05.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, '3 dentes', 76, 61, '38.05.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, '4 dentes', 86, 71, '38.05.02.04');
INSERT INTO ProcedureType VALUES (DEFAULT, '5 dentes', 98, 80, '38.05.02.05');
INSERT INTO ProcedureType VALUES (DEFAULT, '6 dentes', 113, 93, '38.05.02.06');
INSERT INTO ProcedureType VALUES (DEFAULT, '7 dentes', 122, 98, '38.05.02.07');
INSERT INTO ProcedureType VALUES (DEFAULT, '8 dentes', 132, 106, '38.05.02.08');
INSERT INTO ProcedureType VALUES (DEFAULT, '9 dentes', 139, 111, '38.05.02.09');
INSERT INTO ProcedureType VALUES (DEFAULT, '10 dentes', 143, 115, '38.05.02.10');
INSERT INTO ProcedureType VALUES (DEFAULT, '11 dentes', 148, 118, '38.05.02.11');
INSERT INTO ProcedureType VALUES (DEFAULT, '12 dentes', 143, 120, '38.05.02.12');
INSERT INTO ProcedureType VALUES (DEFAULT, '13 dentes', 156, 122, '38.05.02.13');
INSERT INTO ProcedureType VALUES (DEFAULT, '14 dentes', 158, 124, '38.05.02.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Preparação dentária para coroa de revestimento total', 25, 30, '38.05.03.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem para a coroa em auro-cerâmica', 25, 35, '38.05.03.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem para a coroa com espigão intraradicular', 25, 35, '38.05.03.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem para coroa tipo ‘’Jacket’’', 25, 35, '38.05.03.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem para coroa 3?4 ou 4/5', 25, 40, '38.05.03.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Idem para coroa com espigões paralelos intradentinários', 50, 50, '38.05.03.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem para falso-côto fundido', 25, 25, '38.05.03.07');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Preparação gengival com vista à tomada de impressão imediata: retracção gengival, cirurgia, hemostase, remoção de mucosidade e coágulos (em cada elemento)',
                                  30, 25, '38.05.03.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova ou inserção de cada elemento protético (por sessão)', 15, 25, '38.05.03.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Elaboração de prótese provisória em resina para protecção de côto preparado', 30, 20, '38.05.03.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gancho em aço inoxidável', 4, 9, '38.06.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rebaseamento em prótese superior ou inferior', 50, 20, '38.06.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rebaseamento em resina mole', 60, 20, '38.06.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Barra em aço inoxidável', 12, 12, '38.06.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conserto de fractura de prótese acrílica', 21, 15, '38.06.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acrescentar um dente numa prótese', 23, 15, '38.06.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Acrescentar mais de um dente numa prótese: por cada dente mais', 4, 15, '38.06.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Goteira oclusal simples', 20, 50, '38.06.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Soldadura em prótese de cromo-cobalto', 10, 14, '38.06.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rede de cromo-cobalto', 20, 24, '38.06.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Barra lingual ou palatina', 20, 18, '38.06.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dente fundido em prótese em cromo-cobalto', 10, 14, '38.06.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acrescentar uma cela em prótese de cromo-cobalto', 30, 24, '38.06.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gancho fundido', 10, 14, '38.06.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Face oclusal fundida', 8, 13, '38.06.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Obtenção de modelos para análise oclusal', 20, 20, '38.07.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Montagem de modelos em articulador semifuncional sem registos individuais mas com arco facial (valores médicos) e análise',
                                  80, 80, '38.07.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Equilíbrio oclusal clínico (por sessão)', 50, 50, '38.07.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Montagem de modelos em articulador semifuncional com uso de arco facial ajustado e de arco localizador cinemático, e com registos individuais',
                                  300, 250, '38.07.00.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Equilíbrio oclusal do paciente de acordo com os valores obtidos no articulador', 100, 100, '38.07.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia para colocação de implantes', 50, 60, '38.08.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Implante utilizado (por cada implante)', 0, 300, '38.08.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do bordo livre com avanço da mucosa', 80, 0, '39.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão em cunha com encerramento directo', 70, 0, '39.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção maior que 1?4 com reconstrução', 150, 0, '39.00.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção total do lábio inferior ou superior com reconstrução', 250, 0, '39.00.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de fenda labial completa unilateral', 160, 0, '39.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de fenda palatina parcial', 130, 0, '39.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da fenda labial bilateral', 240, 0, '39.00.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de fenda labial tempos complementares', 90, 0, '39.00.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de outras malformações congénitas dos lábios cada tempo', 100, 0, '39.00.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de fenda completa unilateral do paladar primário', 140, 0, '39.00.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de fenda bilateral (cada lado) do paladar primário', 110, 0, '39.00.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de fenda do paladar primário tempos complementares', 80, 0, '39.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fístulas congénitas labiais', 90, 0, '39.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de quistos, abcessos, hematomas', 20, 0, '39.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia do freio lingual', 25, 0, '39.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de lesão da mucosa ou sub-mucosa', 30, 0, '39.01.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de lesão da mucosa ou sub-mucosa com plastia', 55, 0, '39.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de laceração superficial', 25, 0, '39.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de laceração com mais de 2 cm, profunda', 30, 0, '39.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vestibuloplastia por quadrante', 30, 0, '39.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Incisão e drenagem de quistos, abcessos intra-orais ou hematomas da língua ou pavimento da boca - superficiais',
                                  20, 0, '39.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Incisão e drenagem de quistos, abcessos intra-orais ou hematomas da língua ou pavimento da boca - profundos',
                                  25, 0, '39.02.00.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Incisão e drenagem extra-oral de abcesso, quisto e/ou hematoma do pavimento da boca ou sublingual', 30, 0,
   '39.02.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de lesão da língua localizada nos 2/3 anteriores', 35, 0, '39.02.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de lesão da língua localizada no 1/3 posterior', 50, 0, '39.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de lesão do pavimento da boca', 30, 0, '39.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glossectomia menor que 1?2 da língua', 70, 0, '39.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemiglossectomia', 100, 0, '39.02.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Hemiglossectomia com esvasiamento unilateral do pescoço', 220, 0, '39.02.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glossectomia total, sem esvasiamento cervical', 150, 0, '39.02.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glossectomia total, com esvasiamento unilateral', 220, 0, '39.02.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glossectomia total com esvasiamento bilateral', 320, 0, '39.02.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Glossectomia com ressecção do pavimento da boca e mandíbula', 250, 0, '39.02.00.13');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Glossectomia com ressecção do pavimento da boca e mandíbula com esvaziamento cervical', 320, 0,
   '39.02.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reparação de laceração até 2 cm do pavimento ou dos 2/3 anteriores da língua', 20, 0, '39.02.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação de laceração do 1/3 posterior da língua', 25, 0, '39.02.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reparação de laceração do pavimento ou língua (mais de 2 cm)', 30, 0, '39.02.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso do palato ou úvula', 20, 0, '39.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de lesão do palato ou úvula', 30, 0, '39.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de exostose do palato', 25, 0, '39.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de laceração do palato até 2 cm', 25, 0, '39.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de laceração do palato mais de 2 cm', 50, 0, '39.03.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Palotoplastia para tratamento de ferida (palato mole)', 110, 0, '39.03.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Retalho osteo periósteo ou enxerto ósseo em fenda alveolo palatina', 120, 0, '39.03.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estafilorrafia por fenda palatina incompleta ou estafilorrafia simples', 125, 0, '39.03.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uranoestafilorrafia por fenda palatina completa', 150, 0, '39.03.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução do palato anterior em fenda alveolo-palatina', 125, 0, '39.03.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de fístula oroantral', 110, 0, '39.03.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Palatoplastia para correcção de roncopatia', 120, 0, '39.03.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Adenoidectomia (Laforce-Beckman)', 20, 0, '39.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com anestesia geral e intubação endotraqueal', 60, 0, '39.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amigdalectomia por Sluder', 30, 0, '39.04.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Idem, por dissecção, com anestesia geral e intubação endotraqueal', 100, 0, '39.04.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Adenoidectomia com amigdalectomia por Sluder-Laforce-Beckman', 40, 0, '39.04.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Idem, por dissecção (com anestesia geral e intubação endotraqueal)', 130, 0, '39.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho da orofaringe', 15, 0, '39.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, da hipofaringe', 25, 0, '39.04.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso amigdalino', 20, 0, '39.04.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, abcesso retro ou parafaríngeo, por via oral', 30, 0, '39.04.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, por via externa', 40, 0, '39.04.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Faringoplastia em sequela de ferida palatina', 130, 0, '39.04.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Faringoplastia em sequela de fenda palatina', 130, 0, '39.04.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Encerramento de faringostoma, por cada tempo operatório', 100, 0, '39.04.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Faringotomia', 100, 0, '39.04.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extirpação das apófises estiloideias', 70, 0, '39.04.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extirpação de fístula ou quisto branquial, amigdalino, etc.', 110, 0, '39.04.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de faringotomia com retalho', 160, 0, '39.04.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor parafaringeo', 210, 0, '39.04.00.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Faringoplastia em sequela de fenda do paladar secundário', 130, 0, '39.04.00.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Drenagem simples de abcessos (parótida, submaxilar ou sublingual)', 15, 0, '39.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Marsupialização de quisto sublingual (rânula)', 15, 0, '39.05.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de quisto sublingual ou do pavimento', 50, 0, '39.05.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parotidectomia superficial', 210, 0, '39.05.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Parotidectomia total com sacrifício do nervo facial', 210, 0, '39.05.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Parotidectomia total com dissecção e conservação do nervo facial', 310, 0, '39.05.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Parotidectomia total com reconstrução do nervo facial', 320, 0, '39.05.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de glândula submaxilar', 90, 0, '39.05.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de glândula sublingual', 70, 0, '39.05.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Injecção para sialografia com dilatação dos canais salivares', 15, 0, '39.05.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de cálculos dos canais salivares por via endobucal', 40, 0, '39.05.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de glândulas salivares aberrantes', 70, 0, '39.05.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagotomia cervical', 110, 0, '39.06.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagotomia torácica', 180, 0, '39.06.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Miotomia cricofaríngea', 110, 0, '39.06.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Heller', 200, 0, '39.06.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagectomia cervical (operação tipo Wookey)', 160, 0, '39.06.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Esofagectomia sub-total com reconstituição da continuidade', 400, 0, '39.06.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Esofagectomia da 1/3 inferior com reconstituição da continuidade', 250, 0, '39.06.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diverticulectomia de Zenker', 180, 0, '39.06.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagostomia', 110, 0, '39.06.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagoplastia, por atrésia do esófago', 400, 0, '39.06.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laqueação de fístula esófago-traqueal', 300, 0, '39.06.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de varizes esofágicas', 200, 0, '39.06.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diverticulectomia do terço médio e inferior', 250, 0, '39.06.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrotomia', 110, 0, '39.07.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Piloromiotomia', 130, 0, '39.07.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrotomia com excisão de úlcera ou tumor', 120, 0, '39.07.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrectomia parcial ou sub-total', 200, 0, '39.07.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrectomia total', 300, 0, '39.07.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desgastrogastrectomia', 300, 0, '39.07.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrectomia sub-total radical', 250, 0, '39.07.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrenterostomia', 130, 0, '39.07.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrorrafia, sutura de úlcera perfurada ou ferida', 130, 0, '39.07.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Piloroplastia', 130, 0, '39.07.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrostomia', 130, 0, '39.07.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Revisão de anastomose gastroduodenal ou gastrojejunal com reconstrução', 250, 0, '39.07.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vagotomia troncular ou selectiva', 160, 0, '39.07.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vagotomia super selectiva', 180, 0, '39.07.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enterolise de aderências', 110, 0, '39.08.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Duodenotomia', 110, 0, '39.08.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enterotomia', 110, 0, '39.08.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colotomia', 110, 0, '39.08.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enterostomia ou cecostomia', 120, 0, '39.08.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ileostomia «continente»', 180, 0, '39.08.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revisão da ileostomia', 100, 0, '39.08.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colostomia', 140, 0, '39.08.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revisão da colostomia, simples', 110, 0, '39.08.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de pequenas lesões não requerendo anastomose ou exteriorização', 120, 0, '39.08.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enterectomia', 140, 0, '39.08.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enteroenterostomia', 130, 0, '39.08.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colectomia segmentar', 180, 0, '39.08.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemicolectomia', 200, 0, '39.08.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colectomia com coloproctostomia', 300, 0, '39.08.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colectomia tipo Hartmann', 160, 0, '39.08.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colectomia com colostomia e criação de fístula mucosa', 160, 0, '39.08.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colectomia total', 300, 0, '39.08.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Proctolectomia', 350, 0, '39.08.00.21');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de duplicação intestinal simples', 120, 0, '39.08.00.22');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de duplicação intestinal complexa', 200, 0, '39.08.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de ileus meconial', 220, 0, '39.08.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enterorrafia', 130, 0, '39.08.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de enterostomia ou colostomia', 130, 0, '39.08.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fistulas intestinais', 150, 0, '39.08.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plicatura do intestino (tipo Noble)', 150, 0, '39.08.00.28');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico da atrésia do duodeno, jejuno, ileon ou colon', 220, 0, '39.08.00.29');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Coloprotectomia conservadora com reservatório ileo-anal', 380, 0, '39.08.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diverticulectomia', 130, 0, '39.09.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor do mesentério', 160, 0, '39.09.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de mesentério (laceração e hérnia interna)', 130, 0, '39.09.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apendicectomia', 110, 0, '39.09.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de abcesso apendicular', 90, 0, '39.09.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de malrotação intestinal', 160, 0, '39.09.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem Transrectal de abcesso perirectal', 90, 0, '39.10.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção anterior de recto', 250, 0, '39.10.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção anterior de recto (1/3 médio e inferior)', 300, 0, '39.10.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção abdominoperineal do recto', 300, 0, '39.10.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Protectomia com anastomose anal (Pull-Through)', 300, 0, '39.10.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de prolapso rectal por via abdominal ou perineal', 160, 0, '39.10.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de doença de Hirschsprung', 300, 0, '39.10.00.07');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção de tumor benigno por via transagrada e/ou transcoccígea (tipo Kraske)', 180, 0, '39.10.00.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção de tumor maligno por via transagrada e/ou transcoccigea (tipo Kraske)', 250, 0, '39.10.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão, electrocoagulação, criocoagulação ou laser de tumor do recto', 70, 0, '39.10.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de teratoma pré sagrado', 220, 0, '39.10.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de abcesso da margem do anus', 20, 0, '39.11.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esfincterotomia com ou sem fissurectomia', 70, 0, '39.11.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemorroidectomia', 100, 0, '39.11.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fistulectomia por fístula perineo-rectal', 120, 0, '39.11.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Criptectomia', 40, 0, '39.11.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cerclage do anus', 50, 0, '39.11.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação anal, sob anestesia geral', 20, 0, '39.11.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico da agenesia ano-rectal (forma alta)', 300, 0, '39.11.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico da agenesia ano-rectal (forma baixa)', 100, 0, '39.11.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esfincteroplastia, por incontinência anal', 110, 0, '39.11.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transplante do recto interno', 180, 0, '39.11.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transplante muscular livre', 220, 0, '39.11.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão de trombose hemorroidária', 20, 0, '39.11.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hepatectomia parcial atípica', 190, 0, '39.12.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hepatectomia regrada direita', 450, 0, '39.12.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hepatectomia regrada esquerda', 350, 0, '39.12.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Marsupialização ou excisão de quisto ou absesso', 130, 0, '39.12.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Segmentectomia hepática', 220, 0, '39.12.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterização cirúrgica da artéria hepática para tratamento complementar', 220, 0, '39.12.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de quisto hidático simples', 150, 0, '39.12.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Periquistectomia', 300, 0, '39.12.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento dos traumatismos hepáticos grau 1 e 2', 200, 0, '39.12.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de traumatismos hepáticos grau 3, 4 e 5', 350, 0, '39.12.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecistectomia com ou sem colangiografia', 160, 0, '39.13.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecistectomia com coledocotomia', 180, 0, '39.13.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecistectomia com esfincteroplastia', 230, 0, '39.13.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coledocotomia com ou sem colecistectomia', 180, 0, '39.13.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coledocotomia com esfincteroplastia', 240, 0, '39.13.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hepaticotomia para excisão de cálculo', 200, 0, '39.13.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esfincteroplastia transduodenal (operação isolada)', 190, 0, '39.13.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecistoenterostomia', 120, 0, '39.13.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecocoenterostomia', 200, 0, '39.13.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hepaticojejunostomia (Roux)', 350, 0, '39.13.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anastomose topo a topo das vias biliares', 250, 0, '39.13.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anastomose entre os ductos intra-hepáticos e o tubo digestivo', 350, 0, '39.13.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecistostomia (operação isolada)', 110, 0, '39.13.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de quisto do colédoco', 300, 0, '39.13.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumor de Klatskin', 400, 0, '39.13.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Entubação transtumoral de tumor das vias biliares', 180, 0, '39.13.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Duodenopancreatectomia (tipo Whipple)', 450, 0, '39.14.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pancreatectomia distal com esplenectomia', 250, 0, '39.14.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pancreatectomia distal sem esplenectomia', 310, 0, '39.14.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pancreatectomia «quase total» (tipo Chili)', 350, 0, '39.14.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de lesão tumoral do pâncreas', 220, 0, '39.14.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pancreato jejunostomia (tipo Puestow)', 350, 0, '39.14.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pancreato jejunostomia (tipo Duval)', 200, 0, '39.14.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistojejunostomia ou cistogastrostomia', 200, 0, '39.14.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laparotomia exploradora (operação isolada)', 100, 0, '39.15.00.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Laparotomia para drenagem de abcesso peritoneal ou retroperitoneal (excepto apêndice)', 120, 0,
   '39.15.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Laparotomia por perfuração de víscera oca (excepto apêndice)', 130, 0, '39.15.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exérese de tumor benigno ou quistos retroperitoneais, via abdominal', 250, 0, '39.15.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exérese de tumor maligno retroperitoneal via abdominal', 320, 0, '39.15.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exérese de tumor ou quistos retroperitoneais, via toracoabdominal', 350, 0, '39.15.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Omentectomia total (operação isolada)', 160, 0, '39.15.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirurgico de onfalocelo - vários tempos', 300, 0, '39.15.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirurgico de onfalocelo - um tempo', 100, 0, '39.15.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia inguinal', 100, 0, '39.15.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia crural', 110, 0, '39.15.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de hérnia lombar, obturadora ou isquiática', 150, 0, '39.15.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia umbilical', 90, 0, '39.15.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia epigástrica', 90, 0, '39.15.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia de Spiegel', 120, 0, '39.15.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia incisional', 130, 0, '39.15.00.16');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento de hérnia estrangulada, a acrescentar ao valor da respectiva localização', 25, 0,
   '39.15.00.17');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento de hérnia com ressecção intestinal, a acrescentar ao valor da respectiva localização', 45, 0,
   '39.15.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Omentoplastia pediculada', 160, 0, '39.15.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de evisceração post-operatória', 90, 0, '39.15.00.20');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento de perda de substância da parede abdominal-enxertos (fascia lata, dérmico, rede, etc.)', 160, 0,
   '39.15.00.21');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Lombotomia exploradora e exploração cirúrgica retroperitoneal', 120, 0, '40.00.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Drenagem cirúrgica de hematoma, urinoma ou abcesso retroperitoneal', 100, 0, '40.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumor retroperitoneal', 180, 0, '40.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem por via toraco-abdominal', 240, 0, '40.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfadenectomia retroperitoneal para-aórtica-cava', 280, 0, '40.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfadenectomia retroperitoneal pélvica unilateral', 145, 0, '40.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfadenectomia retroperitoneal pélvica bilateral', 200, 0, '40.00.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Linfadenectomia retroperitoneal para-aórtico-cava e pélvica', 350, 0, '40.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Suprarenalectomia por patologia suprarenal', 160, 0, '40.00.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Suprarenalectomia no decorrer de nefrectomia radical', 80, 0, '40.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Suprarenalectomia bilateral', 240, 0, '40.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da artéria renal', 280, 0, '40.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da veia renal', 200, 0, '40.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, '"Cirurgia renal ""ex-situ"""', 400, 0, '40.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Auto-transplantação', 400, 0, '40.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transplantação de rim de cadáver ou de rim vivo', 400, 0, '40.00.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colheita de rim para transplante (de rim de cadáver ou de rim vivo)', 180, 0, '40.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia renal cirúrgica', 100, 0, '40.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefro(lito)tomia', 180, 0, '40.00.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefro(lito)tomia anatrófica', 250, 0, '40.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pielo(lito)tomia simples', 130, 0, '40.00.00.21');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Pielocalico(lito)tomia ou pielonefro(lito)tomia por litíase coraliforme ou précoraliforme', 200, 0,
   '40.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pielo(lito)tomia secundária (iterativa)', 180, 0, '40.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pielo(lito)tomia em malformação renal', 180, 0, '40.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrostomia ou pielostomia aberta', 110, 0, '40.00.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrorrafia por traumatismo–renal', 160, 0, '40.00.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento da fistula pielo-cutânea', 120, 0, '40.00.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula pielo-visceral', 160, 0, '40.00.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calico-ureterostomia', 160, 0, '40.00.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calicorrafia ou calicoplastia', 160, 0, '40.00.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pieloureterolise', 130, 0, '40.00.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pielorrafia', 130, 0, '40.00.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pieloplastia desmembrada tipo Anderson Hynes', 180, 0, '40.00.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outra pieloplastia desmembrada', 180, 0, '40.00.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pieloplastia não desmembrada', 160, 0, '40.00.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pieloplastia em malformação renal', 180, 0, '40.00.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefropexia', 110, 0, '40.00.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quistectomia ou marsupialização de quisto renal', 130, 0, '40.00.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enucleação de tumor do rim', 180, 0, '40.00.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia parcial (inclui heminefrectomia)', 200, 0, '40.00.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia total', 160, 0, '40.00.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia radical', 200, 0, '40.00.00.42');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Nefrectomia radical com linfadenectomia para aórtico-cava', 320, 0, '40.00.00.43');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia secundária', 200, 0, '40.00.00.44');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia de rim ectópico', 180, 0, '40.00.00.45');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia de rim transplantado', 160, 0, '40.00.00.46');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefro-ureterectomia sub-total', 200, 0, '40.00.00.47');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefro-ureterectomia com cistectomia perimeática', 250, 0, '40.00.00.48');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pielectomia com excisão de tumor piélico', 160, 0, '40.00.00.49');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia endoscópica do segmento pielo-ureteral (SPU), bacinete ou cálices com ureterorrenoscópio', 160,
   200, '40.00.00.50');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia renal percutânea com controle RX-Eco', 65, 0, '40.00.00.51');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrostomia percutânea', 110, 0, '40.00.00.52');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento percutâneo de quisto renal', 110, 0, '40.00.00.53');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefroscopia percutânea', 160, 200, '40.00.00.54');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Nefro(lito)extracção percutânea com pinças ou sondas-cesto', 180, 200, '40.00.00.55');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Nefro(lito)extracção percutânea com litotritor ultra-sónico, electro-hidráulico ou laser', 200, 300,
   '40.00.00.56');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pieloureterotomia interna', 160, 200, '40.00.00.57');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infundibulocalicotomia', 150, 200, '40.00.00.58');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção percutânea de tumor do bacinete ou cálices', 160, 200, '40.00.00.59');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fotorradiação percutânea com laser de cálices, bacinete ou SPU', 160, 500, '40.00.00.60');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Litotrícia extracorporal por ondas de choque (por unidade renal)', 150, 3000, '40.00.00.61');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Litotrícia extracorporal por ondas de choque (sessões complementares - dentro de um periodo de 3 meses)',
   130, 1000, '40.00.00.62');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretero(lito)tomia lombar', 130, 0, '40.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretero(lito)tomia ilíaca', 120, 0, '40.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretero(lito)tomia pélvica', 160, 0, '40.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretero(lito)tomia transvesical', 120, 0, '40.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretero(lito)tomia transvaginal', 120, 0, '40.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterostomia intubada', 120, 0, '40.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterostomia cutânea directa unilateral', 120, 0, '40.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterostomia cutânea directa bilateral', 160, 0, '40.01.00.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ureterostomia cutânea indirecta transileal (ureteroileostomia cutânea-operação de Bricker)', 280, 0,
   '40.01.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ureterostomia cutânea indirecta transcólica (ureterocolostomia cutânea)', 280, 0, '40.01.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ureterostomia cutânea indirecta com bolsa intestinal continente', 350, 0, '40.01.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revisão de ureterostomia cutânea', 120, 0, '40.01.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revisão de anastomose uretero intestinal', 200, 0, '40.01.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterosigmoidostomia', 180, 0, '40.01.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ureterorrectostomia (bexiga rectal) com abaixamento intestinal', 320, 0, '40.01.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desderivação urinária', 300, 0, '40.01.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação cirúrgica de tutor ureteral', 120, 0, '40.01.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transureteroureterostomia', 160, 0, '40.01.00.18');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ureterocistoneostomia (Reimplantação ureterovesical) ou operação anti-refluxo sem ureteroneocistostomia',
   160, 0, '40.01.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem bilateral', 200, 0, '40.01.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com modelagem ureteral', 170, 0, '40.01.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com modelagem ureteral bilateral', 220, 0, '40.01.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com plastia vesical (tipo Boari)', 180, 0, '40.01.00.23');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia do ureterocele (sem uretero cistoneostomia)', 140, 0, '40.01.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterorrafia', 150, 0, '40.01.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula uretero-cutânea', 110, 0, '40.01.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula uretero-visceral', 180, 0, '40.01.00.27');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ureteroplastia (inclui ureteroplastia intubada-Davies)', 160, 0, '40.01.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição ureteral por intestino', 300, 0, '40.01.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterectomia de coto ureteral ou ureter acessório', 150, 0, '40.01.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterolise', 130, 0, '40.01.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Descruzamento uretero-vascular', 160, 0, '40.01.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do ureter retro-cava', 180, 0, '40.01.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterolise por fibrose retroperitoneal', 160, 0, '40.01.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intraperitonealizarão de ureter', 200, 0, '40.01.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação endoscópica do meato ureteral', 40, 60, '40.01.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Meatotomia ureteral endoscópica', 50, 60, '40.01.00.37');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção de corpos estranhos do ureter com citoscópio', 50, 60, '40.01.00.38');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia endoscópica de ureterocele (unilateral) com ureterocelotomia', 80, 100, '40.01.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com ressecção de ureterocele', 80, 100, '40.01.00.40');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia endoscópica do refluxo vesico-ureteral (unilateral)', 80, 100, '40.01.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem bilateral', 100, 100, '40.01.00.42');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Cateterismo endoscópico ureteral terapêutico unilateral (incluí dilatação endoscópica sem visão e inclui drenagem)',
                                  40, 60, '40.01.00.43');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem bilateral', 65, 60, '40.01.00.44');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colocação endoscópica retrógada de tutor ureteral (unilateral)', 50, 60, '40.01.00.45');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem bilateral', 80, 60, '40.01.00.46');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterolitoextracção endoscópica sem visão', 80, 60, '40.01.00.47');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fulguração endoscópica do ureter com ureterorrenoscópico (URC)', 120, 200, '40.01.00.48');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterotomia interna sob visão com URC', 140, 200, '40.01.00.49');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ureterolitoextracção sob visão com URC com pinças ou sondas-cesto', 140, 200, '40.01.00.50');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ureterolitoextracção sob visão com URC com litotritor ultra-sónico, electro-hidráulico ou laser', 140, 300,
   '40.01.00.51');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de tumor ureteral com URC', 140, 200, '40.01.00.52');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotorradiação endoscópica com laser com URC', 120, 500, '40.01.00.53');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colocação percutânea anterógrada de tutor ureteral', 120, 150, '40.01.00.54');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Uretero(lito)extracção percutânea com pinças ou sondas-cesto', 160, 200, '40.01.00.55');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Uretero(lito)extracção percutânea com litotritor ultra-sónico, electro-hidráulico ou laser', 160, 300,
   '40.01.00.56');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterotomia interna percutânea', 160, 200, '40.01.00.57');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção percutânea de tumor do ureter', 160, 200, '40.01.00.58');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotoradiação percutânea com laser do ureter', 160, 500, '40.01.00.59');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Litotrícia extracorporal por ondas de choque', 140, 3000, '40.01.00.60');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, sessão complementar', 120, 1000, '40.01.00.61');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exploração cirúrgica da bexiga e perivesical', 110, 0, '40.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem cirúrgica peri-vesical', 110, 0, '40.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cisto(lito)tomia', 110, 0, '40.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistostomia ou vesicostomia', 110, 0, '40.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistorrafia', 110, 0, '40.02.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Encerramento de fístula vesicocutânea (inclui encerramento de cistosmia)', 110, 0, '40.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula vesicoentérica', 180, 0, '40.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula vesico-ginecológica', 180, 0, '40.02.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem complexa com retalho tecidular', 200, 0, '40.02.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Enterocitoplastia de alargamento (qualquer tipo de segmento intestinal)', 280, 0, '40.02.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enterocistoplastia de substituição destubularizada', 320, 0, '40.02.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia de redução vesical', 200, 0, '40.02.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia do diverticulo vesical com diverticulo plastia', 110, 0, '40.02.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diverticulolectomia', 150, 0, '40.02.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão do úraco', 110, 0, '40.02.00.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cistectomia parcial com ressecção transvesical de tumor', 140, 0, '40.02.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia parcial segmentar', 150, 0, '40.02.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia sub-total', 180, 0, '40.02.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia total', 180, 0, '40.02.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia radical (ureterectomia não incluida)', 225, 0, '40.02.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia radical com linfadenectomia pélvica', 320, 0, '40.02.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exenteração pélvica anterior', 320, 0, '40.02.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação cirúrgica de radioisótopos na bexiga', 110, 0, '40.02.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da bexiga extrofiada', 300, 0, '40.02.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com osteotomia bi-ilíaca', 400, 0, '40.02.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem cirúrgica periutretal feminina', 20, 0, '40.02.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrotomia feminina', 30, 0, '40.02.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrorrafia feminina', 50, 0, '40.02.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula uretrovaginal', 100, 0, '40.02.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cervicouretroplastia feminina', 100, 0, '40.02.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução da uretra feminina (inclui neouretra)', 180, 0, '40.02.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colpoperineorrafioplastia anterior', 100, 0, '40.02.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cervicouretropexia por via vaginal', 110, 0, '40.02.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cervicouretropexia por via suprapúbica', 150, 0, '40.02.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cervicouretropexia por via mista', 160, 0, '40.02.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrotomia feminina', 100, 0, '40.02.00.36');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exerése de divertículo uretral feminino (uretrocele)', 100, 0, '40.02.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de carúncula ou prolapso uretral feminino', 30, 0, '40.02.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fulguração endoscópica vesical', 35, 75, '40.02.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção-biópsia endoscópica de tumor vesical', 50, 100, '40.02.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção endoscópica de tumor vesical (RTU-V)', 140, 100, '40.02.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação de laser por via endoscópica', 140, 500, '40.02.00.42');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção endoscópica de cálculo, coágulo ou corpo estranho vesical', 80, 60, '40.02.00.43');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Litotrícia endoscópica vesical com litotritor mecânico sem visão', 80, 40, '40.02.00.44');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Litotrícia endoscópica vesical com litotritor mecânico com visão', 140, 100, '40.02.00.45');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Litotrícia endoscópica vesical com litotritor ultra-sónico, electro-hidráulico ou laser', 140, 300,
   '40.02.00.46');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia endoscópica de divertículo vesical', 120, 100, '40.02.00.47');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação endoscópica da bexiga', 50, 50, '40.02.00.48');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Alargamento endoscópico do colo vesical feminino com incisão de colo vesical', 50, 80, '40.02.00.49');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com ressecção do colo vesical', 60, 100, '40.02.00.50');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento endoscópico de incontinência urinária feminina', 140, 100, '40.02.00.51');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistostomia suprapúbica percutânea', 30, 0, '40.02.00.52');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Litotrícia extracorporal por ondas de choque', 140, 3000, '40.02.00.53');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem sessão complementar', 120, 1000, '40.02.00.54');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Colocação de prótese para tratamento de incontinência urinária (esfincter artificial)', 180, 0,
   '40.02.00.55');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Reeducação perineo-esfincteriana, por incontinência urinária, biofeedback ou electroestimulação, por sessão',
                                  10, 15, '40.02.00.56');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia aberta do colo vesical com incisão ou excisão do colo', 110, 0, '40.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia Y-V do colo vesical', 160, 0, '40.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostatectomia suprapúbica ou retro púbica por HBP', 160, 0, '40.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostatectomia perineal por HBP', 180, 0, '40.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostatectomia radical retropúbica', 200, 0, '40.03.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prostatectomia radical retropúbica com linfadenectomia pélvica', 280, 0, '40.03.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostatectomia radical perineal', 200, 0, '40.03.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação cirúrgica de radioisótopos na próstata', 110, 0, '40.03.00.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia da incontinência urinária do homem (exclui próteses e cirurgia endoscópica)', 180, 0,
   '40.03.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Limpeza cirúrgica de osteíte do púbis', 90, 0, '40.03.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem endoscópica de abcesso da próstata', 100, 100, '40.03.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção endoscópica de próstata (RTUP)', 160, 100, '40.03.00.12');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Alargamento endoscópico da loca prostática com incisão ou ressecção de fibrose da loca', 60, 80,
   '40.03.00.13');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Alargamento endoscópico de colo vesical masculino com incisão ou ressecção de colo vesical', 70, 80,
   '40.03.00.14');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Colocação endoscópica de prótese de alargamento de colo vesical de uretra prostática', 70, 60,
   '40.03.00.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento endoscópico da incontinência urinária masculina', 140, 100, '40.03.00.16');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Colocação endoscópica de prótese uretral expansível reepitelizável (exclui o custo da prótese)', 120, 60,
   '40.03.00.17');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Colocação de prótese para tratamento de incontinência urinária (esfincter artificial)', 150, 0,
   '40.03.00.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Hipertermia prostática (Independentemente do número de sessões)', 80, 800, '40.03.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Termoterapia prostática transuretral (independentemente do número de sessões - não inclui sonda aplicadora)',
                                  80, 1400, '40.03.00.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Laser próstático transuretral (não incluí fibras nem mangas)', 130, 500, '40.03.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exploração cirúrgica da uretra', 70, 0, '40.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem cirúrgica peri-uretral', 25, 0, '40.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Meatomia', 30, 0, '40.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrolitotomia', 50, 0, '40.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrotomia externa', 100, 0, '40.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Monseur', 150, 0, '40.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrostomia', 80, 0, '40.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intubação e recanalização uretral', 90, 0, '40.04.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrorrafia', 90, 0, '40.04.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento da uretrostomia', 100, 0, '40.04.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula uretro-cutânea', 100, 0, '40.04.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fistula uretro-rectal', 200, 0, '40.04.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Meatoplastia', 50, 0, '40.04.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretroplastia de uretra anterior termino terminal', 150, 0, '40.04.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com retalho pediculado', 160, 0, '40.04.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com retalho livre', 160, 0, '40.04.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem 1o. Tempo', 150, 0, '40.04.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem 2o. Tempo', 150, 0, '40.04.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretroplastia da uretra posterior termino-terminal', 200, 0, '40.04.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com retalho pediculado', 200, 0, '40.04.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com retalho livre', 200, 0, '40.04.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem 1o. Tempo', 200, 0, '40.04.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem 2o. Tempo', 180, 0, '40.04.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diverticulectomia uretral', 100, 0, '40.04.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrectomia parcial', 80, 0, '40.04.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrectomia total', 150, 0, '40.04.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrectomia de uretra acessória', 150, 0, '40.04.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção cirúrgica de corpos estranhos uretrais', 50, 0, '40.04.00.28');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia do hipospadias e da uretra curta congénita proximal num só tempo', 220, 0, '40.04.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem distal num só tempo', 150, 0, '40.04.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem em, 2 tempos 1o. Tempo (endireitamento)', 100, 0, '40.04.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem em 2 tempos 2o. Tempo (neouretroplastia)', 160, 0, '40.04.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do epispádias', 230, 0, '40.04.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fulguração endoscópica uretral', 35, 75, '40.04.00.34');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção endoscópica de cálculo ou corpo estranho uretral', 50, 60, '40.04.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrotomia interna sem visão', 50, 20, '40.04.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrotomia interna sob visão', 90, 80, '40.04.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção endoscópica de estenose da uretra', 90, 100, '40.04.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção endoscópica de tumor uretral', 90, 100, '40.04.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esfincterotomia endoscópica', 60, 100, '40.04.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão-ressecção endoscópica de valvas uretrais', 90, 100, '40.04.00.41');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Colocação endoscópica de prótese uretral expansível reepitelizável (exclui o custo da prótese)', 100, 60,
   '40.04.00.42');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corte do freio do pénis', 20, 0, '41.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão para redução da parafimose', 20, 0, '41.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Postectomia (circuncisão)', 40, 0, '41.00.00.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia de angulação e mal-rotação peniana e da doença de Peyronie com operação de Nesbit', 100, 0,
   '41.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com excisão da placa e colocação de retalho', 130, 0, '41.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com excisão da placa e colocação de prótese', 160, 0, '41.00.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia de priapismo com anastomose safeno-cavernosa unilateral', 150, 0, '41.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com anastomose safeno-cavernosa bilateral', 200, 0, '41.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com anastomose caverno esponjosa', 150, 0, '41.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com fistula caverno-esponjosa', 100, 0, '41.00.00.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Punção - esvaziamento - lavagem dos corpos cavernosos para tratamento do priapismo', 30, 0, '41.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação peniana parcial', 75, 0, '41.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação peniana total', 120, 0, '41.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Emasculação', 160, 0, '41.00.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Amputação peniana com linfadenectomia inguinal unilateral', 160, 0, '41.00.00.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Amputação peniana com linfadenectomia inguinal bilateral', 250, 0, '41.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com linfadectomia inguino-pélvica bilateral', 320, 0, '41.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução do pénis (tempo principal)', 150, 0, '41.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem outros tempos (cada)', 65, 0, '41.00.00.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Laqueação de veias penianas na cirurgia da disfunção eréctil', 100, 0, '41.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revascularização peniana', 150, 0, '41.00.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com microcirurgia', 160, 300, '41.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese peniana rígida', 150, 0, '41.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese peniana semi-rígida', 150, 0, '41.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese peniana insuflável', 180, 0, '41.00.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação externa de raios laser', 25, 250, '41.00.00.26');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia do interesexo e transsexual masculino para feminino', 300, 0, '41.00.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem feminino para masculino, completa', 450, 0, '41.00.00.28');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exploração do conteúdo escrotal (celotomia exploradora)', 60, 0, '41.00.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem cirúrgica da bolsa escrotal', 25, 0, '41.00.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de fleimão urinoso', 80, 0, '41.00.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da pele e invólucros da bolsa escrotal', 50, 0, '41.00.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia de hidrocele', 75, 0, '41.00.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção de hidrocele com injecção de esclerosante', 25, 0, '41.00.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do hematocele', 75, 0, '41.00.00.35');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia do varicocele com laqueação alta da veia espermática', 75, 0, '41.00.00.36');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia do varicocele com laqueação-ressecção múltipla de veias varicosas', 90, 0, '41.00.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidorrafia por traumatismo', 100, 0, '41.00.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidopexia escrotal sem funiculolise', 80, 0, '41.00.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidectomia escrotal', 80, 0, '41.00.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidectomia sub-albugínea bilateral', 100, 0, '41.00.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidectomia intra-abdominal', 110, 0, '41.00.00.42');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidectomia inguinal simples', 120, 0, '41.00.00.43');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidectomia inguinal radical sem linfadenectomia', 150, 0, '41.00.00.44');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Idem com Linfadenectomia para-aórtico-cava e pélvica', 350, 0, '41.00.00.45');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Autotransplante testicular', 250, 0, '41.00.00.46');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese testicular unilateral', 75, 0, '41.00.00.47');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese testicular bilateral', 120, 0, '41.00.00.48');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia para deferento vesiculografia', 50, 0, '41.00.00.49');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia da obstrução espermática com anastomose epididimo-deferencial (epididimo-vasostomia)', 160, 0,
   '41.00.00.50');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Idem com anastomose deferento-deferencial (vaso-vasostomia)', 160, 0, '41.00.00.51');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com microcirurgia', 180, 300, '41.00.00.52');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Excisão de espermatocele ou quisto para testicular epididimário ou do cordão espermático', 75, 0,
   '41.00.00.53');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Epididimectomia', 75, 0, '41.00.00.54');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vasectomia, bilateral(ou laqueação dos deferentes)', 40, 0, '41.00.00.55');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Inguinotomia exploradora', 90, 0, '41.00.00.56');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Funicololise (e orquidopexia)', 120, 0, '41.00.00.57');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia das vesículas seminais', 150, 0, '41.00.00.58');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perineoplastia não obstétrica (operação isolada)', 80, 0, '42.00.00.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Colpoperineorrafia por rasgadura incompleta do perineo e vagina (não obstétrica)', 80, 0, '42.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Colpoperrineorrafia com sutura do recto, esfíncter anal, por rasgadura completa do perineo (não obstétrica)',
                                  120, 0, '42.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Marsupialiazação da glândula da Bartholin', 30, 0, '42.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão cirúrgica de condilomas', 40, 0, '42.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vulvectomia parcial', 60, 0, '42.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vulvectomia total', 130, 0, '42.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vulvectomia radical, com esvaziamento ganglionar', 250, 0, '42.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Clitoridectomia', 50, 0, '42.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Clitoridoplastia', 110, 0, '42.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de glândula de Bartholin', 40, 0, '42.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de caruncula uretral', 15, 0, '42.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de pequeno lábio', 30, 0, '42.01.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Himenotomia ou himenectomia parcial', 15, 0, '42.01.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção plástica do intróito', 60, 0, '42.01.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia laser da vulva', 30, 75, '42.01.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colpotomia com drenagem de abcesso', 25, 0, '42.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de hematocolpos', 15, 0, '42.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colpectomia para encerramento parcial da vagina', 80, 0, '42.02.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colpectomia para encerramento total da vagina (Colpocleisis)', 120, 0, '42.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de septo vaginal e plastia', 90, 0, '42.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor ou quisto', 30, 0, '42.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colporrafia por ferida não obstétrica', 75, 0, '42.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colporrafia anterior por cistocelo', 110, 0, '42.02.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colporrafia posterior por rectocelo', 60, 0, '42.02.00.09');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Vesicouretropexia anterior ou uretropexia, via abdominal (tipo Marshall-Marchetti)', 120, 0,
   '42.02.00.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Suspensão uretral (fáscia ou sintético) por incontinência urinária ao esforço (tipo Stockel)', 150, 0,
   '42.02.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Plastia do esfíncter uretral (tipo plicatura uretral de Kelli)', 80, 0, '42.02.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção de enterocelo, via abdominal (operação isolada)', 110, 0, '42.02.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colpopexia por abordagem abdominal', 110, 0, '42.02.00.14');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Intervenção cirúrgica para neovagina, em tempo único, simples com ou sem enxerto cutâneo', 150, 0,
   '42.02.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Intervenção cirúrgica para neovagina, em tempos múltiplos ou com plastia complexa (retalhos loco-regionais)',
                                  250, 0, '42.02.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de fístula recto-vaginal, via vaginal', 120, 0, '42.02.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de fístula vesico-vaginal, via vaginal', 200, 0, '42.02.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, via transvesical', 200, 0, '42.02.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia laser da vagina', 30, 75, '42.02.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia Laser CO2 - Vaporização', 30, 75, '42.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocoagulação ou criocoagulação', 10, 0, '42.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conização', 60, 0, '42.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cervicectomia (operação isolada)', 75, 0, '42.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese do colo restante', 140, 0, '42.03.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traquelorrafia', 75, 0, '42.03.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polipectomia cervical', 10, 0, '42.03.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conização laser CO2', 60, 75, '42.03.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conização com ansa diatérmica', 40, 50, '42.03.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Curetagem por aspiração (tipo Vabra)', 30, 0, '42.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação e curetagem', 30, 0, '42.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Miomectomia por via abdominal ou vaginal', 110, 0, '42.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerectomia total, com anexectomia via abdominal', 180, 0, '42.04.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Histerectomia sub-total com anexectomia, via abdominal', 140, 0, '42.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerectomia vaginal', 140, 0, '42.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerectomia vaginal com correcção de enterocelo', 240, 0, '42.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerectomia vaginal radical (tipo Schauta)', 300, 0, '42.04.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Histerectomia vaginal com colporrafia anterior e/ou posterior', 180, 0, '42.04.00.09');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Histerectomia radical com linfadenectomia pélvica bilateral (tipo Wertheim-Meigs)', 300, 0, '42.04.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exenteração pélvica', 450, 0, '42.04.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerotomia abdominal', 100, 0, '42.04.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histeropexia', 120, 0, '42.04.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ligamentopexia', 120, 0, '42.04.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Histeroplastia por anomalia uterina (tipo Stassman)', 150, 0, '42.04.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de rotura uterina', 110, 0, '42.04.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Intervenção cirúrgica por inversão uterina (não obstétrica)', 110, 0, '42.04.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oclusão de fistula vesico-uterina', 130, 0, '42.04.00.18');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Laparotomia exploradora com biópsias para estadiamento por neoplasia ginecológica', 120, 0, '42.04.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Secção de sinéquias uterinas - via vaginal', 100, 0, '42.04.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de septo por via vaginal', 100, 0, '42.04.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerectomia total com conservação de anexos', 180, 0, '42.04.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Microcirurgia tubar', 200, 0, '42.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso tubo-ovárico', 110, 0, '42.05.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Secção ou laqueação da trompa, abdominal uni ou bilateral', 50, 0, '42.05.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Salpingectomia, uni ou bilateral (operação isolada)', 110, 0, '42.05.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anexectomia, uni ou bilateral', 110, 0, '42.05.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Salpingoplastia, uni ou bilateral', 180, 0, '42.05.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da gravidez ectópica', 110, 0, '42.05.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lise de aderências pélvicas', 110, 0, '42.05.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção em cunha, uni ou bilateral', 100, 0, '42.06.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia do ovário, uni ou bilateral', 110, 0, '42.06.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ovariectomia, uni ou bilateral', 110, 0, '42.06.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ovariectomia, uni ou bilateral com omentectomia', 140, 0, '42.06.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Citoredução do carcinoma do ovário em estadios superiores ou igual ao IIB', 300, 0, '42.06.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coagulação de ovários', 100, 0, '42.06.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Simpaticectomia pélvica', 150, 0, '42.07.00.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Reparação de episiotomia e/ou rasgadura incompleta do períneo e/ou rasgadura da vagina, simples', 25, 0,
   '43.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extensa', 30, 0, '43.00.00.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Colpoperineorrafia e reparação do esfíncter anal por rasgadura completa do perineo consecutiva a parto',
   80, 0, '43.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerorrafia por rotura do útero (obstétrica)', 120, 0, '43.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação por inversão uterina de causa obstétrica', 110, 0, '43.00.00.05');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Parto normal (com ou sem episiotomia) compreendida anestesia feita pelo próprio médico', 65, 0,
   '43.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parto gemelar normal por cada gémeo', 65, 0, '43.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Parto distócico, compreendidas todas as intervenções, tais como: fórceps, ventosa, versão grande,  extracção pélvica, dequitadura artificial, episeorrafia, desencadeamento médico ou instrumental do trabalho',
                                  80, 0, '43.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fetotomia (embriotomia)', 100, 0, '43.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dequitadura manual', 25, 0, '43.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traquelorrafia', 50, 0, '43.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cesariana', 130, 0, '43.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cesariana com histerectomia, sub-total', 200, 0, '43.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cesariana com histerectomia, total', 220, 0, '43.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lobectomia subtotal da tiroide', 120, 0, '44.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lobectomia total da tiroide', 160, 0, '44.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiroidectomia subtotal', 200, 0, '44.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiroidectomia total', 250, 0, '44.00.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tiroidectomia total ou sub-total com esvaziamento cervical conservador', 300, 0, '44.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com esvaziamento cervical radical', 350, 0, '44.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiroidectomia subesternal com esternotomia', 300, 0, '44.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Paratiroidectomia e/ou exploração da paratiroideia', 225, 0, '44.00.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Paratiroidectomia com exploração mediastínica por abordagem torácica', 300, 0, '44.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Timectomia', 370, 0, '44.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Adrenalectomia unilateral', 220, 0, '44.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumor do corpo carotideo', 250, 0, '44.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de quisto do canal tireoglosso', 120, 0, '44.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de quisto ou adenoma da tiroideia', 120, 0, '44.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trepanação simples', 100, 0, '45.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Craniotomia por hematoma epidural', 200, 0, '45.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Craniotomia por hematoma subdural', 200, 0, '45.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esquirolectomia simples', 120, 0, '45.00.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Esquirolectomia com reparação dural e tratamento encefálico', 220, 0, '45.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lobectomia', 250, 0, '45.00.00.06');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Craniectomia ou craniotomia para remoção de corpo estranho no encéfalo (bala, etc)', 250, 0,
   '45.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação de fístula de LCR', 180, 0, '45.01.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reparação de fistula de L.C.R. por via transfenoidal', 300, 0, '45.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fístula de L.C.R. da fossa posterior', 300, 0, '45.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cranioplastia com osso', 220, 0, '45.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cranioplastia com material sintético', 250, 0, '45.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de craniossinostose de uma sutura', 250, 0, '45.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de craniossinostose complexa', 300, 0, '45.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de encefalocelo', 250, 0, '45.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de disrrafismo espinal', 350, 0, '45.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção cirúrgica de lesões de osteite craniana', 70, 0, '45.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trepanação para drenagem de abcesso cerebral', 150, 0, '45.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Craniotomia para tratamento de abcesso cerebral', 250, 0, '45.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Craniotomia para abcesso subdural ou epidural', 250, 0, '45.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abcesso intra-raquidiano via posterior', 250, 0, '45.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abcesso intra-raquidiano via anterior', 300, 0, '45.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abcesso intra-raquidiano cervical via anterior', 300, 0, '45.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abcesso intramedular', 350, 0, '45.02.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Remoção de tumores atingindo a calote sem cranioplastia', 100, 0, '45.03.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Remoção de tumores atingindo a calote com cranioplastia', 200, 0, '45.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Buracos de trepano, com drenagem ventricular', 70, 0, '45.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abordagem transfenoidal', 350, 0, '45.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores da órbitra - abordagem transcraniana', 320, 0, '45.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glioma supratentorial', 300, 0, '45.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glioma infratentorial', 350, 0, '45.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumor intraventricular', 400, 0, '45.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumor selar, supra-selar e para-selar', 400, 0, '45.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores da região pineal', 400, 0, '45.04.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores do ânglo pronto-cerebeloso', 400, 0, '45.04.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gliomas do tronco cerebral', 400, 0, '45.04.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores do IV ventrículo', 400, 0, '45.04.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores da base do crânio', 450, 0, '45.04.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia tumoral estereotáxica', 250, 0, '45.04.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras lesões expansivas intracranianas', 350, 0, '45.04.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hematomas intracerebrais supratentoriais', 250, 0, '45.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hematomas intracerebrais infratentoriais', 300, 0, '45.05.00.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Laqueação da carótida interna intracraniana para tratamento de aneurismas e fistulas carótido-cavernosas',
   250, 0, '45.05.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aneurismas intracranianos da circulação anterior', 400, 0, '45.05.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aneurismas intracranianos da circulação posterior', 450, 0, '45.05.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'MAV supratentorial', 400, 0, '45.05.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'MAV infratentorial', 450, 0, '45.05.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Processo de revascularização', 400, 0, '45.05.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores da coluna vertebral', 300, 0, '45.06.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores da coluna vertebral com estabilização', 400, 0, '45.06.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores intradurais extramedulares', 300, 0, '45.06.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores intradurais intramedulares', 400, 0, '45.06.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'MAV espinal', 450, 0, '45.06.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Malformações da charneira, abordagem anterior', 400, 0, '45.06.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Malformações da charneira, abordagem posterior', 400, 0, '45.06.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de siringomilia', 300, 0, '45.06.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras malformações congénitas', 300, 0, '45.06.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Torkildsen', 250, 0, '45.07.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Derivações ventrículo-atriais', 220, 0, '45.07.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Derivações ventrículo-peritoneais', 170, 0, '45.07.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Derivações cisto-peritoneais', 200, 0, '45.07.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Derivações lombo-peritoneais', 200, 0, '45.07.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ventrículostomia endoscópica', 300, 0, '45.07.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revisões das derivações', 140, 0, '45.07.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Leucotomia estereotáxica', 200, 0, '45.08.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemisferectomia', 380, 0, '45.08.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intervenções estereotáxicas talamicas', 300, 0, '45.08.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cordotomias', 220, 0, '45.08.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da epilepsia com registo operatório', 400, 0, '45.08.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calosotomia', 300, 0, '45.08.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Descompressão nicrovascular de pares cranianos', 300, 0, '45.08.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento percutâneo da nevralgia do trigémio', 200, 0, '45.08.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lesão da DREZ', 300, 0, '45.08.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rizotomia', 200, 0, '45.08.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Comissurotomia', 300, 0, '45.08.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras cirurgias percutâneas da dor', 200, 0, '45.08.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurólises', 90, 0, '45.09.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposições', 110, 0, '45.09.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurorrafias com microcirurgia', 150, 0, '45.09.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do plexo braquial', 350, 0, '45.09.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sindroma do túnel cárpico ou do canal de Guyon', 120, 0, '45.09.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da meralgia parestésica', 120, 0, '45.09.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de neuroma traumático dos nervos periféricos', 180, 0, '45.09.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de neuroma traumático dos nervos periféricos com enxerto', 300, 0, '45.09.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de tumores de nervos periféricos sem reparação', 200, 0, '45.09.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de tumores de nervos periféricos com reparação', 300, 0, '45.09.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de neuroma post-traumático', 120, 0, '45.09.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de neuroma post-traumático, com microcirurgia', 160, 0, '45.09.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de tumores dos nervos periféricos (não incluindo reparação)', 120, 0, '45.09.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Evisceração do globo ocular sem implante', 80, 0, '46.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Evisceração do globo ocular com implante', 100, 0, '46.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enucleação do globo ocular sem implante', 80, 0, '46.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enucleação do globo ocular com implante', 120, 0, '46.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exenteração da órbita', 200, 0, '46.00.00.05');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Exenteração da órbita com remoção de partes ósseas ou com transplante muscular', 220, 0, '46.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de implante ocular', 50, 0, '46.00.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Queratectomia lamelar, parcial, excepto pterígio (ex. quisto dermóide)', 70, 0, '46.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia da córnea (ex: leucoplasia)', 20, 0, '46.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão ou transposição de pterígio, sem enxerto', 60, 0, '46.01.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão ou transposição de pterígio recidivado com enxerto', 100, 0, '46.01.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão ou transposição de pterígio recidivado com queratoplastia parcial', 240, 0, '46.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Raspagem da córnea para diagnóstico', 6, 0, '46.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção do epitélio corneano', 8, 0, '46.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação de agentes químicos e/ou físicos', 10, 0, '46.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tatuagem da córnea, mecânica ou química', 40, 0, '46.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho superficial', 8, 0, '46.01.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de ferida da córnea', 120, 0, '46.01.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Queratoplastia lamelar (inclui preparação do material de enxerto)', 240, 0, '46.01.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Queratoplastia penetrante (inclui preparação do material de enxerto)', 240, 0, '46.01.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Queratoplastia lamelar na afaquia (inclui preparação do material de enxerto)', 240, 0, '46.01.00.14');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Queratoplastia penetrante e queratoprótese (inclui preparação do material de enxerto)', 280, 0,
   '46.01.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratomia refractiva para correcção óptica', 90, 0, '46.01.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratomileusis', 250, 100, '46.01.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Epiqueratoplastia', 200, 100, '46.01.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratofaquia', 250, 100, '46.01.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotoqueratectomia refractiva ou terapêutica', 150, 120, '46.01.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Termoqueratoplastia', 40, 0, '46.01.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Termoqueratoplastia refractiva', 145, 120, '46.01.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Topografia Corneana', 25, 15, '46.01.00.23');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Paracentese da câmara anterior para remoção ou aspiração de humor aquoso, hipópion ou hifema', 50, 0,
   '46.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Paracentese da câmara anterior para remoção de humor vítreo e/ou libertação de sinéquias e/ou discisão da hialoideia anterior, com ou sem injecção de ar',
                                  90, 0, '46.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Goniotomia com ou sem goniopunção', 145, 0, '46.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Goniopunção sem goniotomia', 55, 0, '46.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trabeculotomia ab externo', 140, 0, '46.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trabeculoplastia Laser', 80, 70, '46.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho magnético', 60, 0, '46.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho não magnético', 90, 0, '46.02.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Introdução de lente intra-ocular para correcção da ametropia em olho fáquico', 200, 0, '46.02.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Lise de sinéquias do segmento anterior, incluindo goniosinéquias, por incisão com ou sem injecção de ar/líquido (técnica isolada)',
                                  70, 0, '46.02.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Lise de sinéquias anteriores ou de sinéquias posteriores ou aderências corneovítreas com ou sem injecção de ar/líquido',
                                  55, 0, '46.02.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de invasão epitelial, câmara anterior', 160, 0, '46.02.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de material de implante, segmento anterior', 100, 0, '46.02.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de coágulo sanguíneo, segmento anterior', 70, 0, '46.02.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Injecção de ar/líquido ou medicamento na câmara anterior', 20, 0, '46.02.00.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Operação fistulizante para glaucoma com iridectomia', 140, 0, '46.03.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Trabeculectomia ab externo (fistulizante protegida)', 180, 0, '46.03.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fistulização da esclerótica no glaucoma, iridencleisis', 130, 0, '46.03.00.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Fistulização da esclerótica no glaucoma, trabeculectomia ab externo com encravamento escleral', 190, 0,
   '46.03.00.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Fistulização esclerótica no glaucoma com colocação de tubo de Molteno ou similar', 200, 0, '46.03.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esclerotomia Holmium (cada sessão)', 160, 120, '46.03.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução da esclerótica por estafiloma sem enxerto', 120, 0, '46.03.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução da esclerótica por estafiloma com enxerto', 200, 0, '46.03.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho superficial', 8, 0, '46.03.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de ferida sem lesão da úvea', 100, 0, '46.03.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura de ferida com reposição ou ressecção da úvea', 150, 0, '46.03.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Iridotomia simples/transfixiva', 105, 0, '46.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Iridectomia com ciclectomia', 150, 0, '46.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Iridectomia periférica ou em sector no glaucoma', 120, 0, '46.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Iridectomia óptica', 120, 0, '46.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de iridodiálise', 150, 0, '46.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclodiatermia', 100, 0, '46.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclocrioterapia', 100, 0, '46.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclodiálise', 120, 0, '46.04.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Laserterapia (coreoplastia, gonioplastia e iridotomia (1 ou mais sessões))', 65, 70, '46.04.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fotocoagulação dos processos ciliares (1 ou mais sessões)', 150, 120, '46.04.00.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Destruição de lesões quísticas ou outras da Íris e/ou do corpo ciliar por meios não cruentos', 150, 70,
   '46.04.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Discisão do cristalino', 90, 0, '46.05.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Discisão de catarata secundária e/ou membrana hialoideia anterior', 90, 0, '46.05.00.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Remoção de catarata secundária com ou sem iridectomia (iridocapsulectomia ou iridocapsulotomia)', 180, 0,
   '46.05.00.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Aspiração de material lenticular na sequência ou não de facofragmentação mecânica', 180, 0, '46.05.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Facoemulsificação do cristalino com aspiração de material lenticular', 200, 50, '46.05.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Facoemulsificação do cristalino com implantação de lente intraocular', 280, 50, '46.05.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção extracapsular programada', 200, 0, '46.05.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção intracapsular de catarata, com ou sem enzimas', 180, 0, '46.05.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de cristalino luxado', 200, 0, '46.05.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção intracapsular ou extracapsular na presença de ampola de filtração', 200, 0, '46.05.00.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Aplicação de qualquer lente intraocular simultaneamente à extracção de catarata', 250, 0, '46.05.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Implantação secundária de lente intra-ocular', 190, 0, '46.05.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de lente intraocular de câmara posterior', 145, 0, '46.05.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lentes intraoculares de suspensão escleral', 240, 0, '46.05.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Capsulotomia Yag (por sessão)', 65, 80, '46.05.00.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Vitrectomia parcial da câmara anterior, a céu aberto', 100, 0, '46.06.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Vitrectomia sub-total, via anterior, utilizando vitrectomo mecânico', 180, 0, '46.06.00.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Aspiração de vítreo ou de liquido sub-retiniano ou coroideu (esclerotomia posterior)', 120, 0,
   '46.06.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Injecção de substituto de vítreo, via plana (pneumopexia)', 80, 0, '46.06.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Discisão de bandas de vítreo sem remoção, via pars plana', 150, 0, '46.06.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Liga de bandas de vítreo, adesões da interface do vítreo, bainhas, membranas ou opacidades por cirurgia laser',
                                  85, 50, '46.06.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vitrectomia mecânica, via pars plana', 250, 50, '46.06.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho magnético', 180, 0, '46.06.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho, com vitrectomia', 250, 50, '46.06.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Vitrectomia via pars plana associada à extracção do cristalino', 250, 50, '46.06.00.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Vitrectomia via pars plana associada à extracção de cristalino com introdução de lente intraocular', 360,
   50, '46.06.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Vitrectomia mecânica complicada via pars plana, com tamponamento interno com ou sem extracção de corpo estranho intraocular, com ou sem cirurgia de cristalino',
                                  360, 50, '46.06.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de substituto de vítreo', 95, 0, '46.06.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Crioterapia ou diatermia com ou sem drenagem de líquido subretiniano', 130, 0, '46.07.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Depressão escleral localizada ou circular, com ou sem implante', 240, 0, '46.07.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Qualquer técnica anterior associada à vitrectomia', 280, 50, '46.07.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia de descolamento de retina com vitrectomia associada a tamponamento', 320, 50, '46.07.00.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia de descolamento de retina com vitrectomia a céu aberto e tamponamento interno', 360, 50,
   '46.07.00.05');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia de descolamento de retina com vitrectomia, tamponamento interno e extracção de cristalino', 360,
   50, '46.07.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Cirurgia de descolamento de retina com vitrectomia e segmentação, delaminação e corte de membranas de vítreo ou subretinianas, neovasos com ou sem endolaser, com ou sem cirurgia do cristalino',
                                  400, 50, '46.07.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reoperação de descolamento de retina sem vitrectomia', 200, 0, '46.07.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reoperação de descolamento de retina com vitrectomia', 320, 50, '46.07.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Remoção de material implantado no segmento posterior', 50, 0, '46.07.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Implante e remoção de fonte de radiações', 160, 0, '46.07.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioterapia ou diatermia (por sessão)', 95, 0, '46.07.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotocoagulação Xenon', 80, 40, '46.07.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laser Argon azul-verde', 80, 70, '46.07.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laser monocromático', 80, 90, '46.07.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laser Yag', 80, 80, '46.07.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Esclerocoroidotomia para remoção de tumor com ou sem vitrectomia', 360, 50, '46.07.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia de músculo oculo-motor', 40, 0, '46.08.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura de músculos oculomotores e tendões e/ou a cápsula de Tenon', 60, 0, '46.08.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enfraquecimento/reforço de um músculo', 110, 0, '46.08.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enfraquecimento/reforço de dois músculos', 130, 0, '46.08.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enfraquecimento/reforço de três músculos', 145, 0, '46.08.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enfraquecimento/reforço de quatro músculos', 160, 0, '46.08.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Miopexia retroequatorial de um músculo', 145, 0, '46.08.01.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Miopexia retroequatorial de dois músculos', 175, 0, '46.08.01.06');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Miopexia retroequatorial de um músculo associado a enfraquecimento/reforço de dois músculos', 190, 0,
   '46.08.01.07');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Miopexia retroequatorial de um músculo associada a enfraquecimento/reforço de três músculos', 210, 0,
   '46.08.01.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Miopexia retroequatorial de dois músculos associada a enfraquecimento/reforço de um músculo', 210, 0,
   '46.08.01.09');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Miopexia retroequatorial de dois músculos associada a enfraquecimento/reforço de dois músculos', 225, 0,
   '46.08.01.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia ajustável sobre um músculo (Incluí o ajuste a efectuar posteriormente)', 165, 0, '46.08.01.11');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia ajustável sobre dois músculos (incluí o ajuste a efectuar posterirmente)', 190, 0, '46.08.01.12');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Cirurgia ajustável de um músculo associada a enfraquecimento/reforço/miopexia de um músculo (incluí ajuste a efectuar posteriormente)',
                                  200, 0, '46.08.01.13');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Cirurgia ajustável de um músculo associada a enfraquecimento/reforço/miopexia de dois músculos (incluí ajuste a efectuar posteriormente)',
                                  240, 0, '46.08.01.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Transposição muscular de um músculo no estrabismo paralítico', 120, 0, '46.08.01.15');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Transposição muscular de um músculo no estrabismo paralítico associada a enfraquecimento/reforço/miopexia de um músculo)',
                                  145, 0, '46.08.01.16');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Transposição muscular de um músculo no estrabismo paralítico associada a enfraquecimento/reforço/miopexia de dois músculos)',
                                  175, 0, '46.08.01.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Transposição múscular de dois músculos no estrabismo paralítico', 160, 0, '46.08.01.18');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Transposição muscular de dois músculos no estrabismo paralítico, associada a enfraquecimento/reforço de um músculo',
                                  175, 0, '46.08.01.19');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Transposição muscular de dois músculos no estrabismo paralítico, associada a enfraquecimento/reforço de dois músculos',
                                  225, 0, '46.08.01.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção de toxina botulínica (cada sessão)', 65, 0, '46.08.01.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exploradora com ou sem biópsia', 100, 0, '46.09.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de tumor', 170, 0, '46.09.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho', 200, 0, '46.09.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia por aspiração transconjuntival', 20, 0, '46.09.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de tumor', 250, 0, '46.09.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho', 270, 0, '46.09.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem ou descompressão', 200, 0, '46.09.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exploradora com ou sem biópsia', 200, 0, '46.09.01.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Extracção total ou parcial de tumor ou extracção de corpo estranho-participação de oftalmologista', 100, 0,
   '46.09.02.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Injecção retrobulbar de álcool, ar, contraste ou outros agentes de terapêutica e de diagnóstico', 9, 0,
   '46.09.03.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção terapêutica na cápsula de Tenon', 9, 0, '46.09.03.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Inserção de implante orbitário exterior ao cone muscular (ex: reconstituição de parede orbitária) colaboração de oftalmologista com neurocirurgião e/ou otorrinolaringologista e/ou cirurgião plástico',
                                  100, 0, '46.09.03.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Remoção ou revisão de implante da órbita, exterior ao cone muscular', 80, 0, '46.09.03.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso', 15, 0, '46.10.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de chalázio ou de quisto palpebral único', 30, 0, '46.10.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção de chalázio ou de quisto palpebral, múltiplos', 35, 0, '46.10.00.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Extracção de chalázio ou de quisto palpebral, com anestesia geral e/ou hospitalização', 45, 0,
   '46.10.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsias das pálpebras', 10, 0, '46.10.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocoagulação de cílios', 10, 0, '46.10.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de triquíase e distriquiase', 80, 0, '46.10.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de lesão palpebral sem plastia (excepto chalázio)', 35, 0, '46.10.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Destruição física ou química de lesão do bordo palpebral', 15, 0, '46.10.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tarsorrafia', 40, 0, '46.10.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abertura da Tarsorrafia', 10, 0, '46.10.00.11');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Correcção de ptose: técnica do músculo frontal com sutura (ex:Op. de Friedenwald)', 100, 0, '46.10.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de ptose, outras técnicas', 130, 0, '46.10.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de retracção palpebral', 100, 0, '46.10.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Blefaroplastia com excisão de cunha tarsal (ectrópico e entrópio)', 80, 0, '46.10.00.15');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Blefaroplastia extensa (ectrópio e entrópio) (ex: operações tipo Kuhnt Szymanowski e Wheeler-Fox)', 150, 0,
   '46.10.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Blefaroplastia extensa para correcção da Blefarofimose e do epicantus', 150, 0, '46.10.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura de ferida incisa recente envolvendo as estruturas superficiais e bordo', 40, 0, '46.10.00.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura de ferida incisa recente envolvendo toda a espessura da pálpebra', 80, 0, '46.10.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho', 25, 0, '46.10.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cantoplastia (reconstrução do canto)', 40, 0, '46.10.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Reconstrução e sutura de ferida lacero-contusa, envolvendo todas as estruturas da pálpebra até 1/3 da sua extensão, podendo incluir enxerto de pele, simples ou pediculado',
                                  95, 0, '46.10.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, envolvendo mais de 1/3 do bordo', 120, 0, '46.10.00.23');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Reconstrução de toda a espessura palpebral por retalho tarso-conjuntival da palpebra oposta', 140, 0,
   '46.10.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão para drenagem de quisto', 10, 0, '46.11.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia', 10, 0, '46.11.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão ou destruição de lesão da conjuntiva', 20, 0, '46.11.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção sub-conjuntival', 9, 0, '46.11.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Conjuntivoplastia, por enxerto conjuntival ou por deslizamento', 70, 0, '46.11.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conjuntivoplastia com enxerto de mucosa', 100, 0, '46.11.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução de fundo de saco com mucosa', 150, 0, '46.11.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia de simblefaro, sem enxerto', 60, 0, '46.11.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia do simblefaro, com enxerto de mucosa labial', 160, 0, '46.11.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho superficial', 6, 0, '46.11.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de ferida da conjuntiva', 15, 0, '46.11.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia da glândula lacrimal', 30, 0, '46.12.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Incisão do saco lacrimal para drenagem(dacriocistomia)', 15, 0, '46.12.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese do saco lacrimal (dacriocistectotomia)', 100, 0, '46.12.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Remoção de corpo estranho das vias lacrimais (dacriolito)', 40, 0, '46.12.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução dos canaliculos', 160, 0, '46.12.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção dos pontos lacrimais evertidos', 80, 0, '46.12.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Dacriacistorinostomia (fistulização do saco lacrimal para a cavidade nasal)', 160, 0, '46.12.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conjuntivorinostomia com ou sem inserção de tubo', 160, 0, '46.12.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Obturação permanente ou temporária das vias lacrimais', 20, 0, '46.12.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de fístula lacrimal', 40, 0, '46.12.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sondagem do canal lacrimo-nasal, com ou sem irrigação', 10, 0, '46.12.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, exigindo anestesia geral', 30, 0, '46.12.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Injecção do meio de contraste para da criocistografia', 30, 0, '46.12.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Entubação prolongada das vias lacrimais', 80, 0, '46.12.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho', 7, 0, '47.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho c/anestesia geral', 20, 0, '47.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, por via retro-auricular', 80, 0, '47.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso, otohematoma', 15, 0, '47.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polipectomia do ouvido', 20, 0, '47.00.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Miringotomia com anestesia geral ou local unilateral (sob visão microscópica)', 30, 0, '47.00.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Miringotomia com anestesia geral ou local bilateral (sob visão microscópica)', 45, 0, '47.00.00.07');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Miringotomia com aplicação de tubo de ventilação unilateral (sob visão microscópica)', 50, 0,
   '47.00.00.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Miringotomia com aplicação de tubo de ventilação bilateral (sob visão microscópica)', 80, 0,
   '47.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de exostose do canal auditivo externo', 110, 0, '47.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastoidectomia', 125, 0, '47.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastoidectomia radical', 200, 0, '47.00.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Timpanomastoidectomia com conservação da parede do C.A.E. com timpanoplastia', 300, 0, '47.00.00.13');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Timpanomastoidectomia sem conservação da parede do C.A.E. (com timpanoplastia)', 350, 0, '47.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Timpanoplastia', 200, 0, '47.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Timpanotomia exploradora', 110, 0, '47.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estapedectomia ou estapedotomia', 200, 0, '47.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Labirintectomia transaural', 200, 0, '47.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Descompressão do saco endolinfático', 250, 0, '47.00.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurectomia vestibular (fossa média)', 300, 0, '47.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Descompressão de 2a. e 3a. porções do nervo facial', 300, 0, '47.00.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Descompressão da 1a. porção (fossa média)', 280, 0, '47.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto facial (2a. e 3a. porções)', 250, 0, '47.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anastomose hipoglosso-facial', 200, 0, '47.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto cruzado facio-facial', 250, 0, '47.00.00.25');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exérese neurinoma do acústico (via translabiríntica)', 300, 0, '47.00.00.26');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção do pavilhão auricular sem reconstrução e sem esvaziamento ganglionar', 80, 0, '47.00.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com esvaziamento ganglionar', 200, 0, '47.00.00.28');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução auricular por agenesia ou trauma (tempo principal)', 120, 0, '47.00.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, tempos complementares (cada)', 60, 0, '47.00.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Otoplastia unilateral', 80, 0, '47.00.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Otoplastia bilateral', 120, 0, '47.00.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Petrosectomia com conservação do nervo facial', 360, 0, '47.00.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, sem conservação do nervo facial', 320, 0, '47.00.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor glómico timpânico', 220, 0, '47.00.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor jugular localizado', 280, 0, '47.00.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor jugular com invasão intracraniana', 370, 0, '47.00.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor na base do crânio', 330, 0, '47.00.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Implante coclear', 300, 0, '47.00.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Implante osteointegrado', 200, 0, '47.00.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução da cavidade de esvaziamento', 160, 0, '47.00.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução do C.A.E. por agenesia', 280, 0, '47.00.00.42');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pele', 15, 8, '48.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mama', 20, 0, '48.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tecidos Moles', 20, 0, '48.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Músculo', 20, 0, '48.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nervo', 20, 0, '48.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pénis', 15, 0, '48.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testículo', 30, 0, '48.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vulva', 15, 0, '48.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vagina', 20, 0, '48.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osso', 50, 0, '48.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gânglio superficial', 30, 0, '48.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gânglio profundo', 40, 0, '48.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rectal', 30, 0, '48.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiroideia', 30, 0, '48.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia superior', 300, 0, '50.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 900 K a 801 K', 255, 0, '50.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 800 K a 701 K', 225, 0, '50.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 700 K a 601 K', 195, 0, '50.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 600 K a 561 K', 175, 0, '50.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 560 K a 511 K', 160, 0, '50.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 510 K a 481 K', 150, 0, '50.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 480 K a 461 K', 140, 0, '50.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 460 K a 421 K', 130, 0, '50.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 420 K a 401 K', 120, 0, '50.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 400 K a 341 K', 110, 0, '50.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 340 K a 301 K', 95, 0, '50.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 300 K a 281 K', 87, 0, '50.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 280 K a 241 K', 78, 0, '50.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 240 K a 201 K', 66, 0, '50.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 200 K a 181 K', 57, 0, '50.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 180 K a 161 K', 51, 0, '50.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 160K a 141K', 45, 0, '50.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 140K a 121K', 39, 0, '50.00.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 120 K a 101 K', 33, 0, '50.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se cirurgia de 100 K a', 27, 0, '50.00.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Se for inferior a 81 K', 27, 0, '50.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Analgesia para trabalho de parto', 35, 0, '50.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'mais por hora', 20, 0, '50.01.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Analgesia, sedação e/ou anestesia para exames complementares', 35, 0, '50.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'mais por hora', 20, 0, '50.01.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Apoio de anestesista a actos cirúrgicos feitos sob,anestesia local', 20, 0, '50.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'mais por hora', 20, 0, '50.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia para cardioversão', 25, 0, '50.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia para convulsoterapia', 25, 0, '50.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio do gânglio estrelado-diag/terap.', 18, 0, '50.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio do gânglio estrelado-neurolítico', 25, 0, '50.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio do plexo celíaco-diag/terap', 30, 0, '50.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio do plexo celíaco-neurolítico', 55, 0, '50.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio do simpático lombar-diag/terap', 30, 0, '50.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio do simpático lombar-neurolítico', 25, 0, '50.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio extra-dural-diag/terap', 12, 0, '50.02.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio extra-dural-neurolítico', 25, 0, '50.02.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio sub-aracnoideu-diag/terap', 18, 0, '50.02.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio sub-aracnoideu-neurolitico', 25, 0, '50.02.01.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'V par – gânglio Gasser-diag/terap', 30, 0, '50.02.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'V par – gânglio Gasser-neurolítico', 45, 0, '50.02.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'De zona desencadeante', 15, 0, '50.02.03.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diag/terap', 15, 0, '50.02.03.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurolítico', 50, 0, '50.02.03.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anestesia regional intravenosa (com fins terapêuticos)', 25, 0, '50.02.04.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estimulação transcutânea', 10, 0, '50.02.04.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hipertemia', 80, 0, '50.02.04.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intratecal drenagem do L.C.R.', 25, 0, '50.02.04.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intratecal com narcóticos', 25, 0, '50.02.04.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intratecal com soro gelado', 50, 0, '50.02.04.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intratecal com soro hipertónico', 50, 0, '50.02.04.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intratecal neuroadenolise hipofisária', 150, 0, '50.02.04.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia local', 3, 0, '50.02.04.09');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Reanimação cardio-respiratória e hemodinâmica em casos de paragem, shock, etc. 1a. Hora', 35, 0,
   '50.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, assistência permanente adicional, cada hora', 15, 0, '50.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, 2o. Dia e seguintes', 20, 0, '50.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desobstrução das vias aéreas', 15, 0, '50.03.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Estabelecimento de ventilação assistida ou controlada com intubação nasal ou orotraqueal ou traqueotomia 1o dia',
                                  40, 0, '50.03.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, 2o. Dia e seguintes', 20, 0, '50.03.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abdómen simples – 1 incidência', 2, 10, '60.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abdómen simples – 2 incidências', 2, 16, '60.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cavum ou Rino-Faringe', 3, 4, '60.00.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colangiografia endovenosa (excluindo estudo tomográfico)', 8, 27, '60.00.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colangiografia endovenosa com perfusão (excluindo estudo tomográfico)', 8, 27, '60.00.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colecistografia – 2 incidências + compressão doseada + Prova de Boyden', 6, 17, '60.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dentes – ortopantomografia facial', 2, 22, '60.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dentes todos em dentição completa', 6, 17, '60.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Duodenografia hipotónica estudo complementar', 6, 15, '60.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esófago', 4, 20, '60.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estômago e Duodeno', 10, 27, '60.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estômago e Duodeno com duplo contraste', 12, 33, '60.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Faringe e Laringe', 3, 6, '60.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fígado Simples – 1 incidência', 2, 5, '60.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fígado Simples – 2 incidências', 2, 9, '60.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intestino Delgado (trânsito)', 10, 48, '60.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intestino grosso (clister opaco) com esvaziamento', 6, 33, '60.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Clister opaco duplo contraste', 10, 39, '60.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intestino grosso, por ingestão, trânsito intestinal', 6, 22, '60.00.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trânsito delgado + Trânsito cólon', 10, 66, '60.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Região ileo-cecal ou ceco-apendicular', 6, 20, '60.00.00.21');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Exame ileo-cecal ou ceco-apendicular quando associado aos trânsitos cólico ou delgado', 2, 10,
   '60.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pescoço, partes moles – 1 incidência', 2, 5, '60.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pescoço, partes moles – 2 incidências', 3, 9, '60.00.00.24');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Gastroduodenal com pesquisa de hérnia e exame cardio-tuberositário', 12, 36, '60.00.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tórax, pulmões e coração 1 incidência', 2, 10, '60.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tórax, pulmões e coração 2 incidências', 3, 16, '60.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tórax, pulmões e coração 3 incidências', 4, 22, '60.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tórax, pulmões e coração 4 incidências', 5, 28, '60.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bexiga simples – 1 incidência', 2, 5, '60.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistografia – 3 incidências para esvaziamento', 6, 17, '60.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistografia com duplo contraste', 4, 14, '60.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistografia com uretrografia retrógrada', 6, 17, '60.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rins simples – 1 incidência', 2, 10, '60.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rins simples–– 2 incidências', 3, 18, '60.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Urografia endovenosa', 6, 41, '60.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Urografia endovenosa minutada', 8, 63, '60.02.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Filme pós-miccional', 1, 5, '60.02.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Película de pé ou filme tardio ou incidência suplementar', 2, 7, '60.02.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Urografia endovenosa com perfusão (excluindo o estudo tomográfico)', 8, 46, '60.02.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Associação de cistogramas oblíquos eapós micção à urografia', 2, 12, '60.02.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Pielografia ascendente unilateral (escluindo cataterismo)', 6, 11, '60.02.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrografia retrógrada', 4, 11, '60.02.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anca – 1 incidência', 2, 6, '60.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anca – 2 incidências', 3, 10, '60.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antebraço – 2 incidências', 2, 8, '60.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apófises estiloideias – cada incidência e lado', 2, 6, '60.03.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Articulações têmporo-maxilares, boca aberta e fechada cada lado', 2, 12, '60.03.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bacia – 1 incidência', 2, 10, '60.03.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Braço – 2 incidências', 2, 8, '60.03.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Buracos ópticos – Bilateral', 2, 12, '60.03.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calcâneo – 2 incidências', 2, 8, '60.03.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Charneira occipito-atloideia 2 incidências', 2, 10, '60.03.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Clavícula – cada incidência', 2, 5, '60.03.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna cervical – 2 incidências', 2, 10, '60.03.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna cervical ou estudo funcional 4 incidências', 2, 20, '60.03.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Coluna cervico-dorsal, zona de transição – 2 incidências (frente e obliqua)', 2, 10, '60.03.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna coccígea – 2 incidências', 2, 10, '60.03.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna dorsal – 2 incidências', 4, 15, '60.03.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna lombar – 2 incidências', 4, 15, '60.03.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna charneira lombo sagrada 2 incidências', 2, 15, '60.03.00.18');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Coluna lombo-sagrada, em carga, com inclinações (estudo funcional) 4 incidências', 6, 30, '60.03.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna sagrada – 2 incidências', 2, 10, '60.03.00.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Coluna vertebral, em filme extra-longo (30X90) – cada incidência em carga', 4, 20, '60.03.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Costelas, cada hemitórax 2 incidências', 2, 15, '60.03.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cotovelo – 2 incidências', 2, 11, '60.03.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coxa ou fémur – 2 incidências', 3, 11, '60.03.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crânio – 2 incidências', 3, 11, '60.03.00.25');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Esqueleto – 1 incidência em película 35X43 – recém nascido', 3, 11, '60.03.00.26');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Esqueleto de adulto (1 incidência por sector mínimo de 9 películas)', 8, 80, '60.03.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esterno – 2 incidências', 2, 11, '60.03.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esterno-claviculares (articulações) 3 incidências', 3, 12, '60.03.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Face – 2 incidências', 3, 9, '60.03.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Joelho 2 incidências', 2, 10, '60.03.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mandíbula – cada incidência', 2, 4, '60.03.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mão – 2 incidências', 2, 8, '60.03.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastoideias ou rochedos cada incidência e lado', 2, 10, '60.03.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Maxilar superior – 2 incidências', 2, 8, '60.03.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ombro – 1 incidência', 2, 6, '60.03.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Omoplata – 1 incidência', 2, 6, '60.03.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Órbitas – cada incidência', 2, 8, '60.03.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ossos próprios do nariz cada incidência', 2, 6, '60.03.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pé – 2 incidências', 2, 8, '60.03.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perna – 2 incidências', 2, 14, '60.03.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punho – 2 incidências', 2, 6, '60.03.00.42');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punhos e mãos (idade) óssea 1 incidência', 5, 5, '60.03.00.43');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sacro-ilíacas (articulações) os dois lados – 1 incidência', 2, 8, '60.03.00.44');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sacro ilíacas (articulações) os dois lados face + 2 oblíquas', 4, 15, '60.03.00.45');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Seios perinasais – 2 incidências', 3, 11, '60.03.00.46');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Seios perinasais – 3 incidências', 4, 14, '60.03.00.47');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sela turca – incidência localizada perfil', 2, 4, '60.03.00.48');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tibio-tarsica – 2 incidências', 2, 8, '60.03.00.49');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artropneumografia do joelho, incluindo punção', 10, 36, '60.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncografia cada incidência (só radiologia)', 3, 10, '60.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cálculos salivares, filme simples 2 incidências', 3, 9, '60.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colangiografia per-operatória', 10, 17, '60.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colangiografia pós-operatória', 10, 17, '60.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colangiografia endoscópica cada incidência', 10, 17, '60.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colangiografia percutânea cada incidência', 13, 18, '60.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dacriocistografia', 14, 18, '60.04.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fistulografia', 8, 27, '60.04.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gravidez – 1 incidência', 2, 10, '60.04.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gravidez – 2 incidências', 3, 18, '60.04.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerosalpingografia', 10, 27, '60.04.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idade óssea fetal', 2, 10, '60.04.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intensificação de imagens', 0, 12, '60.04.00.14');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Localização e extracção de corpos estranhos sob controlo radioscópico (radiocirurgia) com intensificador',
   10, 15, '60.04.00.15');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Localizarão de corpos estranhos intra oculares por meio de 4 imagens em posições diferentes', 10, 17,
   '60.04.00.16');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Localização de corpos estranhos intra oculares pelo método de Comberg (lente de contacto)', 10, 15,
   '60.04.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Macrorradiografia – 1 incidência preço da região +', 0, 8, '60.04.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Membros inferiores – cada filme extra longo', 4, 20, '60.04.00.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Métrico dos membros inferiores por sectores articulados', 6, 15, '60.04.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Microrradiografia (película 10+10)', 0.5, 1.75, '60.04.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Radiografia estereoscópica – preço da região +', 0, 4, '60.04.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sialografia', 7, 16, '60.04.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Galactografia, cada lado', 10, 30, '60.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mamografia - 4 incidências, 2 de cada lado', 10, 30, '60.05.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quistografia gasosa, cada lado', 6, 18, '60.05.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mamografia com técnica de magnificação', 12, 45, '60.05.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Angiografia da carótida externa por punção percutânea', 10, 90, '60.06.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Angiografia da fossa posterior por cateterismo da umeral ou femoral', 10, 252, '60.06.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia dos 4 vasos', 15, 360, '60.06.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia percutânea da carótida', 10, 144, '60.06.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, por punção percutânea das 2 carótidas', 10, 198, '60.06.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Angiografia da fossa posterior por punção percutânea da vertebral', 10, 196, '60.06.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia medular', 15, 252, '60.06.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mielografia', 15, 210, '60.06.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiopneumografia', 15, 120, '60.07.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aortografia (por punção de Reinaldo dos Santos ou por técnica de Sel dinger', 15, 180, '60.07.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aortoarteriografia periférica', 15, 180, '60.07.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia periférica por punção directa', 15, 120, '60.07.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografias selectivas', 25, 120, '60.07.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografias selectivas com embolização', 25, 120, '60.07.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arteriografias selectivas com dilatações arteriais', 15, 162, '60.07.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cavografias ou flebografias', 10, 162, '60.07.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografias selectivas', 10, 120, '60.07.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esplenoportografia', 15, 180, '60.07.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfografias', 30, 162, '60.07.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fleborrafia orbitária por punção da veia frontal', 40, 120, '60.07.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tomografia, cada incidência ou lado mínimo 4 planos, filmes 18-24', 6, 14, '60.08.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cada plano mais', 0, 5, '60.08.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tomografia, cada incidência ou lado mínimo 4 planos, filmes 24-30', 6, 22, '60.08.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cada plano mais', 0, 8, '60.08.00.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tomografia, cada incidência ou lado, mínimo 4 planos, filmes 30x40, 35x35 ou medidas superiores', 6, 36,
   '60.08.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cada plano mais', 0, 11, '60.08.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteodensitometria monofotónica primeira avaliação', 5, 20, '60.09.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteodensitometria monofotónica estudos comparativos', 10, 30, '60.09.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteodensitometria bifotónica primeira avaliação', 20, 80, '60.09.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteodensitometria bifotónica estudos comparativos', 30, 120, '60.09.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Osteodensitometria por dupla energia com utilização de ampolas de rx (coluna, femur ou esqueleto isoladamente)',
                                  30, 150, '60.09.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiocardiografia de radionuclídeos (ARN)', 20, 49, '61.00.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Angiocardiografia de Radionuclídeos (ARN) com esforço ou stress', 20, 84, '61.00.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo de perfusão do miocárdio em repouso e esforço com SPECT/TEC', 40, 182, '61.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama cardíaco com àcidos gordos e SPECT/TEC', 30, 70, '61.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama de distribuição do 131I-MIBG cardíaco', 20, 28, '61.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama de distribuição do 123I-MIBG cardíaco', 20, 42, '61.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cisternoventrículo cintigrafia', 20, 84, '61.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama de perfusão cerebral com SPECT/TEC', 30, 126, '61.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de perda de líquido cefalora-quidiano', 20, 84, '61.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama cerebral com SPECT/TEC', 20, 84, '61.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia de tiroideia', 15, 14, '61.02.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo funcional da tiróide com 131I (Cint.+Curv. Fixação)', 20, 35, '61.02.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo da fixação do 131I na tiróide (curva fixação)', 10, 14, '61.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia corporal com 131 I', 20, 119, '61.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama corporal com 99mTc-DMSA', 20, 28, '61.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de distribuição do 131I-MIBG', 20, 98, '61.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudos de distrinbuição do 123I-MIBG', 20, 56, '61.02.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cintigrama hepatobiliar com estimulação vesicular e quantificação', 20, 84, '61.03.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cintigrama hepatobiliar com quantificação da função', 20, 56, '61.03.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cintigrama hepático com globulos vermelhos marcados', 20, 56, '61.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama hepatoesplénico', 20, 28, '61.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da permeabilidade de cateter', 20, 84, '61.03.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de refluxo biliogástrico', 20, 84, '61.03.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia esplénica', 15, 14, '61.03.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cintigrama esplénico com glubulos vermelhos fragilizados', 30, 21, '61.03.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo funcional das glândulas salivares (Cint. + Estimulação)', 20, 56, '61.03.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trânsito Esofágico', 20, 7, '61.03.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvaziamento gástrico', 20, 42, '61.03.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de refluxo gastroesofágico', 20, 42, '61.03.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama intestinal com leucócitos marcados', 50, 182, '61.03.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da permeabilidade intestinal (EDTA)', 20, 84, '61.03.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Determinação de perdas proteicas', 20, 28, '61.03.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de hemorragia digestiva', 20, 42, '61.03.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de divertículo de Meckel', 20, 42, '61.03.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova da absorção intestinal do Fe 59', 10, 28, '61.03.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Absorção de vitamina B12 (Teste Schilling)', 10, 28, '61.03.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Renograma', 20, 28, '61.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Renograma com prova diurética ou outra', 20, 49, '61.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama renal (DTPA; MAG3; HIPURAN)', 20, 42, '61.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama renal + renograma', 20, 42, '61.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia renal com DMSA', 20, 21, '61.04.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cintigrama Renal com quant. função (método gamagráfico)', 20, 49, '61.04.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, '"Quantificação da função com 51 Cr-EDTA (""in vitro"")"', 20, 49, '61.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama Renal + Cistografia indirecta', 20, 49, '61.04.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistocintigrafia directa', 30, 42, '61.04.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de perfusão de rim transplantado', 20, 42, '61.04.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinética do Ferro', 20, 42, '61.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de cinética das plaquetas', 30, 42, '61.05.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de distribuição de leucócitos marcados', 50, 168, '61.05.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama da medula óssea', 20, 84, '61.05.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Semi-vida dos eritrocitos', 20, 42, '61.05.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Volume plasmático', 20, 28, '61.05.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Determinação do volume sanguíneo total ou volémia', 20, 28, '61.05.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cintigrama do Esqueleto (corpo inteiro ou parcelares)', 20, 49, '61.06.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vista parcelar óssea suplementar', 15, 7, '61.06.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cintigrama ósseo com estudo de perfusão de uma região (3 fases)', 20, 56, '61.06.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Densitometria óssea bifotónica/DEXA (1 região)', 15, 14, '61.06.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Densitometria óssea bifotónica/DEXA (corpo inteiro)', 20, 35, '61.06.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Densitometria óssea bifotónica/DEXA com análise evolutiva (comparação)', 20, 14, '61.06.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Densitometria óssea bifotónica/DEXA + morfometria', 20, 42, '61.06.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama pulmonar de ventilação com 133Xe', 20, 63, '61.07.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama pulmonar de inalação (DTPA; Technegas)', 20, 56, '61.07.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia pulmonar de perfusão', 20, 28, '61.07.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da permeabilidade do epitélio pulmonar', 20, 84, '61.07.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de distribuição com Gálio 67 (1 região)', 15, 14, '61.08.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo de distribuição com Gálio 67 (corpo inteiro)', 20, 140, '61.08.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo de distribuição de leucócitos marcados (1 região)', 50, 105, '61.08.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo de distribuição de leucócitos marcados (corpo inteiro)', 50, 182, '61.08.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama das paratiróides com 201 TI/99m Tc', 20, 63, '61.09.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama ósseo com 201TI (1 região)', 15, 14, '61.09.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama corporal com 201TI', 20, 140, '61.09.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama corporal com 99m Tc-DMSA', 20, 28, '61.09.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia de órgão não especificado', 15, 28, '61.09.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dacriocintigrafia', 20, 28, '61.09.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo da fase vascular de um órgão ou região (complemento do estudo)', 15, 14, '61.09.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de distribuição do lodo-colesterol', 20, 84, '61.09.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfocintigrafia', 20, 42, '61.09.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tomografia de emissão computorizada (SPECT/TEC)', 30, 35, '61.09.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Venografia isotópica', 20, 28, '61.09.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cintigrama corporal com receptores da somatostatina', 30, 126, '61.09.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia da mama', 30, 35, '61.09.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama testicular', 20, 14, '61.09.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Permeabilidade tubárica', 20, 84, '61.09.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imunocintigrama com anticorpos monoclonais', 30, 140, '61.10.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 32P (ambulatória)', 9, 0, '61.10.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com Ytrium 1mCi (ambulatória)', 9, 0, '61.10.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com Ytrium cada mCi a mais', 9, 0, '61.10.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com estrôncio (Metastron)', 9, 0, '61.10.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131 IMIBG', 9, 0, '61.10.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131I até 10 mCi', 9, 0, '61.10.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131I até 15 mCi', 9, 0, '61.10.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131I até 50 mCi', 18, 0, '61.10.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131I até 100 mCi', 18, 0, '61.10.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131I de 100 a 150 mCi', 18, 0, '61.10.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131I além de 150 mCi', 18, 0, '61.10.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abdominal', 15, 35, '62.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ginecológica', 10, 18, '62.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ginecológica c/ sonda vaginal', 15, 35, '62.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vagina', 10, 18, '62.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Obstétrica', 10, 18, '62.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Obstétrica c/ fluxometria', 15, 18, '62.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Obstétrica c/ fluxometria umbilical', 10, 18, '62.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Renal e suprarenal', 15, 35, '62.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vesical (suprapúbica)', 10, 18, '62.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vesical (transuretral)', 15, 35, '62.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vesículas seminais', 10, 18, '62.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostática (suprapúbica)', 10, 18, '62.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostática (transrectal)', 15, 35, '62.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Escrotal', 10, 18, '62.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Peniana', 10, 18, '62.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mamária (2 lados)', 10, 20, '62.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Seios perinasais', 10, 18, '62.00.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiroideia', 10, 18, '62.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encefálica', 10, 20, '62.00.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oftalmológica (A)', 10, 20, '62.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oftalmológica (A+B)', 15, 30, '62.00.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biometria ecográfica oftalmológica', 15, 20, '62.00.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Partes moles', 10, 0, '62.00.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glândulas salivares', 10, 18, '62.00.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção ou biópsia dirigida=preço da região +', 20, 0, '62.00.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Per operatória (diagnostica)', 30, 35, '62.00.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia osteoarticular', 25, 18, '62.00.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia carotidea com Doppler', 25, 120, '62.00.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia abdominal com Doppler', 25, 120, '62.00.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia renal com Doppler', 25, 120, '62.00.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia peniana com Doppler', 20, 120, '62.00.00.33');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ecografia arterial dos membros superiores com Doppler', 25, 120, '62.00.00.34');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ecografia venosa dos membros superiores com Doppler', 20, 100, '62.00.00.35');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ecografia arterial dos membros inferiores com Doppler', 25, 120, '62.00.00.36');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ecografia venosa dos membros inferiores com Doppler', 20, 100, '62.00.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crânio ou coluna', 10, 255, '64.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tórax ou abdómen', 15, 300, '64.00.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Crânio ou coluna com cortes de menos de 2 milímetros', 10, 275, '64.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Membros', 10, 210, '64.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção dirigida = preço da região +', 5, 10, '64.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo dinâmico = preço da região +', 5, 10, '64.00.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Plano de tratamento de radioterapia = preço da região +', 0, 20, '64.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame cranio-encefálico', 50, 1300, '65.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da fossa posterior', 50, 1300, '65.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da charneira craniovertebral', 50, 1300, '65.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da coluna cervical', 50, 1300, '65.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da coluna dorsal', 50, 1300, '65.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da coluna lombosagrada', 50, 1300, '65.00.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exame da totalidade da coluna (apenas no plano sagital)', 50, 1300, '65.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame do ouvido médio e labirinto membranoso', 75, 1350, '65.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da órbita', 75, 1350, '65.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da hipófise e seio cavernoso', 50, 1300, '65.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame do cavum faringeo e regiões vizinhas', 50, 1300, '65.00.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exame da região craniofacial dos seios perinasais e glândulas salivares', 50, 1300, '65.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame dos troncos vasculares supra-aórticos', 75, 1350, '65.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame do abdómen', 60, 1300, '65.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da pelve', 60, 1300, '65.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame do tórax', 60, 1300, '65.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame do coração e cardio—vasculares', 75, 1350, '65.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, '"Idem, em ""real-time"" (cine)"', 90, 1400, '65.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame osteo-muscular', 50, 1300, '65.00.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame das articulações', 50, 1300, '65.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame do pescoço', 50, 1300, '65.00.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espectroscopia clínica', 100, 1500, '65.00.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame cranio-encefálico com indicação para estudo das cisternas da base craniana (fossa média e posterior)',
                                  60, 1450, '65.01.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exame cranio-encefálico com indicação para estudo de hidrocefalia', 60, 1450, '65.01.00.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Exame cranio-encefálico com indicação para estudo do hipótalamo e região optoquiasmática', 60, 1450,
   '65.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame cranio-encefálico com indicação para estudo da hipófise e veio cavernoso (incluindo situações de pós operatório)',
                                  60, 1450, '65.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame cranio-encefálico com indicação para estudo do ângulo ponto cerebeloso (incluindo condutos auditivos internos)',
                                  60, 1450, '65.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame cranio-encefálico com indicação para estudo do tronco cerebral (patologia tumoral, desmielinizante e vascular)',
                                  60, 1450, '65.01.00.06');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Exame cranio-encefálico com indicação para estudo vascular dos territórios cerebrais e da fossa posterior',
   60, 1450, '65.01.00.07');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Exame cranio-encefálico com indicação para estudo do aqueduto do Sylvius, região pineal e 4o. ventrículo',
   60, 1450, '65.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame da charneira cranio-vertebral com indicação para estudo das amígdalas cerebelosas, de transição bulbo-medular e respectivas cisternas',
                                  60, 1450, '65.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame da medula com indicação para despiste de lesões de pequena dimensão (cavitações, hematomas, malformações vasculares, anomalias, doenças infecciosas desmielinizantes e tumorais)',
                                  60, 1450, '65.01.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame da coluna lombo-sagrada com indicação para estudo das raízes nervosas e suas relações intratecais e foraminais (patologia herniária, infecciosa e tumoral)',
                                  60, 1450, '65.01.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame do ouvido (particularmente do ouvido crónico complicado, degeneres-cência labiríntica, nervo facial intra e extrapetroso, tumores do conduto e caixa timpânica)',
                                  90, 1500, '65.01.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame da órbita (particularmente patologia intrínseca ou extrínseca do nervo óptico e suas relações com a artéria oftálmica, tumores oculares e seu diagnóstico diferencial)',
                                  90, 1450, '65.01.00.13');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Avaliação hemodinâmica dos membros superiores - Fluxometria Doppler (arterial ou venosa)', 15, 60,
   '66.00.00.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Avaliação hemodinâmica dos membros inferiores - Fluxometria Doppler (arterial ou venosa)', 15, 60,
   '66.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Avaliação hemodinâmica arterial dos membros - Fluxometria Doppler-compressões segmentares ou provas de hiperemia',
                                  20, 60, '66.00.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação hemodinâmica arterial cervico-encefálica - Fluxometria Doppler', 20, 60, '66.00.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação da circulação digital com fotopletismografia', 15, 50, '66.00.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação hemodinâmica da circulação venosa dos membros com pletismografia', 15, 50, '66.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiodinografia (Doppler vascular colorido)', 25, 190, '66.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, '"Eco Doppler ""Duplex-Scan"" carotídeo"', 25, 120, '66.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Doppler Transcraniano', 25, 25, '66.00.00.09');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Avaliação da circulação peniana (Doppler ou pletismografia) (Ver Cod. 16.02.00.02)', 0, 0, '66.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, circulação arterial ou venosa dos membros', 25, 120, '66.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, circulação visceral abdominal', 25, 120, '66.00.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Angiografia ultra-sónica com análise espectral cerebrovascular carotídea', 20, 80, '66.00.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Angiografia ultra-sónica com análise espectral dos membros', 15, 80, '66.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rigiscan', 25, 40, '66.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Doppler Peniano', 15, 80, '66.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Eco Doppler peniano', 25, 120, '66.00.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Eco Doppler colorido peniano', 25, 190, '66.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Teste PGE com papaverina ou prostaglandinas', 15, 10, '66.00.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias cerebrais – Panarteriografia', 60, 0, '66.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia carotidea por punção', 30, 0, '66.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia carotidea por cateterismo (Seldinger)', 40, 0, '66.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia vertebral / por punção umeral', 25, 0, '66.01.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arteriografia vertebral / por cateterismo (Seldinger)', 35, 0, '66.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Membros superiores / por punção ou cateterismo', 20, 0, '66.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aortografia ou aortoarteriografia translombar', 30, 0, '66.01.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aortografia ou aortoarteriografia por cateterismo (Seldinger)', 40, 0, '66.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia selectiva de ramos da aorta', 50, 0, '66.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia do membro inferior', 20, 0, '66.01.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia das artérias genitais', 40, 0, '66.01.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia cava superior', 30, 0, '66.01.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia jugular interna', 25, 0, '66.01.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia dos membros (unilateral)', 10, 0, '66.01.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Iliocavografia', 15, 0, '66.01.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Azigografia', 15, 0, '66.01.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia mamária interna', 15, 0, '66.01.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia renal', 40, 0, '66.01.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia das veias pélvicas', 20, 0, '66.01.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esplenoportografia', 30, 0, '66.01.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Portografia trans-hepática', 50, 0, '66.01.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia supra-hepática', 50, 0, '66.01.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Portografia transumbilical', 30, 0, '66.01.00.23');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arteriografia selectiva e embolização terapêutica, artéria carótida externa', 80, 0, '66.02.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arteriografia selectiva e embolização terapêutica, artéria do membro', 50, 0, '66.02.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arteriografia selectiva e embolização terapêutica, ramo visceral da aorta', 80, 0, '66.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia e dilatação de artéria carótida (*)', 130, 0, '66.02.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arteriografia e dilatação per operatória de artéria vertebral (*)', 100, 0, '66.02.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arteriografia selectiva e dilatação percutânea de artéria do membro', 100, 0, '66.02.00.06');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Arteriografia selectiva e dilatação percutânea do tronco arterial braquiocefálico (*)', 130, 0,
   '66.02.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arteriografia selectiva e dilatação percutânea de um ramo visceral da aorta', 130, 0, '66.02.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação per operatória de artéria de membro (*)', 100, 0, '66.02.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desobstrução intraluminal com Laser', 120, 75, '66.02.00.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Desobstrução intraluminal com Rotablator (*) Adicionar o valor da abordagem cirúrgica se a houver', 120,
   50, '66.02.00.11');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Flebografia selectiva transhepática percutânea e embolização (Varizes gastro-esofágicas)', 80, 0,
   '66.02.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de filtro na V.C.I. por via percutânea', 70, 0, '66.02.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crossografia aortica', 30, 420, '66.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, c/ Troncos supra-aorticos', 30, 650, '66.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, c/ pan-angiografia cerebral', 30, 650, '66.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia orbito-cavernosa', 20, 280, '66.03.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Carótida por punção directa (inclui angiografia cerebral)', 20, 500, '66.03.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Troncos supra-aorticos por punção humeral', 30, 650, '66.03.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crossa aórtica e troncos supra aorticos', 100, 785, '66.03.02.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Uma artéria (carótida interna, externa vertebral ou cervical profunda)', 100, 785, '66.03.03.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Duas artérias', 100, 820, '66.03.03.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Três artérias', 100, 855, '66.03.03.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quatro artérias', 100, 890, '66.03.03.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Mais que quatro artérias (inclui estudo superselectivo dos ramos carotidos)', 100, 1000, '66.03.03.05');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Angiografia radiculo-medular (por cada região: cervical, dorsal ou lombar)', 100, 1075, '66.03.03.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arco aórtico (arteriografia)', 100, 780, '66.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia brônquica', 100, 780, '66.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Pulmonar', 100, 780, '66.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Areteriografia da Subclávia e Humeral', 100, 780, '66.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia dos Membros Superiores', 100, 780, '66.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Abdominal', 100, 780, '66.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tronco Celíaco', 100, 780, '66.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Selectiva Esplénica', 100, 780, '66.04.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Selectiva Coronária Estomáquica', 100, 780, '66.04.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Selectiva Hepática', 100, 780, '66.04.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Pancreática', 100, 780, '66.04.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pantografia por via arterial', 100, 780, '66.04.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia das Supra-Renais', 100, 780, '66.04.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia das Supra-Renais', 100, 780, '66.04.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colheitas Selectivas Reninas (Renais)', 100, 780, '66.04.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colheitas Selectivas Hormonais (supra renais)', 100, 780, '66.04.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia Ovárica, Testicular', 100, 780, '66.04.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia do Mesentério Superior', 100, 780, '66.04.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia do Mesentérico Inferior', 100, 780, '66.04.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia da Hipogástrica', 100, 780, '66.04.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia das íliacas', 100, 780, '66.04.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Periférica dos Membros Inferiores', 100, 780, '66.04.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia dos Membros Superiores', 20, 280, '66.04.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia dos Membros Inferiores', 20, 280, '66.04.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia da Veia-Cava superior', 100, 780, '66.04.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia da Veia-Cava Inferior', 100, 780, '66.04.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intracraniana e Medular', 250, 1500, '66.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carótida Externa', 250, 1200, '66.05.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outros Territórios', 200, 1000, '66.05.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Avaliação Clínica e decisão do tratamento', 12, 0, '67.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cobaltoterapia', 3, 12, '67.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Simulação do tratamento', 10, 60, '67.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imobilização e moldes', 0, 50, '67.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dosimetria', 0, 80, '67.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas de acompanhamento', 12, 0, '67.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Roentgenterapia', 2, 6, '67.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Planeamento Clínico', 14, 0, '67.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'A.L. de particulas (baixa energia)', 2, 50, '67.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'A.L. de partículas (média energia)', 2, 75, '67.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'A.L. de particulas (alta energia)', 2, 100, '67.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Irradiação de meio corpo', 12, 200, '67.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Irradiação de corpo inteiro', 20, 350, '67.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Células Falciformes (Prova da Formação)', 0, 3, '70.10.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Células falciformes (Prova da formação com agente redutor)', 0, 4, '70.10.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corpos de Heinz (Pesquisa)', 0, 3, '70.10.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corpos de Heinz (Susceptibilidade de Formação)', 0, 5, '70.10.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Eritrograma (Eritrócitos+Hemoglobina+Hematócrito+Indíces Eritrocitários)', 0, 3, '70.10.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Eritrograma + Leucócitos', 0, 4, '70.10.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo Morfológico dos Leucócitos pelo Método de Enriquecimento', 0, 8, '70.10.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hematócrito = Volume Globular Eritrocitário', 0, 2, '70.10.00.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Hemograma com plaquetas (Eritrograma+leucócitos+ fórmula leucocitária+plaquetas)', 0, 10, '70.10.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Hemograma (Eritrograma+leucócitos+fórmula leucocitária)', 0, 8, '70.10.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Leucograma (Contagem dos Leucócitos + Fórmula Leucocitária)', 0, 6, '70.10.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plaquetas (Contagem)', 0, 2, '70.10.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reticulócitos (Contagem)', 0, 5, '70.10.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sangue periférico (Estudo morfológico do...)', 0, 8, '70.10.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'DNA dos leucócitos (Quantificação)', 0, 50, '70.11.00.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Esterases não específicas (Alfa-naftil acetato; butirato; naftol ASD acetato), cada', 0, 10,
   '70.11.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fosfatase Ácida dos Leucócitos', 0, 10, '70.11.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fosfatase ácida dos leucócitos (com inibição pelo tartarato)', 0, 10, '70.11.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fosfatase Alcalina dos leucócitos', 0, 10, '70.11.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'P.A.S.', 0, 10, '70.11.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mieloperoxidases', 0, 10, '70.11.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'RNA (Identificação pela Reacção de Ribonuclease)', 0, 8, '70.11.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Siderócitos no sangue periférico (Pesquisa)', 0, 6, '70.11.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Eosinófilos no exsudado nasal (Pesquisa)', 0, 5, '70.11.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sudão Negro', 0, 10, '70.11.00.11');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Esterases não específicas (Alfa-naftil acetato; butirato; naftol ASD acetato) com fluoreto, cada', 0, 10,
   '70.11.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esterase específica (Cloro acetato)', 0, 10, '70.11.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Auto-Hemólise', 0, 10, '70.12.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carboxihemoglobina (Pesquisa)', 0, 5, '70.12.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electroforese das hemoglobinas (a pH alcalino; a pH neutro; a pH ácido), cada', 0, 15, '70.12.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electroforese das cadeias da globina (a pH alcalino; a pH ácido), cada', 0, 20, '70.12.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electroforese das hemoglobinas por focagem isoeléctrica', 0, 30, '70.12.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Enzimas dos eritrócitos (Screening para deficiência), cada', 0, 7, '70.12.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fragilidade Osmótica = Resistência Osmótica', 0, 10, '70.12.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fragilidade Osmótica 24 h após incubação a 37o', 0, 10, '70.12.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Glucose-6-Fosfato Desidrogenase (Screening para deficiência)', 0, 7, '70.12.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glucose-6-Fosfato Desidrogenase (doseamento)', 0, 20, '70.12.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glutatião (Prova de Estabilidade)', 0, 30, '70.12.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glutatião Reduzido', 0, 14, '70.12.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glutatião-Reductase', 0, 20, '70.12.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glutatião-Reductase (Pesquisa)', 0, 6, '70.12.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova de Ham = Prova do soro acidificado', 0, 10, '70.12.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Hemoglobinas instáveis (Pesquisa de: corpos de Heinz, Hemoglobina H, desnat. calor, prec. isopropanol), cada',
                                  0, 5, '70.12.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemoglobina A2 (Cromatografia)', 0, 20, '70.12.00.17');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Hemoglobina fetal = Hemoglobina alcalino-resistente (Prova de desnaturação alcalina)', 0, 10,
   '70.12.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemoglobina Fetal (Técnica da Eluição)', 0, 10, '70.12.00.19');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Hemoglobina fetal (Pesquisa em esfregaço de sangue periférico - Teste de Kleihauer)', 0, 10,
   '70.12.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemoglobina H (Pesquisa)', 0, 5, '70.12.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemoglobina S (Pesquisa)', 0, 5, '70.12.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemoglobina S (Quantificação)', 0, 20, '70.12.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Metahemoglobina', 0, 10, '70.12.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Metahemoglobina (Pesquisa)', 0, 5, '70.12.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Metalbumina', 0, 6, '70.12.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oxihemoglobina', 0, 2, '70.12.00.27');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Estudo espectrofotométrico dos pigmentos da hemoglobina (Oxi, Carboxi, Meta e Sulfa)', 0, 20,
   '70.12.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Piruvato-Kinase = PK (Screening)', 0, 7, '70.12.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Piruvato-Kinase = PK (doseamento)', 0, 20, '70.12.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova da Sacarose = Prova de Hemólise pela Sacarose', 0, 12, '70.12.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sulfahemoglobina (Pesquisa)', 0, 5, '70.12.00.32');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Estudo de uma anemia - (exames executados+valor da consulta) Ver Cód. 01.00.00.03 ou 01.00.00.04', 0, 0,
   '70.12.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemoglobina Plasmática', 0, 8, '70.13.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Velocidade de sedimentação eritrocitária = VS', 0, 5, '70.13.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Viscosidade Plasmática', 0, 20, '70.13.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Viscosidade Sanguínea', 0, 20, '70.13.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Viscosidade Sérica', 0, 20, '70.13.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Volémia Sanguínea', 0, 9, '70.13.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Eritropoietina', 0, 60, '70.13.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Adenograma (não inclui colheita)', 0, 40, '70.14.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esplenograma (não inclui colheita)', 0, 25, '70.14.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo do ferro na medula óssea - Reacção de perls. (não inclui colheita)', 0, 10, '70.14.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemosiderina na urina (doseamento)', 0, 6, '70.14.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mielograma (não inclui colheita)', 0, 25, '70.14.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo citológico dos líquidos biológicos', 0, 8, '70.14.00.06');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Imunofenotipagem celular (sangue periférico; medula óssea; gânglio), cada anticorpo', 0, 50,
   '70.14.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Estudo de órgãos hematopoiéticos - (exames executados+valor da consulta) ver cód. 01.00.00.03 ou 01.00.00.04',
                                  0, 0, '70.14.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova do Laço = Prova de Rumpel-Leed', 0, 2, '70.21.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tempo de hemorragia (Ivy modificado, 2 determinações sem e com AAS)', 0, 30, '70.21.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tempo de hemorragia (Ivy modificado)', 0, 16, '70.21.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'A.P.T.T. = Tempo de Tromboplastina Parcial Activado = T.de Cefalina-Caulino', 0, 3, '70.22.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'A.P.T.T. para Estudo dos Tempos de Tromboplastina Parcial Alongados', 0, 15, '70.22.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'I.N.R. = R.N.I. - Ver Cód. 70.22.00.29', 0, 0, '70.22.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Protrombina (Prova da Correcção do Consumo da...)', 0, 8, '70.22.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Protrombina (Prova do Consumo da...)', 0, 6, '70.22.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Protrombina (Taxa) = Tempo de Protrombina', 0, 4, '70.22.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova da Correcção do Consumo de Protrombina Ver Cód.70.22.00.04', 0, 0, '70.22.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova de Hicks-Pitney', 0, 9, '70.22.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova do Consumo de Protrombina Ver Cód.70.22.00.05', 0, 0, '70.22.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'R.N.I. = I.N.R. - Ver Cód. 70.22.00.29', 0, 0, '70.22.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retracção do Coágulo (Avaliação Qualitativa da...)', 0, 2, '70.22.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retracçrão do Coágulo (Avaliação Quantitativa da...)', 0, 8, '70.22.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Taxa de Protrombina = Tempo de Protrombina - Ver Cód. 70.22.00.06', 0, 0, '70.22.00.16');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tempo de Cefalina-Caulino = Tempo de Tromboplastina Parcial Activada = A.P.T.T. Ver Cód.70.22.00.01', 0, 0,
   '70.22.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tempo de Protrombina = Taxa de Protrombina Ver Cód.70.22.00.06', 0, 0, '70.22.00.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tempo de Quick = Taxa de Protrombina - Ver Cód. 70.22.00.06', 0, 0, '70.22.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tempo de Recalcificação do Plasma', 0, 2, '70.22.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tempo de Recalcificação do Plasma Activado', 0, 2, '70.22.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tempo de Reptilase', 0, 19, '70.22.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tempo de Stypven', 0, 6, '70.22.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tempo de Trombina', 0, 6, '70.22.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tempo de Trombina-Coagulase', 0, 6, '70.22.00.25');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tempo de Tromboplastina Parcial Activado = T.de Caulino- Cefalina = A.P.T.T. Ver Cód.70.22.00.01', 0, 0,
   '70.22.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tempo de trombina com sulfato de protamina', 0, 20, '70.22.00.27');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Estudo da coagulação: Consulta (Acrescido das provas executadas) - Ver Cod. 01.00.00.03 ou 01.00.00.04', 0,
   0, '70.22.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tempo de protrombina com terapêutica orientadora', 2, 4, '70.22.00.29');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Antigénio Relacionado com o Factor IX = Factor IX Ag', 0, 30, '70.23.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Antigénio Relacionado com o Factor VIII = Factor VIII Ag', 0, 30, '70.23.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Criofibrinogénio', 0, 9, '70.23.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor I = Fibrinogénio', 0, 15, '70.23.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor II-C', 0, 20, '70.23.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor IX-C', 0, 15, '70.23.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Factor IX Ag = Antigénio Relacionado c/o Factor IX Ver Cód.70.23.00.01', 0, 0, '70.23.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor V-C', 0, 15, '70.23.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor VII Ag', 0, 63, '70.23.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor VII-C', 0, 15, '70.23.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Factor VIII Ag = Antigénio Relacionada c/o F.VIII Ver Cód.70.23.00.02', 0, 0, '70.23.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor VIII-C', 0, 30, '70.23.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor VIII-vW = Cofactor da Ristocetina', 0, 33, '70.23.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor Von', 0, 8, '70.23.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor X-C', 0, 40, '70.23.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor XI-C', 0, 30, '70.23.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor XII-C', 0, 60, '70.23.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor XIII-C', 0, 35, '70.23.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fibrinogénio = Factor I - Ver Cód. 70.23.00.04', 0, 0, '70.23.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'P&P de Owren', 0, 6, '70.23.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tromboteste', 0, 5, '70.23.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Two-seven-ten = T.S.T.', 0, 5, '70.23.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fibronectina', 0, 84, '70.23.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Beta = Tromboglobulina = Beta-TG', 0, 100, '70.24.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Complexo Trombina/Antitrombina III = TAT', 0, 150, '70.24.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor Fletcher = Pré-Kalikreína', 0, 10, '70.24.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor Plaquetário 4 = PF4', 0, 100, '70.24.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Kalicreína', 0, 10, '70.24.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pré-Kalicreína = Factor Fletcher Ver Cód.70.24.00.03', 0, 0, '70.24.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostaciclinas (Plasmáticas ou urinárias)', 0, 200, '70.24.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tromboxanos (Plasmáticos ou urinários)', 0, 200, '70.24.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticoagulante Lúpico', 0, 40, '70.25.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticoagulantes Circulantes (Pesquisa de...)', 0, 10, '70.25.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antitrombina III', 0, 15, '70.25.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Heparina', 0, 13, '70.25.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Heparina (Prova de Tolerância à...)', 0, 6, '70.25.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Proteína C da Coagulaçao', 0, 15, '70.25.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Proteína S total', 0, 60, '70.25.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova de Tolerância à Heparina - Ver Cód. 70.25.00.05', 0, 0, '70.25.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antitrombina III modificada', 0, 67, '70.25.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Proteina C da coagulação (Ag)', 0, 63, '70.25.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Proteina S (livre)', 0, 60, '70.25.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Proteina S (funcional)', 0, 17, '70.25.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'C4 bBP', 0, 92, '70.25.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fragmentos 1 e 2 da protrombina (F1+2)', 0, 105, '70.25.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpo anti-cardiolipina (ACA) (IgG ou IgM), cada', 0, 50, '70.25.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpo anti-fosfolipido (APA)', 0, 50, '70.25.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpo anti-lupico', 0, 70, '70.25.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Resistência à Proteina C activada', 0, 20, '70.25.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dímero D da Fibrina, (Pesquisa de...)', 0, 7, '70.26.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fibrina (Dímero D da...) por Elisa', 0, 60, '70.26.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fibrina (Dímero D da ) (Pesquisa de ..) Ver Cód. 70.26.00.01', 0, 0, '70.26.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fibrina (Pesquisa de monómeros da...)', 0, 7, '70.26.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fibrinopeptídeo A', 0, 50, '70.26.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fibrinólise (Lise do Coágulo de Euglobulinas)', 0, 8, '70.26.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fibrinólise (Lise do Coágulo de Sangue Total)', 0, 2, '70.26.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Gel-Etanol (Prova do...) = Pesquisa de Monómeros de Fibrina', 0, 3, '70.26.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lise das Euglobulinas', 0, 8, '70.26.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lise do Coágulo de Sangue Total Ver Cód.70.26.00.07', 0, 0, '70.26.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Monómeros de Fibrina (Pesquisa de ...) - Ver Cód. 70.26.00.08', 0, 0, '70.26.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Produtos de Degradaqão da Fibrina = FDP = PDF Ver Cód.70.26.00.04', 0, 0, '70.26.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Protamina (Prova da...)', 0, 6, '70.26.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova da Protamina - Ver Cód. 70.26.00.13', 0, 0, '70.26.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova do Gel-Etanol = Pesquisa de Monómeros de Fibrina Ver Cód.70.26.00.08', 0, 0, '70.26.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-2-Antiplasmina', 0, 18, '70.27.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antiplasmina = Inibidor da Plasmina', 0, 120, '70.27.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estreptoquinase', 0, 120, '70.27.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plasmina', 0, 120, '70.27.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plasminogénio', 0, 8, '70.27.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Plasminogénio (Activador Tecidular do...) = tPA com ou sem estase (cada)', 0, 50, '70.27.00.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Plasminogénio (Activador do...) = uPA(Urokinase)com ou sem estase (cada)', 0, 120, '70.27.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plasminogénio (Actividade do...) = PA', 0, 30, '70.27.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plasminogénio (Inibidor do Activador do...) = PAI', 0, 40, '70.27.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Plasminogénio Ag.(Antigénio do Plasminogénio) = PA Ag', 0, 120, '70.27.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Adesividade Plaquetária', 0, 13, '70.29.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Agregação Plaquetária Espontânea', 0, 10, '70.29.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Agregação Plaquetária Induzida pela Adrenalina', 0, 13, '70.29.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Agregação Plaquetária Induzida pela Ristocetina (no P.R.P.)', 0, 17, '70.29.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Agregação Plaquetária Induzida pelo ADP', 0, 14, '70.29.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Agregação Plaquetária Induzida pelo Colagénio', 0, 17, '70.29.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor Plaquetário 3', 0, 12, '70.29.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Agregação plaquetária induzida pela ristocetina (FWR:Co/Plasmático)', 0, 33, '70.29.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Agregação plaquetária induzida pelo ácido araquidónico', 0, 17, '70.29.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'ABO e Rh – (Grupo Sanguíneo – Sistema ABO e Rh)', 0, 5, '70.31.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aglutininas Eritrocitárias (Identificação das...)', 0, 30, '70.31.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aglutininas Eritrocitárias (Pesquisa c/Albumina)', 0, 6, '70.31.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aglutininas Eritrocitárias (Pesquisa com enzimas)', 0, 6, '70.31.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aglutininas Eritrocitárias (Pesquisa em meio salino)', 0, 5, '70.31.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aglutininas Eritrocitárias (Titulação c/albumina)', 0, 9, '70.31.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aglutininas Eritrocitárias (Titulação com enzimas)', 0, 9, '70.31.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aglutininas Eritrocitárias (Titulação em meio salino)', 0, 8, '70.31.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos anti-Leucocitários (Pesquisa c/Titulação, se necessário de.)', 0, 15, '70.31.00.09');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Anticorpos anti-Plaquetários (Pesquisa c/Titulação se necessário de...) -Ver Cód. 75.01.00.01', 0, 0,
   '70.31.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos bi-fásicos de Donath-Landsteiner (Pesq.c/Titulação se nec.de)', 0, 8, '70.31.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antigénios Eritrocitários (excl.os do sist.ABO e Rh)', 0, 8, '70.31.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coombs Directa (Prova de...)', 0, 5, '70.31.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coombs Indirecta Qualitativa (Prova de...)', 0, 5, '70.31.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coombs Indirecta Quantitativa (Prova de...)', 0, 20, '70.31.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioaglutininas (Pesquisa de...)', 0, 5, '70.31.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioaglutininas (Titulação das...)', 0, 10, '70.31.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fenótipo Rhesus (aglutinogénios)', 0, 12, '70.31.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Iso-hemaglutininas Naturais (Titulação)', 0, 10, '70.31.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rh (determinação do Genótipo)', 0, 15, '70.31.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Láctico=Lactatos', 0, 10, '72.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Láctico (Pesquisa de...)', 0, 3, '72.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Pirúvico', 0, 10, '72.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Açúcares (Estudo Cromatográfico)', 0, 10, '72.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Frutosamina', 0, 20, '72.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Frutose', 0, 6, '72.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Frutose (Sobrecarga Endovenosa)', 0, 125, '72.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Frutose-1,6 Difosfatase', 0, 50, '72.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Galactose', 0, 8, '72.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Galactose (Prova de Tolerância à...)', 0, 35, '72.01.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Galactose - Sobrecarga Endovenosa', 0, 140, '72.01.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glicogénio', 0, 30, '72.01.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glicose', 0, 2, '72.01.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glicose Após Almoço', 0, 3, '72.01.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glucagina por Sobrecarga Endovenosa', 0, 64, '72.01.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glutamina', 0, 8, '72.01.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemoglobina A1c = Hemoglobina Glicada', 0, 30, '72.01.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lactose', 0, 8, '72.01.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lactose (Pesquisa de...)', 0, 2, '72.01.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Levulose', 0, 8, '72.01.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Levulose (Pesquisa de...)', 0, 2, '72.01.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oligossacaridos - Pesquisa e Identificação', 0, 20, '72.01.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pentoses (Pesquisa de...)', 0, 4, '72.01.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Açúcares redutores (pesquisa)', 0, 5, '72.01.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Curva de hiperglicémia provocada 3h com 4 doseamentos de Glicose = Prova oral de tolerância à Glicose de 3h com 4 doseamentos de Glicose',
                                  0, 11, '72.01.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Curva de hiperglicémia provocada 4h com 5 doseamentos de Glicose = Prova oral de tolerância à Glicose de 4h com 5 doseamentos de Glicose',
                                  0, 12, '72.01.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Curva de hiperglicémia provocada 5h com 6 doseamentos de Glicose = Prova oral de tolerância à Glicose de 5h com 6 doseamentos de Glicose',
                                  0, 14, '72.01.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exton-Rose (Prova de)', 0, 10, '72.01.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Frutose 1 Fosfato Aldolase', 0, 80, '72.01.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Frutose 1,6 Difosfato-Aldolase', 0, 80, '72.01.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lactose (Prova de tolerância à)', 0, 35, '72.01.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Fenilpirúvico (Pesquisa de...)', 0, 2, '72.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Glutâmico (Pesquisa de...)', 0, 5, '72.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Homogentísico (Pesquisa de...)', 0, 3, '72.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Oxálico', 0, 30, '72.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Úrico', 0, 3, '72.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácidos Aminados (sep.cromatog.bidimensional)', 0, 25, '72.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácidos Aminados (sep.cromatog.unidimensional)', 0, 11, '72.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácidos Orgânicos + Azoto Amoniacal', 0, 20, '72.02.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acidúrias Orgânicas (Pesquisa e Identificação)', 0, 50, '72.02.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alanina – Sobrecarga Oral', 0, 76, '72.02.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Albumina', 0, 3, '72.02.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Albumina (Pesquisa de...)', 0, 2, '72.02.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Albumina e Globulinas', 0, 6, '72.02.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-1 Antitripsina', 0, 12, '72.02.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-1 Antitripsina (Fenotipagem)', 0, 40, '72.02.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-1 Quimotripsina', 0, 12, '72.02.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-2 Macroglobulina', 0, 12, '72.02.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aminoacidúria Total', 0, 20, '72.02.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amónia', 0, 10, '72.02.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apolipoproteína A', 0, 30, '72.02.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apolipoproteína C', 0, 40, '72.02.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apolipoproteína E', 0, 40, '72.02.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apolipoproteína Lp(a)', 0, 40, '72.02.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Azoto Total não Proteico', 0, 2, '72.02.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Azoto dos ácidos Aminados', 0, 8, '72.02.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Beta-1 Glicoproteína', 0, 50, '72.02.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Beta-2 Microglobulina', 0, 50, '72.02.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ceruloplasmina', 0, 12, '72.02.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistina (Pesquisa de...)', 0, 3, '72.02.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistinúria', 0, 20, '72.02.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Creatina', 0, 9, '72.02.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Creatinina', 0, 2, '72.02.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioglobulinas (Caracterização das...)', 0, 20, '72.02.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioglobulinas (Pesquisa de...)', 0, 5, '72.02.00.34');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electroforese das Proteínas em liq.biológicos, após sua concentração', 0, 15, '72.02.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fenilalanina', 0, 36, '72.02.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fenilcetonúria = PKU (Pesquisa de...)', 0, 12, '72.02.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ferritina', 0, 40, '72.02.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glicoproteínas (Electroforese das...)', 0, 15, '72.02.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Haptoglobina', 0, 12, '72.02.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemoglobina (Pesquisa de...)', 0, 2, '72.02.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemopexina', 0, 12, '72.02.00.42');
INSERT INTO ProcedureType VALUES (DEFAULT, 'L-DOPA', 0, 40, '72.02.00.43');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Melanina (Pesquisa de...)', 0, 4, '72.02.00.44');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Microalbuminúria', 0, 18, '72.02.00.45');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mioglobina (Pesquisa de...)', 0, 5, '72.02.00.46');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Mucopolissacaridases na Urina (est.cromat. camada fina e coluna)', 0, 50, '72.02.00.47');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mucopolissacáridos (Estudo Cromatográfico)', 0, 40, '72.02.00.48');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mucoproteínas', 0, 9, '72.02.00.49');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Proteína Bence-Jones (Met-Quimico) - Cód. 75.02.00.02', 0, 0, '72.02.00.50');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Proteínas Totais', 0, 3, '72.02.00.51');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Proteínas (Pesquisa de ...)', 0, 2, '72.02.00.52');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transferrina', 0, 12, '72.02.00.53');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureia', 0, 2, '72.02.00.54');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureia (Depuração da...)', 0, 6, '72.02.00.55');
INSERT INTO ProcedureType VALUES (DEFAULT, 'ANP - Péptido natridiurético auricular', 0, 100, '72.02.00.56');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acetona (Pesquisa de)', 0, 2, '72.02.00.57');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido', 0, 2, '72.02.00.58');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Gama-Aminobutirico = GABA', 0, 40, '72.02.00.59');
INSERT INTO ProcedureType VALUES (DEFAULT, 'AMP = Adenosina Monofosfato', 0, 20, '72.02.00.60');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apolipoproteina B', 0, 30, '72.02.00.61');
INSERT INTO ProcedureType VALUES (DEFAULT, 'BGP = Osteocalcina', 0, 70, '72.02.00.62');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Clearence da Creatinina', 0, 6, '72.02.00.63');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electroforese das proteinas = Proteínograma', 0, 6, '72.02.00.64');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemossiderina na urina (pesquisa de)', 0, 4, '72.02.00.65');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mucopolissacáridos (pesquisa de)', 0, 5, '72.02.00.66');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Homocisteína (pesquisa de)', 0, 10, '72.02.00.67');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lp(a)', 0, 40, '72.02.00.68');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Adenosinotrifosfato = ATP', 0, 9, '72.02.00.69');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acetona', 0, 5, '72.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Beta-Hidroxibutírico', 0, 5, '72.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Diacético', 0, 5, '72.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Diacético (Pesquisa de...)', 0, 2, '72.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácidos Gordos (cromatografia)', 0, 10, '72.03.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácidos Gordos Esterificados', 0, 10, '72.03.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácidos Gordos Livres', 0, 10, '72.03.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aspecto do Soro após Refrigeração= Supernatant Creaming', 0, 2, '72.03.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Beta-Lipoproteínas', 0, 6, '72.03.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colesterol HDL 2', 0, 6, '72.03.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colesterol HDL 3', 0, 4, '72.03.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colesterol Total, Livre e Esterificado', 0, 6, '72.03.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colesterol VLDL', 0, 4, '72.03.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colesterol total', 0, 3, '72.03.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corpos Cetónicos = Acetona (Doseamento)', 0, 5, '72.03.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corpos Cetónicos = Acetona (Pesquisa de...)', 0, 2, '72.03.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esteres dos Ácidos Gordos', 0, 40, '72.03.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fosfolipídeos', 0, 40, '72.03.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gorduras Totais nas Fezes de 3 Dias', 0, 20, '72.03.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perfil Lipidico (separação por Ultracentrifugação)', 0, 60, '72.03.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Triglicerídeos', 0, 6, '72.03.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aril Sulfatase A', 0, 115, '72.03.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colesterol HDL', 0, 4, '72.03.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apoproteina E total', 0, 67, '72.03.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colesterol LDL', 0, 4, '72.03.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apoproteina E - isomorfos', 0, 100, '72.03.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colesterol LDL (Det. Directa)', 0, 4, '72.03.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hexosaminidase total', 0, 67, '72.03.00.28');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electroforese das lipoproteínas = Lipoproteinograma = Lipidograma', 0, 25, '72.03.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lecitina-colesterol-acetiltransferase (LCAT)', 0, 225, '72.03.00.30');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ficha lípidica = Lipidograma + Colesterol + Trigliceridos + Colestrol HDL', 0, 38, '72.03.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Razão Palmítica/esteária', 0, 13, '72.03.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoproteina lipase (LPL)', 0, 54, '72.03.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Triglicérido-lipase-hepática TGHL', 0, 54, '72.03.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'VLDL Colesterol', 0, 4, '72.03.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, '5-Nucleotídase = 5-NT', 0, 8, '72.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acetilcolinesterase', 0, 9, '72.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aldolase', 0, 9, '72.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-L-HiaIoduronidase', 0, 50, '72.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amilase', 0, 4, '72.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aminopeptidase', 0, 6, '72.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aminopeptidase A', 0, 50, '72.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aril-Sulfatase A', 0, 50, '72.04.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aril-Sulfatase B', 0, 50, '72.04.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Beta-Galactosídase', 0, 50, '72.04.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Beta-Glucoronidase', 0, 50, '72.04.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Beta-Glucosidase', 0, 50, '72.04.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colinesterase', 0, 9, '72.04.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desidrogenase Alfa-Hidroxibutírica = HBDH', 0, 8, '72.04.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desidrogenase Glutâmica = GLDH', 0, 8, '72.04.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desidrogenase Isocítrica = ICDH', 0, 8, '72.04.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desidrogenase Láctica = LDH = DHL', 0, 6, '72.04.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Desidrogenase Láctica = LDH (Sep.Térmica das Iso-enzimas)', 0, 15, '72.04.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desidrogenase Málica = MDH', 0, 8, '72.04.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desidrogenase Sorbítica = SDH', 0, 12, '72.04.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dipeptidil-Aminopeptídase IV', 0, 50, '72.04.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dissacaridases', 0, 70, '72.04.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enzima Conversor da Angiotensina = SACE', 0, 40, '72.04.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fosfatase Ácida Total', 0, 3, '72.04.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fosfatase Alcalina', 0, 3, '72.04.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fosfatase Alcalina (Fraccionamento Térmico)', 0, 15, '72.04.00.26');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fosfatase Alcalina (Sep.Electroforética das Iso-enzimas da...)', 0, 30, '72.04.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fosfoglicero-mutase', 0, 12, '72.04.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fosfohexose-Isomerase = PHI', 0, 12, '72.04.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fosforilases', 0, 60, '72.04.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Galacto Aminase (Pesquisa)', 0, 2, '72.04.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Galacto-1-Fosfato-Uridiltransferase', 0, 8, '72.04.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Galactose-1-Fosfato-Glutamil-Transferase', 0, 20, '72.04.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Galactotransferase (Pesquisa de...) =Spot Test', 0, 15, '72.04.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glucose - 6 Fosfatase', 0, 20, '72.04.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hexosaminidase A', 0, 50, '72.04.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hexosaminidase A+B', 0, 60, '72.04.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Isoamílase', 0, 10, '72.04.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'L-Fucosidase', 0, 50, '72.04.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lisozima = Muramidase', 0, 12, '72.04.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipase', 0, 8, '72.04.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Manosidase', 0, 50, '72.04.00.42');
INSERT INTO ProcedureType VALUES (DEFAULT, 'N-Acetil-Glucosaminidase', 0, 50, '72.04.00.43');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ornitino-Carbamiltransferase', 0, 12, '72.04.00.44');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pepsina', 0, 8, '72.04.00.45');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tripsina (Pesquisa de...)', 0, 5, '72.04.00.46');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tripsina', 0, 40, '72.04.00.47');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acetilcolinesterase Isoenzimas', 0, 13, '72.04.00.48');
INSERT INTO ProcedureType VALUES (DEFAULT, 'ALT = Alanina Aminotransferase = TGP', 0, 3, '72.04.00.49');
INSERT INTO ProcedureType VALUES (DEFAULT, 'AST = Aminotransferase Aspartato = GOT', 0, 3, '72.04.00.50');
INSERT INTO ProcedureType VALUES (DEFAULT, 'CK = CPK = Creatinafosfoquinase', 0, 8, '72.04.00.51');
INSERT INTO ProcedureType VALUES (DEFAULT, 'CK MB = Creatinafosfoquinase fracção MB', 0, 12, '72.04.00.52');
INSERT INTO ProcedureType VALUES (DEFAULT, 'CK MM = Creatinafosfoquinase fracção MM', 0, 30, '72.04.00.53');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Isoenzimas da CK (Sep. Electrof. Das Iso-enzimas da CK)', 0, 30, '72.04.00.54');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desidrogenase da Glicose 6 Fosfato=G-6-PDH', 0, 6, '72.04.00.55');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Desidrogenase Láctica (Separação electroforética das Iso-enzimas da...)', 0, 30, '72.04.00.56');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fosfatase ácida total e fracção prostática', 0, 6, '72.04.00.57');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Galactotransferase Eritrocitária', 0, 58, '72.04.00.58');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gama glutamil transferase (GGT)', 0, 8, '72.04.00.59');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glucoroniltransferase da uridina difosfato', 0, 20, '72.04.00.60');
INSERT INTO ProcedureType VALUES (DEFAULT, 'LAP = Leucina-Aminopeptidase', 0, 8, '72.04.00.61');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quimotripsina', 0, 15, '72.04.00.62');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-Amilase Pancreática', 0, 30, '72.04.00.63');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-Amilase Salivar', 0, 30, '72.04.00.64');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ac.Clorídrico Livre e Acidez Tot.(Cont.Gástrico e/ou Duod.)s/ Colheita', 0, 15, '72.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bicarbonatos', 0, 5, '72.05.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cálcio', 0, 3, '72.05.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cálcio (absorção atómica)', 0, 40, '72.05.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cálcio Ionizado (Calculado)', 0, 7, '72.05.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cálcio Ionizado (Determinação Directa)', 0, 12, '72.05.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cloreto de Amónio', 0, 3, '72.05.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cloro', 0, 3, '72.05.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Equilíbrio ácido-base (pH, pCO2, sat O2 e excesso de', 0, 40, '72.05.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ferro', 0, 4, '72.05.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ferro (Absorção Atómica)', 0, 40, '72.05.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fosforo Inorganico', 0, 2, '72.05.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Magnésio', 0, 6, '72.05.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Magnésio (Absorqão Atómica)', 0, 40, '72.05.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Magnésio Eritrocitário (Absorsão Atómica)', 0, 50, '72.05.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osmolaridade', 0, 10, '72.05.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'pH (Determinação do)', 0, 2, '72.05.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potássio', 0, 3, '72.05.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sódio', 0, 3, '72.05.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Capacidade total de fixação do ferro', 0, 6, '72.05.00.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Determinação indirecta dos cloretos no suor pela prova da placa', 0, 3, '72.05.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gases no sangue e pH', 0, 40, '72.05.00.22');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Suor (Determinação dos cloretos ou sódio no), após estimulação por iontoforese com pilocarpina', 1, 20,
   '72.05.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alumínio (Absorção Atómica)', 0, 40, '72.06.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cobre (Absorção Atómica)', 0, 40, '72.06.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cobre (dos. Quimica)', 0, 6, '72.06.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fluor', 0, 12, '72.06.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lítio', 0, 6, '72.06.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Zinco (Absorção Atómica)', 0, 40, '72.06.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Zinco (Doseamento Químico)', 0, 8, '72.06.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ferro (Capacidade de fixação)', 0, 6, '72.06.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reserva Alcalina', 0, 5, '72.06.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Ascórbico = Vitamina C (Pesquisa de...)', 0, 2, '72.07.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Fólico', 0, 60, '72.07.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Caroteno', 0, 8, '72.07.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vitamina A', 0, 8, '72.07.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vitamina B12', 0, 40, '72.07.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vitamina D', 0, 50, '72.07.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vitamina E', 0, 50, '72.07.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Vitaminas do Complexo B (B1; B2; B6;Ac.nicotinico) cada', 0, 50, '72.07.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Àcido Formiminoglutâmico = FIGLU', 0, 40, '72.07.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Vitamina C (pesquisa de) = Ácido Ascórbico (pesquisa de)', 0, 2, '72.07.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vitamina C = Ácido Ascórbico (doseamento)', 0, 50, '72.07.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amikacina', 0, 40, '72.08.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aminofilina = Teofilina', 0, 20, '72.08.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anfetamina', 0, 40, '72.08.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antiepilépticos (cada)', 0, 40, '72.08.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antiparkinsónicos (cada)', 0, 40, '72.08.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arsénio (Pesquisa de...)', 0, 6, '72.08.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Barbitúricos (Pesquisa de...)', 0, 4, '72.08.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Benzodiazepinas (cada)', 0, 40, '72.08.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cádmio (Doseamento por Abs.Atómica)', 0, 40, '72.08.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Canabinoides', 0, 40, '72.08.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carbamazepina', 0, 40, '72.08.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Chumbo (Abs. Atómica)', 0, 40, '72.08.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Chumbo (Ex. químico)', 0, 8, '72.08.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclosporina', 0, 25, '72.08.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Clonazepan', 0, 40, '72.08.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cocaína', 0, 40, '72.08.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crómio', 0, 20, '72.08.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Difenil-Hidantoína = Fenintoína = Hidantina', 0, 40, '72.08.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Digoxina', 0, 40, '72.08.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Disopiramida', 0, 40, '72.08.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fenobarbital', 0, 40, '72.08.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gentamicina', 0, 40, '72.08.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Kanamicina', 0, 40, '72.08.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lidocaína', 0, 40, '72.08.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mercúrio (Absorção Atómica)', 0, 40, '72.08.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Metadona', 0, 40, '72.08.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Metrotexato', 0, 40, '72.08.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Morfina', 0, 40, '72.08.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Netilmicina', 0, 40, '72.08.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Primidona', 0, 40, '72.08.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Procainamida', 0, 40, '72.08.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Propanolol', 0, 40, '72.08.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quinidina', 0, 40, '72.08.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Selénio (Abs.Atómica)', 0, 40, '72.08.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tobramicina', 0, 40, '72.08.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Warfarina', 0, 40, '72.08.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drogas de abuso (pesquisa), cada', 0, 40, '72.08.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Etosuccimida', 0, 40, '72.08.00.38');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fármacos (não descriminados na tabela), cada doseamento', 0, 40, '72.08.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mercúrio', 0, 8, '72.08.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Opiáceos, cada', 0, 40, '72.08.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácidos Biliares (Pesquisa)', 0, 2, '72.09.00.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ácidos Biliares conjugados e não conjugados na Bilis (Pesquisa e Identificação)', 0, 40, '72.09.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bilirrubina (Pesquisa de)', 0, 2, '72.09.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bilirrubina Total', 0, 3, '72.09.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bilirrubina Total + Directa e Indirecta', 0, 6, '72.09.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coproporfirinas (Doseamento)', 0, 15, '72.09.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coproporfirinas (Pesquisa de...)', 0, 4, '72.09.00.07');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Hiperbilirrubinemia Neo-Natal (Bilirrubina total+directa+albumina) 1a. Determinação', 0, 80,
   '72.09.00.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Hiperbilirrubinemia Neo-Natal (Bilirrubina total+directa+albumina) Determinações seguintes', 0, 30,
   '72.09.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Porfirina eritrocitária Livre', 0, 30, '72.09.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Porfirinas (Pesquisa de...)', 0, 5, '72.09.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Porfirinas (Uro + Coproporfirinas)', 0, 30, '72.09.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Porfobilinogénio (doseamento)', 0, 20, '72.09.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Porfobilinogénio (pesquisa)', 0, 3, '72.09.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Protoporfirinas', 0, 30, '72.09.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sais Biliares (Dos)', 0, 40, '72.09.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Urobilina (Pesquisa de...)', 0, 2, '72.09.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Urobilinogénio (Pesquisa de...)', 0, 2, '72.09.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uroporfirinas (doseamento)', 0, 15, '72.09.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uroporfirinas (Pesquisa de...)', 0, 5, '72.09.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Àcido Delta-Aminolevulítico = ALA', 0, 20, '72.09.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pigmentos biliares (pesquisa de)', 0, 10, '72.09.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Addis (Contagem ou Prova de...)', 0, 5, '72.10.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alcool Etílico', 0, 12, '72.10.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Amido (Prova de Tolerância ao...) – não inclui produtos administrados', 0, 30, '72.10.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cálculo urinário (Ex. químico Qualitativo) cada', 0, 8, '72.10.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cálculo urinário (Ex. Espectográfico)', 0, 40, '72.10.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Concentração Urinária (Prova de...)', 0, 5, '72.10.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diluição Urinária (Prova de...)', 0, 5, '72.10.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gonadotrofinas Coriónicas (=HCG)', 0, 20, '72.10.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Grau de Digestão dos Alimentos, nas Fezes', 0, 5, '72.10.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Gravidez (Diagnóstico Imunológico da...)=D.I.G.=T.I.G', 0, 5, '72.10.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hidroxiprolina', 0, 40, '72.10.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oxalatos Urinários (Det.Enzimática)', 0, 30, '72.10.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova da Estimulação pela Secretina', 0, 61, '72.10.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova da Xilose', 0, 20, '72.10.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova de Estimulação pela Pancreozimina', 0, 61, '72.10.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sangue Oculto (Pesquisa de...)', 0, 2, '72.10.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sedimento Urinário', 0, 2, '72.10.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Substâncias Metacromáticas na Urina (Pesquisa de...)', 0, 20, '72.10.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Análise sumária da urina (Urina II)', 0, 3, '72.10.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteocalcina', 0, 60, '72.10.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'VIP - Vasoactive peptide intestinal', 0, 60, '72.10.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cloraminas', 0, 20, '72.10.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Contagem minutada da urina', 0, 5, '72.10.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cristais (pesquisa de)', 0, 15, '72.10.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Densidade de líquidos biológicos', 0, 3, '72.10.00.25');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova de estimulação do suco gástrico pela Pentagastrina', 0, 55, '72.10.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova de estimulação do suco gástrico pelo Histalog', 0, 55, '72.10.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Secretina e Pancreozimina (Prova de estimulação pela) S/incluir produtos administrados ou utilização do RX',
                                  0, 90, '72.10.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Urina (Contagem minutada)', 0, 5, '72.10.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Xilose (Prova da)', 0, 20, '72.10.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'ACTH (cada doseamento)', 0, 35, '73.01.01.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'F.S.H.=Hormona Foliculo-Estimulante', 0, 25, '73.01.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hormona do Crescimento = GH=STH= Somatotrofina', 0, 30, '73.01.01.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Hormona do Crescimento = STH = GH- Ver Cód. 73.01.01.04', 0, 0, '73.01.01.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Hormopa Folículo-Estimulante = FSH - Ver Cód.73.01.01.03', 0, 0, '73.01.01.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hormona Lactogénica Placentária = HPL', 0, 40, '73.01.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hormona Anti-Diurética = ADH =Vasopressina', 0, 60, '73.01.01.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hormona Luteo-Estimulante = LH', 0, 25, '73.01.01.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hormona Tireo-Estimulante = TSH', 0, 25, '73.01.01.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'HPL = Hormona Lactogénica Placentária- Ver Cód. 73.01.01.07', 0, 0, '73.01.01.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'LH = Hormona Luteo-Estimulante- Ver Cód. 73.01.01.10', 0, 0, '73.01.01.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Progesterona = Prog = PRG', 0, 25, '73.01.01.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prolactina = PRL', 0, 25, '73.01.01.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Somatomedina C', 0, 60, '73.01.01.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Somototrofina = hGH = STH = GH = Hormona de Crescimento- Ver Cód. 73.01.01.04', 0, 0, '73.01.01.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'STH = Somatotrofina = hGH = GH = Hormona de Crescimento- Ver Cód. 73.01.01.04', 0, 0, '73.01.01.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'TSH = Hormona Tireo-Estimulante- Ver Cód. 73.01.01.10', 0, 0, '73.01.01.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Vasopressina = ADH = Hormona Anti-Diurética- Ver Cód. 73.01.01.08', 0, 0, '73.01.01.19');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Estudo de alterações endocrinológicas - (exames executados+valor da consulta) Ver Cód. 01.00.00.03 ou 01.00.00.04',
                                  0, 0, '73.01.01.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calcitonina', 0, 75, '73.01.02.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'T3', 0, 18, '73.01.02.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'T3 Livre', 0, 18, '73.01.02.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'T3 Reverse', 0, 75, '73.01.02.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'T3 Uptake = Fixação do T3', 0, 15, '73.01.02.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'T4', 0, 18, '73.01.02.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'T4 Livre', 0, 18, '73.01.02.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'TBG = Globulina Ligada à Tiroxina', 0, 25, '73.01.02.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiroglobulina', 0, 75, '73.01.02.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uptake da T3 = Fixação do T3 Ver Cód.73.01.02.05', 0, 0, '73.01.02.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'AMP Cíclico', 0, 100, '73.01.03.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parathormona = PTH', 0, 60, '73.01.03.02');
INSERT INTO ProcedureType VALUES (DEFAULT, '17-Alfa-Hidroxiprogesterona', 0, 40, '73.01.03.04');
INSERT INTO ProcedureType VALUES (DEFAULT, '17-Beta-estradiol', 0, 30, '73.01.03.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Beta-HCG = Unidade Beta da Gonadotrofina Coriónica', 0, 50, '73.01.03.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estradiol', 0, 30, '73.01.03.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estriol Plasmático', 0, 30, '73.01.03.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estrogénios Totais', 0, 20, '73.01.03.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estrogénios Fraccionados na Urina', 0, 90, '73.01.03.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estrona', 0, 30, '73.01.03.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Receptores Celulares de Estrogéneos', 0, 165, '73.01.03.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Receptores Celulares de Progesterona', 0, 165, '73.01.03.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'S.H.B.G. - Globulina ligada às Hormonas Sexuais', 0, 60, '73.01.03.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testoterona (T)', 0, 25, '73.01.03.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testoterona Livre', 0, 30, '73.01.03.16');
INSERT INTO ProcedureType VALUES (DEFAULT, '17-Cetosteroides Fraccionados', 0, 60, '73.01.04.01');
INSERT INTO ProcedureType VALUES (DEFAULT, '17-Cetosteroides Totais = 17-Ks', 0, 12, '73.01.04.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Homovanílico = HVA', 0, 20, '73.01.04.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido Vanililmandélico = VMA', 0, 20, '73.01.04.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aldosterona', 0, 40, '73.01.04.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiotensina', 0, 100, '73.01.04.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Catecolaminas Fraccionadas (Adrenalina e Nor-Adrenalina) cada', 0, 30, '73.01.04.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Catecolaminas Fraccionadas (Adrenalina e Nor Adrenalina+Dopamina)', 0, 100, '73.01.04.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Catecolaminas Totais', 0, 30, '73.01.04.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Composto S = Desoxicortisol', 0, 30, '73.01.04.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cortisol = Hidrocortisona = Composto F', 0, 20, '73.01.04.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dehidroepiandrosterona = DHEA urinária', 0, 14, '73.01.04.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dehidroepiandrosterona Sulfato = DHEA-S04', 0, 40, '73.01.04.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Delta-4-Androstenodiona=Delta-4-A', 0, 40, '73.01.04.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desoxicortisol = Composto S- Ver Cód. 73.01.04.10', 0, 0, '73.01.04.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Epinefrina', 0, 30, '73.01.04.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'HVA = ácido Homovanilico- Ver Cód. 73.01.04.03', 0, 0, '73.01.04.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Metanefrinas totais', 0, 30, '73.01.04.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Metanefrinas totais (Metanefrina+Nor-Metanefrinas) por HPLC', 0, 100, '73.01.04.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pregnanetriol (triol)', 0, 18, '73.01.04.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'VMA = Ácido Vanililmandélico- Ver Cód. 73.01.04.04', 0, 0, '73.01.04.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glucagon = Glucagina', 0, 40, '73.01.05.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Insulina (cada doseamento)', 0, 20, '73.01.05.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Peptideo C', 0, 35, '73.01.05.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ácido 5-Hidroxi-Indolacético = 5HIAA', 0, 20, '73.01.05.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ácido 5-Hidroxi-Indolacético = 5-HIAA (Pesquisa de ...)', 0, 6, '73.01.05.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecístoquinina', 0, 40, '73.01.05.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrina', 0, 50, '73.01.05.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, '5-HIAA = Ácido 5-Hidroxi-Indolacético- Ver Cód. 73.01.05.05', 0, 0, '73.01.05.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, '5-HIAA = Ácido 5-Hidroxi-Indolacético (Pesquisa de...)- Ver Cód. 73.01.05.06', 0, 0, '73.01.05.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Secretina', 0, 40, '73.01.05.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Serotonina', 0, 20, '73.01.05.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Eritropoietina', 0, 60, '73.01.06.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Renina (Actividade Plasmática da...), cada', 0, 30, '73.01.06.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Beta-Endorfina', 0, 40, '73.01.07.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova da Clonidina com Doseamentos Hormonais', 100, 0, '73.02.01.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova da L-Dopa com ou sem Propanolol c/doseamento STH (cada doseamento)', 0, 30, '73.02.01.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Prova de Clomifene Alargada (doseamentos de L.H.,FSH,Estradiol, Testosterona cada doseamento)', 3, 30,
   '73.02.01.03');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Prova de Clomifene com 2 doseamentos de H.L., 2 de FSH, 2 de Estradiol, 2 de Testosterona', 3, 210,
   '73.02.01.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova de Estim.da STH pelo Exercício, cada determ.de STH', 3, 30, '73.02.01.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova.de Estimul.c/L.R.H. com 3 doseamentos de L.H. e 3 de FSH, cada', 3, 25, '73.02.01.06');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova de Estimul.c/T.R.H. com doseamentos de TSH, cada', 3, 25, '73.02.01.07');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Prova de estim. múltipla p/ trh, lrh e hipoglicémia (7/glicémia, 6/sth, 5/cortisol, 4/prl, 4/fsh, 4/l, 5/acth)',
                                  8, 830, '73.02.01.08');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Prova de estimulação múltipla alarg. pelo trh, lrh e hipoglic. c/ dos. prl, tsh, fsh, lh, acth, cortisol cada',
                                  8, 30, '73.02.01.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova de Glucagon com doseamentos de STH-cada doseamento', 3, 30, '73.02.01.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Prova de Hipoglicémia Insulinica (I.V.) com doseamentos hormonais, cada determinação', 8, 30,
   '73.02.01.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova de Inibiçâo da STH após sobrecarga Glúcidica, cada dos. De STH', 3, 30, '73.02.01.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova da Metirapona c/2 dos.Comp. S/17 Cetosteroides, (cada)', 3, 30, '73.02.02.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova de Estimulação com ACTH, com doseamentos de Cortisol (cada)', 4, 20, '73.02.02.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Prova da Gonadotrofina Corionica com doseamentos de Testosterona e Estradiol, cada doseamento', 0, 30,
   '73.02.03.01');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Prova de Hiperglicémia provocada com doseamentos de insulina simultâneos, cada', 3, 18, '73.02.04.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anaeróbios (Pesquisa e identificação de)', 0, 20, '74.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antibiograma = TSA', 0, 16, '74.01.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Antibiograma para Bacilos ácido-Resistentes (cada Tuberculostático)', 0, 16, '74.01.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Antibióticos (Determinação da Concentração Inibitória Minima, cada)', 0, 12, '74.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Autovacina', 0, 0, '74.01.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'B.K. (Exame Directo com e sem Homogeneização para Pesquisa de...)', 0, 6, '74.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'B.K. (Exame Directo e Cultural)', 0, 12, '74.01.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Bacilo Diftérico = Bacilo Loeffler, inclui exame cultural', 0, 20, '74.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bacilos de Hansen (Pesquisa de...)', 0, 5, '74.01.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Bacteriológico (c/Identificação) + Micológico e Parasitológico', 0, 15, '74.01.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Bacteriológico cult.em Aerobiose, com estudo paralelo em Anaerobiose', 0, 30, '74.01.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bacteriológico Directo (Coloração pelo Gram)', 0, 2, '74.01.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bacteriológico directo e Cultural c/Identificação', 0, 12, '74.01.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Bactérias (Imunofluorescência para identificação de...)', 0, 25, '74.01.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Bordetela pertussis (Exame cultural e identificação)', 0, 15, '74.01.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Brucella (hemocultura p/)', 0, 20, '74.01.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Chlamydia trachomatis (Pesq.)', 0, 42, '74.01.00.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Chlamydia trachomatis (Pesquisa em cultura de células da...)', 0, 70, '74.01.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Citobacteriologico (Ex. Directo e Cultura)', 0, 17, '74.01.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Citobacteriologico de urina c/ contagem de colónias', 0, 15, '74.01.00.21');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Coprocultura (incl.Pesq.de Salmonella, Shigella e Staphylococcus)', 0, 20, '74.01.00.22');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Corynebacterium diphteriae (Pesquisa com Exame Cultural de...) Ver Cód.74.01.00.08', 0, 0, '74.01.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Eosinófilos (pesquisa de...)', 0, 5, '74.01.00.24');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Escherichia coli enteropatogénica (Exame Cultural e Identificação Serológica)', 0, 40, '74.01.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espermocultura', 0, 12, '74.01.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estreptococos (Identificação Imunológica dos...)', 0, 20, '74.01.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estreptococos Beta-hemolíticos (Pesquisa do Grupo A)', 0, 6, '74.01.00.28');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Exame Bacteriológico de Fezes (incl.Pesq. de Salmonella,Shigella e Staphylococcus) Ver Cód.74.01.00.22', 0,
   0, '74.01.00.29');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Hansen (Pesquisa de Bacilos de...) - ver cód. 74.01.00.09', 0, 0, '74.01.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Helicobacter (Exame cultural e Identificação)', 0, 40, '74.01.00.31');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Hemocultura (inclui estudo em anaerobiose e respectivas subculturas)', 0, 35, '74.01.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemocultura (incluindo 3 subculturas)', 0, 30, '74.01.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Inoculação no cobaio', 0, 20, '74.01.00.34');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Legionella sp-Pesq. e identif. (Cult.e Serologia por Imunofluorescência)', 0, 100, '74.01.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Listeria (exame cultural e identificação)', 0, 40, '74.01.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mielocultura (sem colheita)', 0, 40, '74.01.00.37');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Mycobacterium leprae (Pesquisa de...) - ver cód. 74.01.00.09', 0, 0, '74.01.00.38');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Mycobacterium tuberculosis (Exame Directo com e sem Homogenização) Ver Cód. 74.01.00.06', 0, 0,
   '74.01.00.39');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Mycobacterium tuberculosis (ExameDirecto e Cultural)- Ver Cód. 74.01.00.07', 0, 0, '74.01.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mycoplasma urealyticum (Exame Cultural)', 0, 40, '74.01.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neisseria gonorrhoae (exame directo e cultural)', 0, 20, '74.01.00.42');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neisseria meningitidis (exame directo e cultural)', 0, 20, '74.01.00.43');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'PCR (Polymerase chain Reaction) para pesquisa e identificação de bacteria', 0, 230, '74.01.00.44');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Pesquisa Chlamydia Trachomatis por IF. Ver Cód.74.01.00.18', 0, 0, '74.01.00.45');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Salmonella e Shigella (Exame Cultural e Identificação c/serotipagem)', 0, 40, '74.01.00.46');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Staphylococcus (Exame Cultural e identificação da espécie)', 0, 30, '74.01.00.47');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Streptococcus beta haemoliticcus (Exame Cultural e Identificação serológica)', 0, 30, '74.01.00.48');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Teste de Sensibilidade aos Quimioterápios p’ Bacilos ácido-resistentes - Ver Cód.74.01.00.03', 0, 0,
   '74.01.00.49');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Treponema (Pesquisa microscópica em fundo escuro do...)', 0, 6, '74.01.00.50');
INSERT INTO ProcedureType VALUES (DEFAULT, 'T.S.A. = Antibiograma- Ver Cód. 74.01.00.02', 0, 0, '74.01.00.51');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ureaplasma urealyticum (Exame Cultural)- Ver Cód. 74.01.00.41', 0, 0, '74.01.00.52');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vibrio cholerae (Exame Cultural e Identificação)', 0, 50, '74.01.00.53');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Yersinia (Exame Cultural e Identificação)', 0, 40, '74.01.00.54');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Estudo de sindrome febril indeterminado - (exames executados+valor da consulta) Ver Cód. 01.00.00.03 ou 01.00.00.04',
                                  0, 0, '74.01.00.55');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame micológico directo', 0, 3, '74.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame micológico (Directo, cultura e identificação)', 0, 30, '74.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Filaria (Pesquisa de...)', 0, 15, '74.03.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Giardia lamblia (pesquisa no liquido de lavagem duodenal)-sem colheita', 0, 5, '74.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Leishmania (Pesquisa de...)', 0, 15, '74.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parasitológico (Exame...) com e sem Enriquecimento', 0, 10, '74.03.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Parasitológico (Exame...) por I.F.p’ sua identificação, cada', 0, 30, '74.03.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Pesquisa de Ovos, Quistos e Parasitas nas Fezes (cada amostra)', 0, 6, '74.03.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plasmódio (pesquisa e Identificação de...)', 0, 15, '74.03.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toxoplasma (Pesquisa de...)', 0, 15, '74.03.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trypanossoma (Pesquisa de...)', 0, 15, '74.03.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rotavirus (Determinação', 0, 50, '74.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cultura de vírus não orientada e identificação', 0, 150, '74.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cultura de vírus orientada e identificação', 0, 100, '74.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rotavirus (Pesquisa por Hemaglutinação...)', 0, 25, '74.04.00.04');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Vírus (Colheita,isolamento e identificação em cult.cel.de...)', 0, 84, '74.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de vírus por técnica de aglutinação', 0, 10, '74.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vírus (Identificaqão por I.F. ou ELISA...), cada', 0, 34, '74.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de vírus por técnica de imunofluorescência', 0, 20, '74.04.00.08');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Vírus Responsáveis por Inf.respiratórias (Pesq.por I.F.ou ELISA), cada', 0, 84, '74.04.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de vírus por técnica de E.I.A.', 0, 30, '74.04.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de vírus por microscopia electrónica', 0, 100, '74.04.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vírus Sincicial (Pesquisa por I.F. ou ELISA do ...)', 0, 84, '74.04.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de vírus por técnica de PCR', 0, 230, '74.04.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'HBV - Pesquisa de ADN do vírus B da hepatite por PCR ou técnica afim', 0, 150, '74.04.00.14');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'HCV - Pesquisa de ARN do vírus C da hepatite por RT-PCR ou outra técnica de amplificação', 0, 200,
   '74.04.00.15');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'HDV - Pesquisa de ADN do vírus D da hepatite por PCR ou outra técnica de amplificação', 0, 200,
   '74.04.00.16');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'HEV - Pesquisa de ADN do vírus E da hepatite por PCR ou outra técnica de amplificação', 0, 200,
   '74.04.00.17');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'HIV 1 - Pesquisa de ARN do vírus 1 da Imunodeficiência humana por RT-PCR ou técnica similar', 0, 200,
   '74.04.00.18');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'HIV 2 - Pesquisa de ARN do vírus 2 da imunodeficiência humana por RT-PCR ou técnica similar', 0, 200,
   '74.04.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'HCV (Quantificação da virémia ou “carga viral”)', 0, 300, '74.04.00.20');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'HIV 1 (Quantificação do ARN do vírus ou “carga viral”)', 0, 300, '74.04.00.21');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Outras quantificações de ARN viral em amostras biológicas', 0, 300, '74.04.00.22');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Outras quantificações de ADN viral em amostras biológicas', 0, 300, '74.04.00.23');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Genotipagem do vírus C da hepatite com recurso a técnicas de RT-PCR e sondas moleculares específicas', 0,
   300, '74.04.00.24');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos anti-leucocitários ou anti-plaquetários (cada)', 0, 100, '75.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antigénio HLA (Determinação da presença de um...)', 0, 40, '75.01.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Citotoxicidade-Celular Mediada por Anticorpos (ADCC)', 0, 100, '75.01.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cultura linfocitária mista entre linfócitos de 2 individuos (MLC)', 0, 80, '75.01.00.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cultura linfocitária mista entre linfócitos de 2 indivíduos (MLC) - cada dador adicional', 0, 40,
   '75.01.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Desgranulação dos Basófilos (Teste da...), cada antigénio', 0, 50, '75.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Redução do NBT por leucócitos - Teste do NBT', 0, 12, '75.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'HLA classe II (HLA-DR, DQ, DP), cada grupo', 0, 70, '75.01.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Iso-Hemaglutininas Naturais (Titulação das...)', 0, 10, '75.01.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova cutânea de hipersensibilidade retardada (PCHR), mínimo 4 antigénios', 0, 40, '75.01.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Linfócitos - Resposta a Antigénios ‘’in vitro’’ por estimulação em cultura', 0, 100, '75.01.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Linfócitos B - Detecção Ig’s da Superf. Da Memb. (Sig’s-IF), cada anti-soro', 0, 50, '75.01.00.13');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Linfócitos B - imunoglobulinas (Clg’s) intra-citoplasmáticas (Determ. Das ...),cada anti-soro', 0, 50,
   '75.01.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Linfócitos B - ind. Blástica por mitogénio, cada mitogénio', 0, 100, '75.01.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfócitos B - Receptores Fc (Estudos dos...)', 0, 50, '75.01.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Leucócitos - Determinação dos receptores celulares', 0, 50, '75.01.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Linfócitos B - Rosetas espontâneas com eritrócitos de ratinho', 0, 25, '75.01.00.18');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Linfócitos B - Síntese das Imunoglobulinas (Ig’s) ‘’in vitro’’', 0, 200, '75.01.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Citotoxicidade celular', 0, 100, '75.01.00.20');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Linfócitos T - Inducção Blástica por mitogénios (PHA, Com A, PWN), resp. a cada', 0, 100, '75.01.00.21');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Linfócitos T - Inibição da Migração após Estim. Por Mitogénios', 0, 80, '75.01.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfócitos T - Linfólise Med. Por Células', 0, 100, '75.01.00.23');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Linfócitos T - Rosetas espontâneas (E), com eritrócitos de carneiro', 0, 25, '75.01.00.24');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Quantificação de populações celulares (linfocitárias/outras) com anticorpos monoclonais, cada marcador', 0,
   50, '75.01.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Test Linfocitário de Pré-Estimulação PTL', 0, 120, '75.01.00.26');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Atc. Anti-Plaq. (Pesquisa contra painel plaq. C/HLA)', 0, 50, '75.01.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Avaliação da paternidade, indíce de probabilidade por estudo grupos sanguíneos HW/Rh/Duffy/Lewis/Kell/P/MN/Ss/HLA A, B, C, DR',
                                  0, 200, '75.01.00.28');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Estudo da função fagocítica dos leucócitos (neutrófilos, Monócitos, Macrófagos), cada', 0, 80,
   '75.01.00.29');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Estudo da função fagocítica e microbiocida dos leucócitos (neutrófilos, Monócitos, Macrófagos), cada', 0,
   100, '75.01.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Libertação leucocitária de histamina (Prova de)', 0, 50, '75.01.00.31');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Quimiotaxia de células fagociticas (Neutrófilos/Monócitos/Macrófagos) - cada linha celular', 0, 80,
   '75.01.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tipagem HLA classe I (A,B e C)', 0, 100, '75.01.00.33');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Estudo de doença imunológica - (exames executados+valor da consulta) ver cód 01.00.00.03 ou 01.00.00.04',
   0, 0, '75.01.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tipagem de Alótipos de Imunoglobulinas (Gm/Inu/Gc)', 0, 50, '75.02.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cadeias leves de imunoglobulinas (Kappa e Lambda) na urina - Dos., cada', 0, 30, '75.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Beta-1-Glicoproteína', 0, 50, '75.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Beta-2-Microglobina', 0, 50, '75.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Inactivador da esterase do C1', 0, 20, '75.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'C’3 (C’3c)', 0, 12, '75.02.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'C’3 (inactivador de...)', 0, 20, '75.02.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'C’3 PA (PRO-ACTIVADOR)', 0, 20, '75.02.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'C’4', 0, 12, '75.02.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Complemento, factores (C1q, C2, C5, C6, C7, C8 e C9)', 0, 30, '75.02.00.10');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Complemento total (Título de actividade hemolítica - CH 50), via clássica/via alterna, cada', 0, 40,
   '75.02.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Complemento (fragmentos activados: C3a, C5a, etc), cada', 0, 80, '75.02.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioglobulinas (Caracterização Imunoquimica)', 0, 20, '75.02.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Crioglobulinas (pesquisa e caracterização imunoquímica, se necessário)', 0, 20, '75.02.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioglobulinas (Pesquisa de...)', 0, 5, '75.02.00.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Imunocomplexos, identificação dos componentes após precipitação pelo PEG', 0, 25, '75.02.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Imunocomplexos (Téc.do Cons.do Complemento, medida pelo CH50)', 0, 25, '75.02.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imunocomplexos (Técnica de Fixação C’1q )', 0, 30, '75.02.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imunoelectroforese com Anti-Soro Polivalente', 0, 15, '75.02.00.19');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Imunoelectroforese das proteínas (Total + IgG + IgA + IgM + C.L. Kappa + C.L. lambda)', 0, 40,
   '75.02.00.20');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Imunoelectroforese das proteinas com concentração prévia da amostra (LCR, urina,...)', 0, 50,
   '75.02.00.21');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Electroimunofixação das proteinas (Total+IgG + IgA + IgM + C.L. Kappa + C.L. lambda)', 0, 40,
   '75.02.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imunoglobulina A (IgA)', 0, 10, '75.02.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imunoglobulina A - secretora (pesq.)', 0, 10, '75.02.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imunoglobulina D (IgD)', 0, 25, '75.02.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imunoglobulina E (IgE)', 0, 25, '75.02.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imunoglobulina G (IgG)', 0, 10, '75.02.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imunoglobulina M (IgM)', 0, 10, '75.02.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imunoglobulinas (IgA+IgG+IgM)', 0, 30, '75.02.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'IgG1', 0, 50, '75.02.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'IgG2', 0, 50, '75.02.00.31');
INSERT INTO ProcedureType VALUES (DEFAULT, 'IgG3', 0, 50, '75.02.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'IgG4', 0, 50, '75.02.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Proteína C- Reactiva (Doseamento da...)', 0, 20, '75.02.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova de Sia', 0, 1, '75.02.00.35');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'IgE específica para um determinado alergénio (RAST Test), cada', 0, 54, '75.02.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Waaler-Rose (Reacção de...)', 0, 15, '75.02.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-1 Anti-Tripsina', 0, 12, '75.02.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-1 Anti-Tripsina (fenótipos)', 0, 40, '75.02.00.39');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-1 Glicoproteina ácida (ou orosomucóide)', 0, 12, '75.02.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-2 Macroglobulina', 0, 12, '75.02.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos IgG4 específicos, cada antigénio', 0, 54, '75.02.00.42');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cadeias leves de imunoglobulinas (Kappa e lambda) - dos., cada', 0, 30, '75.02.00.43');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Citocinas (Interfeões, interleucinas, outras), cada', 0, 60, '75.02.00.44');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Complemento - Fragmentos de activação (C3d, C4d, MAC, outros), cada', 0, 50, '75.02.00.45');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electroimunofixação das proteinas após concentração, (mínimo 4 anti-soros)', 0, 50, '75.02.00.46');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Factor reumatóide, doseamento', 0, 20, '75.02.00.47');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Factor reumatóide, doseamento com determinação do tipo de cadeia pesada (A, G e M) - cada', 0, 50,
   '75.02.00.48');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histamina', 0, 50, '75.02.00.49');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Identificação precipitinas, cada', 0, 20, '75.02.00.50');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Imunocomplexos circulantes (técnica de inibição de factor reumatóide)', 0, 30, '75.02.00.51');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Imunocomplexos circulantes (técnica de nefelometria simples)', 0, 20, '75.02.00.52');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Inactivador da esterase do C1, teste funcional', 0, 60, '75.02.00.53');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Metil-histamina', 0, 50, '75.02.00.54');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mieloperoxidase (doseamento)', 0, 50, '75.02.00.55');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Proteina catiónica do eosinófilo (ECP)', 0, 50, '75.02.00.56');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Proteina X do eosinófilo', 0, 50, '75.02.00.57');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Receptores solúveis de citocinas', 0, 60, '75.02.00.58');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sub-classes de Imunoglobulina A (IgA1 e IgA2), cada', 0, 50, '75.02.00.59');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Triptase', 0, 50, '75.02.00.60');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'ANCA = Anticorpos anti-citoplasma dos neutrófilos (IF)', 0, 50, '75.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-AND nativo = ANTI-DNA ou anti-AND', 0, 35, '75.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-cardiolipina (IgG, IgA, IgM), cada', 0, 50, '75.03.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos Anti-Célula Parietal Gástrica (c/tit. Quando necessário)', 0, 50, '75.03.00.04');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Anticorpos anti-antigénios nucleares extraíveis (ENA) - Sm/Rnp/SS-A/SS-B/ outros', 0, 50, '75.03.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Esperma', 0, 50, '75.03.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Gliadina IgA ou IgG, cada', 0, 50, '75.03.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Histonas', 0, 50, '75.03.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Ilhéus de Langerhans', 0, 50, '75.03.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Insulina', 0, 60, '75.03.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-LC1 (citosol hepático)', 0, 60, '75.03.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Membrana Basal Glomérulo Renal', 0, 50, '75.03.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Membrana Basal Tubular', 0, 50, '75.03.00.13');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos Anti-Mitocondria por I.F. (c/ titulação, se positivos)', 0, 30, '75.03.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos Anti-Músculo Estriado por I.F. (c/ titulaçâo, se positivos)', 0, 50, '75.03.00.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos Anti-Músculo Liso por I.F. (c/ titulaqão, se positivos)', 0, 30, '75.03.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos Anti-Nucleares por I.F. (c/ titulação, se positivos)', 0, 30, '75.03.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticórpos Anti-Ovário', 0, 50, '75.03.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Pâncreas Exócrino', 0, 50, '75.03.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Queratina', 0, 50, '75.03.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Reticulina', 0, 50, '75.03.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Supra-Renal', 0, 50, '75.03.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Testículo', 0, 50, '75.03.00.23');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos Anti-Tiroideus (Anti-Tiroglobul.+Anti-Micross,)', 0, 50, '75.03.00.24');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-Centómetro', 0, 50, '75.03.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-LKM - anti-liver, kidney microsome', 0, 60, '75.03.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'TRABs - anticorpos antireceptor de TSH', 0, 60, '75.03.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-ducto salivar', 0, 50, '75.03.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-elastina', 0, 50, '75.03.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-endomísio', 0, 50, '75.03.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-factor intrínseco', 0, 60, '75.03.00.31');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos anti-fosfolipídeo (IgG, IgM ou IGA), cada', 0, 50, '75.03.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-hormona do crescimento (anti-HGH)', 0, 60, '75.03.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-LKM', 0, 50, '75.03.00.34');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-Membrana Basal Glomerular (GBM)', 0, 50, '75.03.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-mieloperoxidase (MPO)', 0, 50, '75.03.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-mitocôndriais (M1, M2, outros)', 0, 50, '75.03.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-proteinase 3 (PR3)', 0, 50, '75.03.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-receptor de acetilcolina', 0, 150, '75.03.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-receptor da insulina', 0, 60, '75.03.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-SCL70', 0, 50, '75.03.00.43');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anti-HVC', 0, 120, '75.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anti-HVD - Anticorpos Anti-Hepatite Delta', 0, 50, '75.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anti-HVD IgM - Anticorpos Anti-Hepatite Delta (IgM)', 0, 60, '75.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anti-HBc = Anticorpos Anti-HBc', 0, 40, '75.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anti-HBc IgM = Anticorpos Anti-HBc IgM', 0, 50, '75.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anti-HBe = Anticorpos Anti-Hbe', 0, 40, '75.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anti-HBs = Anticorpos anti-HBs', 0, 30, '75.04.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anti-HVA IgG ou IgM = Anticorpos anti-HVA IgM ou IgG, cada', 0, 40, '75.04.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-HBc = Ver Anti-HBc', 0, 0, '75.04.00.09');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos anti-HBc IgM = Ver Anti—HBc IgM Ver Cód. 75.04.00.05', 0, 0, '75.04.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos anti-HBe = Ver Anti-Hbe Ver Cód. 75.04.00.06', 0, 0, '75.04.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos Anti-HBs = Ver Anti-HBs (RIA ou ELISA) Ver Cód. 75.04.00.07', 0, 0, '75.04.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti HC (Hepatite C) (IgG ou IgM) cada', 0, 40, '75.04.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti HC (Hepatite C) Test Confirmativo', 0, 60, '75.04.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti Hepatite Delta', 0, 50, '75.04.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Adenovirus (Titulação por FC)', 0, 80, '75.04.00.16');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Anticorpos Anti Agentes Microbianos, Viricos, Parasitários ou Fúngicos não icluídos nesta tabela', 0, 40,
   '75.04.00.17');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-Brucella', 0, 40, '75.04.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-Citomegalovirus', 0, 50, '75.04.00.19');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-Clamydia Trachomatis', 0, 50, '75.04.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-Coxiella Burnetii = Febre Q', 0, 50, '75.04.00.21');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Diftéricos', 0, 30, '75.04.00.22');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Enterovirus', 0, 50, '75.04.00.23');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Epstein-Barr-Anti-VCA-EBNA', 0, 60, '75.04.00.24');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos anti-vírus de Epstein-Barr (IgG ou IgM), cada', 0, 60, '75.04.00.25');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Epstein-Barr-Anti-VCA-Lg M', 0, 60, '75.04.00.26');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-Equinococo', 0, 40, '75.04.00.27');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Equinococo (Hema glutinação)', 0, 13, '75.04.00.28');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Equinococo (IF)', 0, 30, '75.04.00.29');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Estreptodornase', 0, 20, '75.04.00.30');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Exoenzimas Estreptocócicos', 0, 10, '75.04.00.31');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos Anti-Exoenzimas Estreptocócicos (Titulação)', 0, 30, '75.04.00.32');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Febre Q Ver Cód. 75.04.00.21', 0, 0, '75.04.00.33');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-HIV (HIV1 + HIV2)', 0, 100, '75.04.00.34');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos Anti-HIV (Test Confirmativo por Blotting)', 0, 190, '75.04.00.35');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-HTLV (HTLV1 + HTLV2)', 0, 100, '75.04.00.36');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-HVA IgG (ELISA)', 0, 40, '75.04.00.37');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-HVA IgM (ELISA)', 0, 40, '75.04.00.38');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Hialuronidase', 0, 13, '75.04.00.39');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos Anti-Legionella (Tit. para 11 antigénios)', 0, 84, '75.04.00.40');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Leptospira', 0, 80, '75.04.00.41');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Listéria Monocytogenes', 0, 60, '75.04.00.42');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Mycoplasma Pneumoniae', 0, 80, '75.04.00.43');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Ornitose', 0, 80, '75.04.00.44');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-P 24', 0, 75, '75.04.00.45');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-Plasmodium', 0, 80, '75.04.00.46');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos Anti-Ricketsia (Tit. por Imunofluorescência para 3 espécies)', 0, 42, '75.04.00.47');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Rotavirus', 0, 100, '75.04.00.48');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Tetânicos (Inc. Tit. se necessário)', 0, 30, '75.04.00.49');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Toxoplasma (Inc. Tit.) IgG', 0, 30, '75.04.00.50');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Toxoplasma', 0, 60, '75.04.00.51');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Toxoplasma (Inc. Tit.) IgM', 0, 40, '75.04.00.52');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos anti-Treponema palidum (Inc.Tit.) Ver TPHA', 0, 50, '75.04.00.53');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Treponema Palidum = FTA4ABS (IF)', 0, 50, '75.04.00.54');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti - Tripanossoma', 0, 80, '75.04.00.55');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Vírus da Coriomeningite Linfocítica', 0, 50, '75.04.00.56');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Vírus da Influenza', 0, 50, '75.04.00.57');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos Anti-Vírus da Mononucleo se Infecciosa (Prova em Lâmina)', 0, 6, '75.04.00.58');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Vírus da Papeira', 0, 34, '75.04.00.59');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Vírus Parainfluenza', 0, 50, '75.04.00.60');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Vírus da Rubéola (Inc. Tit.) IgM', 0, 30, '75.04.00.61');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Vírus da Rubéola (Inc. Tit.) IgG', 0, 20, '75.04.00.62');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Vírus da Varicela', 0, 50, '75.04.00.63');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Vírus do Herpes I', 0, 50, '75.04.00.64');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Vírus do Herpes II', 0, 50, '75.04.00.65');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos Anti-Vírus do Sarampo', 0, 50, '75.04.00.66');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos para qualq. outro ag.Microb. (Bact., Virus, Paras.)', 0, 40, '75.04.00.67');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antiestreptolisina O (Pesquisa)', 0, 2, '75.04.00.68');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Anticorpos anti-Antiestreptolisina O (titulação/doseamento) = TASO', 0, 5, '75.04.00.69');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antigénio Vírus de Epstein – Barr', 0, 50, '75.04.00.70');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antigénio HBe = HBe Ag', 0, 30, '75.04.00.71');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antigénio HBs = HBs Ag', 0, 30, '75.04.00.72');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antigénio P 24', 0, 150, '75.04.00.73');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antigénio P 24 – (Pesquisa)', 0, 75, '75.04.00.74');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antigénio Rotavírus', 0, 50, '75.04.00.75');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Blotting-Western; Southern; Northen (Técnicas de) para identificação de antigénios ou anticorpos', 0, 190,
   '75.04.00.76');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Paul-Bunnel (Reacção de...)', 0, 8, '75.04.00.77');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'RPR (Método, rápido para pesq. de reaginas sifilíticas)', 0, 5, '75.04.00.78');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reacção de Casoni (não inclui ampola)', 0, 6, '75.04.00.79');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reacção de fix. compl. para o Mycoplasma pneumoniae', 0, 9, '75.04.00.80');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reacção de Hudlesson', 0, 5, '75.04.00.81');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reacção de Paul-Bunnell (Ver Paul Bunnell) Ver Cód. 75.04.00.77', 0, 0, '75.04.00.82');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reacção de Weil-Felix (3 antigénios)', 0, 10, '75.04.00.83');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reacção de Weinberg', 0, 10, '75.04.00.84');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reacção de Widal (4 antigénios)', 0, 8, '75.04.00.85');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reacção de Wright Ver Cód. 75.04.00.81', 0, 0, '75.04.00.86');
INSERT INTO ProcedureType VALUES (DEFAULT, 'VDRL (Reacção do...)', 0, 3, '75.04.00.87');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reacção para Fasciola Hepática (Fascioliase)', 0, 42, '75.04.00.88');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Rotavirus, (Antigénio do...) pelo método de ELISA (Ver Antigénio do Rotavirus) Ver Cód. 75.04.00.75', 0, 0,
   '75.04.00.89');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'TASO - Titulo de Antiestreptolisina O - ver o cód. 70.04.00.69', 0, 0, '75.04.00.90');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Teste Confirmativo da HC (Hepatite C)', 0, 120, '75.04.00.91');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Monospot-test ou equivalente = Antic. Anti-Virus da Monon. Inf. (p. lamina)', 0, 6, '75.04.00.92');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toxoplasmose – Anticorpos – Lg G', 0, 30, '75.04.00.93');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anticorpos anti-Toxoplasmose IgG + IgM', 0, 60, '75.04.00.94');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toxoplasmose – Anticorpos – Lg M', 0, 40, '75.04.00.95');
INSERT INTO ProcedureType VALUES (DEFAULT, 'TPHA - ver cód. 75.04.00.53', 0, 0, '75.04.00.96');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'VDRL (incl. titulação, se necessário) - ver cód. 74.04.00.87', 0, 0, '75.04.00.97');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Weil-Felix (reacção de...) Ver Cód. 75.04.00.83', 0, 0, '75.04.00.98');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Weinberg (Reacção de...) Ver Cód. 75.04.00.84', 0, 0, '75.04.00.99');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Western Blotting (técnicas de ) Ver Cód. 75.04.00.35', 0, 0, '75.04.01.00');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Widal (Reacção de...) (4 antigénios) Ver cód. 75.04.00.85', 0, 0, '75.04.01.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Wright (Reacção de...) Ver Cód. 75.04.00.81', 0, 0, '75.04.01.02');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Diagnóstico serológico da Hepatite B (HBs + Anti-HBs + HBe + Anti-Hbe + Anti-HBc)', 0, 170, '75.04.01.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alfa-Fetoproteína', 0, 30, '75.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antigénio Carcino-Embrionário (CEA)', 0, 50, '75.05.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Antigénio Específico da Próstata = SPA (RIA/EIA) = PSA', 0, 50, '75.05.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'CA – 125', 0, 50, '75.05.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'CA – 19.9', 0, 50, '75.05.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'CA 15.3', 0, 50, '75.05.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'CA 19.5', 0, 50, '75.05.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'CA 50', 0, 50, '75.05.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'CA 54.9', 0, 50, '75.05.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'CA 72.4', 0, 50, '75.05.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'MCA', 0, 50, '75.05.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'NSE', 0, 50, '75.05.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'PSA = SPA Ver Cód. 75.05.00.03', 0, 0, '75.05.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fosfatase ácida prostática - PAP', 0, 50, '75.05.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Marcadores tumorais não incluidos nesta tabela', 0, 50, '75.05.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'PSA livre', 0, 50, '75.05.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ionograma (Na, K, Cl)', 0, 9, '75.05.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Determinação Indirecta dos Cloretos pela Prova da placa (suor)', 0, 3, '76.00.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Esperma-Ex.Macrosc. (Caract.Físicas, Coagulação-Liquefação e Volume)', 0, 10, '76.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esperma-Teste de Sims-Huhner (teste pós-coito)', 0, 9, '76.00.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Espermograma (contagem, exame morfológico, motilidade)', 0, 20, '76.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imobilizinas-cada', 0, 15, '76.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Líquido Amniótico (espectrofotometria do...)', 0, 10, '76.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Líquido Amniótico (relação lecitina esfingomielina)', 0, 20, '76.00.00.07');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Líquido Cérebro Espinal = Liquor (Ex.Macrosc.,Cont.de células)', 0, 12, '76.00.00.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Líquido Pericardico, peritoneal ou pleural (ex. quimicos ou microbiológicos) ver secção respectiva', 0, 0,
   '76.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Líquido pericárdico, peritoneal ou pleural (ex.macroscopico, ex.microscopico, cont cel.e cont.diferencial)',
                                  0, 12, '76.00.00.10');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Líquido Pericárdico Peritoneal pleural (Ex.Quim.+Microb.+Cel.cìif.)', 0, 30, '76.00.00.11');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Líquido Sinovial (Ex.Macrosc.,Viscosidade e Test de Coagulação)', 0, 40, '76.00.00.12');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Líquido Sinovial (Ex.Quimico, Imunológicos ou Microbiológicos)', 0, 30, '76.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mucopolisacáridos (pesquisa de )', 0, 5, '76.00.00.14');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Razão Palmitica/Estearica', 0, 13, '76.00.00.15');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Suco Gástrico e/ou Duodenal (Exame Macroscópico e Químico)', 0, 18, '76.00.00.16');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Suco Gástrico-Prova de Estimulação pela Hipoglicemia induz. pela insulina', 3, 50, '76.00.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Suco Gástrico-Prova de Estimulação pela Pentagastrina', 3, 55, '76.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Suco Gástrico-Prova de Estimulação pelo Histalog', 3, 55, '76.00.00.19');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Suor-Det. Cloretos ou Sódio no suor após Estim. por Iontof.c/Pilocarp.', 1, 20, '76.00.00.20');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Deslocações domiciliárias urbanas', 4, 0, '76.01.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Deslocações domiciliárias fora de área urbana+ 25%/litro gasolina super por Km', 4, 0, '76.01.00.02');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção do conteúdo gástrico (mais de uma colheita com uma única intubação)', 9, 0, '76.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colheita de faneras', 1, 0, '76.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção óssea para extracção de medula', 6, 0, '76.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exsudados nasofaringeos (colheita)', 2, 0, '76.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exsudados purulentos superficiais (colheita)', 1, 0, '76.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exsudados vaginais e ureterais (colheita)', 2, 0, '76.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames histológicos', 10, 20, '80.00.00.01');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exames cito-histológicos (exame citológico com inclusão)', 10, 20, '80.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames citológicos', 5, 10, '80.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames citohormonais por esfregaços seriados', 10, 20, '80.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames histológicos extemporâneos per-operatórios', 40, 60, '80.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames ultraestruturais (microscopia electrónica)', 50, 50, '80.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diagnóstico imuno-cito-químico', 50, 50, '80.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de alta resoluçâo em fibro blastos', 20, 200, '81.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de alta resolução em linfocitos com PHA', 20, 120, '81.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de alta resolução em linfocitos sem PHA', 20, 130, '81.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de células amnióticas', 20, 200, '81.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de fibroblastos', 0, 150, '81.00.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de linfócitos c/PHA', 0, 75, '81.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de linfócitos s/PHA', 0, 85, '81.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo da medula óssea c/PHA', 20, 120, '81.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo da medula óssea s/PHA', 20, 130, '81.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de meioses (Ver Cód. 81.00.00.17)', 0, 0, '81.00.00.10');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de vilosidades coriónicas', 20, 250, '81.00.00.11');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conteúdo mediano de DNA nas células tumorais', 0, 20, '81.00.00.12');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cromatina sexual X ou Y no raspado lingual', 0, 8, '81.00.00.13');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cromatina sexual no ex. vaginal', 0, 8, '81.00.00.14');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'DNA em células tumorais ver conteúdo mediano de DNA (Ver Cód. 81.00.00.12)', 0, 0, '81.00.00.15');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo cromossómico ver cariótipo', 0, 0, '81.00.00.16');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de meioses no esperma', 0, 75, '81.00.00.17');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo em biópsia testicular, pele, tecido de aborto', 20, 200, '81.00.00.18');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame de marcha com registo gráfico', 6, 10, '90.00.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame muscular com registo gráfico', 6, 10, '90.00.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Raquimetria', 6, 10, '90.00.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrodiagnóstico de estimulação', 4, 5, '90.00.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electromiografia (Ver Cód. 14.02)', 0, 0, '90.00.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ecotomografia das partes moles (Ver Cód. 62.00.00.25)', 0, 0, '90.00.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudos urodinâmicos (Ver Cód. 16.)', 0, 0, '90.00.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Provas Funcionais Respiratórias (Ver Cód. 10.01)', 0, 0, '90.00.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testes de Psicomotricidade', 25, 10, '90.00.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corrente contínua', 1, 1, '90.01.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corrente de baixa frequência', 1, 1, '90.01.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corrente de média frequência', 1, 1, '90.01.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corrente de alta frequência', 1.5, 2, '90.01.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ultra-som', 1.5, 2, '90.01.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estimulação eléctrica de pontos motores', 1.5, 2, '90.01.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Magnetoterapia', 1.5, 2, '90.01.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biofeedback', 2, 3, '90.01.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Raios infra-vermelhos', 1, 1, '90.02.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Raios ultra-violetas', 1, 1, '90.02.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laserterapia de hélio-neon', 1.5, 2, '90.02.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laserterapia de raios infra-vermelhos', 1.5, 2, '90.02.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laserterapia de hélio-neon + raios infra-vermelhos', 2, 2, '90.02.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioterapia', 1, 1, '90.03.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calor húmido', 1, 1, '90.03.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parafina', 1, 1.5, '90.03.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parafango', 1, 1.5, '90.03.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outros pelóides', 1, 1.5, '90.03.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hidrocinesiterapia', 2.5, 4, '90.04.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hidromassagem', 1.5, 4, '90.04.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Banho de contraste', 1, 2, '90.04.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Banho de turbilhão', 1, 2, '90.04.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Banhos especiais', 1, 2, '90.04.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Duches', 1.5, 3, '90.04.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tanque de hubbard', 2, 4, '90.04.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tanque de marcha', 2, 3, '90.04.00.08');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Massagem manual de uma região', 1.5, 2, '90.05.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Massagem manual de mais de uma região', 2, 2, '90.05.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Massagem com técnicas especiais', 2, 2, '90.05.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Massagem manual em imersão', 2, 2, '90.05.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vibromassagem', 1, 1, '90.05.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Massagem com vácuo', 1.5, 1, '90.05.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinesiterapia respiratória', 2, 3, '90.06.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinésiterapia vertebral', 2, 2, '90.06.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinesiterapia correctiva postural', 2, 2, '90.06.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinesiterapia pré e pós parto', 2, 2, '90.06.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fortalecimento muscular manual', 2, 2, '90.06.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mobilização articular manual', 1.5, 2, '90.06.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Técnicas especiais de Cinesiterapia', 2, 3, '90.06.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reeducação do equilíbrio e/ou marcha', 2, 2, '90.06.00.08');
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Qualquer destas modalidades terapêuticas quando feita em grupo (máximo de 6 doentes)', 1, 2,
   '90.06.00.09');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aerossóis', 1, 1, '90.07.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aerossóis ultra-sónicos', 1.5, 2, '90.07.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'IPPB', 1.5, 2, '90.07.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oxigenoterapia', 1, 1, '90.07.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tracção vertebral mecânica', 1.5, 1, '90.08.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tracção vertebral motorizada', 1.5, 2, '90.08.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pressões alternas positivas', 1.5, 2, '90.08.00.03');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Pressões alternas positivas com monitorização contínua', 2, 5, '90.08.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fortalecimento muscular/mobilização articular', 1.5, 2, '90.08.00.05');
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fortalecimento muscular/mobilização articular com monitorização contínua', 5, 5, '90.08.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fortalecimento muscular isocinético', 5, 5, '90.08.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uso de próteses', 2, 5, '90.09.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uso de ortóteses', 2, 5, '90.09.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Actividades de vida diária', 2, 5, '90.09.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapia ocupacional', 2, 5, '90.09.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapia da fala/comunicação', 2, 5, '90.09.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Readaptação ao esforço com monitorização contínua', 6, 5, '90.09.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Manipulação vertebral', 8, 0, '90.10.00.01');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Manipulação de membros', 6, 0, '90.10.00.02');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acupuntura', 6, 0, '90.10.00.03');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração', 6, 0, '90.10.00.04');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mesoterapia', 6, 0, '90.10.00.05');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estimulação transcutânea', 5, 0, '90.10.00.06');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Confecção de ligadura funcional', 7, 0, '90.10.00.07');
INSERT INTO ProcedureType VALUES (DEFAULT, 'Confecção de ortóteses', 7, 0, '90.10.00.08');


INSERT INTO Organization VALUES (DEFAULT, 'Org');
INSERT INTO Account VALUES (DEFAULT, 'José', 'a@a.pt',
                            '445fff776df2293d242b261ba0f0d35be6c5b5a5110394fe8942a21e4d7af759fa277f608c3553ee7b3f8f64fce174b31146746ca8ef67dd37eedf70fe79ef9d',
                            'bea95c126335da5b92c91de01635311ede91a58f0ca0d9cb0344462333c35c9ef12977e976e2e8332861cff2c4efa42c653214b626ed96a76ba19ed0e414b71a',
                            '123456789',
                            DEFAULT,
                            CURRENT_DATE + INTERVAL '1 year',
                            -1);

INSERT INTO Account VALUES (DEFAULT, 'b', 'b@b.pt',
                            '6b9f904771f21b6d9d017582d9a001c41eef2dd5128ff80fd1985d8f1f2e62fe5e23b4e77c16adea3e86eaf8353acc55e93f982419c9f87356e3a805ef7fae16',
                            'beb281b875e9c11fb6f8290fb7952e6da45dcd50f903299b374c6d8c816eca7dfa66c9d2b70bd3900a0b9c666eaf656505739c370ca2f2a788c33e1ff16a4736',
                            '987654321',
                            DEFAULT,
                            CURRENT_DATE + INTERVAL '1 year',
                            -1);

INSERT INTO Account VALUES (DEFAULT, 'c', 'c@c.pt',
                            'b13188a1fb01f1b9c41e9229dacf2c030d6ea18bd14c0d462dc488e5bbe7fb28d7a33ac16a8bc5989ea7e1af2d4a0476cfeea2b3e4c82253cd70e42688e60988',
                            '6deba07b456d9594d85baa07c911bd7ae9ca659ed2b16760d78b6c443252ac0d2357b8363780b1dc47eccc49b12989a61da2727d4519b241a5eb5768046a72e1',
                            '012345678',
                            DEFAULT);

INSERT INTO PrivatePayer VALUES (DEFAULT, 1, 'Aquele Mano', 5);
INSERT INTO OrgAuthorization VALUES (1, 1, 'AdminVisible');
INSERT INTO OrgInvitation VALUES (1, 1, '111111111', FALSE);
INSERT INTO OrgInvitation VALUES (1, 1, '012345678', FALSE, FALSE, '2014-06-02 20:36:43.206615');
INSERT INTO Professional
VALUES (DEFAULT, 2, 1, 'asdrubal', NULL, '123456789', '987654321', '2014-06-02 20:36:43.206615');
INSERT INTO Professional
VALUES (DEFAULT, 2, 1, 'asdrubal incompleto', NULL, NULL, '987654321', '2014-06-02 20:36:43.206615');
INSERT INTO Professional VALUES (DEFAULT, 1, 1, 'Quim Manel', NULL, NULL, '111111111', '2014-06-02 20:36:43.206615');
INSERT INTO Professional VALUES (DEFAULT, 1, 1, 'Quim Ze', NULL, NULL, NULL, '2014-06-22 20:36:43.206615');
INSERT INTO Professional VALUES (DEFAULT, 1, 1, 'Quim Ze Completo', NULL, NULL, NULL, '2014-06-12 20:36:43.206615');
INSERT INTO Professional
VALUES (DEFAULT, 1, 1, 'Quim Ze Completo', NULL, NULL, '159268753', '2014-07-02 20:36:43.206615');
INSERT INTO OrgAuthorization VALUES (1, 2, 'Visible');