DROP TABLE IF EXISTS OrgInvitation;
DROP TABLE IF EXISTS ProcedureInvitation;
DROP TABLE IF EXISTS OrgAuthorization;
DROP TABLE IF EXISTS Organization;
DROP TABLE IF EXISTS ProcedureProcedureType;
DROP TABLE IF EXISTS ProcedureAccount;
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

CREATE TYPE ProcedurePaymentStatus AS ENUM ('Recebi', 'Paguei', 'Pendente');
CREATE TYPE EntityType AS ENUM ('Hospital', 'Insurance');
CREATE TYPE OrgAuthorizationType AS ENUM ('AdminVisible', 'AdminNotVisible', 'Visible', 'NotVisible');

------------------------------------------------------------------------

CREATE DOMAIN Email VARCHAR(254)
CONSTRAINT validEmail
CHECK (VALUE ~ '^[a-zA-Z0-9._%+-]+\@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');

CREATE DOMAIN NIF CHAR(9)
CONSTRAINT validNIF
CHECK (VALUE ~ '\d{9}');

CREATE DOMAIN LicenseId CHAR(9)
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
  name           VARCHAR(40) NOT NULL,
  nif            NIF         NOT NULL,
  valuePerK      REAL
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
  name         VARCHAR(50)
);

CREATE TABLE Professional (
  idProfessional SERIAL PRIMARY KEY,
  idSpeciality   INTEGER REFERENCES Speciality (idSpeciality),
  idAccount      INTEGER NOT NULL REFERENCES Account (idAccount),
  name           VARCHAR(40),
  nif            NIF,
  licenseId      LicenseId,
  email          VARCHAR(120),
  cell           NIF,
  createdOn      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  remuneration   FLOAT
);

CREATE TABLE ProcedureType (
  idProcedureType SERIAL PRIMARY KEY,
  name            VARCHAR(256) NOT NULL,
  K               FLOAT        NOT NULL
);

CREATE TABLE Procedure (
  idProcedure       SERIAL PRIMARY KEY,
  paymentStatus     ProcedurePaymentStatus NOT NULL DEFAULT 'Pendente',
  idPrivatePayer    INTEGER REFERENCES PrivatePayer (idPrivatePayer), -- Ou um, ou outro
  idEntityPayer     INTEGER REFERENCES EntityPayer (idEntityPayer),
  idGeneral         INTEGER REFERENCES Professional (idProfessional),
  idFirstAssistant  INTEGER REFERENCES Professional (idProfessional),
  idSecondAssistant INTEGER REFERENCES Professional (idProfessional),
  idAnesthetist     INTEGER REFERENCES Professional (idProfessional),
  idInstrumentist   INTEGER REFERENCES Professional (idProfessional),
  idMaster          INTEGER REFERENCES Professional (idProfessional),
  date              DATE                   NOT NULL DEFAULT CURRENT_DATE,
  valuePerK         FLOAT,
  wasAssistant      BOOLEAN                NOT NULL DEFAULT FALSE,
  totalRemun        FLOAT DEFAULT 0,
  personalRemun     FLOAT DEFAULT 0
);

CREATE TABLE ProcedureAccount (
  idProcedure INTEGER NOT NULL REFERENCES Procedure (idProcedure) ON DELETE CASCADE,
  idAccount   INTEGER NOT NULL REFERENCES Account (idAccount) ON DELETE CASCADE,
  PRIMARY KEY (idProcedure, idAccount)
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
  idProcedure       INTEGER   NOT NULL REFERENCES Procedure (idProcedure) ON DELETE CASCADE,
  idInvitingAccount INTEGER   NOT NULL REFERENCES Account (idAccount) ON DELETE CASCADE,
  licenseIdInvited  LicenseId NOT NULL, -- Não tem referência para manter anonimato, ON DELETE CASCADE
  wasRejected       BOOL      NOT NULL DEFAULT FALSE,

  PRIMARY KEY (idProcedure, idInvitingAccount, licenseIdInvited)
);

CREATE OR REPLACE FUNCTION share_procedure_with_all(idp INTEGER, ida INTEGER)
  RETURNS VOID AS $$
DECLARE
BEGIN
  IF NOT EXISTS(SELECT
                  *
                FROM ProcedureAccount
                WHERE idprocedure = idp AND idaccount = ida)
  THEN
    RETURN;
  END IF;

  INSERT INTO ProcedureInvitation (idprocedure, idinvitingaccount, licenseidinvited)
    SELECT
      idp,
      ida,
      licenseid
    FROM ProcedureProfessional, Professional
    WHERE
      ProcedureProfessional.idprocedure = idp AND Professional.idprofessional = ProcedureProfessional.idprofessional AND
      licenseid IS NOT NULL AND NOT EXISTS(SELECT
                                             *
                                           FROM procedureinvitation
                                           WHERE procedureinvitation.idprocedure = idp AND
                                                 procedureinvitation.idInvitingAccount = ida AND
                                                 procedureinvitation.licenseidinvited = licenseid);
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_procedureaccount_trigger()
  RETURNS TRIGGER AS $$
DECLARE
BEGIN
  IF NOT EXISTS(SELECT
                  idprocedure
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
      name,
      nif,
      licenseid
    FROM Professional, Procedure
    WHERE idProcedure = NEW.idProcedure AND (
      idProfessional = idgeneral OR idProfessional = idfirstassistant OR idProfessional = idsecondassistant OR
      idProfessional = idinstrumentist OR idProfessional = idanesthetist) AND Professional.idAccount != NEW.idAccount;

  INSERT INTO PrivatePayer (idaccount, name, nif, valuePerK)
    SELECT
      NEW.idaccount,
      name,
      nif,
      PrivatePayer.valueperk
    FROM PrivatePayer, Procedure
    WHERE idProcedure = NEW.idProcedure AND PrivatePayer.idPrivatePayer = Procedure.idPrivatePayer AND
          idAccount != NEW.idAccount;

  INSERT INTO EntityPayer (idaccount, name, contractStart, contractEnd, type, nif, valuePerK)
    SELECT
      NEW.idaccount,
      name,
      contractStart,
      contractEnd,
      type,
      nif,
      EntityPayer.valuePerK
    FROM EntityPayer, Procedure
    WHERE idProcedure = NEW.idProcedure AND EntityPayer.idEntityPayer = Procedure.idPrivatePayer AND
          idAccount != NEW.idAccount;


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

INSERT INTO Organization VALUES (DEFAULT, 'Org');

INSERT INTO Account VALUES (DEFAULT, 'José', 'a@a.pt',
                            '445fff776df2293d242b261ba0f0d35be6c5b5a5110394fe8942a21e4d7af759fa277f608c3553ee7b3f8f64fce174b31146746ca8ef67dd37eedf70fe79ef9d',
                            'bea95c126335da5b92c91de01635311ede91a58f0ca0d9cb0344462333c35c9ef12977e976e2e8332861cff2c4efa42c653214b626ed96a76ba19ed0e414b71a',
                            '123456789');

INSERT INTO Account VALUES (DEFAULT, 'b', 'b@b.pt',
                            '6b9f904771f21b6d9d017582d9a001c41eef2dd5128ff80fd1985d8f1f2e62fe5e23b4e77c16adea3e86eaf8353acc55e93f982419c9f87356e3a805ef7fae16',
                            'beb281b875e9c11fb6f8290fb7952e6da45dcd50f903299b374c6d8c816eca7dfa66c9d2b70bd3900a0b9c666eaf656505739c370ca2f2a788c33e1ff16a4736',
                            '987654321');

INSERT INTO Account VALUES (DEFAULT, 'c', 'c@c.pt',
                            'b13188a1fb01f1b9c41e9229dacf2c030d6ea18bd14c0d462dc488e5bbe7fb28d7a33ac16a8bc5989ea7e1af2d4a0476cfeea2b3e4c82253cd70e42688e60988',
                            '6deba07b456d9594d85baa07c911bd7ae9ca659ed2b16760d78b6c443252ac0d2357b8363780b1dc47eccc49b12989a61da2727d4519b241a5eb5768046a72e1',
                            '012345678');

INSERT INTO PrivatePayer VALUES (DEFAULT, 1, 'Aquele Mano', '135792468', 5);
INSERT INTO EntityPayer VALUES (DEFAULT, 1, 'Seguro', NULL, NULL, 'Insurance', '123456789', NULL);
INSERT INTO EntityPayer VALUES (DEFAULT, 1, 'Hospital', '2014-07-01', '2014-07-02', 'Hospital', '123456789', 10);
INSERT INTO OrgAuthorization VALUES (1, 1, 'AdminVisible');
INSERT INTO OrgInvitation VALUES (1, 1, '111111111', FALSE);
INSERT INTO OrgInvitation VALUES (1, 1, '012345678', FALSE, FALSE, '2014-06-02 20:36:43.206615');
INSERT INTO Speciality VALUES (DEFAULT, 'Cena');
INSERT INTO Speciality VALUES (DEFAULT, 'OutraCena');
INSERT INTO Professional VALUES (DEFAULT, 2, 1, 'asdrubal', '123456789', '987654321', '2014-06-02 20:36:43.206615');
INSERT INTO Professional VALUES (DEFAULT, 2, 1, 'asdrubal incompleto', NULL, '987654321', '2014-06-02 20:36:43.206615');
INSERT INTO Professional VALUES (DEFAULT, 1, 1, 'Quim Manel', NULL, NULL, '2014-06-02 20:36:43.206615');
INSERT INTO Professional VALUES (DEFAULT, 1, 1, 'Quim Ze', NULL, NULL, '2014-06-22 20:36:43.206615');
INSERT INTO Professional VALUES (DEFAULT, 1, 1, 'Quim Ze Completo', NULL, NULL, '2014-06-12 20:36:43.206615');
INSERT INTO Professional VALUES (DEFAULT, 1, 1, 'Quim Ze Completo', NULL, NULL, '2014-07-02 20:36:43.206615');
INSERT INTO Procedure VALUES (DEFAULT, DEFAULT, 1, NULL, 1, 2, 3, 4, NULL, NULL, DEFAULT, 0, FALSE, 0);
INSERT INTO ProcedureProfessional VALUES (1, 1, 0);
INSERT INTO ProcedureProfessional VALUES (1, 4, 0);
INSERT INTO ProcedureAccount VALUES (1, 1);
INSERT INTO ProcedureAccount VALUES (1, 2);
SELECT
  share_procedure_with_all(1, 1);
INSERT INTO OrgAuthorization VALUES (1, 2, 'Visible');


INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratoscopia fotográfica', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glotografia', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vectocardiograma', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de triquíase e distriquiase', 80);

INSERT INTO Speciality VALUES (DEFAULT, 'Anatomia Patológica');
INSERT INTO Speciality VALUES (DEFAULT, 'Anestesiologia');
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

INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Consultório - Não Especialista-1ª. Consulta', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Consultório - Não Especialista-2ª. Consulta', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Consultório - Especialista-1ª. Consulta', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Consultório - Especialista-2ª. Consulta', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Consultório - Psiquiatria e Oftalmologia-1ª. consulta', 14);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Consultório - Psiquiatria e Oftalmologia-2ª. consulta', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Domicílio - Não Especialista-1ª. consulta', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Domicílio - Não Especialista-2ª. consulta', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Domicílio - Especialista-1ª. Consulta', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Domicílio - Especialista-2ª. Consulta', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Domicílio - Psiquiatria-1ª. Consulta', 21);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas no Domicílio - Psiquiatria-2ª. Consulta', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Não Especialista-1ª. Consulta', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Não Especialista-2ª. Consulta', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Especialista-1ª. Consulta', 24);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Especialista-2ª. consulta', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Psiquiatria-1ª. consulta', 28);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Psiquiatria-2ª. consulta', 24);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conferência Médica', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame pericial com relatório', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame pericial em testamento', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Relatório do processo clínico', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acompanhamento permanente do doente (por dia)', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação do tratamento inicial do doente em condição crítica (até 1ª. hora)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Assistência permanente adicional (cada 1 hora)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame sob anestesia geral (como acto médico)', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Assistência a actos operatórios (por hora)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Observação de um recém-nascido', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Assistência pediátrica ao parto, e observação de recém-nascido', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Algaliação na Mulher', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Algaliação no Homem', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Paracentese', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pericardiocentese', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Torancentese', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção testicular', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção articular', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção da bolsa sub-deltoideia', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção prostática', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção lombar-terapêutica ou exploradora', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção com drenagem de derrame pleural ou peritoneal', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aspiração de abcesso, hematoma, seroma ou quisto', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colpocentese', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de cateter umbilical no RN', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento arterial ou venoso', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exanguíneo transfusão', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transfusão fetal intra-uterina', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção femoral, jugular ou do seio longitudinal superior', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transfusão ou perfusão intravenosa (Aplicação)', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perfusão epicraniana', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colheita de sangue fetal', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intubação gástrica', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intubação duodenal', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lavagem gástrica', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção arterial', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pensos', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infusão para quimioterapia', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção intracavitária para quimioterapia', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção intratecal para quimioterapia', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção esclerosante de varizes (por sessão)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras injecções', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consulta de grupo', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica convulsivante (electrochoque)', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica insulínica', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testes psicológicos', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bateria de testes psicológicos, com relatório', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Relatório médico-legal', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemodiálise aguda', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemodiálise crónica com filtro novo', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemodiálise crónica com filtro reutilizado', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemofiltração contínua arteriovenosa', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemoperfusão', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plasmaferese', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação esofágica (cada sessão)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação esofágica (por endoscopia)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de varizes por via endoscópica (esclerose)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho por via endoscópica', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese esofágica (excluindo a prótese)', 65);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tamponamento de varizes esofágicas', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia por cápsula', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Manometria esofágica', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quimismo gástrico, basal', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quimismo gástrico, com estimulação', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pancreatografia e/ou colangiografia retrógada (CPRE)', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esfincterotomia transendoscópica', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esfincterotomia transendoscópica com extracção de cálculo', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de cálculo por via transendoscópica', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação transcutânea de prótese de drenagem biliar', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colangiografia percutânea (CPT)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Implantação endoscópica da prótese de drenagem biliar', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento esclerosante de hemorróidas (por sessão)', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção sub-fissurária', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hemorróidas por laqueação elástica (por sessão)', 6);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Polipectomia do rectosigmoide com tubo rígido (incluindo exame endoscópico)', 20);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Polipectomia do tubo digestivo a adicionar ao respectivo exame endoscópico', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colheita de material para citologia esfoliativa', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Determinação do pH por eléctrodo no tubo digestivo', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pneumoperitoneo', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retropneumoperitoneo', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrostomia por via endoscópica', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hemorróidas por infravermelhos', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hemorróidas por criocoagulação', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecoendoscopia', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Manometria ano-rectal', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Terapêutica hemostática (não varicosa) a adicionar ao respectivo exame endoscópico', 20);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Terapêutica por raio laser a adicionar ao respectivo exame endoscópico (cada sessão)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Litotripsia biliar extracorporal', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Teste Respiratório com Carbono 13 (diagnóstico da infecção pelo Helicobacter pylori)', 3);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame oftalmológico completo sob anestesia geral, com ou sem manipulação do globo ocular, para diagnóstico inicial, relatório médico',
                                  30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gonioscopia', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo moto-sensorial efectuado ao sinoptóforo', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sessão de tratamento ortóptico ou pleóptico', 4);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação da visão binocular de perto e longe com testes subjectivos de fixação', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gráfico sinoptométrico', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gráfico de Hess', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Campo visual binocular', 16);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Adaptação de lentes de contacto com fins terapêuticos (não inclui o preço da lente)', 12);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação de campos visuais, exame limitado (estimulos simples/equivalentes)', 12);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Avaliação dos campos visuais, exame intermédio (estimulos múltiplos, compo completo, vária esoptéras no perímetro Goldmann/equivalente)',
                                  18);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação dos campos visuais, exame extenso (perimetria quantitativa, estática ou cinética)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perimetria computadorizada', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Curva tonométrica de 24 horas', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tonografia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tonografia com testes de provocação de glaucoma', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testes de provocação de glaucoma sem tonografia', 8);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Elaboração de relatório médico com base nos elementos do processo clínico', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame oftalmológico para fins médico legais com relatório', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conferência médica interdisciplinar ou inter-serviços', 20);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Oftalmoscopia indirecta completa (inclui interposição lente, desenho/esquema/e/ou biomicroscopia do fundo)',
                                  20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angioscopia fluoresceínica, fotografias seriadas, relatório médico', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oftalmodinamometria', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retinorrafia', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia scan laser oftalmológico', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinevideoangiografia', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia com verde indocianina', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Eco Doppler "Duplex Scan" Carótideo/Oftalmológico', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electro-oculomiografia, 1 ou mais músculos extraoculares, relatório', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electro-oculografia com registo e relatório', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electro-retinografia com registo e relatório', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo dos potenciais occipitais evocados e relatório', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo elaborado da visão cromática', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Adaptometria', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotografia de aspetos oculares externos', 10);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fotografia especial do segmento anterior, com ou sem microscopia especular', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotografia do segmento anterior com angiografia fluoresceínica', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fluofotometria do segmento anterior', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fluofotometria do segmento posterior', 30);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Avaliação da acuidade visual por técnicas diferenciadas (interferometria, visão de sensibilidade ao contraste, visão mesópica e escotópica/outras)',
                                  15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratoscopia fotográfia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratoscopia computorizada', 25);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electronistagmografia e/ou electro-oculograma dinâmico com teste de nistagmo optocinético', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biomicroscopia especular', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prescrição e adaptação de próteses oculares (olho artificial)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prescrição de auxiliares ópticos em situação de subvisâo', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia oftalmica A+B', 20);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ecografia oftalmica linear, análise espectral com quantificação da amplitude', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia oftalmica bidimensional de contacto', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biometria oftalmica por ecografia linear', 10);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Biometria oftalmica por ecografia linear com cálculo de potência da lente intraocular', 15);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Biometria oftalmica por ecografia linear com cálculo da espessura da córnea, paquimetria', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia oftalmica para localização de corpos estranhos', 15);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Localização radiológica de corpo estranho da região orbitária (anel Comberg/equivalente)', 15);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Biomicroscopia do fundo ocular ou visão camerular com lente de Goldmann', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Audiograma tonal simples', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Audiograma vocal', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Audiometria automática (Beckesy)', 5);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estudo auditivo completo (audiometria tonal e vocal, impedância, prova de fadiga e recobro)', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Testes suplementares de audiometria (Tone Decay, Sisi, recobro, etc.) cada', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acufenometria', 5);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Optimização do ganho auditivo de performance electro-acústica das próteses auditivas "in situ"', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rastreio da surdez do recém nascido', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Audiometria tonal até 5 anos de idade', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Audiometria tonal até 8 anos de idade', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Audiometria vocal até 10 anos de idade', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'ERA (incluindo BER e ECOG ou outra prova global)', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrococleografia - traçado e protocolo', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Respostas de tronco cerebral - traçado e protocolo', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Respostas semi precoces - traçado e protocolo', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Respostas auditivas corticais', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Otoemissões', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Teste do promontório', 60);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Timpanograma, incluindo a medição de compliance e volume do conduto externo', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de reflexos acústicos ipsi-laterais ou contra-laterais', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa do "Decay" do reflexo bilateral', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de reflexos não acústicos', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reflexograma de Metz', 5);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Estudo timpanométrico do funcionamento da Trompa de Eustáquio (medição feita com ponte de admitância)', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Provas suplementares de timpanometria', 5);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Impedância ou admitância (incluindo timpanograma, medição de compliance, volume do conduto externo, reflexos acústicos ipsi e contra-laterais)',
                                  15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame vestibular sumário (provas térmicas)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame vestibular por electronistagmografia (E.N.G.)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'E.N.G. computorizada', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Craniocorpografia', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Posturografia estática', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Posturografia dinâmica', 60);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electroneuronomiografia de superfície com auxílio de equipamento computorizado E.No.M.G. (três avaliações sucessivas)',
                                  40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electroneuronografia', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estroboscopia', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sonografia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glotografia', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fonetograma', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrogustometria', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento método de PROETZ', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rinodebitomanometria', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames realizados sob indução medicamentosa', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames realizados sob anestesia geral', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Observação e tratamento sob microscopia', 5);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Fonocardiograma com registo simultâneo duma derivação electrocardiográfica e dum mecanograma de referência',
                                  9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apexocardiograma', 7);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electrocardiograma simples de 12 derivações com interpretação e relatório', 6);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electrocardiograma simples de 12 derivações com interpretação e relatório, no domicílio', 9);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Prova de esforço máxima ou submáxima em tapete rolante ou cicloergómetro com monitorização electrocardiográfica contínua, sob supervisão médica, com interpretação e relatório',
                                  40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vectocardiograma, com ou sem ECG, com interpretação e relatório', 10);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Monitorização electrocardiográfica contínua prolongada pelo método de Holter com gravação contínua, "scanning" por sobreposição ou impressão total miniaturizada, e análise automática, efectuada sob supervisão médica, com interpretação e relatório',
                                  20);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Monitorização electrocardiográfica contínua prolongada por método de Holter, com análise de dados em tempo real, gravação não contínua e registo intermitente, efectuada sob supervisão médica, com interpretação e relatório',
                                  12);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Monitorização electrocardiográfica prolongada com registo de eventos activado pelo doente com memorização pré e pós-sintomática, efectuada sob supervisão médica, com intrepretação',
                                  10);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Registo electrocardiográfico de alta resolução, com ou sem ECG de 12 derivações', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Análise da variabilidade do intervalo RR', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fluoroscopia cardíaca', 7);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Registo ambulatório prolongado (24h ou mais) da pressão arterial incluindo gravação, análise por "scanning", interpretação e relatório',
                                  20);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Teste baroreflexo da função cardiovascular com mesa basculante ("tilt table"), com ou sem intervenção farmacológica',
                                  20);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ecocardiografia em tempo real (bidimensional), com registo de imagem, com ou sem registo em modo-M', 20);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Idem, associada a ecografia Doppler, pulsada ou contínua, com análise espectral', 40);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ecocardiografia transesofágica em tempo real (bidimensional), com ou sem registo em modo-M, com inclusão de posicionamento da sonda, aquisição de imagem, interpretação e relatório',
                                  80);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ecocardiog. de sobrecarga em tempo real (bidim.), c/ou sem registo em modo-M, durante repouso e prova Cardiov., c/teste máx. ou submáx. em tap. rolante, cicloergométrico e/ou sobrec. farmac., incluindo monitorização electrocardiog., c/interpret. e relat.',
                                  80);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ecocardiografia intra-operatória em tempo real (bidimensional), com registo de imagem, com ou sem registo em modo-M, com estudo Doppler, pulsado ou contínuo, com análise espectral, estudo completo, com interpretação e relatório',
                                  80);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Fonocardiograma com registo simultâneo duma derivação electrocardiográfica e dum mecanograma de referência',
                                  14);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apexocardiograma', 10);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electrocardiograma simples de 12 derivações com interpretação e relatório', 8);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Electrocardiograma simples de 12 derivações com interpretação e relatório, no domicílio', 14);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Prova de esforço máxima ou submáxima em tapete rolante ou cicloergómetro com monitorização electrocardiográfica contínua, sob supervisão médica, com interpretação e relatório',
                                  30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vectocardiograma, com ou sem ECG, com interpretação e relatório', 15);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Monitorização electrocardiográfica contínua prolongada pelo método de Holter com gravação contínua, "scanning" por sobreposição ou impressão total miniaturizada, e análise automática, efectuada sob supervisão médica, com interpretação e relatório',
                                  30);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Monitorização electrocardiográfica contínua prolongada por método de Holter, com análise de dados em tempo real, gravação não contínua e registo intermitente, efectuada sob supervisão médica, com',
                                  16);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Monitorização electrocardiográfica prolongada com registo de eventos activado pelo doente com memorização pré e pós sintomática, efectuada sob supervisão médica, com intrepretação',
                                  15);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Registo electrocardiográfico de alta resolução, com ou sem ECG de 12 derivações', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Análise da variabilidade do intervalo RR', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fluoroscopia cardíaca', 10);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Registo ambulatório prolongado (24h ou mais) da pressão arterial incluindo gravação, análise por "scanning", interpretação e relatório',
                                  20);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Teste baroreflexo da função cardiovascular com mesa basculante ("tilt table"), com ou sem intervenção farmacológica',
                                  20);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ecocardiografia em tempo real (bidimensional), com registo de imagem, com ou sem registo em modo-M', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Idem, associada a ecografia Doppler, pulsada ou contínua, com análise espectral', 50);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ecografia em tempo real (bidimensional), com ou sem registo em modo-M, transesofágica, com inclusão de posicionamento da sonda, aquisição de imagem, interpretação e relatório',
                                  120);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ecocardiog. Em tempo real (bidim.), c/ou sem registo em modo-M, durante repouso e prova sobrec. Cardiov., c/teste máx. ou submáximo em tap. Rolante, cicloergométrico e/ou sobrec. Farmac., incluindo monitorização electrocardiográfica, c/interpret. E relat.',
                                  50);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ecocardiografia em tempo real (bidimensional), com registo de imagem, com ou sem registo em modo-M, com estudo Doppler, pulsado ou contínuo, com análise espectral, intra-operatória, estudo completo, com interpretação e relatório',
                                  45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecocardiografia de contraste', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecocardiografia fetal', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo Doppler cardíaco fetal', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco direito', 60);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Implantação e posicionamento de catéter de balão por cateterismo direito para monitorização (Swan-Ganz)',
   50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo por via trans-septal', 105);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco direito e esquerdo', 105);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco direito com angiografia (ventrículo direito ou artéria pulmonar)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia esquerda', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com coronariografia selectiva', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva', 115);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva e aortografia',
   120);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva, aortografia e cateterísmo direito',
                                  145);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva, aortografia, cateterismo direito e visualização de "bypasses" aorto-coronários',
                                  155);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com visualização de "bypasses" aorto-coronários', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova de provocação de espasmo coronário (ergonovina)', 75);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Estudos de medição de débito cardíaco com corantes indicadores ou por termodiluição, incluindo cateterismo arterial ou venoso',
                                  75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, medições subsequentes', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Registo electrocardiográfico transesofágico', 13);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Registo electrocardiográfico transesofágico com estimulação eléctrica ("pacing")', 18);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Registo do electrograma intra-auricular, do feixe de His, do ventrículo direito ou do ventrículo esquerdo',
   25);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Mapeamento intraventricular e/ou intrta-auricular de focos de taquicardia com registo multifocal, para indentificação da origem da taquicárdia',
                                  35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Indução de arritmia por "pacing"', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, '"Pacing" intra-auricular ou intraventricular', 25);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Estudo electrofisiológico completo com "pacing" e/ou registo de auricula direita, ventrículo direito e feixe de His, com indução de arritmias, incluindo implantação e reposicionamento de múltiplos electro-catéteres',
                                  130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com indução de arritmias', 175);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Idem, com regiso de aurícula esquerda, seio coronário ou ventrículo esquerdo com ou sem "pacing"', 200);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estimulação programada e "pacing" após infusão intravenosa de fármacos', 70);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Estudo electrofisiológico de "follow-up" com "pacing" e registo para teste de eficácia de terapêutica, incluindo indução ou tentativa de indução de arritmia',
                                  70);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com coronariografia selectiva e angioscopia coronária', 130);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com coronariografia selectiva e ultrassonografia intracoronária', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia endomiocárdica', 55);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco direito (venoso)', 100);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Implantação e posicionamento de catéter de balão por cateterismo direito para monitorização (Swan-Ganz)',
   75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo (por punção arterial)', 125);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo (por desbridamento)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo por via transeptal', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco direito e esquerdo', 220);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco direito com angiografia (ventrículo direito ou artéria pulmonar)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia esquerda', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia e aortografia', 175);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com coronariografia selectiva', 200);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva', 220);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva e aortografia',
   130);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva, aortografia e cateterísmo direito',
                                  300);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Cateterismo cardíaco esquerdo com ventrículografia esquerda, coronariografia selectiva, aortografia, cateterismo direito e visualização de "bypasses" aorto-coronários',
                                  300);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com visualização de "bypasses" aorto-coronários', 225);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Estudos de medição de débito cardíaco com corantes indicadores ou por termo-diluição, incluindo cateterismo arterial ou venoso',
                                  125);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, medições subsequentes', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Registo electrocardiográfico transesofágico', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Registo electrocardiográfico transesofágico com estimulação eléctrica ("pacing")', 40);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Registo do electrograma intra-auricular, do feixe de His, do ventrículo direito ou do ventrículo esquerdo',
   50);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Mapeamento intraventricular e/ou intra-auricular de focos de taquicardia com registo multifocal, para identificação da origem da taquicárdia',
                                  75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Indução de arritmia por "pacing"', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, '"Pacing" intra-auricular ou intraventricular', 50);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Estudo electrofisiológico completo com "pacing" e/ou registo de auricula direita, ventrículo direito e feixe de His, com indução de arritmias, incluindo implantação e reposicionamento de múltiplos electro-catéteres',
                                  150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com indução de arritmias', 175);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Idem, com registo de aurícula esquerda, seio coronário ou ventrículo esquerdo com ou sem "pacing"', 180);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com coronariografia selectiva e angioscopia coronária', 250);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterismo cardíaco esquerdo com coronariografia selectiva e ultrassonografia intracoronária', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia endomiocárdica', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cardioversão eléctrica externa, electiva', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressuscitação cardio-respiratória', 35);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Colocação percutânea de dispositivo de assistência cardio-circulatória, v.g. balão intra-aórtico para contrapulsação',
                                  105);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, remoção', 55);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, controle', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Trombólise coronária por infusão intracoronária, incluindo coronariografia selectiva', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trombólise coronária por infusão intravenosa', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angioplastia coronária percutânea transluminal de um vaso', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, por cada vaso adicional', 125);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Implantação de prótese intracoronária ("stent")', 210);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aterectomia percutânea trasluminal direccional coronária de Simpson de um vaso', 210);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, por cada vaso adicional', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia pulmunar percutânea de balão', 230);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia tricúspide percutânea de balão', 195);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia aórtica percutânea de balão', 260);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia mitral percutânea de balão', 355);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação percutânea de coarctação da aorta', 195);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Atrioseptostomia transvenosa por balão, do tipo Rashkind', 230);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem por lâmina, do tipo Park', 230);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento percutâneo de canal arterial persistente', 310);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento percutâneo de comunicação interauricular', 310);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de comunicação interventricular', 310);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação de ramos da artéria pulmonar', 230);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação de estenoses de veias pulmonares', 230);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Embolização vascular', 230);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electrofisiologia de intervenção terapêutica, com ablacção de vias anómalas, por energia de radiofrequência',
                                  235);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electrofisiologia de intervenção terapêutica, com ablacção ou modulação da junção auriculo-ventricular, por energia de radiofrequência',
                                  200);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electrofisiologia de intervenção terapêutcia, com ablacção de focos de taquidisritmia ventricular, por energia de radiofrequência',
                                  250);
INSERT INTO ProcedureType VALUES (DEFAULT, '"Pacing" temporário percutâneo', 45);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Implantação de pacemaker permanente com eléctrodo transvenoso, auricular', 180);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Implantação de pacemaker permanente com eléctrodo transvenoso, ventricular', 180);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Implantação de pacemaker permanente com eléctrodo transvenoso, de dupla câmara', 195);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição de gerador "pacemaker", de uma ou duas câmaras', 85);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Passagem de sistema "pacemaker" de câmara única a dupla câmara, (incluindo explantação do gerador anterior, teste do eléctrodo existente e implantação de novo eléctrodo e de novo gerador)',
                                  185);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Revisão cirúrgica de sistema "pacemaker", sem substituição de gerador (incluindo substituição, reposicionamento ou reparação de eléctrodos transvenosos permanentes), cinco ou mais dias após implantação inicial)',
                                  70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de sistema "pacemaker"', 70);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Controlo electrónico do sistema "pacemaker" permanente de uma câmara, sem programação', 4.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com programação', 6);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Controlo electrónico de sistema "pacemaker" permanente de dupla câmara, sem programação', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com programação', 8);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Implantação de cardioversor-desfibrilhador automático com eléctrodos (sensores e cardioversores-desfibrilhadores) transvenosos',
                                  360);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição de gerador cardioversor-desfibrilhador', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revisão de loca de gerador cardioversor-desfibrilhador', 115);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Revisão, reposicionamento ou explantação de eléctrodos (sensores e cardioversores-desfibrilhadores) transvenosos de sistema cardioversor-desfibrilhador',
                                  315);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Controlo electrónico de cardioversor-desfibrilhador automático, sem programação', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com programação', 8);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação electrofisiológica de cardioversor desfibrilhador automático', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pericardiocentese', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Explantação de corpos estranhos por cateterismo percutâneo', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cardioversão eléctrica externa, electiva', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressuscitação cardio-respiratória', 50);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Colocação percutânea de dispositivo de assistência cardio-circulatória, v.g. balão intra-aórtico para contrapulsação',
                                  120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, remoção', 55);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, controle', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia pulmonar percutânea de balão', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia aórtica percutânea de balão', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastia mitral percutânea de balão', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação percutânea de coarctação ou recoartação da aorta', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Atrioseptostomia transvenosa por balão, do tipo Rashkind', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem por lâmina, do tipo Park', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento percutâneo de canal arterial persistente', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento percutâneo de comunicação interauricular', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de comunicação interventricular', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação (angioplastia) de ramos da artéria pulmonar', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação (angioplastia) de estenoses de veias pulmonares', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Embolização vascular, arterial, venosa ou arteriovenosa', 300);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electrofisiologia de intervenção terapêutica, com ablacção de vias anómalas, por energia de radiofrequência',
                                  320);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electrofisiologia de intervenção terapêutica, com ablacção ou modulação da junção auriculo-ventricular, por energia de radiofrequência',
                                  320);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Electrofisiologia de intervenção terapêutcia, com ablacção de focos de taquidisritmia ventricular, por energia de radiofrequência',
                                  320);
INSERT INTO ProcedureType VALUES (DEFAULT, '"Pacing" temporário percutâneo', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Implantação de "pacemaker" permanente com eléctrodo transvenoso, auricular', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Implantação de "pacemaker" permanente com eléctrodo transvenoso, ventricular', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Implantação de "pacemaker" permanente com eléctrodos transvenosos, de dupla câmara', 270);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição de gerador "pacemaker", de uma ou duas câmaras', 100);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Passagem de sistema "pacemaker" de câmara única a dupla câmara, (incluindo explantação do gerador anterior, teste do eléctrodo existente e implantação de novo eléctrodo e de novo gerador)',
                                  185);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Revisão cirúrgica de sistema "pacemaker", sem substituição de gerador (incluindo substituição, reposicionamento ou reparação de eléctrodos transvenosos permanentes), cinco ou mais dias após implantação inicial)',
                                  150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de sistema "pacemaker"', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Controlo electrónico do sistema "pacemaker" permanente de uma câmara, sem programação', 4.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com programação', 6);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Controlo electrónico de sistema "pacemaker" permanente de dupla câmara, sem programação', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com programação', 8);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Implantação de cardioversor-desfibrilhador automático com eléctrodos (sensores e cardioversores-desfibrilhadores) transvenosos',
                                  360);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição de gerador cardioversor-desfibrilhador', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revisão de loca de gerador cardioversor-desfibrilhador', 115);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Revisão, reposicionamento ou explantação de eléctrodos (sensores e cardioversores-desfibrilhadores) transvenosos de sistema cardioversor-desfibrilhador',
                                  315);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Controlo electrónico de cardioversor-desfibrilhador automático, sem programação', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com programação', 8);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação electrofisiológica de cardioversor desfibrilhador automático', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pericardiocentese', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Explantação de corpos estranhos por cateterismo percutâneo', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem pleural contínua', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exsuflação de pneumotórax expontâneo', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pleurodese', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção transtraqueal', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção transtorácica', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espirometria simples (estudo dos volumes e débitos)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espirometria simples com prova de broncodilatação', 13);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espirometria simples com prova de provocação inalatória inespecífica', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espirometria simples com prova de provocação inalatória específica', 20);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Mecânica ventilatória simples (estudo de volumes, incluindo o volume residual+débitos+resistência das vias aéreas)',
                                  22);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mecânica ventilatória com prova de broncodilatação', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mecânica ventilatória com prova de provocação inalatória inespecífica', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mecânica ventilatória com prova de provocação inalatória específica', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, '"Compliance" pulmonar', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Difusão', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oximetria transcutânea', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Registo poligráfico do sono com avaliação terapêutica (CPAP)', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aspirado brônquico, para bacteriologia, micologia, parasitologia e citologia', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Citologia por escovado', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Citologia por punção aspirativa (transbrônquica)', 15);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Escovado brônquico duplamente protegido para pesquisa de germens (aeróbios e anaeróbios) e fungos', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lavagem bronco-alveolar', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lavagens brônquicas dirigidas', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncografia (introdução do produto de contraste)', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoaspiração de secreções', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia por Laser ( fotocoagulação)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Instilação de soro gelado e/ou adrenalina em hemoptises', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intubações endotraqueais (conduzidas por broncofibroscópio)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tamponamento de hemoptises', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioterapia endobrônquica', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese enduminal', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação de colas biológicas', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coagulação por Laser', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocauterização', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pleurodese', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aerossóis (por sessão)', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aerossóis ultra-sónicos', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'IPPB (Ventilação por pressão positiva intermitente)', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oxigenoterapia (a utilizar durante as sessões de readaptação)', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Por picada (no mínimo série standard)', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intradérmica (no mínimo série standard)', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Por contacto (no mínimo série standard)', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da imunidade celular por testes múltiplos', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Inespecíficas', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Específicas', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Inespecíficas', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Específicas', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cada alergeno', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cada alergeno', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espirometria simples (estudo dos volumes e débitos)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncodilatadoras por espirometria simples', 13);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoconstritoras inespecíficas por espirometria simples', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoconstritoras específicas (cada) por espirometria simples', 20);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Mecânica ventilatória simples (estudo de volumes, incluindo o volume residual+débitos+resistência das vias aéreas)',
                                  22);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncodilatadoras por mecânica ventilatória', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoconstritoras inespecíficas por mecânica ventilatória', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoconstritoras específicas (cada) por mecânica ventilatória', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção (sob vigilância médica)', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aerossóis (cada)', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Introdução de pessário', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Introdução do DIU', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção do DIU por via abdominal (laparotomia ou celioscopia)', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Manobras para exame radiográfico do útero e anexos', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Secção de sinéquias por histeroscopia', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Teste de Huhner', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Inseminação artificial', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclo G.I.F.T.', 175);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclo F.I.V.', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclo Z.I.F.T.', 175);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclo I.C.S.I.', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Monitorização da ovulação', 15);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de condilomas vulvares (cauterização química, eléctrica ou criocoagulação)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amniocentese (2º. Trimestre)', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amniocentese (3º. Trimestre)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Teste de stress à ocitocina', 20);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Iniciação e/ou supervisão de monitorização fetal interna durante o trabalho de parto', 40);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Injecção intra-amniótica (amniocentese) de solução hipertónica e/ou prostaglandinas para indução do trabalho de parto',
                                  20);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Injecção intra-uterina extra amniótica de solução hipertónica e/ou prostaglandinas para indução do trabalho',
                                  10);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Monitorização fetal externa, com protocolos e extractos dos cardiotocogramas (fora ou durante o trabalho de parto de parto) . Teste de reatividade fetal',
                                  8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia do corion', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cordocentese', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traçado diurno com provas de activação (HPP e ELI)', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traçado de sono diurno', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traçado fora do laboratório', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traçado poligráfico', 38);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocorticografia', 36);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Teste de latência múltipla do sono', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Registo prolongado de EEG e Video (monitorização no laboratório)', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Registo prolongado de EEG e Video (monitorização em ambulatório)', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traçado de sono em ambulatório', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Registo poligráfico de sono nocturno', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cartografia do EEG', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cartografia de potenciais evocados visuais', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cartografia de potenciais evocados auditivos', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cartografia de potenciais evocados somatosensitivos', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cartografia do P300', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados visuais', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados auditivos', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados somatosensitivos', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados do nervo pudendo', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados por estimulação de pares cranianos', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados por estimulação paraespinhal', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados por estimulação de dermatomas', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reflexo bulbocavernoso', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electromiografia (incluindo velocidades de condução)', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electromiografia de fibra única', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reflexo de encerramento ocular (Blink reflex)', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da condução do nervo frénico', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Resposta simpática cutânea', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da variação R-R', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estimulação magnética motora com captação a níveis diversos', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioterapia com neve carbónica (por sessão)', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioterapia, com azoto liquido, de lesões benignas (por sessão)', 8);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Crioterapia, com azoto liquido, de lesões malignas, excepto face e região frontal', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Crioterapia, com azoto liquido, de lesões malignas da face e região frontal', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocoagulação ou electrólise de pêlos (por sessão)', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocoagulação de lesões cutâneas', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia pelo método de Mohs (microscopicamente controlada)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto de cabelo (técnica de Orentreich) por selo', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica intralesional com corticóides ou citostáticos', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'P.U.V.A. (por sessão) banho prévio com psolareno', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'P.U.V.A. (por sessão) terapêutica oral ou tópica com psolareno', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quimio cirurgia com pasta de zinco', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laserterapia cirúrgica por laser de CO2 de lesões cutâneas', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diagnóstico pela luz de Wood', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laser pulsado de contraste (até 10 cm2)', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, > 10 cm2 < 20 cm2', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, maior que 20 cm2', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Redução manual de parafimose', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fulguração e cauterização nos genitais externos', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calibração e dilatação da uretra', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Instilação intravesical', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição não cirúrgica de sondas cateteres ou tubos de drenagem', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fluxometria', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistografia (água ou gás)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electromiografia esfincteriana', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perfil uretral', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame urodinâmico completo do aparelho urinário baixo', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exame urodinâmico do aparelho urinário alto-estudo de perfusão renal (exclui nefrostomia)', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rigiscan', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Doppler peniano', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cavernosometria', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cavernosografia dinâmica', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Test. PGE com papaverina ou prostaglandina', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electromiografia da fibra muscular do corpo cavernoso', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Potenciais evocados somato-sensitivos do nervo pudendo', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagoscopia', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Endoscopia Alta (Esofagogastroduodenoscopia)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enteroscopia', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coledoscopia peroral', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colonoscopia Total', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colonoscopia esquerda', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fibrosigmoidoscopia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rectosigmoidoscopia (tubo rígido)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anuscopia', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rinoscopia posterior endoscópica', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinuscopia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laringoscopia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Microlaringoscopia em suspensão', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoscopia', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pleuroscopia', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoscopia com broncovideoscopia', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mediastinoscopia cervical', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hiloscopia', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretroscopia', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistoscopia simples', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterorrenoscopia de diagnóstico', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefroscopia percutânea', 140);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Endoscopia flexivel (a acrescentar ao valor do custo real da endoscopia do orgão)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Peniscopia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laparoscopia Diagnóstica', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colposcopia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Culdoscopia', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histeroscopia', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amnioscopia', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amnioscopia intra ovular ( fetoscopia)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroscopia', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gânglio', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gengival', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fígado', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mama', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tecidos Moles', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osso', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pénis', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Próstata', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rim', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testículo', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiróide', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pulmão', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pleura', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mediastino', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vulva', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vagina', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colo do útero', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Recto', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orofaringe', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nasofaringe', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laringe', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nariz', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Baço', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Baço, com manometria', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pele', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mucosa', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Endométrio', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia endoscópica (acresce ao valor da endoscopia)', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antebraço', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Braço e antebraço', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cervicotorácico (Minerva)', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dedos da mão ou pé', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mão e antebraço distal (luva gessada)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tóraco-braquial', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Torácico (colete gessado)', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colar', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Velpeau', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pelvi-podálico unilateral', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pelvi-podálico bilateral', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Halopelvico', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coxa, perna e pé', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perna e pé', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coxa e perna (joelheira gessada)', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Leito gessado', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toda a coluna vertebral com correcção de escoliose', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de tala tipo Denis Browne em pé ou mão bôta', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cutânea à cabeça', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cutânea à bacia', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cutânea aos membros', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esquelética ao crânio', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esquelética aos membros', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esquelética aos dedos', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Halopélvica', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Escleroterapia ambulatória de varizes do membro inferior (por sessão e por membro)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Escleroterapia de varizes do membroinferior sob anestesia geral', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Limpeza ou curetagem de úlcera de perna', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto cutâneo de úlcera de perna', 70);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aplicação de aparelho de compressão permanente (bota una, cola de zinco, kompress, etc.)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Compressão pneumática sequencial', 5);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Drenagem linfática de membro por correntes farádicas em sincronismo cardíaco, com massagem', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laserterapia de varizes', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Simpatólise lombar', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aspiração de bolsas sinoviais', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aspiração de bolsas sinoviais sob controlo ecográfico', 16);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrocentese diagnóstica', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrocentese diagnóstica sob controlo ecográfico', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia sinovial fechada do joelho', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia sinovial fechada da coxo-femoral', 40);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Biópsia sinovial fechada de outras articulações sem intensificador de imagem', 20);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Biópsia sinovial fechada de outras articulações com intensificador de imagem', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia sinovial sob artroscopia (acresce ao valor da artroscopia)', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia das glândulas salivares', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Condroscopia', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrografia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Discografia', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração de partes moles', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração de partes moles sob controlo ecográfico', 16);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração articular', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração articular sob controlo ecográfico', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração articular sob intensificador de imagem', 23);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroclise', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio de nervo periférico', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração epidural', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção intratecal', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinoviortese com hexacetonido', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinoviortese com hexacetonido sob controlo ecográfico', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinoviortese com hexacetonido sob intensificador de imagem', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinoviortese com ácido ósmico', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinoviortese com ácido ósmico sob controlo ecográfico', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinoviortese com ácido ósmico sob intensificador de imagem', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinoviortese com radioisótopos Itrium', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinoviortese com radioisótopos Renium 186 (com controlo ecográfico)', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sinoviortese com radioisótopos Renium 186 (com intensificador de imagem)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quimionucleólise', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nucleólise percutânea', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artroscopia terapêutica simples (extração de corpos livres, desbridamentos, secções, etc)', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroscopia terapêutica de lesões articulares circunscritas', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Capilaroscopia da prega cutânea periungueal', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de abcesso subcutâneo', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de abcesso profundo', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de quisto sebáceo, quisto pilonidal ou fúrunculo', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de oníquia ou perioníquia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de hematoma', 15);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de pequenos tumores benignos ou quistos subcutâneos excepto região frontal e face', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de lesões benignas da região frontal da face e mão, passíveis de encerramento directo', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumor profundo', 100);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Excisão de lesões benignas ou malignas só passíveis de encerramento com plastia complexa, na região frontal, face e mão',
                                  200);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Excisão de lesões benignas ou malignas só passíveis de encerramento com plastia complexa, excepto região frontal, face e mão',
                                  150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de cicatrizes da face, pescoço ou mão e plastia por retalhos locais (Z, W, LLL, etc)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Curetagem de verrugas ou condilomas', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de quisto ou fístula pilonidal', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de quisto ou fístula branquial', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura de ferida da face e região frontal até 5 cm (adultos) e 2,5 cm (crianças)', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura de ferida da face e região frontal maior do que 5 cm (adultos) e 2,5 cm(crianças)', 60);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura de ferida cutânea até 5 cm (adultos) ou 2,5 cm (crianças) excepto face e região frontal', 15);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Sutura de ferida cutânea maior do que 5 cm (adultos) ou 2,5 cm (crianças), excepto face e região frontal',
   20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da unha encravada', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de cicatrizes da face, pescoço ou mão e sutura directa', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de cicatrizes de pregas de flexão e plastia por retalhos locais', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de cicatrizes, excepto face, pescoço ou mão e sutura directa', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de cicatrizes, excepto face, pescoço ou mão e plastia por retalhos locais', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de cicatriz e plastia por enxerto de pele total', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho supra-aponevrótico excepto face ou mão', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho subaponevrótico excepto face ou mão', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho da face ou mão', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento cirúrgico de ulceração até 3% da superfície corporal', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento cirúrgico de ulceração entre 3% e 10%', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento cirúrgico de ulceração entre 10% e 30%', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento cirúrgico de ulceração acima de 30%', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento cirúrgico de queimaduras da face, pescoço ou mão', 40);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Desbridamento cirúrgico de queimadura até 3% excepto face, pescoço e mão', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento cirúrgico de queimaduras entre 3% e 10%', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento cirúrgico de queimaduras entre 10% e 30%', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento cirúrgico de queimaduras acima de 30%', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso cirúrgico de queimadura até 3%', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso cirúrgico de queimadura entre 3% e 10%', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso cirúrgico de queimadura entre 10% e 30%', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso cirúrgico de queimadura com mais de 30%', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso inicial de queimadura até 3%', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso inicial de queimadura entre 3% e 10%', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso inicial de queimadura entre 10% e 30%', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Penso inicial de queimadura mais de 30%', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pensos ulteriores entre 3% e 10%', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pensos ulteriores entre 10% e 30%', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pensos ulteriores mais de 30%', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da calvície com expansor tecidular - cada tempo', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da calvície, enxertos pilosos, com Laser (cada sessão)', 200);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia da calvície, enxertos pilosos, com microcirurgia (cada sessão)', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da calvície, enxertos pilosos, cada sessão', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dermabrasão cirúrgica total da face', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dermabrasão cirúrgica parcial da face por unidade estética', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dermabrasão cirúrgica em qualquer outra área', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dermabrasão química total da face', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dermabrasão química parcial da face por unidade estética', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ritidectomia cervicofacial', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ritidectomia frontal', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ritidectomia cervicofacial e frontal', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ritidectomia das pálpebras (por pálpebra)', 40);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ritidectomia das pálpebras (por pálpebra) com ressecção das bolsas adiposas', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rinoplastia completa', 125);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rinoplastia da ponta', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rinoplastia das asas', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução nasal parcial, tempo principal', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução nasal parcial, tempo complementar', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução nasal total, tempo principal', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução nasal total, tempo complementar', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução nasal por retalho pré-fabricado (1º. tempo)', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção do nariz em sela com enxerto ósseo ou cartilagens', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de orelhas descoladas (otoplastia) unilateral', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução total da orelha, tempo principal', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução total da orelha, tempo complementar', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução parcial da orelha, tempo principal', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução parcial da orelha, tempo complementar', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queilopastia estética', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mentoplastia estética com endopróteses', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mentoplastia estética com osteotomias', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção do duplo queixo', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Modelação estética malar-zigomática com endoprótese', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Modelação estética malar-zigomática com osteotomias', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abdominoplastia (simples ressecção)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abdominoplastia, com transposição do umbigo', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Abdominoplastia, com transposição do umbigo e reparação músculo-aponevrótica', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dermolipectomiabraquial (unilateral)', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ritidectomia da mão (unilateral)', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia estética da região glutea(unilateral)', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dermolipectomia da coxa (unilateral)', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração do pescoço', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração do tórax (zonas limitadas)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração do abdómen', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração do membro superior(unilateral)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração da região glútea(unilateral)', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração trocantérica (unilateral)', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração da coxa (unilateral)', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lipoaspiração da perna', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remodelação corporal por auto-enxertos', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Remodelação corporal por inclusão de material biológico conservado, por unidade estética', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tatuagem estética por sessão ou unidade anatómica', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção cirúrgica de tatuagem, cada tempo', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da calvície, com retalhos, cada tempo operatório', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mentoplastia estética com retalhos locais', 120);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto dermoepidérmico até 10 cm2 ou de 0,5% da superfície corporal das crianças, excepto face, boca, pescoço, genitais ou mão',
                                  40);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto dermoepidérmico até 100 cm2 ou de 1% da superfície corporal das crianças excepto face, boca, pescoço, genitais ou mão',
                                  60);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Enxerto dermoepidérmico maior que 100 cm2 ou de 1% da superfície corporal das crianças', 100);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto dermoepidérmico maior que 100 cm2 ou de 1% da superfície corporal das crianças por cada área de 100 cm2 a mais',
                                  50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxertos em rede', 80);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto dermoepidérmico até 100 cm2 ou de 1% da superfície corporal das crianças, face, boca, pescoço, genitais ou mão',
                                  100);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto dermoepidérmico maior que 100 cm2 ou de 1% da superfície corporal das crianças na face, boca, genitais ou mão',
                                  150);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto de clivagem, ou de pele total na região frontal, face, boca, pescoço, axila, genitais, mãos e pés até 20',
                                  100);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Enxerto de clivagem, ou de pele total na região frontal, face, boca, pescoço, axila, genitais, mãos e pés maior que',
                                  140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto de clivagem de pele total até 20 cm2 noutras regiões', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto de clivagem em pele total maior que 20 cm2 noutras regiões', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Enxertos adiposos ou dermo-adiposos fascia, cartilagem, ósseo, periósteo', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos locais, em Z,U,W,V, Y, etc.', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos locais, plastias em Z, múltiplas, etc.', 90);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Retalhos de tecidos adjacentes na região frontal face, boca, pescoço, axila, genitais mãos, pés até 10',
   140);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Retalhos de tecidos adjacentes na região frontal, face, boca, pescoço, axila, genitais, mãos, pés, maior que 10',
                                  150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos de tecidos adjacentes noutras regiões menores que 10', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos de tecidos adjacentes noutras regiões de 10 cm2 a 30', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Formação de retalhos pediculados, à distância, 1º. tempo', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cada tempo complementar', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos de tecidos adjacentes noutras regiões maior que 30', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos miocutâneos sem pedículo vascular identificado', 150);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Retalhos cutâneos, miocutâneos ou musculares com pedículo vascular ou vasculo nervoso identificado', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos fasciocutâneos', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos musculares ou miocutâneos', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalhos osteomiocutâneos ou osteo-musculares', 170);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalho livre com microanastomoses vasculares', 250);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Retalhos de tecidos adjacentes no couro cabeludo, tronco e membros (excepto mãos e pés) menores que', 100);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Retalhos de tecidos adjacentes no couro cabeludo, tronco e membros (excepto mãos e pés) de 10cm2 a', 120);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Retalhos de tecidos adjacentes no couro cabeludo, tronco e membros (excepto mãos e pés) maior que', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Retalhos miocutâneos, musculares, ou fasciocutâneos sem pedículo vascular indentificado', 150);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Retalhos cutâneos, miocutâneos, fasciocutâneos ou musculares, com pedículo vascular ou vasculo nervoso identificado',
                                  200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalho livre com microanastomoses', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução osteoplástica de dedos, cada tempo', 150);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Expansão tissular para correcção de anomalias várias, por cada expansor e cada tempo operatório', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento de escara de decúbito', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desbridamento de escara de decúbito com plastia local', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transferência de dedo à distância por microcirurgia', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de abcesso profundo', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de fibroadenomas e quisto', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia parcial (quadrantectomia)', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia simples', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia subcutânea', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia por ginecomastia, unilateral', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia radical', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia radical com linfadenectomia da mamária interna', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia superradical (Urban)', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia radical modificada', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastectomia parcial com esvasiamento axilar', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia mamária de redução unilateral', 175);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia mamária de aumento unilateral', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção ou substituição de material de prótese', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de encapsulação de material de prótese', 70);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução mamária pós mastectomia ou agenesia com utilização de expansor', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução mamária com retalhos adjacentes', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução mamária com retalhos miocutâneos à distância', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução do complexo areolo-mamilar', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução mamária com retalho miocutâneo do grande dorsal', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução mamária com Tram-Flap', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de mamilos invertidos (unilateral)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de mamilos supranumerários', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de mama supranumerária', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução mamária com retalho livre', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de lesão infraclínica da mama com marcação prévia', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de lesão da mama (com ou sem marcação) e com esvaziamento axilar', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reexcisão da área da biópsia prévia e esvasiamento axilar', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de canais galactóforos', 60);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Esvasiamento axilar como 2º. tempo de cirurgia conservadora do carcinoma da mama (cirurgia diferida)',
   140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reimplantes do braço ou antebraço, completos', 500);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reimplantes do braço e antebraço incompletos (com pedículo de tecidos moles)', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reimplantes da mão, completa', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reimplantes da mão, incompleta (com pedículo de tecidos moles)', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reimplantes de dedos, completa', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reimplantes de dedos, incompleta (com pedículo de tecidos moles)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de craniosinostose por via extracraniana', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de craniosinostose por via intracraniana', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de teleorbitismo por via extracraniana', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de teleorbitismo por via intracraniana', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia têmporo-mandíbular', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coronoidectomia (operação isolada)', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do condilo mandíbular', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Meniscectomia têmporo-mandíbular', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de quisto ou tumor benigno da mandíbula', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção parcial da mandíbula, sem perda de continuidade', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção parcial da mandíbula com perda de continuidade', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção total da mandíbula', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção total da mandíbula com reconstrução imediata', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção parcial do maxilar superior', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção parcial do maxilar superior com reconstrução imediata', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção total do maxilar superior', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de outros ossos da face por quisto ou tumor', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução parcial da mandíbula com material aloplástico', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução parcial da mandíbula com enxerto osteo-cartilagineo', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução total da mandíbula com material aloplástico', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução total da mandíbula com enxerto ósseo', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteoplastia mandíbular por prognatismo ou retroprognatismo', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteoplastia da mandíbula segmentar', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteoplastia da mandíbula, total', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteoplastia do maxilar superior, segmentar tipo Le Fort I', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteoplastia maxilo-facial, com osteotomia tipo Le Fort II', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Condiloplastia mandíbular programada unilateral', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia têmporo-mandíbular (cada lado)', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cranioplastia complexa com enxerto ósseo', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia segmentar do maxilar superior', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cranioplastia simples com enxerto ósseo', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Disfunção intermaxilar', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cranioplastia simples com material aloplastico', 170);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ablação de tumor por dupla abordagem (intra e extracraniana)', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da fractura de nariz por redução simples fechada', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de fractura instável de nariz', 50);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento de fractura do complexo nasoetmoide, incluindo reparação dos ligamentos centrais epicantais',
   150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de fractura nasomaxilar (tipo Le Fort III)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da fractura-disjunção cranio-facial (tipo Le Fort III)', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de fractura do maxilar superior, por método simples', 75);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de fractura do maxilar superior, com fixação interna ou externa', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da fractura do complexo zigomático malar sem fixação', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da fractura do complexo zigomático malar com fixação', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de fractura do pavimento da órbita, tipo "blow-out"', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de fractura do pavimento da òrbita, tipo "blow-out" com endoprotese de "Silastic"', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de fractura do pavimento da órbita, tipo "blow-out", com enxerto ósseo', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio intermaxilar (operação isolada)', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da fractura da mandíbula por método simples', 75);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento ortopédico da fractura mandíbular por fixação intermaxilar', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico e osteossíntese da fractura mandíbular (1 osteossíntese)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de luxação têmporo-maxilar por manipulação externa', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de luxação têmporo-maxilar por método cirúrgico', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de fractura tipo Le Fort I ou Le Fort II', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico com osteossínteses múltiplas de fracturas mandíbulares', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de fractura do maxilar superior, por bloqueio intermaxilar', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de fractura do maxilar superior com osteossíntese', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com suspensão', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de fractura mandíbular por bloqueio intermaxilar', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de fractura mandíbular por osteossíntese e bloqueio intermaxilar', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de luxação têmporo-mandíbular por manipulação externa', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia dos escalenos', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia muscular dinâmica por transferência muscular', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxertos musculares livres', 250);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia estética para estabilização funcional das comissuras (suspensões) mioneurotomias selectivas',
   150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Torcicolo congénito, mioplastia de alongamento ou miectomia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Celulectomia cervical unilateral', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Celulectomia cervical bilateral', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurorrafia do nervo facial', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto nervoso do nervo facial', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto nervoso cruzado do nervo facial', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurotização a partir de outro nervo craniano', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do esterno (osteossíntese)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fracturas de costelas (fixação)', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de costelas', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação da parede torácica com prótese', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de "pectus excavatum" ou "carinatum"', 260);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura ou luxação vertebral', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apófises espinhosas cervicais', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apófises transversas lombares', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sacro e cóccix', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna cervical, via transoral ou lateral', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna cervical, via anterior ou anterolateral', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna cervical, via posterior', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna dorsal, via anterior', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna dorsal, via anterolateral', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna dorsal, via posterior', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna lombar, via anterior', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna lombar, via anterolateral', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna lombar, via posterior', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da occípito vertebral', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna cervical, via anterior', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna cervical, via posterior', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna dorsal, via anterior', 270);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna dorsal, via posterior', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna lombar, via anterior', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna lombar, via posterior', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna lombossagrada, via anterior', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna lombossagrada, via posterior', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da coluna lombossagrada, via combinada', 300);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Fracturas ou fractura luxação da coluna cervical, via transoral, sem artrodese ou osteossíntese', 180);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Fracturas ou fractura luxação da coluna cervical, via transoral, com artrodese ou osteossíntese', 220);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna cervical, via anterior ou anterolateral sem artrodese', 180);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna cervical, via anterior ou anterolateral com artrodese', 220);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna cervical, via posterior sem artrodese', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna cervical, via posterior com artrodese', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna dorsal, via anterior', 220);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna dorsal, via anterior com artrodese', 270);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna dorsal, via posterior sem artrodese', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna dorsal, via posterior com artrodese', 180);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna lombar, via anterior sem artrodese', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna lombar, via anterior com artrodese', 240);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna lombar, via posterior sem artrodese', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fracturas ou fractura luxação da coluna lombar, via posterior com artrodese', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espondilolistese via anterior', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espondilolistese via posterior', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espondilolistese via combinada', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Escoliose, cifose ou em associação - Artrodese posterior', 270);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Escoliose, cifose ou em associação - Artrodese anterior', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Escoliose, cifose ou em associação - Via combinada', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteótomia da coluna vertebral', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do cóccix', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de apofises transversas lombares', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lamínectomia descompressiva (até duas vértebras)', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laminectomia descompressiva (mais de duas vértebras)', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Realinhamento de canal estreito', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corporectomia cervical por via anterior', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Foraminectomia', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extirpação de hérnia discal cervical', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extirpação de hérnia discal dorsal', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extirpação de hérnia discal lombar', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nucleolise percutânea', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da clavícula', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da omoplata', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do troquíter', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da epífise umeral ou do colo do úmero', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da diáfise do úmero', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação esternoclavicular', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação acromioclavicular', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação gleno-umeral', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação do ombro', 65);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura da clavícula', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da pseudoartrose da clavícula', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da omoplata', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura-avulsão do troquíter', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese do colo do úmero com ou sem fractura do troquíter', 140);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de fractura cominutiva ou fractura-luxação da extremidade proximal do úmero', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese da diáfise umeral (com ou sem exploração do nervo radial)', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da pseudoartrose do úmero (colo ou diáfise)', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação esternoclavicular (aguda)', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação esternoclavicular (recidivante ou inveterada)', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação acrómioclavicular', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Redução da luxação do ombro (inveterada)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da luxação recidivante do ombro', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de osteomielite (clavícula omoplata, úmero)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de pequenos tumores benignos (exostoses inclusive, 1 ou 2)', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de tumores osteoperiósticos extensos', 180);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção óssea segmentar de tumores invasivos com reconstituição por prótese ou enxerto homólogo', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação interescápulotorácica', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desarticulação do ombro', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação pelo braço', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção parcial da omoplata', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção total da omoplata', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cleidectomia parcial', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cleidectomia total', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da extremidade proximal do úmero', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia com osteossíntese do úmero (colo ou diáfise)', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do acromion', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia parcial com prótese', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese do ombro', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia simples', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinovectomia', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da elevação congénita da omoplata', 210);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de tendinopatia calcificante', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento do síndroma de conflito infra-acromiocoracoideu', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia dos músculos do ombro', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da rotura da coifa', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da rotura do supraespinhoso', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura do tendão ou tendões do bicípite ou de um longo músculo do ombro', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição tendinosa por paralisia dos flexores do cotovelo', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de sequelas de paralisia obstétrica no ombro', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção das sequelas da paralisia braquial no ombro do adulto', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção das sequelas da paralisia braquial no cotovelo (dinamização)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do plexo braquial, exploração cirúrgica', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do plexo braquial, neurólise', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do plexo braquial, reconstrução com enxertos nervosos', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura supracondiliana do úmero', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura dos côndilos umerais', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da epitróclea ou epicôndilo', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do olecrâneo', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da tacícula radial', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da diáfise do rádio ou do cúbito', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura das diáfises do rádio e cúbito', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteoclasia por fractura em consolidação viciosa', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação do cotovelo', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação do cotovelo', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pronação dolorosa', 10);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese percutânea ou cruenta da fractura supracondiliana do úmero na criança', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura supracondiliana no adulto', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese supra e intercondiliana no adulto', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese de um côndilo umeral', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da epitróclea', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura-luxação complexa do cotovelo', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do côndilo umeral', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese do olecrâneo', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do olecrâneo', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese ou Exérese da tacícula radial', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução do ligamento anular do colo do rádio', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da diáfise do rádio ou do cúbito', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese diafisária dos dois ossos do antebraço', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese a "céu fechado" da diáfise do rádio ou do cúbito', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese a "céu fechado" diafisária dos dois ossos do antebraço', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura-luxação de Monteggia ou Galeazzi', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação do cotovelo (inveterada)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pseudartrose supracondiliana do úmero', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pseudartrose de um osso do antebraço', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pseudartrose dos dois ossos do antebraço', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de osteíte ou osteomielite no cotovelo ou antebraço', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de pequenos tumores benignos (exostoses inclusive, 1 ou 2)', 90);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de tumores sinoviais ou osteoperiósticos extensos no cotovelo', 180);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Ressecção óssea segmentar de tumores invasivos com reconstituição por prótese ou enxerto homólogo no cotovelo',
                                  220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção óssea segmentar no antebraço com reconstituição', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação do cotovelo', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação pelo antebraço', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Krukenberg', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrolise do cotovelo', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total do cotovelo', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia protésica da tacícula', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese do cotovelo', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia do rádio ou do cúbito', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia dos dois ossos do antebraço', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de sinostose rádiocubital', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia simples', 40);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinovectomia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição do nervo cubital', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da epicondilite ou epitrocleíte', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de higroma ou bursite', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia reparadora da retracção de Wolkman', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia dos músculos flexores ou extensores do punho e dedos', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenodese dos músculos do antebraço em um ou vários tempos', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Transposição dos tendões por paralisia dos extensores (paralisia do nervo radial)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição dos tendões por paralisia dos flexores dos dedos', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da extremidade distal do rádio ou cúbito', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do escafóide', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de outros ossos do carpo', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do 1º. Metacarpiano', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de outros metacarpianos', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de uma falange', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de duas ou mais falanges', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação rádio-cárpica', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação semilunar', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação de dedos da mão (cada)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da extremidade distal do rádio', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação rádiocubital distal', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do escafóide', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pseudartrose do escafóide', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação do semilunar', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação do punho', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação do carpo ou instabilidade traumática', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação de Bennet', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de um ou dois metacarpianos', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação metacarpofalângica', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de uma falange', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de várias falanges', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação interfalângica', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Várias luxações interfalângicas', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Curetagem (osteíte, encondromas) ou biópsia', 40);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de pequenas lesões ou tumores ósseos circunscritos com preenchimento ósseo', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da extremidade distal do rádio com reconstrução', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da apófise estiloideia do rádio', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da extremidade distal do cúbito', 70);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção parcial do escafóide cárpico ou semilunar com artroplastia de interposição', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da 1ª. fileira do carpo', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de um metacarpiano', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de dois ou mais', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção artroplástica metacarpofalângica (cada)', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação e desarticulação pelo punho', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação e desarticulação de metacarpiano', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação e desarticulação de dedo', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação de dois ou mais', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia distal do rádio', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia do 1º. metacarpiano', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia de um metacarpiano excepto 1º.', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia de uma falange', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total do punho', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia de substituição do escafóide ou semilunar', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia do grande osso para tratamento de doença Kienboeck', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total carpometacarpiana do polegar', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia metacarpofalângica ou interfalângica (uma)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia metacarpofalângica ou interfalângica (mais de uma)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese do punho', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese intercárpica', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese carpometacarpiana', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese metacarpofalângica ou interfalângica (cada)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alongamento de um metacarpiano ou falange', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Falangização do 1º. metacarpiano', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polegarização', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polegarização por transplante', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução do polegar num só tempo (Gillies)', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução do polegar em vários tempos com plastia abdominal ou torácica e enxerto ósseo', 230);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Reconstrução do polegar em vários tempos com plastia abdominal ou torácica, enxerto ósseo e pedículo neurovascular de Littler',
                                  300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com sinovectomia', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia ou artroscopia para tratamento de lesões articulares', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura dos tendões extensores dos dedos (um tendão)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura dos tendões extensores dos dedos (mais de um tendão)', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura dos tendões flexores dos dedos (um tendão)', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura dos tendões flexores dos dedos (mais de um tendão)', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia tendinosa para oponência ou para a extensão do polegar', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenosinovectomia do punho e mão', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da tenosinovite de DuQuervain', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação da bainha tendinosa dos dedos (dedo em gatilho)', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras tenolises', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fasciotomia limitada por retracção da aponevrose palmar', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fasciotomia total por retracção da aponevrose palmar', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fasciotomia total com enxerto cutâneo por retracção da aponevrose palmar', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção da deformidade em botoeira ou em colo de cisne', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Libertação da aderência dos tendões flexores dos dedos (Howard)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Libertação da aderência dos tendões extensores dos dedos (Howard)', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de ligamento metacarpofalângico ou interfalângico', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ligamentoplastia metacarpofalângica ou interfalângica', 80);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção da paralisia dos músculos intrinsecos por lesão do nervo cubital', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção da paralisia dos músculos intrinsecos por lesão do nervo mediano', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção cirúrgica de sindactilia (uma) sem enxerto', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, cada comissura a mais, sem enxerto', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com enxerto', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com enxerto por cada uma a mais', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção da sindactilia com sinfalangismo', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mão bota radial (partes moles)', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mão bota radial (com centralização do cúbito)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de polidactilia', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de clinodactilia', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de malformações congénitas do polegar', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenoplastia por enxerto ou prótese de tendão da mão (um)', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, dois', 170);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, três ou mais', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução osteoplástica dos dedos (Cada tempo)', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução dos dedos por transferência', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura ou tenólise dos tendões, extensores dos dedos da mão 1 tendão', 40);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura ou tenólise dos tendões extensores dos dedos da mão: mais de um tendão', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura tenólise dos tendões flexores dos dedos da mão 1 tendão', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenoplastia por enxerto de tendão da mão', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenoplastia por enxerto de tendão da mão', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenoplastia por enxerto de tendão da mão 3 ou mais', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fasciotomia por retracção da aponevrose palmar', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fasciectomia regional por retracção da aponevrose palmar', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fasciectomia total por retracção da aponevrose palmar', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fasciectomia parcial com enxerto cutâneo por retracção da aponevrose palmar', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fasciectomia total com enxerto cutâneo por retracção da aponevrose palmar', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção de sequelas reumatismais da mão (artroplastia) por cada articulação', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia por cada articulação', 70);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção da sindroma do canal cárpico e outras sindromes compressivos do membro superior', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de sindactília sem sinfalangismo', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exploração nervosa cirúrgica', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurorrafia sem microcirurgia', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto nervoso', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição nervosa', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do ílion, púbis ou ísquion', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com desvios ou luxações', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação congénita da anca (LCA)', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação coxofemoral', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da cavidade cotiloideia', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação traumática da anca', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do colo do fémur e fractura trocantérica', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Redução cirúrgica da luxação traumática da anca', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese do rebordo posterior do acetábulo', 170);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese das colunas acetabulares', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da sínfise púbica', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese sacro-íliaca', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação Malgaigne', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura do colo ou trocantérica', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de osteomielite', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Biópsia a "céu aberto" ou ressecção de pequenos tumores benignos (exostoses inclusive, 1 ou 2)', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de tumores osteoperiósticos extensos', 200);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção óssea segmentar de tumores invasivos com reconstituição por prótese ou enxerto homólogo', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação interílio-abdominal', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desarticulação coxofemoral', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da extremidade superior do fémur (Girdlestone)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia com osteossíntese, do colo do fémur', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, trocantérica ou subtrocantérica, na criança', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, trocantérica ou subtroncatérica, no adulto', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomias tipo Salter, Chiari ou Pemberton', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tectoplastia cotiloideia', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Redução cirúrgica de LCA com duas ou mais osteotomias', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição do grande trocânter', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queilectomia', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia parcial (Moore, Tompson)', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total em coxartrose ou revisão de hemiartroplastia', 220);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artroplastia total em revisão de prótese total, de artrodese, de LCA ou após Girdlestone', 260);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese sacro-ilíaca (Unilateral)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese da anca sem osteossíntese', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com osteossíntese', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fixação in situ de epifisiolise', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de epifísiolise com osteotomia e osteossíntese', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia simples', 70);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinovectomia', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia dos adutores com ou sem neurectomia', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição dos adutores', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia dos adutores com neurectomia intrapélvica', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia ou alongamento dos flexores', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia dos rotatores', 90);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Plastia músculo-aponevrótica por paralisia dos glúteos em 1 ou vários tempos', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição dos glúteos em 1 ou vários tempos', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição do psoas-iliaco', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da bolsa subglútea incluindo trocânter', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da anca de ressalto', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da pubalgia', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da diáfise do fémur', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura supracondiliana ou intercondiliana', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura ou luxação da rótula', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação do joelho', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da extremidade proximal da tíbia ou dos planaltos tibiais', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lesão ligamentar', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação femorotibial', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese diafisária a "céu aberto"', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese diafisária a "céu fechado"', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotaxia da fractura do fémur', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura supracondiliana', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura supra e intercondiliana', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura unicondiliana', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da rótula (osteossíntese ou patelectomia)', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da espinha da tíbia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de um planalto tibial', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteossíntese da fractura bituberositária ou da fractura cominutiva da extremidade proximal', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese das fracturas osteocondrais', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteomielite', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pseudartrose do fémur', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrite séptica', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de pequenos tumores benignos (exostoses, 1 ou 2)', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de tumores osteoperiósticos extensos', 140);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção óssea segmentar de tumores invasivos com reconstituição por prótese ou enxerto homólogo', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com reconstituição da continuidade óssea por artrodese', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação pela coxa', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação pelo joelho', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia diafisária ou distal do fémur', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia proximal da tíbia', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia da tíbia e peróneo', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Epifisiodese (cada osso)', 60);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução focal da superfície articular com enxerto osteocartilagíneo', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artroplastia total por artrose ou revisão de prótese unicompartimental', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total por revisão de prótese total', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia unicompartimental femorotibial', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia femoropatelar', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese do joelho', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Meniscectomia convencional ou artroscópica', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reinserção meniscal convencional ou artroscópica', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Um dos ligamentos cruzados', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Um dos ligamentos periféricos', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação das lesões da "tríada"', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação das lesões da "pêntada"', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ligamento cruzado (cada)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ligamento periférico (cada)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extrarticulares ou de compensação (acto cirúrgico isolado)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extrarticulares ou de compensação (acto cirúrgico associado)', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quadriciplastia', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia pararotuliana convencional ou artroscópica (suturas, plicaduras, secções)', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação recidivante da rótula', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação congénita da rótula', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tendinite rotuliana', 90);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Rotura do tendão quadricipital, rotuliano, ou fractura-avulsão tuberositária', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alongamento ou encurtamento do aparelho extensor a qualquer nível', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrolise simples convencional ou artroscópica', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia simples e artroscopia diagnóstica', 60);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinovectomia', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operações sobre os tendões (Eggers)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transferência dos isquiotibiais para a rótula', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras transferências', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intervenções múltiplas para correcção do flexo', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fasciotomia (Yount)', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bursite ou higroma rotuliano', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quisto poplíteu, outros quistos e bursites', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da diáfise da tíbia e peróneo', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da diáfise da tíbia', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da diáfise do peróneo', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura da extremidade distal da tíbia', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação do tornozelo', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura monomaleolar', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura bimaleolar', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura trimaleolar', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação do tornozelo', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Entorse ou rotura ligamentar externa do tornozelo', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura diafisária da tíbia a "céu aberto"', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura diafisária da tíbia a "céu fechado"', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da tíbia e peróneo', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotaxia da fractura da tíbia', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento da pseudoartrose da diáfise da tíbia após fractura (com ou sem enxerto ósseo)', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da pseudoartrose congénita da tíbia', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da diáfise do peróneo', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação tibiotársica', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese de um ou dois maléolos ou equivalentes ligamentares', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese trimaleolar ou equivalentes ligamentares', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura cominutiva do pilão tibial', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção da consolidação viciosa da fractura de um maleolo', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção da consolidação viciosa das fracturas bi ou trimaleolares', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteomielite (tratamento em um tempo)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteomielite (tratamento em dois ou mais tempos)', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de pequenos tumores benignos (exostoses inclusive, 1 ou 2)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de tumores osteoperiósticos extensos', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção óssea segmentar de tumores invasivos com reconstrução por prótese ou enxerto', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação pela perna', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia diafisária da tíbia sem osteossíntese', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia diafisária da tíbia com osteossíntese', 130);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteotomia diafisária do peróneo (isolada, não adjuvante de osteotomia da tíbia)', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da cabeça do peróneo', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia da extremidade distal da tíbia e peróneo', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia total do tornozelo', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese do tornozelo', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia simples e artroscopia diagnóstica', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia ou artroscopia com tratamento de lesões articulares circunscritas', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrotomia por osteotomia maleolar com tratamento de lesões articulares', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sinovectomia total', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia subcutânea do tendão de Aquiles', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Alongamento a "céu aberto" do tendão de Aquiles ou tratamento da tendinite', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação da rotura do tendão de Aquiles', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação da rotura de outros tendões na região', 60);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Tratamento do síndrome do canal társico e das neuropatias estenosantes dos ramos do nervo tíbial posterior',
                                  110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da luxação dos peroniais', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação de instabilidade ligamentar crónica do tornozelo', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição tendinosa para a insuficiência tricipital', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do astrágalo', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação do astrágalo', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do calcâneo', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de outros ossos do tarso', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de um metatarso', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de mais que um metatarso', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura de um ou mais dedos', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação mediotársica ou tarsometatársica', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação de dedos (cada)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura ou fractura luxação do astrágalo', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese da fractura do calcâneo', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura do tarso', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese de um ou dois metatarsianos', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese de mais de dois metatarsianos', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese de uma ou duas falanges de dedos', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteossíntese de mais de duas falanges', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fractura-luxação tarsometatársica', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação tarsometatársica', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Luxação de dedo (cada)', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de osteomielite no retropé', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de osteomielite no mediopé ou antepé', 80);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de pequenas lesões ou tumores ósseos circunscritos com preenchimento ósseo', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação de Syme', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação transmetatarsiana', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação do 1º. Raio (metatarsiano+hallux)', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação de raio do 2º. Ao 5º. (metatarsiano+dedo)', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação de dedo', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do astrágalo', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de um ou mais ossos do tarso', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de um metatarsiano', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dois ou mais metatarsianos', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de exostose ou ossículo supranumerário no retro ou mediopé', 60);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ressecção artroplástica de uma metatarsofalângica, excepto a 1ª. Ou de uma ou duas interfalângicas', 60);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção artroplástica de duas metatarsifalângicas, excepto a 1ª. Ou de várias interfalângicas', 60);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção artroplástica múltipla para realinhamento metatarsofalângico', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia do calcâneo', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia mediotársica', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese subastragaliana (intra ou extrarticular)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Triciple artrodese', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese mediotársica', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese tarsometatarsiana', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrorrisis subastragaliana no pé plano infantil (via interna e externa)', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artrorrisis subastragaliana no pé plano infantil por "calcâneo stop" bilateral', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alongamento de um metatarsiano', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Alongamento de dois ou mais metatarsianos', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrotomia', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com sinovectomia', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção simples de exostose no 1º.metatarsiano', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção simples de exostose no 5º.metatarsiano', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia de ressecção metatarsofalângica (tipo Op. de Keller)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Realinhamento da 1º. metatarso falângica (tipo Op. de Silver)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia da base do 1º. metatarsiano ou artrodese cuneometatarsiana', 80);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteotomia diafisária do 1º. metatarsiano (tipo Qp. Wilson ou de Helal)', 80);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Osteotomia distal do 1º. Matatarsiano (tipo Op. de Mitchell ou de "chevron")', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição do tendão conjunto (tipo Op. de McBride)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artroplastia de interposição da 1ª. metatarsofalângica', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese metatarsofalângica do 1º.raio', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia de um ou de dois metatarsianos, excepto o 1º.', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia de três ou de mais metatarsianos, excepto o 1º.', 80);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Uma ou duas artroplastias de interposição protésica metarsofalângica, excepto no 1º. raio, ou interfalângicas',
                                  100);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Três ou mais artroplastias de interposição protésica metatarso falângicas, excepto no 1º. raio, ou interfalângicas',
                                  120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Uma ou duas artroplastias de ressecção ou artrodeses interfalângicas, excepto no 1º. raio', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Três ou mais artroplastias de ressecção ou artrodeses interfalângicas, excepto no 1º. raio', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteotomia cuneiforme ou de encurtamento da 1ª. falange no hallux', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artrodese ou tenodese interfalângica no hallux', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento do 5º. dedo aduto', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transferência do tendão do tibial posterior', 130);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Transferência de tendão do tibial anterior, peroniais ou do longo extensor comum', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Transferência do longo extensor ao colo do 1º. metatarsiano (Op. de Jones)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transferência do extensor comum ao colo dos metatarsianos', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenodeses e outras transferências de tendão da perna ou pé', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de doença de Morton', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Secção superficial da fáscia plantar', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Secção profunda das estruturas plantares (Op. de Steindler)', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenotomia dum tendão do pé ou dedo', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, de vários dedos', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tenoplastias com enxerto-1 tendão', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, 2 tendões', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, 3 ou mais tendões', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento do pé boto', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento do astrágalo vertical congénito', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento do antepé aduto (metarsus varus)', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de defeitos congénitos no antepé e dedos', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento do pé plano valgo', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colheita de enxerto cortico-esponjoso, como adjuvante de uma cirurgia', 30);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento de quisto, ou outros defeitos ósseos circunscritos, por esvasiamento e preenchimento com', 140);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento de quisto, ou outros defeitos ósseos circunscritos, por esvaziamento e preenchimento com', 120);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento de quisto, ou outros defeitos ósseos circunscritos, por esvaziamento e preenchimento com', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição óssea', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trepanação óssea', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Por via percutânea', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Alongamento ósseo com fixador externo (Illizarov, Wagner, etc.) (tratamento total)', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fasciotomias por síndrome de compartimento', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumores benignos', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumores malignos de tecidos moles', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tamponamento nasal anterior', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, posterior', 27);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cauterização da mancha vascular', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpos estranhos das fossas nasais com anestesia local', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com anestesia geral', 32);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocoagulação dos cornetos unilateral', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Turbinectomia unilateral', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de papiloma do vestíbulo nasal', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, de pólipo sangrante do septo', 37);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polipectomia nasal unilateral', 37);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 57);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polipectomia nasal com etmoidectomia unilateral', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polipectomia com Caldwell-Luc unilateral', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Caldwell-Luc unilateral', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Caldwell-Luc com etmoidectomìa unilateral', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Ermiro de Lima', 145);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do nervo vidiano', 145);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção submucosa do septo', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Septoplastia (operação isolada)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Microcirurgia endonasal e /ou endoscópica unilateral', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abordagem da hipófise, via transeptal', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rino-septoplastia', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da ozena', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Etmoidectomia externa por via paralateronasal', 125);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Etmoidectomia total, via combinada', 260);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de quisto naso-vestibular', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção da sinéquia nasal', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação osteoplástica da sinusite frontal', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Maxilectomia sem exenteração da órbita', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com exenteração', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de angiofibroma naso-faringeo', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rinectomia parcial', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, total', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de rinofima', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abordagem cirúrgica do seio esfenoidal', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de imperfuração choanal via endonasal', 65);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, outras vias', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de hematoma do septo nasal', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção do seio maxilar', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção do seio maxilar com implantação de tubo de drenagem', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, bilateral', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem do seio frontal', 65);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laringectomia total simples', 270);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laringectomia supra glótica com esvaziamento', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemilaringectomia', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laringofissura com cordectomia', 155);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aritenoidopexia', 155);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aritenoidectomia+ Cordopexia', 155);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de estenose laringo-traqueal (1º. Tempo)', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tempos seguintes', 135);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laringectomia (total ou parcíal) com esvaziamento unilateral', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com esvaziamento bilateral', 365);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Faringo-laringectomia com esvaziamento sem reconstrução', 365);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com reconstrução', 465);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Microcirurgia laríngea', 135);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Microcirurgia laríngea com laser', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico das malformações congénitas da laringe (bridas, quistos, palmuras)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traqueotomia (operação isolada)', 85);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cricotiroidotomia (operação isolada)', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento simples de traqueotomia ou fístula traqueal', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fístula fonatória', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traqueoplastia por estenose traqueal', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncoplastia', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncotomia', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anastomose traqueo-brônquica ou bronco-brônquica', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de ferida brônquica', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fístula traqueo-ou bronco-esofágica, tratamento cirúrgico', 270);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpos estranhos por via endoscópica', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem pleural', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem pleural por empiema com ressecção costal', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracotomia exploradora', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracotomia por ferida aberta do tórax', 135);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracotomia por pneumotórax espontâneo', 135);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracotomia por hemorragia traumática ou perda de tecido pulmonar', 135);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pneumectomia', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pneumectomia com esvaziamento ganglionar mediastinico', 370);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lobectomia', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bilobectomia', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Segmentectomia ou ressecção em cunha, única ou múltipla', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção pulmonar com ressecção de parede torácica', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracoplastia (primeiro tempo)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracoplastia (tempo complementar)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor da pleura', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Descorticação pulmonar', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pleurectomia parietal', 175);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Toracoplastia de indicação pleural (num só tempo)', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento do canal arterial', 175);
INSERT INTO ProcedureType VALUES (DEFAULT, '"Banding" da artéria pulmonar', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Blalock e outros shunts sistémico-pulmonares', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Focalização de MAPCAS', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de anel vascular', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Shunt cavo-pulmonar', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Blalock-Hanlon', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de coartação da aorta torácica', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de interrupção do arco aórtico', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação de aneurisma/rotura traumática da aorta torácica', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvulotomia aórtica', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pericardiotomia - via subxifoideia', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Construção de janela pleuropericárdica', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pericardiectomia', 370);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvulotomia mitral', 355);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de feridas cardíacas', 325);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia de implantação epicárdica de sistemas de pacemaker/disfibrilhação automática', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bypass coronário com veia safena e/ou 1 anastomose arterial', 500);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bypass coronário com 2 ou mais anastomoses arteriais', 525);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bypass coronário com 3 ou mais anastomoses arteriais', 550);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de aneurisma do VE com ou sem bypass coronário', 600);
INSERT INTO ProcedureType VALUES (DEFAULT, 'rotura do septo IV ou parede livre após enfarte', 650);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição de uma válvula', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição de duas válvulas', 500);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição de três válvulas', 550);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia de 1 válvula', 500);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia de 2 ou mais válvulas', 550);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Ross', 700);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumores de coração', 500);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de comunicação inter auricular', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de comunicação interventricular', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de estenose da artéria pulmonar', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de canal AV parcial/Ostium Primum', 500);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de canal AV completo', 550);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de Tetralogia de Fallot simples', 525);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de obstrução da câmara de saída VE', 500);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dissecção da aorta', 625);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Substituição da aorta ascendente e válvula aórtica c/tubo valvulado ou homoenxerto (op. de Bentall)', 700);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do arco aórtico', 700);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Outras cirurgias para correcção total de cardiopatias congénitas complexas', 700);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Troncos supra-aorticos (carótida e TABC)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias dos membros-incisão única', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias dos membros-incisão múltipla', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bifurcação aórtica', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias viscerais', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria carótida, via cervical', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria carótida, via torácica', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tronco arterial braquiocefálico', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias subclavias, via cervical', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias subclavias, via torácica ou combinada', 230);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria vertebral', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria do membro superior', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorta abdominal', 230);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ramos viscerais da aorta', 280);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artérias ilíacas: unilateral sem desobstrução aórtica, via abdominal ou extraperitoneal', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artérias ilíacas: unilateral sem desobstrução aórtica, via inguinal (anéis)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bilateral, em combinação com a aorta', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bilateral, sem desobstrução aórtica, via abdominal', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bilateral, sem desobstrução aórtica, via inguinal (aneis)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria femoral comum ou profunda', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artérias femoral superficial ou poplitea ou tronco tibioperoneal segmentar', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artérias femoral superficial ou poplitea ou tronco tibioperoneal, extensa(Edwards)', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revascularização de artéria cerebral extra-craniana (via cervical)', 230);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, via torácica', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Subclavio-subclavia ou axilar', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-subclavia', 300);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Revascularização múltipla de troncos supra-aorticos a partir da aorta', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Axilo-femoral unilateral', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Axilo-bifemoral', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revascularização de um ramo visceral da aorta', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revascularização múltipla de ramos viscerais da aorta', 460);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-iliaco unilateral', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-iliaco bilateral', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-femoral ou aorto-popliteo unilateral', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-femoral ou aorto-popliteo bilateral', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-iliofemoral unilateral', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-iliofemoral bilateral', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-femoropopliteo unilateral', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorto-femoropopliteo bilateral', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ilio- femoral via anatómica', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ilio-femoral via extra anatómica', 230);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Femoro-popliteo ou femoro- femoral unilateral', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Femoro- femoral cruzado', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ilio-iliaco', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Femoro-distal', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Popliteo-distal', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias dos membros superiores', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias genitais', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arco aortico, com protecção por C.E.C. ou pontes (incluindo toda a equipa médica)', 800);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Aorta descendente torácica e/ou abdominal; incluindo ramos viscerais, sem C.E.C. (aorta toracoabdominal)',
   500);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Aorta descendente, torácica e abdominal, incluindo ramos viscerais, com C.E.C. (incluindo a equipa médica)',
                                  600);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carótidas via cervical', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carótidas via toracocervical', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com C.E.C. ou ponte (incluindo toda a equipa médica)', 800);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tronco braquiocefálico', 430);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias subclavias, via cervical ou axilar', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias subclavias, via toracocervical', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias axilar e restantes do membro superior', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorta abdominal infra-renal', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ramos viscerais da aorta', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias ilíacas', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias femorais ou popliteas', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras artérias dos membros', 180);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reparação das lesões da dissecção da aorta, tipo distal na porta de entrada', 500);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, nos ramos viscerais da aorta', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, na circulação dos membros inferiores', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'No pescoço', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'No tórax com C.E.C. ou ponte', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'No tórax sem C.E.C. ou ponte', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'No abdómen, aorta acima de renais', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'No abdómen, aorta abaixo de renais ou ilíacas', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ramos viscerais da aorta', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nos membros, simples', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nos membros, quando combinada com sutura venosa', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias carótidas, exploração simples', 80);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Artérias carótidas, libertação e fixação para tratamento de angulações', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias do tórax', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias do abdómen e pelve', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias dos membros', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias do pescoço', 190);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias intratorácicas', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias abdominais', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias dos membros', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria maxilar interna na fossa pterigopalatina', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria etmoidal anterior, via intraorbitária', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias do pescoço', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias do tórax', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias abdominais', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de prótese entre a aorta e artérias do membro inferior', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, entre a aorta e troncos supraaorticos', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias dos membros', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento da fístula aorto-digestiva ou aortocava', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Simpaticectomia lombar', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Simpaticectomia cervicodorsal', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Simpaticectomia torácica superior (via axilar ou transpleural)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de costela cervical, unilateral', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção da 1ª. Costela, unilateral', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias cava inferior, ilíacas, femorais e popliteas, via abdominal', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Grandes veias do tórax', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias dos membros (via periférica)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias viscerais abdominais', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias do pescoço', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Grandes veias do tórax', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veia cava inferior acima das veias renais', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Restantes veias do abdómen', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias dos membros', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto do segmento venoso valvulado', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Valvuloplastias', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Palma e similares', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias do pescoço', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias dos membros', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias do tórax', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Grandes veias abdominais e pélvicas', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laqueação de veias do pescoço', 60);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Interrupção da veia cava inferior por laqueação, plicatura, ou agrafe', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Interrupção de veia ilíaca', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Interrupção de veia femoral', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laqueação isolada da crossa da veia safena interna ou externa', 80);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Idem + excisão da veia safena interna ou externa com ou sem laqueação de comunicantes com ou sem excisão de segmentos venosos',
                                  160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem em ambas as veias de um membro (veia safena interna e externa)', 190);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Excisão da veia safena interna ou externa com ou sem laqueação de comunicantes, com ou sem laqueação de segmentos venosos intermédios, sem laqueação de crossas de safena interna ou externa',
                                  130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laqueação de comunicantes com ou sem excisão de segmentos venosos', 75);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Laqueação da crossa da veia safena interna ou externa + laqueação de comunicantes com ou sem excisão de segmentos',
                                  150);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Laqueação das crossas das veias safena interna e externa + laqueação de comunicantes com ou sem excisão venosas',
                                  190);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Revisão de laqueação de crossa de veia safena interna ou externa em recidiva de varizes', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem em ambas as veias de um membro', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Linton ou Cockett isolada', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem a adicionar a valor de outra cirurgia de varizes', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Via torácica, intraesofágica', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Via abdominal, extragastrica', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Via abdominal, intra e extragastrica', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Sugiura', 200);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Via abdominal, transsecção esofágica ou plicatura com anastomose(instrumento mecânico)', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Via abdominal, ressecção gástrica', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Porto-cava termino-lateral', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Porto-cava latero-lateral', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Porto-cava em H', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esplenorenal proximal (anastomose directa)', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esplenorenal distal (op. Warren) ou espleno cava distal', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esplenorenal em H', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mesenterico-cava ­ iliaca-ovarica ou renal', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mesenterico-cava em H', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coronário-cava (op. Inokuchi)', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras anastomoses atípicas', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arterialização do fígado', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão-enxerto', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto pediculado', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Thompson', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Epiploplastia', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Implantação de fios ou outro material para incrementar a drenagem linfática', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anastomose linfovenosa', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Canal torácico, via cervical', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Canal torácico, via torácica', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Membros', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura ou anastomose do canal torácico, via cervical', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura ou anastomose do canal torácico, via torácica', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ponte (Shunt) exterior', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fistula arteriovenosa no punho', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fistula arteriovenosa no cotovelo', 130);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ponte arterio-arterial ou arterio-venosa (não inclui o custo de op. acessória ou de prótese)', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia das complicações dos acessos vasculares com continuidade do acesso', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com sacrifício do acesso vascular', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Introdução de cateter i.v. com tunelização ou em posição subcutânea', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revascularização da artéria hipogastrica', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revascularização do pénis', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com microcirurgia', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de drenagem venosa do pénis', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veia cava superior', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coração direito ou artéria pulmonar', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias cervicais', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias renais', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias supra-hepáticas', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias intra-hepática', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veia aferente do sistema porta', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Veias dos membros', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carótida', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria vertebral', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria do membro superior ou inferior', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aorta', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carótida', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artéria dos membros', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Canal torácico', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vasos linfáticos de membros (superiores e inferiores)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esplenectomia (total ou parcial) ou esplenorrafia', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso ganglionar', 17);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de gânglio linfático superficial', 32);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de gânglio linfático profundo', 42);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de linfangioma quistico (Exceptuando parótida)', 155);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de linfangioma quístico cervico-parótideo', 270);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento suprahioideu, unilateral', 115);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento suprahioideu, bilateral', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento cervical radical', 165);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento cervical radical, bilateral', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento cervical conservador, unilateral', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento cervical conservador, bilateral', 210);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento axilar', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento inguinal, unilateral', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento inguinal e pélvico em continuidade, unilateral', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento pélvico unilateral', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento pélvico bilateral', 210);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvasiamento retroperitoneal (aorto-renal e pélvico)', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mediastinotomia transesternal exploradora', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mediastinotomia transtorácica exploradora', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor do mediastino', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia do hiato por via abdominal', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia do hiato por via torácica', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de rotura traumática do diafragma', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia de Bochdalek', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imbricação do diafragma por eventração', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia de Morgagni', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de diafragma (por tumor ou perfuração inflamatória)', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação do diafragma com prótese', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Em cavidade com compromisso de 1 só face dentária', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Em cavidade com compromisso 2 faces dentárias', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Em cavidade com compromisso de 3 ou mais faces dentárias', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Com espigões dentários ou intra-radiculares (cada espigão)', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polimento de restauração metálica', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dente de 1 só canal', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dente de 2 canais', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dente com 3 canais', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Endodontio que necessita várias sessões de tratamento (por sessão)', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação tópica de fluoretos (por sessão)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação de compósitos para selagem de fisuras (por quadrante)', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Destartarização (por sessão de ½ hora)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Curetagem sub-gengival (por quadrante) sem cirurgia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gengivectomia (por bloco anterior ou lateral)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia de retalho', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxertos pediculados', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto da mucosa bucal', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Auto-enxerto ósseo', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estabilização de peças dentárias por qualquer técnica', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exodontia simples de monorradicular', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exodontia simples de multirradicular', 13);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exodontia complicada ou de siso incluso, não complicada (sem osteotomia)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exodontia de dentes inclusos', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reimplantação dentária', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Germectomia', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transplantação de germes dentários', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exodontias múltiplas sob anestesia geral', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exodoptia seguida de sutura', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apicectomia de monorradiculares', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apicectomia de multirradiculares', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aprofundamento do vestíbulo (por quadrante)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desinserção e alongamento do freio labial', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de bridas gengivais (por quadrante)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Radiculectomia', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quistos paradentários, com anestesia local ou regional', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quistos paradentários, com anestesia geral', 75);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exérese de ranulas simples ou outros pequenos tumores dos tecidos moles da cavidade oral, com anestesia local',
                                  20);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exérese de ranulas simples ou outros pequenos tumores dos tecidos moles da cavidade oral, com anestesia geral',
                                  50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Curetagem de focos de osteite não simultânea com a exodontia', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia de tecidos moles', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia óssea', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de epulides, hiperplasia do rebordo alveolar', 30);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Redução e contenção do dente luxado por trauma com regularização do bordo alveolar (por quadrante)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de abcessos de origem dentária, por via bucal', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de abcessos de origem dentária, por via cutânea', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Radiografia apical', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Interpromixal (Bitewing)', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Radiografia oclusal', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ortopantomografia', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aparelhos removíveis', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Controle', 7);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aparelhos fixos', 550);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Controle', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conserto de aparelho removível, sem impressão', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conserto de aparelho removível, com impressão', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conjunção de fixação extra-oral', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Impressões e modelos de estudo', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Análise cefalométrica da telerradiografia e panorâmica', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotografia e estudo fotográfico', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Impressão el alginato e modelo de estudo', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Impressão em alginato em moldeira individual e modelo de trabalho', 20);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Impressão em elastrómero de síntese ou hidrocoloide reversível (com moldeira ajustada ou equivalente)',
   45);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Impressão funcional usando base ajustada, material termoplástico e outro', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Impressão de preparação com espigões intradentários paralelos', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Placa para registo de relação intermaxilar', 5);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Registo da relação intermaxilar usando cera em base estabilizada numa arcada', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem em duas arcadas em (p.p.)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem numa arcada (P.T.)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, '1 dente', 28);
INSERT INTO ProcedureType VALUES (DEFAULT, '2 dentes', 31);
INSERT INTO ProcedureType VALUES (DEFAULT, '3 dentes', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, '4 dentes', 38);
INSERT INTO ProcedureType VALUES (DEFAULT, '5 dentes', 42);
INSERT INTO ProcedureType VALUES (DEFAULT, '6 dentes', 46);
INSERT INTO ProcedureType VALUES (DEFAULT, '7 dentes', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, '8 dentes', 54);
INSERT INTO ProcedureType VALUES (DEFAULT, '9 dentes', 58);
INSERT INTO ProcedureType VALUES (DEFAULT, '10 dentes', 61);
INSERT INTO ProcedureType VALUES (DEFAULT, '11 dentes', 65);
INSERT INTO ProcedureType VALUES (DEFAULT, '12 dentes', 69);
INSERT INTO ProcedureType VALUES (DEFAULT, '13 dentes', 72);
INSERT INTO ProcedureType VALUES (DEFAULT, '14 dentes', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, '28 dentes', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, '1 dente', 55);
INSERT INTO ProcedureType VALUES (DEFAULT, '2 dentes', 68);
INSERT INTO ProcedureType VALUES (DEFAULT, '3 dentes', 76);
INSERT INTO ProcedureType VALUES (DEFAULT, '4 dentes', 86);
INSERT INTO ProcedureType VALUES (DEFAULT, '5 dentes', 98);
INSERT INTO ProcedureType VALUES (DEFAULT, '6 dentes', 113);
INSERT INTO ProcedureType VALUES (DEFAULT, '7 dentes', 122);
INSERT INTO ProcedureType VALUES (DEFAULT, '8 dentes', 132);
INSERT INTO ProcedureType VALUES (DEFAULT, '9 dentes', 139);
INSERT INTO ProcedureType VALUES (DEFAULT, '10 dentes', 143);
INSERT INTO ProcedureType VALUES (DEFAULT, '11 dentes', 148);
INSERT INTO ProcedureType VALUES (DEFAULT, '12 dentes', 143);
INSERT INTO ProcedureType VALUES (DEFAULT, '13 dentes', 156);
INSERT INTO ProcedureType VALUES (DEFAULT, '14 dentes', 158);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Preparação dentária para coroa de revestimento total', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem para a coroa em auro-cerâmica', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem para a coroa com espigão intraradicular', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem para coroa tipo Jacket', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem para coroa 3/4 ou 4/5', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem para coroa com espigões paralelos intradentinários', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem para falso-côto fundido', 25);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Preparação gengival com vista à tomada de impressão imediata: retracção gengival, cirurgia, hemostase, remoção de mucosidade e coágulos (em cada elemento)',
                                  30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova ou inserção de cada elemento protético (por sessão)', 15);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Elaboração de prótese provisória em resina para protecção de côto preparado', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gancho em aço inoxidável', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rebaseamento em prótese superior ou inferior', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rebaseamento em resina mole', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Barra em aço inoxidável', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conserto de fractura de prótese acrílica', 21);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acrescentar um dente numa prótese', 23);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acrescentar mais de um dente numa prótese: por cada dente mais', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Goteira oclusal simples', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Soldadura em prótese de cromo-cobalto', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rede de cromo-cobalto', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Barra lingual ou palatina', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dente fundido em prótese em cromo-cobalto', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acrescentar uma cela em prótese de cromo-cobalto', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gancho fundido', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Face oclusal fundida', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Obtenção de modelos para análise oclusal', 20);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Montagem de modelos em articulador semifuncional sem registos individuais mas com arco facial (valores médicos) e análise',
                                  80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Equilíbrio oclusal clínico (por sessão)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Montagem de modelos em articulador semifuncional com uso de arco facial ajustado e de arco localizador cinemático, e com registos individuais',
                                  300);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Equilíbrio oclusal do paciente de acordo com os valores obtidos no articulador', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia para colocação de implantes', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção do bordo livre com avanço da mucosa', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão em cunha com encerramento directo', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção maior que ¼ com reconstrução', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção total do lábio inferior ou superior com reconstrução', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de fenda labial completa unilateral', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de fenda palatina parcial', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da fenda labial bilateral', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de fenda labial tempos complementares', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de outras malformações congénitas dos lábios cada tempo', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de fenda completa unilateral do paladar primário', 140);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de fenda bilateral (cada lado) do paladar primário', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento cirúrgico de fenda do paladar primário tempos complementares', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fístulas congénitas labiais', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de quistos, abcessos, hematomas', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia do freio lingual', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de lesão da mucosa ou sub-mucosa', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de lesão da mucosa ou sub-mucosa com plastia', 55);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de laceração superficial', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de laceração com mais de 2 cm, profunda', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vestibuloplastia por quadrante', 30);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Incisão e drenagem de quistos, abcessos intra-orais ou hematomas da língua ou pavimento da boca-superficiais',
                                  20);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Incisão e drenagem de quistos, abcessos intra-orais ou hematomas da língua ou pavimento da boca-profundos',
   25);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Incisão e drenagem extra-oral de abcesso, quisto e/ou hematoma do pavimento da boca ou sublingual', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de lesão da língua localizada nos 2/3 anteriores', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de lesão da língua localizada no 1/3 posterior', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de lesão do pavimento da boca', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glossectomia menor que ½ da língua', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemiglossectomia', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemiglossectomia com esvasiamento unilateral do pescoço', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glossectomia total, sem esvasiamento cervical', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glossectomia total, com esvasiamento unilateral', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glossectomia total com esvasiamento bilateral', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glossectomia com ressecção do pavimento da boca e mandíbula', 250);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Glossectomia com ressecção do pavimento da boca e mandíbula com esvaziamento cervical', 320);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reparação de laceração até 2 cm do pavimento ou dos 2/3 anteriores da língua', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação de laceração do 1/3 posterior da língua', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação de laceração do pavimento ou língua (mais de 2 cm)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso do palato ou úvula', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de lesão do palato ou úvula', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de exostose do palato', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de laceração do palato até 2 cm', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de laceração do palato mais de 2 cm', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Palotoplastia para tratamento de ferida (palato mole)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Retalho osteo periósteo ou enxerto ósseo em fenda alveolo palatina', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Estafilorrafia por fenda palatina incompleta ou estafilorrafia simples', 125);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uranoestafilorrafia por fenda palatina completa', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução do palato anterior em fenda alveolo-palatina', 125);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de fístula oroantral', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Palatoplastia para correcção de roncopatia', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Adenoidectomia (Laforce-Beckman)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com anestesia geral e intubação endotraqueal', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amigdalectomia por Sluder', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, por dissecção, com anestesia geral e intubação endotraqueal', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Adenoidectomia com amigdalectomia por Sluder-Laforce-Beckman', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, por dissecção (com anestesia geral e intubação endotraqueal)', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho da orofaringe', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, da hipofaringe', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso amigdalino', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, abcesso retro ou parafaríngeo, por via oral', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, por via externa', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Faringoplastia em sequela de ferida palatina', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Faringoplastia em sequela de fenda palatina', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de faringostoma, por cada tempo operatório', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Faringotomia', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extirpação das apófises estiloideias', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extirpação de fístula ou quisto branquial, amigdalino, etc.', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de faringotomia com retalho', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor parafaringeo', 210);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Faringoplastia em sequela de fenda do paladar secundário', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem simples de abcessos (parótida, submaxilar ou sublingual)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Marsupialização de quisto sublingual (rânula)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de quisto sublingual ou do pavimento', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parotidectomia superficial', 210);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parotidectomia total com sacrifício do nervo facial', 210);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parotidectomia total com dissecção e conservação do nervo facial', 310);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parotidectomia total com reconstrução do nervo facial', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de glândula submaxilar', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de glândula sublingual', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção para sialografia com dilatação dos canais salivares', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de cálculos dos canais salivares por via endobucal', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de glândulas salivares aberrantes', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagotomia cervical', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagotomia torácica', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Miotomia cricofaríngea', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Heller', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagectomia cervical (operação tipo Wookey)', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagectomia sub-total com reconstituição da continuidade', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagectomia da 1/3 inferior com reconstituição da continuidade', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diverticulectomia de Zenker', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagostomia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esofagoplastia, por atrésia do esófago', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laqueação de fístula esófago-traqueal', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de varizes esofágicas', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diverticulectomia do terço médio e inferior', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrotomia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Piloromiotomia', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrotomia com excisão de úlcera ou tumor', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrectomia parcial ou sub-total', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrectomia total', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desgastrogastrectomia', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrectomia sub-total radical', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrenterostomia', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrorrafia, sutura de úlcera perfurada ou ferida', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Piloroplastia', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastrostomia', 130);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Revisão de anastomose gastroduodenal ou gastrojejunal com reconstrução', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vagotomia troncular ou selectiva', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vagotomia super selectiva', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enterolise de aderências', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Duodenotomia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enterotomia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colotomia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enterostomia ou cecostomia', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ileostomia «continente»', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revisão da ileostomia', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colostomia', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revisão da colostomia, simples', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de pequenas lesões não requerendo anastomose ou exteriorização', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enterectomia', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enteroenterostomia', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colectomia segmentar', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemicolectomia', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colectomia com coloproctostomia', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colectomia tipo Hartmann', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colectomia com colostomia e criação de fístula mucosa', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colectomia total', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Proctolectomia', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de duplicação intestinal simples', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de duplicação intestinal complexa', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de ileus meconial', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enterorrafia', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de enterostomia ou colostomia', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fistulas intestinais', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plicatura do intestino (tipo Noble)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da atrésia do duodeno, jejuno, ileon ou colon', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coloprotectomia conservadora com reservatório ileo-anal', 380);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diverticulectomia', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor do mesentério', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de mesentério (laceração e hérnia interna)', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apendicectomia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de abcesso apendicular', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de malrotação intestinal', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem Transrectal de abcesso perirectal', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção anterior de recto', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção anterior de recto (1/3 médio e inferior)', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção abdominoperineal do recto', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Protectomia com anastomose anal (Pull-Through)', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de prolapso rectal por via abdominal ou perineal', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de doença de Hirschsprung', 300);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de tumor benigno por via transagrada e/ou transcoccígea (tipo Kraske)', 180);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção de tumor maligno por via transagrada e/ou transcoccigea (tipo Kraske)', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão, electrocoagulação, criocoagulação ou laser de tumor do recto', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de teratoma pré sagrado', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão e drenagem de abcesso da margem do anus', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esfincterotomia com ou sem fissurectomia', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemorroidectomia', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fistulectomia por fístula perineo-rectal', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Criptectomia', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cerclage do anus', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação anal, sob anestesia geral', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da agenesia ano-rectal (forma alta)', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da agenesia ano-rectal (forma baixa)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esfincteroplastia, por incontinência anal', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transplante do recto interno', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transplante muscular livre', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão de trombose hemorroidária', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hepatectomia parcial atípica', 190);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hepatectomia regrada direita', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hepatectomia regrada esquerda', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Marsupialização ou excisão de quisto ou absesso', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Segmentectomia hepática', 220);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cateterização cirúrgica da artéria hepática para tratamento complementar', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de quisto hidático simples', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Periquistectomia', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento dos traumatismos hepáticos grau 1 e', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de traumatismos hepáticos grau 3, 4 e', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecistectomia com ou sem colangiografia', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecistectomia com coledocotomia', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecistectomia com esfincteroplastia', 230);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coledocotomia com ou sem colecistectomia', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coledocotomia com esfincteroplastia', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hepaticotomia para excisão de cálculo', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esfincteroplastia transduodenal (operação isolada)', 190);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecistoenterostomia', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecocoenterostomia', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hepaticojejunostomia (Roux)', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anastomose topo a topo das vias biliares', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anastomose entre os ductos intra-hepáticos e o tubo digestivo', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecistostomia (operação isolada)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de quisto do colédoco', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumor de Klatskin', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Entubação transtumoral de tumor das vias biliares', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Duodenopancreatectomia (tipo Whipple)', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pancreatectomia distal com esplenectomia', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pancreatectomia distal sem esplenectomia', 310);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pancreatectomia «quase total» (tipo Chili)', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de lesão tumoral do pâncreas', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pancreato jejunostomia (tipo Puestow)', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pancreato jejunostomia (tipo Duval)', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistojejunostomia ou cistogastrostomia', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laparotomia exploradora (operação isolada)', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Laparotomia para drenagem de abcesso peritoneal ou retroperitoneal (excepto apêndice)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laparotomia por perfuração de víscera oca (excepto apêndice)', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor benigno ou quistos retroperitoneais, via abdominal', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor maligno retroperitoneal via abdominal', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor ou quistos retroperitoneais, via toracoabdominal', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Omentectomia total (operação isolada)', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirurgico de onfalocelo - vários tempos', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirurgico de onfalocelo - um tempo', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia inguinal', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia crural', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia lombar, obturadora ou isquiática', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia umbilical', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia epigástrica', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia de Spiegel', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de hérnia incisional', 130);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de hérnia estrangulada, a acrescentar ao valor da respectiva localização', 25);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tratamento de hérnia com ressecção intestinal, a acrescentar ao valor da respectiva localização', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Omentoplastia pediculada', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de evisceração post-operatória', 90);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Tratamento de perda de substância da parede abdominal-enxertos (fascia lata, dérmico, rede, etc.)', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lombotomia exploradora e exploração cirúrgica retroperitoneal', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem cirúrgica de hematoma, urinoma ou abcesso retroperitoneal', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumor retroperitoneal', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem por via toraco-abdominal', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfadenectomia retroperitoneal para-aórtica-cava', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfadenectomia retroperitoneal pélvica unilateral', 145);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfadenectomia retroperitoneal pélvica bilateral', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfadenectomia retroperitoneal para-aórtico-cava e pélvica', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Suprarenalectomia por patologia suprarenal', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Suprarenalectomia no decorrer de nefrectomia radical', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Suprarenalectomia bilateral', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da artéria renal', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da veia renal', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia renal "ex-situ"', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Auto-transplantação', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transplantação de rim de cadáver ou de rim vivo', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colheita de rim para transplante (de rim de cadáver ou de rim vivo)', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia renal cirúrgica', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefro(lito)tomia', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefro(lito)tomia anatrófica', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pielo(lito)tomia simples', 130);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Pielocalico(lito)tomia ou pielonefro(lito)tomia por litíase coraliforme ou précoraliforme', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pielo(lito)tomia secundária (iterativa)', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pielo(lito)tomia em malformação renal', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrostomia ou pielostomia aberta', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrorrafia por traumatismo­renal', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento da fistula pielo-cutânea', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula pielo-visceral', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calico-ureterostomia', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calicorrafia ou calicoplastia', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pieloureterolise', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pielorrafia', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pieloplastia desmembrada tipo Anderson Hynes', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outra pieloplastia desmembrada', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pieloplastia não desmembrada', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pieloplastia em malformação renal', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefropexia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quistectomia ou marsupialização de quisto renal', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enucleação de tumor do rim', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia parcial (inclui heminefrectomia)', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia total', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia radical', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia radical com linfadenectomia para aórtico-cava', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia secundária', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia de rim ectópico', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrectomia de rim transplantado', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefro-ureterectomia sub-total', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefro-ureterectomia com cistectomia perimeática', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pielectomia com excisão de tumor piélico', 160);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia endoscópica do segmento pielo-ureteral (SPU), bacinete ou cálices com ureterorrenoscópio', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia renal percutânea com controle RX-Eco', 65);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefrostomia percutânea', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento percutâneo de quisto renal', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefroscopia percutânea', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nefro(lito)extracção percutânea com pinças ou sondas-cesto', 180);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Nefro(lito)extracção percutânea com litotritor ultra-sónico, electro-hidráulico ou laser', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pieloureterotomia interna', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infundibulocalicotomia', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção percutânea de tumor do bacinete ou cálices', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotorradiação percutânea com laser de cálices, bacinete ou SPU', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Litotrícia extracorporal por ondas de choque (por unidade renal)', 150);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Litotrícia extracorporal por ondas de choque (sessões complementares - dentro de um periodo de 3 meses)',
   130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretero(lito)tomia lombar', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretero(lito)tomia ilíaca', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretero(lito)tomia pélvica', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretero(lito)tomia transvesical', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretero(lito)tomia transvaginal', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterostomia intubada', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterostomia cutânea directa unilateral', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterostomia cutânea directa bilateral', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ureterostomia cutânea indirecta transileal (ureteroileostomia cutânea-operação de Bricker)', 280);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ureterostomia cutânea indirecta transcólica (ureterocolostomia cutânea)', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterostomia cutânea indirecta com bolsa intestinal continente', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revisão de ureterostomia cutânea', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revisão de anastomose uretero intestinal', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterosigmoidostomia', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterorrectostomia (bexiga rectal) com abaixamento intestinal', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desderivação urinária', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação cirúrgica de tutor ureteral', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transureteroureterostomia', 160);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ureterocistoneostomia (Reimplantação ureterovesical) ou operação anti-refluxo sem ureteroneocistostomia',
   160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem bilateral', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com modelagem ureteral', 170);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com modelagem ureteral bilateral', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com plastia vesical (tipo Boari)', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do ureterocele (sem uretero cistoneostomia)', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterorrafia', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula uretero-cutânea', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula uretero-visceral', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureteroplastia (inclui ureteroplastia intubada-Davies)', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Substituição ureteral por intestino', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterectomia de coto ureteral ou ureter acessório', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterolise', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Descruzamento uretero-vascular', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do ureter retro-cava', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterolise por fibrose retroperitoneal', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intraperitonealizarão de ureter', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação endoscópica do meato ureteral', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Meatotomia ureteral endoscópica', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpos estranhos do ureter com citoscópio', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia endoscópica de ureterocele (unilateral) com ureterocelotomia', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com ressecção de ureterocele', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia endoscópica do refluxo vesico-ureteral (unilateral)', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem bilateral', 100);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cateterismo endoscópico ureteral terapêutico unilateral (incluí dilatação endoscópica sem visão e inclui',
   40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem bilateral', 65);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação endoscópica retrógada de tutor ureteral (unilateral)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem bilateral', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterolitoextracção endoscópica sem visão', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fulguração endoscópica do ureter com ureterorrenoscópico (URC)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterotomia interna sob visão com URC', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterolitoextracção sob visão com URC com pinças ou sondas-cesto', 140);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Ureterolitoextracção sob visão com URC com litotritor ultra-sónico, electro-hidráulico ou laser', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção de tumor ureteral com URC', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotorradiação endoscópica com laser com URC', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação percutânea anterógrada de tutor ureteral', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretero(lito)extracção percutânea com pinças ou sondas-cesto', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Uretero(lito)extracção percutânea com litotritor ultra-sónico, electro-hidráulico ou laser', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ureterotomia interna percutânea', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção percutânea de tumor do ureter', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotoradiação percutânea com laser do ureter', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Litotrícia extracorporal por ondas de choque', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, sessão complementar', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exploração cirúrgica da bexiga e perivesical', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem cirúrgica peri-vesical', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cisto(lito)tomia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistostomia ou vesicostomia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistorrafia', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Encerramento de fístula vesicocutânea (inclui encerramento de cistosmia)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula vesicoentérica', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula vesico-ginecológica', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem complexa com retalho tecidular', 200);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Enterocitoplastia de alargamento (qualquer tipo de segmento intestinal)', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enterocistoplastia de substituição destubularizada', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia de redução vesical', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do diverticulo vesical com diverticulo plastia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diverticulolectomia', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão do úraco', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia parcial com ressecção transvesical de tumor', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia parcial segmentar', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia sub-total', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia total', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia radical (ureterectomia não incluida)', 225);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia radical com linfadenectomia pélvica', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exenteração pélvica anterior', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação cirúrgica de radioisótopos na bexiga', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da bexiga extrofiada', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com osteotomia bi-ilíaca', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem cirúrgica periutretal feminina', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrotomia feminina', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrorrafia feminina', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula uretrovaginal', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cervicouretroplastia feminina', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução da uretra feminina (inclui neouretra)', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colpoperineorrafioplastia anterior', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cervicouretropexia por via vaginal', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cervicouretropexia por via suprapúbica', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cervicouretropexia por via mista', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrotomia feminina', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exerése de divertículo uretral feminino (uretrocele)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de carúncula ou prolapso uretral feminino', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fulguração endoscópica vesical', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção-biópsia endoscópica de tumor vesical', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção endoscópica de tumor vesical (RTU-V)', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação de laser por via endoscópica', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção endoscópica de cálculo, coágulo ou corpo estranho vesical', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Litotrícia endoscópica vesical com litotritor mecânico sem visão', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Litotrícia endoscópica vesical com litotritor mecânico com visão', 140);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Litotrícia endoscópica vesical com litotritor ultra-sónico, electro-hidráulico ou laser', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia endoscópica de divertículo vesical', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação endoscópica da bexiga', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Alargamento endoscópico do colo vesical feminino com incisão de colo vesical', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com ressecção do colo vesical', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento endoscópico de incontinência urinária feminina', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistostomia suprapúbica percutânea', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Litotrícia extracorporal por ondas de choque', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem sessão complementar', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colocação de prótese para tratamento de incontinência urinária (esfincter artificial)', 180);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Reeducação perineo-esfincteriana, por incontinência urinária, biofeedback ou electroestimulação, por sessão',
                                  10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia aberta do colo vesical com incisão ou excisão do colo', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia Y-V do colo vesical', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostatectomia suprapúbica ou retro púbica por HBP', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostatectomia perineal por HBP', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostatectomia radical retropúbica', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostatectomia radical retropúbica com linfadenectomia pélvica', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostatectomia radical perineal', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação cirúrgica de radioisótopos na próstata', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia da incontinência urinária do homem (exclui próteses e cirurgia endoscópica)', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Limpeza cirúrgica de osteíte do púbis', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem endoscópica de abcesso da próstata', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção endoscópica de próstata (RTUP)', 160);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Alargamento endoscópico da loca prostática com incisão ou ressecção de fibrose da loca', 60);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Alargamento endoscópico de colo vesical masculino com incisão ou ressecção de colo vesical', 70);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colocação endoscópica de prótese de alargamento de colo vesical de uretra prostática', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento endoscópico da incontinência urinária masculina', 140);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colocação endoscópica de prótese uretral expansível reepitelizável (exclui o custo da prótese)', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colocação de prótese para tratamento de incontinência urinária (esfincter artificial)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hipertermia prostática (Independentemente do número de sessões)', 80);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Termoterapia prostática transuretral (independentemente do número de sessões - não incluí sonda aplicadora)',
                                  80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laser próstático transuretral (não incluí fibras nem mangas)', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exploração cirúrgica da uretra', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem cirúrgica peri-uretral', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Meatomia', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrolitotomia', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrotomia externa', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação de Monseur', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrostomia', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intubação e recanalização uretral', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrorrafia', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento da uretrostomia', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fístula uretro-cutânea', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encerramento de fistula uretro-rectal', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Meatoplastia', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretroplastia de uretra anterior termino terminal', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com retalho pediculado', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com retalho livre', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem 1º. Tempo', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem 2º. Tempo', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretroplastia da uretra posterior termino-terminal', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com retalho pediculado', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com retalho livre', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem 1º. Tempo', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem 2º. Tempo', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diverticulectomia uretral', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrectomia parcial', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrectomia total', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrectomia de uretra acessória', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção cirúrgica de corpos estranhos uretrais', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia do hipospadias e da uretra curta congénita proximal num só tempo', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem distal num só tempo', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem em, 2 tempos 1º. Tempo (endireitamento)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem em 2 tempos 2º. Tempo (neouretroplastia)', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do epispádias', 230);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fulguração endoscópica uretral', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção endoscópica de cálculo ou corpo estranho uretral', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrotomia interna sem visão', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrotomia interna sob visão', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção endoscópica de estenose da uretra', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção endoscópica de tumor uretral', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esfincterotomia endoscópica', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão-ressecção endoscópica de valvas uretrais', 90);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colocação endoscópica de prótese uretral expansível reepitelizável (exclui o custo da prótese)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corte do freio do pénis', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão para redução da parafimose', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Postectomia (circuncisão)', 40);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia de angulação e mal-rotação peniana e da doença de Peyronie com operação de Nesbit', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com excisão da placa e colocação de retalho', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com excisão da placa e colocação de prótese', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia de priapismo com anastomose safeno-cavernosa unilateral', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com anastomose safeno-cavernosa bilateral', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com anastomose caverno esponjosa', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com fistula caverno-esponjosa', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Punção - esvaziamento - lavagem dos corpos cavernosos para tratamento do priapismo', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação peniana parcial', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação peniana total', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Emasculação', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação peniana com linfadenectomia inguinal unilateral', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Amputação peniana com linfadenectomia inguinal bilateral', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com linfadectomia inguino-pélvica bilateral', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução do pénis (tempo principal)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem outros tempos (cada)', 65);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laqueação de veias penianas na cirurgia da disfunção eréctil', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revascularização peniana', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com microcirurgia', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese peniana rígida', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese peniana semi-rígida', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese peniana insuflável', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação externa de raios laser', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do interesexo e transsexual masculino para feminino', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem feminino para masculino, completa', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exploração do conteúdo escrotal (celotomia exploradora)', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem cirúrgica da bolsa escrotal', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de fleimão urinoso', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da pele e invólucros da bolsa escrotal', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia de hidrocele', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção de hidrocele com injecção de esclerosante', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do hematocele', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do varicocele com laqueação alta da veia espermática', 75);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia do varicocele com laqueação-ressecção múltipla de veias varicosas', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidorrafia por traumatismo', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidopexia escrotal sem funiculolise', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidectomia escrotal', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidectomia sub-albugínea bilateral', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidectomia intra-abdominal', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidectomia inguinal simples', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Orquidectomia inguinal radical sem linfadenectomia', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com Linfadenectomia para-aórtico-cava e pélvica', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Autotransplante testicular', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese testicular unilateral', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de prótese testicular bilateral', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia para deferento vesiculografia', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia da obstrução espermática com anastomose epididimo-deferencial (epididimo-vasostomia)', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com anastomose deferento-deferencial (vaso-vasostomia)', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem com microcirurgia', 180);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão de espermatocele ou quisto para testicular epididimário ou do cordão espermático', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Epididimectomia', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vasectomia, bilateral(ou laqueação dos deferentes)', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Inguinotomia exploradora', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Funicololise (e orquidopexia)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia das vesículas seminais', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perineoplastia não obstétrica (operação isolada)', 80);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Colpoperineorrafia por rasgadura incompleta do perineo e vagina (não obstétrica)', 80);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Colpoperrineorrafia com sutura do recto, esfíncter anal, por rasgadura completa do perineo (não obstétrica)',
                                  120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Marsupialiazação da glândula da Bartholin', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão cirúrgica de condilomas', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vulvectomia parcial', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vulvectomia total', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vulvectomia radical, com esvaziamento ganglionar', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Clitoridectomia', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Clitoridoplastia', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de glândula de Bartholin', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de caruncula uretral', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de pequeno lábio', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Himenotomia ou himenectomia parcial', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção plástica do intróito', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia laser da vulva', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colpotomia com drenagem de abcesso', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de hematocolpos', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colpectomia para encerramento parcial da vagina', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colpectomia para encerramento total da vagina (Colpocleisis)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de septo vaginal e plastia', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor ou quisto', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colporrafia por ferida não obstétrica', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colporrafia anterior por cistocelo', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colporrafia posterior por rectocelo', 60);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Vesicouretropexia anterior ou uretropexia, via abdominal (tipo Marshall-Marchetti)', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Suspensão uretral (fáscia ou sintético) por incontinência urinária ao esforço (tipo Stockel)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plastia do esfíncter uretral (tipo plicatura uretral de Kelli)', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de enterocelo, via abdominal (operação isolada)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colpopexia por abordagem abdominal', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Intervenção cirúrgica para neovagina, em tempo único, simples com ou sem enxerto cutâneo', 150);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Intervenção cirúrgica para neovagina em tempos múltiplos, ou com plastia complexa (retalhos loco-regionais)',
                                  250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de fístula recto-vaginal, via vaginal', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de fístula vesico-vaginal, via vaginal', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, via transvesical', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia laser da vagina', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia Laser CO2 - Vaporização', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocoagulação ou criocoagulação', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conização', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cervicectomia (operação isolada)', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese do colo restante', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traquelorrafia', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polipectomia cervical', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conização laser CO2', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conização com ansa diatérmica', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Curetagem por aspiração (tipo Vabra)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação e curetagem', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Miomectomia por via abdominal ou vaginal', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerectomia total, com anexectomia via abdominal', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerectomia sub-total com anexectomia, via abdominal', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerectomia vaginal', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerectomia vaginal com correcção de enterocelo', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerectomia vaginal radical (tipo Schauta)', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerectomia vaginal com colporrafia anterior e/ou posterior', 180);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Histerectomia radical com linfadenectomia pélvica bilateral (tipo Wertheim-Meigs)', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exenteração pélvica', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerotomia abdominal', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histeropexia', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ligamentopexia', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histeroplastia por anomalia uterina (tipo Stassman)', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de rotura uterina', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intervenção cirúrgica por inversão uterina (não obstétrica)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oclusão de fistula vesico-uterina', 130);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Laparotomia exploradora com biópsias para estadiamento por neoplasia ginecológica', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Secção de sinéquias uterinas - via vaginal', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de septo por via vaginal', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerectomia total com conservação de anexos', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Microcirurgia tubar', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso tubo-ovárico', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Secção ou laqueação da trompa, abdominal uni ou bilateral', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Salpingectomia, uni ou bilateral (operação isolada)', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anexectomia, uni ou bilateral', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Salpingoplastia, uni ou bilateral', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da gravidez ectópica', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lise de aderências pélvicas', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ressecção em cunha, uni ou bilateral', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistectomia do ovário, uni ou bilateral', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ovariectomia, uni ou bilateral', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ovariectomia, uni ou bilateral com omentectomia', 140);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Citoredução do carcinoma do ovário em estadios superiores ou igual ao IIB', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coagulação de ovários', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Simpaticectomia pélvica', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reparação de episiotomia e/ou rasgadura incompleta do períneo e/ou rasgadura da vagina, simples', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extensa', 30);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Colpoperineorrafia e reparação do esfíncter anal por rasgadura completa do perineo consecutiva a parto',
   80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerorrafia por rotura do útero (obstétrica)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação por inversão uterina de causa obstétrica', 110);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Parto normal (com ou sem episiotomia) compreendida anestesia feita pelo próprio médico', 65);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parto gemelar normal por cada gémeo', 65);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Parto distócio, compreendidas todas as intervenções, tais como: fórceps, ventosa, versão grande, extracção pélvica, dequitadura artificial, episeorrafia, desencadeamento médico ou instrumental do trabalho',
                                  80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fetotomia (embriotomia)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dequitadura manual', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Traquelorrafia', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cesariana', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cesariana com histerectomia, sub-total', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cesariana com histerectomia, total', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lobectomia subtotal da tiroide', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lobectomia total da tiroide', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiroidectomia subtotal', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiroidectomia total', 250);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tiroidectomia total ou sub-total com esvaziamento cervical conservador', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com esvaziamento cervical radical', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiroidectomia subesternal com esternotomia', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Paratiroidectomia e/ou exploração da paratiroideia', 225);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Paratiroidectomia com exploração mediastínica por abordagem torácica', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Timectomia', 370);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Adrenalectomia unilateral', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumor do corpo carotideo', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de quisto do canal tireoglosso', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de quisto ou adenoma da tiroideia', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trepanação simples', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Craniotomia por hematoma epidural', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Craniotomia por hematoma subdural', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esquirolectomia simples', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esquirolectomia com reparação dural e tratamento encefálico', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lobectomia', 250);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Craniectomia ou craniotomia para remoção de corpo estranho no encéfalo (bala, etc)', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação de fístula de LCR', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reparação de fistula de L.C.R. por via transfenoidal', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fístula de L.C.R. da fossa posterior', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cranioplastia com osso', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cranioplastia com material sintético', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de craniossinostose de uma sutura', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento de craniossinostose complexa', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de encefalocelo', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de disrrafismo espinal', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção cirúrgica de lesões de osteite craniana', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trepanação para drenagem de abcesso cerebral', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Craniotomia para tratamento de abcesso cerebral', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Craniotomia para abcesso subdural ou epidural', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abcesso intra-raquidiano via posterior', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abcesso intra-raquidiano via anterior', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abcesso intra-raquidiano cervical via anterior', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abcesso intramedular', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de tumores atingindo a calote sem cranioplastia', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de tumores atingindo a calote com cranioplastia', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Buracos de trepano, com drenagem ventricular', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abordagem transfenoidal', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores da órbitra - abordagem transcraniana', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glioma supratentorial', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glioma infratentorial', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumor intraventricular', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumor selar, supra-selar e para-selar', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores da região pineal', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores do ânglo pronto-cerebeloso', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gliomas do tronco cerebral', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores do IV ventrículo', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores da base do crânio', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia tumoral estereotáxica', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras lesões expansivas intracranianas', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hematomas intracerebrais supratentoriais', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hematomas intracerebrais infratentoriais', 300);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Laqueação da carótida interna intracraniana para tratamento de aneurismas e fistulas carótido-cavernosas',
   250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aneurismas intracranianos da circulação anterior', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aneurismas intracranianos da circulação posterior', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'MAV supratentorial', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'MAV infratentorial', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Processo de revascularização', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores da coluna vertebral', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores da coluna vertebral com estabilização', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores intradurais extramedulares', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tumores intradurais intramedulares', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'MAV espinal', 450);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Malformações da charneira, abordagem anterior', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Malformações da charneira, abordagem posterior', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico de siringomilia', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras malformações congénitas', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Torkildsen', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Derivações ventrículo-atriais', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Derivações ventrículo-peritoneais', 170);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Derivações cisto-peritoneais', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Derivações lombo-peritoneais', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ventrículostomia endoscópica', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Revisões das derivações', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Leucotomia estereotáxica', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hemisferectomia', 380);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intervenções estereotáxicas talamicas', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cordotomias', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia da epilepsia com registo operatório', 400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calosotomia', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Descompressão nicrovascular de pares cranianos', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento percutâneo da nevralgia do trigémio', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lesão da DREZ', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rizotomia', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Comissurotomia', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outras cirurgias percutâneas da dor', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurólises', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposições', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurorrafias com microcirurgia', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do plexo braquial', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sindroma do túnel cárpico ou do canal de Guyon', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tratamento cirúrgico da meralgia parestésica', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de neuroma traumático dos nervos periféricos', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de neuroma traumático dos nervos periféricos com enxerto', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumores de nervos periféricos sem reparação', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumores de nervos periféricos com reparação', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de neuroma post-traumático', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de neuroma post-traumático, com microcirurgia', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de tumores dos nervos periféricos (não incluindo reparação)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Evisceração do globo ocular sem implante', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Evisceração do globo ocular com implante', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enucleação do globo ocular sem implante', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enucleação do globo ocular com implante', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exenteração da órbita', 200);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exenteração da órbita com remoção de partes ósseas ou com transplante muscular', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de implante ocular', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Queratectomia lamelar, parcial, excepto pterígio (ex. quisto dermóide)', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia da córnea (ex: leucoplasia)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão ou transposição de pterígio, sem enxerto', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão ou transposição de pterígio recidivado com enxerto', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Excisão ou transposição de pterígio recidivado com queratoplastia parcial', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Raspagem da córnea para diagnóstico', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção do epitélio corneano', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aplicação de agentes químicos e/ou físicos', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tatuagem da córnea, mecânica ou química', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho superficial', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de ferida da córnea', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratoplastia lamelar (inclui preparação do material de enxerto)', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratoplastia penetrante (inclui preparação do material de enxerto)', 240);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Queratoplastia lamelar na afaquia (inclui preparação do material de enxerto)', 240);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Queratoplastia penetrante e queratoprótese (inclui preparação do material de enxerto)', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratomia refractiva para correcção óptica', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratomileusis', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Epiqueratoplastia', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Queratofaquia', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotoqueratectomia refractiva ou terapêutica', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Termoqueratoplastia', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Termoqueratoplastia refractiva', 145);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Topografia Corneana', 25);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Paracentese da câmara anterior para remoção ou aspiração de humor aquoso, hipópion ou hifema', 50);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Paracentese da câmara anterior para remoção de humor vítreo e/ou libertação de sinéquias e/ou discisão da hialoideia anterior, com ou sem injecção de ar',
                                  90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Goniotomia com ou sem goniopunção', 145);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Goniopunção sem goniotomia', 55);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trabeculotomia ab externo', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trabeculoplastia Laser', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho magnético', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho não magnético', 90);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Introdução de lente intra-ocular para correcção da ametropia em olho fáquico', 200);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Lise de sinéquias do segmento anterior, incluindo goniosinéquias, por incisão com ou sem injecção de ar/líquido (técnica isolada)',
                                  70);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Lise de sinéquias anteriores ou de sinéquias posteriores ou de aderências corneovítreas com ou sem injecção de ar/líquido',
                                  55);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de invasão epitelial, câmara anterior', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de material de implante, segmento anterior', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de coágulo sanguíneo, segmento anterior', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção de ar/líquido ou medicamento na câmara anterior', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Operação fistulizante para glaucoma com iridectomia', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trabeculectomia ab externo (fistulizante protegida)', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fistulização da esclerótica no glaucoma, iridencleisis', 130);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fistulização da esclerótica no glaucoma, trabeculectomia ab externo com encravamento escleral', 190);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fistulização esclerótica no glaucoma com colocação de tubo de Molteno ou similar', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esclerotomia Holmium (cada sessão)', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução da esclerótica por estafiloma sem enxerto', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução da esclerótica por estafiloma com enxerto', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho superficial', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de ferida sem lesão da úvea', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de ferida com reposição ou ressecção da úvea', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Iridotomia simples/transfixiva', 105);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Iridectomia com ciclectomia', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Iridectomia periférica ou em sector no glaucoma', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Iridectomia óptica', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de iridodiálise', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclodiatermia', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclocrioterapia', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ciclodiálise', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Laserterapia (coreoplastia, gonioplastia e iridotomia (1 ou mais sessões))', 65);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotocoagulação dos processos ciliares (1 ou mais sessões)', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Destruição de lesões quísticas ou outras da Íris e/ou do corpo ciliar por meios não cruentos', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Discisão do cristalino', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Discisão de catarata secundária e/ou membrana hialoideia anterior', 90);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Remoção de catarata secundária com ou sem iridectomia (iridocapsulectomia ou iridocapsulotomia)', 180);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aspiração de material lenticular na sequência ou não de facofragmentação mecânica', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Facoemulsificação do cristalino com aspiração de material lenticular', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Facoemulsificação do cristalino com implantação de lente intraocular', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção extracapsular programada', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção intracapsular de catarata, com ou sem enzimas', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de cristalino luxado', 200);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção intracapsular ou extracapsular na presença de ampola de filtração', 200);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aplicação de qualquer lente intraocular simultaneamente à extracção de catarata', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Implantação secundária de lente intra-ocular', 190);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de lente intraocular de câmara posterior', 145);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Lentes intraoculares de suspensão escleral', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Capsulotomia Yag (por sessão)', 65);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vitrectomia parcial da câmara anterior, a céu aberto', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vitrectomia sub-total, via anterior, utilizando vitrectomo mecânico', 180);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aspiração de vítreo ou de liquido sub-retiniano ou coroideu (esclerotomia posterior)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção de substituto de vítreo, via plana (pneumopexia)', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Discisão de bandas de vítreo sem remoção, via pars plana', 150);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Liga de bandas de vítreo, adesões da interface do vítreo, bainhas, membranas ou opacidades por cirurgia laser',
                                  85);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vitrectomia mecânica, via pars plana', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho magnético', 180);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho, com vitrectomia', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vitrectomia via pars plana associada à extracção do cristalino', 250);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Vitrectomia via pars plana associada à extracção de cristalino com introdução de lente intraocular', 360);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Vitrectomia mecânica complicada via pars plana, com tamponamento interno com ou sem extracção de corpo estranho intraocular, com ou sem cirurgia de cristalino',
                                  360);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de substituto de vítreo', 95);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioterapia ou diatermia com ou sem drenagem de líquido subretiniano', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Depressão escleral localizada ou circular, com ou sem implante', 240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Qualquer técnica anterior associada à vitrectomia', 280);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia de descolamento de retina com vitrectomia associada a tamponamento', 320);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia de descolamento de retina com vitrectomia a céu aberto e tamponamento interno', 360);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia de descolamento de retina com vitrectomia, tamponamento interno e extracção de cristalino', 360);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Cirurgia de descolamento de retina com vitrectomia e segmentação, delaminação e corte de membranas de',
   400);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reoperação de descolamento de retina sem vitrectomia', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reoperação de descolamento de retina com vitrectomia', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de material implantado no segmento posterior', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Implante e remoção de fonte de radiações', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioterapia ou diatermia (por sessão)', 95);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fotocoagulação Xenon', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laser Argon azul-verde', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laser monocromático', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laser Yag', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esclerocoroidotomia para remoção de tumor com ou sem vitrectomia', 360);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia de músculo oculo-motor', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de músculos oculomotores e tendões e/ou a cápsula de Tenon', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enfraquecimento/reforço de um músculo', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enfraquecimento/reforço de dois músculos', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enfraquecimento/reforço de três músculos', 145);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enfraquecimento/reforço de quatro músculos', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Miopexia retroequatorial de um músculo', 145);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Miopexia retroequatorial de dois músculos', 175);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Miopexia retroequatorial de um músculo associado a enfraquecimento/reforço de dois músculos', 190);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Miopexia retroequatorial de um músculo associada a enfraquecimento/reforço de três músculos', 210);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Miopexia retroequatorial de dois músculos associada a enfraquecimento/reforço de um músculo', 210);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Miopexia retroequatorial de dois músculos associada a enfraquecimento/reforço de dois músculos', 225);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia ajustável sobre um músculo (Incluí o ajuste a efectuar posteriormente)', 165);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Cirurgia ajustável sobre dois músculos (incluí o ajuste a efectuar posterirmente)', 190);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Cirurgia ajustável de um músculo associada a enfraquecimento/reforço/miopexia de um músculo (incluí ajuste a efectuar posteriormente)',
                                  200);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Cirurgia ajustável de um músculo associada a enfraquecimento/reforço/miopexia de dois músculos (incluí ajuste a efectuar posteriormente)',
                                  240);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição muscular de um músculo no estrabismo paralítico', 120);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Transposição        muscular         de     um      músculo       no      estrabismo        paralítico        associada a enfraquecimento/reforço/miopexia de um músculo)',
                                  145);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Transposição       muscular         de      um      músculo      no      estrabismo         paralítico,       associada a enfraquecimento/reforço/miopexia de dois músculos)',
                                  175);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Transposição múscular de dois músculos no estrabismo paralítico', 160);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Transposição muscular de dois músculos no estrabismo paralítico, associada a enfraquecimento/reforço de um músculo',
                                  175);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Transposição muscular de dois músculos no estrabismo paralítico, associada a enfraquecimento/reforço de dois músculos',
                                  225);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção de toxina botulínica (cada sessão)', 65);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exploradora com ou sem biópsia', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de tumor', 170);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia por aspiração transconjuntival', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de tumor', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho', 270);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem ou descompressão', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exploradora com ou sem biópsia', 200);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Extracção total ou parcial de tumor ou extracção de corpo estranho-participação de oftalmologista', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Injecção retrobulbar de álcool, ar, contraste ou outros agentes de terapêutica e de diagnóstico', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção terapêutica na cápsula de Tenon', 9);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Inserção de implante orbitário exterior ao cone muscular (ex: reconstituição de parede orbitária) colaboração de oftalmologista com neurocirurgião e/ou otorrinolaringologista e/ou cirurgião plástico',
                                  100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção ou revisão de implante da órbita, exterior ao cone muscular', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de chalázio ou de quisto palpebral único', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de chalázio ou de quisto palpebral, múltiplos', 35);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Extracção de chalázio ou de quisto palpebral, com anestesia geral e/ou hospitalização', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsias das pálpebras', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrocoagulação de cílios', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de triquíase e distriquiase', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão de lesão palpebral sem plastia (excepto chalázio)', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Destruição física ou química de lesão do bordo palpebral', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tarsorrafia', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abertura da Tarsorrafia', 10);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Correcção de ptose: técnica do músculo frontal com sutura (ex:Op. de Friedenwald)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de ptose, outras técnicas', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de retracção palpebral', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Blefaroplastia com excisão de cunha tarsal (ectrópico e entrópio)', 80);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Blefaroplastia extensa (ectrópio e entrópio) (ex: operações tipo Kuhnt Szymanowski e Wheeler-Fox)', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Blefaroplastia extensa para correcção da Blefarofimose e do epicantus', 150);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura de ferida incisa recente envolvendo as estruturas superficiais e bordo', 40);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Sutura de ferida incisa recente envolvendo toda a espessura da pálpebra', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cantoplastia (reconstrução do canto)', 40);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Reconstrução e sutura de ferida lacero-contusa, envolvendo todas as estruturas da pálpebra até 1/3 da sua extensão, podendo incluir enxerto de pele, simples ou pediculado',
                                  95);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, envolvendo mais de 1/3 do bordo', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reconstrução de toda a espessura palpebral por retalho tarso-conjuntival da palpebra oposta', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão para drenagem de quisto', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Excisão ou destruição de lesão da conjuntiva', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção sub-conjuntival', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conjuntivoplastia, por enxerto conjuntival ou por deslizamento', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conjuntivoplastia com enxerto de mucosa', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução de fundo de saco com mucosa', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia de simblefaro, sem enxerto', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cirurgia do simblefaro, com enxerto de mucosa labial', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho superficial', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sutura de ferida da conjuntiva', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biópsia da glândula lacrimal', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Incisão do saco lacrimal para drenagem(dacriocistomia)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese do saco lacrimal (dacriocistectotomia)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Remoção de corpo estranho das vias lacrimais (dacriolito)', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução dos canaliculos', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção dos pontos lacrimais evertidos', 80);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Dacriacistorinostomia (fistulização do saco lacrimal para a cavidade nasal)', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Conjuntivorinostomia com ou sem inserção de tubo', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Obturação permanente ou temporária das vias lacrimais', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de fístula lacrimal', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sondagem do canal lacrimo-nasal, com ou sem irrigação', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, exigindo anestesia geral', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Injecção do meio de contraste para da criocistografia', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Entubação prolongada das vias lacrimais', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho', 7);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Extracção de corpo estranho c/anestesia geral', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, por via retro-auricular', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Drenagem de abcesso, otohematoma', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Polipectomia do ouvido', 20);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Miringotomia com anestesia geral ou local unilateral (sob visão microscópica)', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Miringotomia com anestesia geral ou local bilateral (sob visão microscópica)', 45);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Miringotomia com aplicação de tubo de ventilação unilateral (sob visão microscópica)', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Miringotomia com aplicação de tubo de ventilação bilateral (sob visão microscópica)', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Correcção de exostose do canal auditivo externo', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastoidectomia', 125);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastoidectomia radical', 200);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Timpanomastoidectomia com conservação da parede do C.A.E. com timpanoplastia', 300);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Timpanomastoidectomia sem conservação da parede do C.A.E. (com timpanoplastia)', 350);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Timpanoplastia', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Timpanotomia exploradora', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estapedectomia ou estapedotomia', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Labirintectomia transaural', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Descompressão do saco endolinfático', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurectomia vestibular (fossa média)', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Descompressão de 2ª. e 3ª. porções do nervo facial', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Descompressão da 1ª. porção (fossa média)', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto facial (2ª. e 3ª. porções)', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anastomose hipoglosso-facial', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Enxerto cruzado facio-facial', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese neurinoma do acústico (via translabiríntica)', 300);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Ressecção do pavilhão auricular sem reconstrução e sem esvaziamento ganglionar', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, com esvaziamento ganglionar', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução auricular por agenesia ou trauma (tempo principal)', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, tempos complementares (cada)', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Otoplastia unilateral', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Otoplastia bilateral', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Petrosectomia com conservação do nervo facial', 360);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, sem conservação do nervo facial', 320);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor glómico timpânico', 220);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor jugular localizado', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor jugular com invasão intracraniana', 370);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exérese de tumor na base do crânio', 330);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Implante coclear', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Implante osteointegrado', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução da cavidade de esvaziamento', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reconstrução do C.A.E. por agenesia', 280);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pele', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mama', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tecidos Moles', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Músculo', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Nervo', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pénis', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testículo', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vulva', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vagina', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osso', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gânglio superficial', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gânglio profundo', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rectal', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiroideia', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia superior a 900 K', 300);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 900 K a 801 K', 255);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 800 K a 701 K', 225);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 700 K a 601 K', 195);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 600 K a 561 K', 175);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 560 K a 511 K', 160);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 510 K a 481 K', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 480 K a 461 K', 140);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 460 K a 421 K', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 420 K a 401 K', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 400 K a 341 K', 110);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 340 K a 301 K', 95);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 300 K a 281 K', 87);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 280 K a 241 K', 78);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 240 K a 201 K', 66);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 200 K a 181 K', 57);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 180 K a 161 K', 51);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 160K a 141K', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 140K a 121K', 39);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 120 K a 101 K', 33);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se cirurgia de 100 K a 81 K', 27);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia se for inferior a 81 K', 27);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Analgesia para trabalho de parto', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'mais por hora', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Analgesia, sedação e/ou anestesia para exames complementares', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'mais por hora', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apoio de anestesista a actos cirúrgicos feitos sob,anestesia local', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'mais por hora', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia para cardioversão', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia para convulsoterapia', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio do gânglio estrelado-diag/terap.', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio do gânglio estrelado-neurolítico', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio do plexo celíaco-diag/terap', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio do plexo celíaco-neurolítico', 55);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio do simpático lombar-diag/terap', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio do simpático lombar-neurolítico', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio extra-dural-diag/terap', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio extra-dural-neurolítico', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio sub-aracnoideu-diag/terap', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bloqueio sub-aracnoideu-neurolitico', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'V par ­ gânglio Gasser-diag/terap', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'V par ­ gânglio Gasser-neurolítico', 45);
INSERT INTO ProcedureType VALUES (DEFAULT, 'De zona desencadeante', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diag/terap', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Neurolítico', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia regional intravenosa (com fins terapêuticos)', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estimulação transcutânea', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hipertemia', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intratecal drenagem do L.C.R.', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intratecal com narcóticos', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intratecal com soro gelado', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intratecal com soro hipertónico', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intratecal neuroadenolise hipofisária', 150);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anestesia local', 3);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Reanimação cardio-respiratória e hemodinâmica em casos de paragem, shock, etc. 1ª. Hora', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, assistência permanente adicional, cada hora', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, 2º. Dia e seguintes', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desobstrução das vias aéreas', 15);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Estabelecimento de ventilação assistida ou controlada com intubação nasal ou orotraqueal ou traqueotomia 1º. Dia',
                                  40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, 2º. Dia e seguintes', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abdómen simples ­ 1 incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abdómen simples ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cavum ou Rino-Faringe', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colangiografia endovenosa (excluindo estudo tomográfico)', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colangiografia endovenosa com perfusão (excluindo estudo tomográfico)', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colecistografia ­ 2 incidências + compressão doseada + Prova de Boyden', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dentes ­ ortopantomografia facial', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dentes todos em dentição completa', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Duodenografia hipotónica estudo complementar', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esófago', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estômago e Duodeno', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estômago e Duodeno com duplo contraste', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Faringe e Laringe', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fígado Simples ­ 1 incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fígado Simples ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intestino Delgado (trânsito)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intestino grosso (clister opaco) com esvaziamento', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Clister opaco duplo contraste', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intestino grosso, por ingestão, trânsito intestinal', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trânsito delgado + Trânsito cólon', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Região ileo-cecal ou ceco-apendicular', 6);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exame ileo-cecal ou ceco-apendicular quando associado aos trânsitos cólico ou delgado', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pescoço, partes moles ­ 1 incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pescoço, partes moles ­ 2 incidências', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gastroduodenal com pesquisa de hérnia e exame cardio-tuberositário', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tórax, pulmões e coração 1 incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tórax, pulmões e coração 2 incidências', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tórax, pulmões e coração 3 incidências', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tórax, pulmões e coração 4 incidências', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bexiga simples ­ 1 incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistografia ­ 3 incidências para esvaziamento', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistografia com duplo contraste', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistografia com uretrografia retrógrada', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rins simples ­ 1 incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rins simples­­ 2 incidências', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Urografia endovenosa', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Urografia endovenosa minutada', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Filme pós-miccional', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Película de pé ou filme tardio ou incidência suplementar', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Urografia endovenosa com perfusão (excluindo o estudo tomográfico)', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Associação de cistogramas oblíquos eapós micção à urografia', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pielografia ascendente unilateral (escluindo cataterismo)', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uretrografia retrógrada', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anca ­ 1 incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Anca ­ 2 incidências', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Antebraço ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Apófises estiloideias ­ cada incidência e lado', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Articulações têmporo-maxilares, boca aberta e fechada cada lado', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Bacia ­ 1 incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Braço ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Buracos ópticos ­ Bilateral', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calcâneo ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Charneira occipito-atloideia 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Clavícula ­ cada incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna cervical ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna cervical ou estudo funcional 4 incidências', 2);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Coluna cervico-dorsal, zona de transição ­ 2 incidências (frente e obliqua)', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna coccígea ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna dorsal ­ 2 incidências', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna lombar ­ 2 incidências', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna charneira lombo sagrada 2 incidências', 2);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Coluna lombo-sagrada, em carga, com inclinações (estudo funcional) 4 incidências', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coluna sagrada ­ 2 incidências', 2);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Coluna vertebral, em filme extra-longo (30X90) ­ cada incidência em carga', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Costelas, cada hemitórax 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cotovelo ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Coxa ou fémur ­ 2 incidências', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crânio ­ 2 incidências', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esqueleto ­ 1 incidência em película 35X43 ­ recém nascido', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esqueleto de adulto (1 incidência por sector mínimo de 9 películas)', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esterno ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esterno-claviculares (articulações) 3 incidências', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Face ­ 2 incidências', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Joelho 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mandíbula ­ cada incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mão ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mastoideias ou rochedos cada incidência e lado', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Maxilar superior ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ombro ­ 1 incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Omoplata ­ 1 incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Órbitas ­ cada incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ossos próprios do nariz cada incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pé ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Perna ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punho ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punhos e mãos (idade) óssea 1 incidência', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sacro-ilíacas (articulações) os dois lados ­ 1 incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sacro ilíacas (articulações) os dois lados face + 2 oblíquas', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Seios perinasais ­ 2 incidências', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Seios perinasais ­ 3 incidências', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sela turca ­ incidência localizada perfil', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tibio-tarsica ­ 2 incidências', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artropneumografia do joelho, incluindo punção', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Broncografia cada incidência (só radiologia)', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cálculos salivares, filme simples 2 incidências', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colangiografia per-operatória', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colangiografia pós-operatória', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colangiografia endoscópica cada incidência', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colangiografia percutânea cada incidência', 13);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dacriocistografia', 14);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fistulografia', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gravidez ­ 1 incidência', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Gravidez ­ 2 incidências', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Histerosalpingografia', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idade óssea fetal', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intensificação de imagens', 12);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Localização e extracção de corpos estranhos sob controlo radioscópico (radiocirurgia) com intensificador',
   10);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Localizarão de corpos estranhos intra oculares por meio de 4 imagens em posições diferentes', 10);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Localização de corpos estranhos intra oculares pelo método de Comberg (lente de contacto)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Macrorradiografia ­ 1 incidência preço da região +', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Membros inferiores ­ cada filme extra longo', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Métrico dos membros inferiores por sectores articulados', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Microrradiografia (película 10+10)', 0.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Radiografia estereoscópica ­ preço da região +', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Sialografia', 7);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Galactografia, cada lado', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mamografia - 4 incidências, 2 de cada lado', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quistografia gasosa, cada lado', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mamografia com técnica de magnificação', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia da carótida externa por punção percutânea', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia da fossa posterior por cateterismo da umeral ou femoral', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia dos 4 vasos', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia percutânea da carótida', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, por punção percutânea das 2 carótidas', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia da fossa posterior por punção percutânea da vertebral', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia medular', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mielografia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiopneumografia', 15);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Aortografia (por punção de Reinaldo dos Santos ou por técnica de Sel dinger', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aortoarteriografia periférica', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia periférica por punção directa', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografias selectivas', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografias selectivas com embolização', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografias selectivas com dilatações arteriais', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cavografias ou flebografias', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografias selectivas', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esplenoportografia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfografias', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fleborrafia orbitária por punção da veia frontal', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tomografia, cada incidência ou lado mínimo 4 planos, filmes 18-24', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tomografia, cada incidência ou lado mínimo 4 planos, filmes 24-30', 6);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Tomografia, cada incidência ou lado, mínimo 4 planos, filmes 30x40, 35x35 ou medidas superiores', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteodensitometria monofotónica primeira avaliação', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteodensitometria monofotónica estudos comparativos', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteodensitometria bifotónica primeira avaliação', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Osteodensitometria bifotónica estudos comparativos', 30);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Osteodensitometria por dupla energia com utilização de ampolas de Rx (coluna, femur ou esqueleto', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiocardiografia de radionuclídeos (ARN)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiocardiografia de Radionuclídeos (ARN) com esforço ou stress', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de perfusão do miocárdio em repouso e esforço com SPECT/TEC', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama cardíaco com àcidos gordos e SPECT/TEC', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama de distribuição do 131I-MIBG cardíaco', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama de distribuição do 123I-MIBG cardíaco', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cisternoventrículo cintigrafia', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama de perfusão cerebral com SPECT/TEC', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de perda de líquido cefalora-quidiano', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama cerebral com SPECT/TEC', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia de tiroideia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo funcional da tiróide com 131I (Cint.+Curv. Fixação)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da fixação do 131I na tiróide (curva fixação)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia corporal com 131 I', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama corporal com 99mTc-DMSA', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de distribuição do 131I-MIBG', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudos de distrinbuição do 123I-MIBG', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama hepatobiliar com estimulação vesicular e quantificação', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama hepatobiliar com quantificação da função', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama hepático com globulos vermelhos marcados', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama hepatoesplénico', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da permeabilidade de cateter', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de refluxo biliogástrico', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia esplénica', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama esplénico com glubulos vermelhos fragilizados', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo funcional das glândulas salivares (Cint. + Estimulação)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Trânsito Esofágico', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esvaziamento gástrico', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de refluxo gastroesofágico', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama intestinal com leucócitos marcados', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da permeabilidade intestinal (EDTA)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Determinação de perdas proteicas', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de hemorragia digestiva', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pesquisa de divertículo de Meckel', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova da absorção intestinal do Fe 59', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Absorção de vitamina B12 (Teste Schilling)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Renograma', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Renograma com prova diurética ou outra', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama renal (DTPA; MAG3; HIPURAN)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama renal + renograma', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia renal com DMSA', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama Renal com quant. função (método gamagráfico)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quantificação da função com 51 Cr-EDTA ("in vitro")', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama Renal + Cistografia indirecta', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cistocintigrafia directa', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de perfusão de rim transplantado', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinética do Ferro', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de cinética das plaquetas', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de distribuição de leucócitos marcados', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama da medula óssea', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Semi-vida dos eritrocitos', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Volume plasmático', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Determinação do volume sanguíneo total ou volémia', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama do Esqueleto (corpo inteiro ou parcelares)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vista parcelar óssea suplementar', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama ósseo com estudo de perfusão de uma região (3 fases)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Densitometria óssea bifotónica/DEXA (1 região)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Densitometria óssea bifotónica/DEXA (corpo inteiro)', 20);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Densitometria óssea bifotónica/DEXA com análise evolutiva (comparação)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Densitometria óssea bifotónica/DEXA + morfometria', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama pulmonar de ventilação com 133Xe', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama pulmonar de inalação (DTPA; Technegas)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia pulmonar de perfusão', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da permeabilidade do epitélio pulmonar', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de distribuição com Gálio 67 (1 região)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de distribuição com Gálio 67 (corpo inteiro)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de distribuição de leucócitos marcados (1 região)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de distribuição de leucócitos marcados (corpo inteiro)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama das paratiróides com 201 TI/99m Tc', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama ósseo com 201TI (1 região)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama corporal com 201TI', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama corporal com 99m Tc-DMSA', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia de órgão não especificado', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dacriocintigrafia', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo da fase vascular de um órgão ou região (complemento do estudo)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo de distribuição do lodo-colesterol', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Linfocintigrafia', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tomografia de emissão computorizada (SPECT/TEC)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Venografia isotópica', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama corporal com receptores da somatostatina', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrafia da mama', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cintigrama testicular', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Permeabilidade tubárica', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Imunocintigrama com anticorpos monoclonais', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 32P (ambulatória)', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com Ytrium 1mCi (ambulatória)', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com Ytrium cada mCi a mais', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com estrôncio (Metastron)', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131 IMIBG', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131I até 10 mCi', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131I até 15 mCi', 9);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131I até 50 mCi', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131I até 100 mCi', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131I de 100 a 150 mCi', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapêutica com 131I além de 150 mCi', 18);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Abdominal', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ginecológica', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ginecológica c/ sonda vaginal', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vagina', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Obstétrica', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Obstétrica c/ fluxometria', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Obstétrica c/ fluxometria umbilical', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Renal e suprarenal', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vesical (suprapúbica)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vesical (transuretral)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vesículas seminais', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostática (suprapúbica)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prostática (transrectal)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Escrotal', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Peniana', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mamária (2 lados)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Seios perinasais', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tiroideia', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Encefálica', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oftalmológica (A)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oftalmológica (A+B)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biometria ecográfica oftalmológica', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Partes moles', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Glândulas salivares', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção ou biópsia dirigida=preço da região +', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Per operatória (diagnostica)', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia osteoarticular', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia carotidea com Doppler', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia abdominal com Doppler', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia renal com Doppler', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia peniana com Doppler', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia arterial dos membros superiores com Doppler', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia venosa dos membros superiores com Doppler', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia arterial dos membros inferiores com Doppler', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ecografia venosa dos membros inferiores com Doppler', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crânio ou coluna', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tórax ou abdómen', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crânio ou coluna com cortes de menos de 2 milímetros', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Membros', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Punção dirigida = preço da região +', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo dinâmico = preço da região +', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Plano de tratamento de radioterapia = preço da região +', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame cranio-encefálico', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da fossa posterior', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da charneira craniovertebral', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da coluna cervical', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da coluna dorsal', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da coluna lombosagrada', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da totalidade da coluna (apenas no plano sagital)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame do ouvido médio e labirinto membranoso', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da órbita', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da hipófise e seio cavernoso', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame do cavum faringeo e regiões vizinhas', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exame da região craniofacial dos seios perinasais e glândulas salivares', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame dos troncos vasculares supra-aórticos', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame do abdómen', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame da pelve', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame do tórax', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame do coração e cardio--vasculares', 75);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, em "real-time" (cine)', 90);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame osteo-muscular', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame das articulações', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame do pescoço', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Espectroscopia clínica', 100);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame cranio-encefálico com indicação para estudo das cisternas da base craniana (Fossa média e posterior)',
                                  60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame cranio-encefálico com indicação para estudo de hidrocefalia', 60);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Exame cranio-encefálico com indicação para estudo do hipótalamo e região optoquiasmática', 60);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame cranio-encefálico com indicação para estudo da hipófise e veio cavernoso (incluindo situações de pós operatório)',
                                  60);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame cranio-encefálico com indicarão para estudo do angulo ponto cerebeloso (incluindo condutos auditivos internos)',
                                  60);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame cranio-encefálico com indicação para estudo do tronco cerebral (patologia tumoral, desmielinizante e vascular)',
                                  60);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Exame cranio-encefálico com indicação para estudo vascular dos territórios cerebrais e da fossa posterior',
   60);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame cranio-encefálico com indicação para estudo do aqueduto do Sylvius, região pineal e 4º. ventrículo (incluindo patologia tumoral)',
                                  60);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame da charneira cranio-vertebral com indicação para estudo das amígdalas cerebelosas, de transição bulbo-medular e respectivas cisternas',
                                  60);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame da medula com indicação para despiste de lesões de pequena dimensão (cavitações, hematomas, malformações vasculares, anomalias, doenças infecciosas desmielinizantes e tumorais)',
                                  60);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame da coluna lombo-sagrada com indicação para estudo das raízes nervosas e suas relações intratecais e foraminais (patologia herniária, infecciosa e tumoral)',
                                  60);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame do ouvido (particularmente do ouvido crónico complicado, degeneres-cência labiríntica, nervo facial intra e extrapetroso, tumores do conduto e caixa timpânica)',
                                  90);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Exame da órbita (particularmente patologia intrínseca ou extrínseca do nervo óptico e suas relações com a artéria oftálmica, tumores oculares e seu diagnóstico diferencial)',
                                  90);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação hemodinâmica dos membros superiores - Fluxometria Doppler (arterial ou venosa)', 15);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação hemodinâmica dos membros inferiores - Fluxometria Doppler (arterial ou venosa)', 15);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Avaliação hemodinâmica arterial dos membros - Fluxometria Doppler-compressões segmentares ou provas de hiperemia',
                                  20);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação hemodinâmica arterial cervico-encefálica - Fluxometria Doppler', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Avaliação da circulação digital com fotopletismografia', 15);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Avaliação hemodinâmica da circulação venosa dos membros com pletismografia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiodinografia (Doppler vascular colorido)', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Eco Doppler "Duplex-Scan" carotídeo', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Doppler Transcraniano', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, circulação arterial ou venosa dos membros', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, circulação visceral abdominal', 25);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Angiografia ultra-sónica com análise espectral cerebrovascular carotídea', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia ultra-sónica com análise espectral dos membros', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Rigiscan', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Doppler Peniano', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Eco Doppler peniano', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Eco Doppler colorido peniano', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Teste PGE com papaverina ou prostaglandinas', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Artérias cerebrais ­ Panarteriografia', 60);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia carotidea por punção', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia carotidea por cateterismo (Seldinger)', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia vertebral / por punção umeral', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia vertebral / por cateterismo (Seldinger)', 35);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Membros superiores / por punção ou cateterismo', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aortografia ou aortoarteriografia translombar', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aortografia ou aortoarteriografia por cateterismo (Seldinger)', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia selectiva de ramos da aorta', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia do membro inferior', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia das artérias genitais', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia cava superior', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia jugular interna', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia dos membros (unilateral)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Iliocavografia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Azigografia', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia mamária interna', 15);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia renal', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia das veias pélvicas', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Esplenoportografia', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Portografia trans-hepática', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia supra-hepática', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Portografia transumbilical', 30);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arteriografia selectiva e embolização terapêutica, artéria carótida externa', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia selectiva e embolização terapêutica, artéria do membro', 50);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arteriografia selectiva e embolização terapêutica, ramo visceral da aorta', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia e dilatação de artéria carótida (*)', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia e dilatação per operatória de artéria vertebral (*)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia selectiva e dilatação percutânea de artéria do membro', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arteriografia selectiva e dilatação percutânea do tronco arterial braquiocefálico (*)', 130);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Arteriografia selectiva e dilatação percutânea de um ramo visceral da aorta', 130);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Dilatação per operatória de artéria de membro (*)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desobstrução intraluminal com Laser', 120);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Desobstrução intraluminal com Rotablator', 120);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Flebografia selectiva transhepática percutânea e embolização (Varizes gastro-esofágicas)', 80);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colocação de filtro na V.C.I. por via percutânea', 70);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crossografia aortica', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, c/ Troncos supra-aorticos', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Idem, c/ pan-angiografia cerebral', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia orbito-cavernosa', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carótida por punção directa (inclui angiografia cerebral)', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Troncos supra-aorticos por punção humeral', 30);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crossa aórtica e troncos supra aorticos', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Uma artéria (carótida interna, externa vertebral ou cervical profunda)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Duas artérias', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Três artérias', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Quatro artérias', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Mais que quatro artérias (inclui estudo superselectivo dos ramos carotidos)', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Angiografia radiculo-medular (por cada região: cervical, dorsal ou lombar)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arco aórtico (arteriografia)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia brônquica', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Pulmonar', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Areteriografia da Subclávia e Humeral', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia dos Membros Superiores', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Abdominal', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tronco Celíaco', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Selectiva Esplénica', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Selectiva Coronária Estomáquica', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Selectiva Hepática', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Pancreática', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pantografia por via arterial', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia das Supra-Renais', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia das Supra-Renais', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colheitas Selectivas Reninas (Renais)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Colheitas Selectivas Hormonais (supra renais)', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Angiografia Ovárica, Testicular', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia do Mesentério Superior', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia do Mesentérico Inferior', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia da Hipogástrica', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia das íliacas', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Arteriografia Periférica dos Membros Inferiores', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia dos Membros Superiores', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia dos Membros Inferiores', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia da Veia-Cava superior', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Flebografia da Veia-Cava Inferior', 100);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Intracraniana e Medular', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Carótida Externa', 250);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outros Territórios', 200);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Avaliação Clínica e decisão do tratamento', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cobaltoterapia', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Simulação do tratamento', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Consultas de acompanhamento', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Roentgenterapia', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Planeamento Clínico', 14);
INSERT INTO ProcedureType VALUES (DEFAULT, 'A.L. de particulas (baixa energia)', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'A.L. de partículas (média energia)', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'A.L. de particulas (alta energia)', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Irradiação de meio corpo', 12);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Irradiação de corpo inteiro', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'A.P.T.T. para Estudo dos Tempos de Tromboplastina Parcial Alongados', 15);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Suor (Determinação dos cloretos ou sódio no), após estimulação por iontoforese com pilocarpina', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova da Clonidina com Doseamentos Hormonais', 100);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova de Clomifene Alargada (doseamentos de L.H.,FSH,Estradiol, Testosterona cada doseamento)', 3);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova de Clomifene com 2 doseamentos de H.L., 2 de FSH, 2 de Estradiol, 2 de Testosterona', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova de Estim.da STH pelo Exercício, cada determ.de STH', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova.de Estimul.c/L.R.H. com 3 doseamentos de L.H. e 3 de FSH, cada', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova de Estimul.c/T.R.H. com doseamentos de TSH, cada', 3);
INSERT INTO ProcedureType VALUES (DEFAULT,
                                  'Prova de Estim.Múltipla p/ TRH,LRH e Hipoglicémia (7/Glicémia, 6/STH, 5/Cortiso1,4/PRL, 4/FSH, 4/L, 5/ACTH',
                                  8);
INSERT INTO ProcedureType VALUES
  (DEFAULT, 'Prova de Estimulaqão Múltipla alarg. pelo TRH,LRH e Hipoglic.c/dos.PRL, TSH,FSH,LH,ACTH,Cortisol cada', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova de Glucagon com doseamentos de STH-cada doseamento', 3);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova de Hipoglicémia Insulinica (I.V.) com doseamentos hormonais, cada determinação', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova de Inibiçâo da STH após sobrecarga Glúcidica, cada dos. De STH', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova da Metirapona c/2 dos.Comp. S/17 Cetosteroides, (cada)', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Prova de Estimulação com ACTH, com doseamentos de Cortisol (cada)', 4);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Prova de Hiperglicémia provocada com doseamentos de insulina simultâneos, cada', 3);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Suco Gástrico-Prova de Estimulação pela Hipoglicemia induz. pela insulina', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Suco Gástrico-Prova de Estimulação pela Pentagastrina', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Suco Gástrico-Prova de Estimulação pelo Histalog', 3);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Suor-Det. Cloretos ou Sódio no suor após Estim. por Iontof.c/Pilocarp.', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames histológicos', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames cito-histológicos (exame citológico com inclusão)', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames citológicos', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames citohormonais por esfregaços seriados', 10);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames histológicos extemporâneos per-operatórios', 40);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exames ultraestruturais (microscopia electrónica)', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Diagnóstico imuno-cito-químico', 50);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de alta resoluçâo em fibro blastos', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de alta resolução em linfocitos com PHA', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de alta resolução em linfocitos sem PHA', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de células amnióticas', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo da medula óssea c/PHA', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo da medula óssea s/PHA', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cariótipo de vilosidades coriónicas', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estudo em biópsia testicular, pele, tecido de aborto', 20);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame de marcha com registo gráfico', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Exame muscular com registo gráfico', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Raquimetria', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Electrodiagnóstico de estimulação', 4);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Testes de Psicomotricidade', 25);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corrente contínua', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corrente de baixa frequência', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corrente de média frequência', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Corrente de alta frequência', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Ultra-som', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estimulação eléctrica de pontos motores', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Magnetoterapia', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Biofeedback', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Raios infra-vermelhos', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Raios ultra-violetas', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laserterapia de hélio-neon', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laserterapia de raios infra-vermelhos', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Laserterapia de hélio-neon + raios infra-vermelhos', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Crioterapia', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Calor húmido', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parafina', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Parafango', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Outros pelóides', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hidrocinesiterapia', 2.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Hidromassagem', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Banho de contraste', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Banho de turbilhão', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Banhos especiais', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Duches', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tanque de hubbard', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tanque de marcha', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Massagem manual de uma região', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Massagem manual de mais de uma região', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Massagem com técnicas especiais', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Massagem manual em imersão', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Vibromassagem', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Massagem com vácuo', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinesiterapia respiratória', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinésiterapia vertebral', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinesiterapia correctiva postural', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Cinesiterapia pré e pós parto', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fortalecimento muscular manual', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mobilização articular manual', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Técnicas especiais de Cinesiterapia', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Reeducação do equilíbrio e/ou marcha', 2);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Qualquer destas modalidades terapêuticas quando feita em grupo (máximo de 6 doentes)', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aerossóis', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Aerossóis ultra-sónicos', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'IPPB', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Oxigenoterapia', 1);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tracção vertebral mecânica', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Tracção vertebral motorizada', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pressões alternas positivas', 1.5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Pressões alternas positivas com monitorização contínua', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fortalecimento muscular/mobilização articular', 1.5);
INSERT INTO ProcedureType
VALUES (DEFAULT, 'Fortalecimento muscular/mobilização articular com monitorização contínua', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Fortalecimento muscular isocinético', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uso de próteses', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Uso de ortóteses', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Actividades de vida diária', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapia ocupacional', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Terapia da fala/comunicação', 2);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Readaptação ao esforço com monitorização contínua', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Manipulação vertebral', 8);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Manipulação de membros', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Acupuntura', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Infiltração', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Mesoterapia', 6);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Estimulação transcutânea', 5);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Confecção de ligadura funcional', 7);
INSERT INTO ProcedureType VALUES (DEFAULT, 'Confecção de ortóteses', 7);