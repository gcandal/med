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

  /*
  INSERT INTO PrivatePayer (idaccount, name, valuePerK)
    SELECT
      NEW.idaccount,
      name,
      PrivatePayer.valueperk
    FROM PrivatePayer, Procedure
    WHERE idProcedure = NEW.idProcedure AND PrivatePayer.idPrivatePayer = Procedure.idPrivatePayer AND
          idAccount != NEW.idAccount;
          */

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

DROP TRIGGER IF EXISTS edit_procedure_trigger ON Procedure;
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