<?php

function getProcedures($idAccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT idProcedure, paymentstatus, idprivatepayer, identitypayer, date,
        totalRemun, role, readonly, personalremun
         FROM PROCEDURE NATURAL JOIN PROCEDUREACCOUNT WHERE idAccount = ? ORDER BY date DESC");

    $stmt->execute(array($idAccount));

    $procedures = $stmt->fetchAll();

    foreach ($procedures as &$procedure) {
        if ($procedure['idprivatepayer'] != 0) {
            $tmp = getPrivatePayer($procedure['idprivatepayer']);
            $procedure['payerName'] = $tmp['name'];
            $procedure['idpayer'] = $tmp['idprivatepayer'];
        } else if ($procedure['identitypayer'] != 0) {
            $tmp = getEntityPayer($procedure['identitypayer']);
            $procedure['payerName'] = $tmp['name'];
            $procedure['idpayer'] = $tmp['identitypayer'];
        } else {
            $procedure['payerName'] = 'Não Definido';
            $procedure['idpayer'] = 0;
        }

        $organization = getOrganizationForProcedure($procedure['idprocedure'], $idAccount);

        if ($organization) {
            $procedure['organizationName'] = $organization['name'];
            $procedure['idorganization'] = $organization['idorganization'];
        }
    }

    return $procedures;
}

function getOrganizationForProcedure($idProcedure, $idAccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT name, Organization.idOrganization FROM Organization, ProcedureOrganization
                            WHERE ProcedureOrganization.idProcedure = :idProcedure
                            AND ProcedureOrganization.idAccount = :idAccount
                            AND Organization.idOrganization = ProcedureOrganization.idOrganization");

    $stmt->execute(array("idProcedure" => $idProcedure, "idAccount" => $idAccount));

    return $stmt->fetch();
}

function getPatientForProcedure($idProcedure)
{
    global $conn;

    $stmt = $conn->prepare("SELECT Patient.idpatient, name, nif, cellphone, beneficiarynr
                            FROM Patient, Procedure
                            WHERE Procedure.idProcedure = :idProcedure AND Patient.idPatient = Procedure.idPatient");

    $stmt->execute(array("idProcedure" => $idProcedure));

    return $stmt->fetch();
}

function getProcedure($idAccount, $idProcedure)
{
    global $conn;

    $stmt = $conn->prepare("SELECT idProcedure, paymentstatus, idprivatepayer, identitypayer, date,
        totalRemun, role, hasManualK, anesthetistK, readonly, localanesthesia, valueperk
         FROM PROCEDURE NATURAL JOIN PROCEDUREACCOUNT WHERE idAccount = ? AND idProcedure = ?
         ORDER BY date DESC");

    $stmt->execute(array($idAccount, $idProcedure));

    $procedure = $stmt->fetch();

    if (!$procedure)
        return false;

    if ($procedure['idprivatepayer'] != 0) {
        $tmp = getPrivatePayer($procedure['idprivatepayer']);
        $procedure['payerName'] = $tmp['name'];
        $procedure['idpayer'] = $tmp['idprivatepayer'];
    } else if ($procedure['identitypayer'] != 0) {
        $tmp = getEntityPayer($procedure['identitypayer']);
        $procedure['payerName'] = $tmp['name'];
        $procedure['idpayer'] = $tmp['identitypayer'];
    } else {
        $procedure['payerName'] = 'Não Definido';
        $procedure['idpayer'] = 0;
    }

    $organization = getOrganizationForProcedure($procedure['idprocedure'], $idAccount);

    if ($organization) {
        $procedure['organizationName'] = $organization['name'];
        $procedure['idorganization'] = $organization['idorganization'];
    } else $procedure['idorganization'] = -1;

    $patient = getPatientForProcedure($procedure['idprocedure']);

    if ($patient) {
        $procedure['patientName'] = $patient['name'];
        $procedure['patientNif'] = $patient['nif'];
        $procedure['patientCellphone'] = $patient['cellphone'];
        $procedure['patientBenefeciaryNr'] = $patient['benefeciarynr'];
        $procedure['idpatient'] = $patient['idpatient'];
    } else $procedure['idpatient'] = -1;


    return $procedure;
}

function getSubProcedures($idProcedure)
{
    global $conn;

    $stmt = $conn->prepare("SELECT name, quantity FROM proceduretype, procedureproceduretype
                                WHERE procedureproceduretype.idprocedure = :idProcedure
                                AND procedureproceduretype.idproceduretype = proceduretype.idproceduretype");

    $stmt->execute(array("idProcedure" => $idProcedure));

    return $stmt->fetchAll();
}

function getSubProceduresIds($idProcedure)
{
    global $conn;

    $stmt = $conn->prepare("SELECT quantity, procedureproceduretype.idproceduretype  FROM proceduretype, procedureproceduretype
                                WHERE procedureproceduretype.idprocedure = :idProcedure
                                AND procedureproceduretype.idproceduretype = proceduretype.idproceduretype");

    $stmt->execute(array("idProcedure" => $idProcedure));

    return $stmt->fetchAll();
}

function getNumberOfOpenProcedures($idAccount)
{
    global $conn;
    $stmt = $conn->prepare("SELECT COUNT(*) AS number FROM  PROCEDURE NATURAL JOIN PROCEDUREACCOUNT WHERE idAccount = ?
                                AND (paymentstatus = 'Recebi' OR paymentstatus = 'Pendente');");
    $stmt->execute(array($idAccount));

    return $stmt->fetch();
}

function isProcedure($idProcedure)
{
    global $conn;
    $stmt = $conn->prepare("SELECT * FROM PROCEDURE WHERE idProcedure = ?");
    $stmt->execute(array($idProcedure));

    return $stmt->fetch() == true;
}

function isEntityPayer($idEntityPayer)
{
    global $conn;
    $stmt = $conn->prepare("SELECT * FROM ENTITYPAYER WHERE idEntityPayer = ?");
    $stmt->execute(array($idEntityPayer));

    return $stmt->fetch() == true;
}

function isPrivatePayer($idPrivatePayer)
{
    global $conn;
    $stmt = $conn->prepare("SELECT * FROM PRIVATEPAYER WHERE idPrivatePayer = ?");
    $stmt->execute(array($idPrivatePayer));

    return $stmt->fetch() == true;
}

function addProcedure($idAccount, $paymentStatus, $date, $totalRemun, $valuePerK,
                      $idprivatepayer, $identitypayer, $role,
                      $anesthetistK, $hasManualK, $localAnesthesia, $personalRemun,
                      $generalRemun, $firstAssistantRemun, $secondAssistantRemun,
                      $anesthetistRemun, $instrumentistRemun)
{
    global $conn;

    if (!is_numeric($totalRemun) || $totalRemun < 0)
        $totalRemun = 0;

    if (!is_numeric($valuePerK) || $valuePerK < 0)
        $valuePerK = 0;

    if (!$hasManualK)
        $hasManualK = "false";

    if (strtotime($date)) {
        $stmt = $conn->prepare("INSERT INTO PROCEDURE(paymentstatus, date, identitypayer,
                                idprivatepayer, totalremun, valueperk,
                                anesthetistK, hasmanualk, generalremun, firstassistantremun,
                                secondassistantremun, anesthetistremun, instrumentistremun,
                                localAnesthesia)
                                VALUES(:paymentStatus, :date, :identitypayer,
                                :idprivatepayer, :totalremun, :valueperk, :anesthetistK, :hasManualK,
                                :generalRemun, :firstAssistantRemun, :secondAssistantRemun,
                                :anesthetistRemun, :instrumentistRemun, :localAnesthesia);");

        $stmt->execute(array("paymentStatus" => $paymentStatus, "date" => $date,
            "identitypayer" => $identitypayer, "idprivatepayer" => $idprivatepayer,
            "totalremun" => $totalRemun, "valueperk" => $valuePerK, "anesthetistK" => $anesthetistK,
            "hasManualK" => $hasManualK, "generalRemun" => $generalRemun,
            "firstAssistantRemun" => $firstAssistantRemun, "secondAssistantRemun" => $secondAssistantRemun,
            "anesthetistRemun" => $anesthetistRemun, "instrumentistRemun" => $instrumentistRemun,
            "localAnesthesia" => $localAnesthesia));
    } else {
        $stmt = $conn->prepare("INSERT INTO PROCEDURE(paymentstatus, date, identitypayer,
                                idprivatepayer, totalremun, valueperk,
                                anesthetistK, hasmanualk, generalremun, firstassistantremun,
                                secondassistantremun, anesthetistremun, instrumentistremun,
                                localAnesthesia)
                                VALUES(:paymentStatus, CURRENT_TIMESTAMP,
                                :identitypayer, :idprivatepayer, :totalremun, :valueperk,
                                :anesthetistK, :hasManualK,
                                :generalRemun, :firstAssistantRemun, :secondAssistantRemun,
                                :anesthetistRemun, :instrumentistRemun, :localAnesthesia);");

        $stmt->execute(array("paymentStatus" => $paymentStatus,
            "identitypayer" => $identitypayer, "idprivatepayer" => $idprivatepayer,
            "totalremun" => $totalRemun, "valueperk" => $valuePerK, "anesthetistK" => $anesthetistK,
            "hasManualK" => $hasManualK, "generalRemun" => $generalRemun,
            "firstAssistantRemun" => $firstAssistantRemun, "secondAssistantRemun" => $secondAssistantRemun,
            "anesthetistRemun" => $anesthetistRemun, "instrumentistRemun" => $instrumentistRemun,
            "localAnesthesia" => $localAnesthesia));
    }

    $id = $conn->lastInsertId('procedure_idprocedure_seq');

    decrementFreeRegisters($idAccount);
    addProcedureToAccount($id, $idAccount, $role, 'false', $personalRemun);

    return $id;
}

function decrementFreeRegisters($idAccount)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE ACCOUNT SET freeRegisters = freeRegisters - 1
                            WHERE idAccount = :idaccount AND freeRegisters > 0");
    $stmt->execute(array(":idaccount" => $idAccount));
}

function incrementFreeRegisters($idAccount)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE ACCOUNT SET freeRegisters = freeRegisters + 1
                            WHERE idAccount = :idaccount AND freeRegisters > -1");
    $stmt->execute(array(":idaccount" => $idAccount));
}

function getFreeRegisters($idAccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT freeRegisters FROM Account
                            WHERE idAccount = :idAccount");

    $stmt->execute(array(":idAccount" => $idAccount));

    $result = $stmt->fetch();

    return $result['freeregisters'];
}

function editProcedure($idAccount, $idProcedure, $paymentStatus, $date, $totalRemun, $valuePerK, $idprivatepayer,
                       $identitypayer, $role, $anesthetistK, $hasManualK, $personalRemun,
                       $generalRemun, $firstAssistantRemun, $secondAssistantRemun,
                       $anesthetistRemun, $instrumentistRemun)
{
    global $conn;

    if (!is_numeric($totalRemun) || $totalRemun < 0)
        $totalRemun = 0;

    if (!is_numeric($valuePerK) || $valuePerK < 0)
        $valuePerK = 0;

    if (!$hasManualK)
        $hasManualK = "false";

    $stmt = $conn->prepare("UPDATE PROCEDURE SET
                            paymentstatus = :paymentStatus,
                            identitypayer = :identitypayer,
                            idprivatepayer = :idprivatepayer,
                            totalremun = :totalremun,
                            valueperk = :valueperk,
                            anesthetistK = :anesthetistK,
                            hasmanualk = :hasManualK,
                            generalremun = :generalRemun,
                            firstassistantremun = :firstAssistantRemun,
                            secondassistantremun = :secondAssistantRemun,
                            anesthetistremun = :anesthetistRemun,
                            instrumentistremun = :instrumentistRemun
                            WHERE idprocedure = :idprocedure");

    $stmt->execute(array("paymentStatus" => $paymentStatus,
        "identitypayer" => $identitypayer, "idprivatepayer" => $idprivatepayer,
        "totalremun" => $totalRemun, "valueperk" => $valuePerK, "anesthetistK" => $anesthetistK,
        "hasManualK" => $hasManualK, "idprocedure" => $idProcedure, "generalRemun" => $generalRemun,
        "firstAssistantRemun" => $firstAssistantRemun, "secondAssistantRemun" => $secondAssistantRemun,
        "anesthetistRemun" => $anesthetistRemun, "instrumentistRemun" => $instrumentistRemun));

    if (strtotime($date)) {
        $stmt = $conn->prepare("UPDATE PROCEDURE SET
                            date = :date
                            WHERE idprocedure = :idprocedure");

        $stmt->execute(array("date" => $date, "idprocedure" => $idProcedure));
    } else {
        $stmt = $conn->prepare("UPDATE PROCEDURE SET
                            date = CURRENT_TIMESTAMP
                            WHERE idprocedure = :idprocedure");
        $stmt->execute();
    }

    editProcedureAccount($idProcedure, $idAccount, $role, 'false', $personalRemun);
}

function editSubProcedures($idProcedure, $subProcedures)
{
    global $conn;

    $stmt = $conn->prepare("DELETE FROM PROCEDUREPROCEDURETYPE WHERE idprocedure = ?");

    $stmt->execute(array($idProcedure));

    addSubProcedures($idProcedure, $subProcedures);
}

function addSubProcedures($idProcedure, $subProcedures)
{
    global $conn;

    $groupedSubProcedures = array();

    foreach ($subProcedures as $subProcedure) {
        if ($groupedSubProcedures[$subProcedure])
            $groupedSubProcedures[$subProcedure] += 1;
        else
            $groupedSubProcedures[$subProcedure] = 1;
    }

    foreach ($groupedSubProcedures as $subProcedure => $count) {
        $stmt = $conn->prepare("INSERT INTO PROCEDUREPROCEDURETYPE(idprocedure, idproceduretype, quantity)
                          VALUES(:idProcedure, :idProcedureType, :quantity)");

        $stmt->execute(array(":idProcedure" => $idProcedure, ":idProcedureType" => $subProcedure,
            ":quantity" => $count));
    }

    return $groupedSubProcedures;
}

function addProcedureToOrganization($idProcedure, $idOrganization, $idAccount)
{
    global $conn;

    $stmt = $conn->prepare("INSERT INTO ProcedureOrganization
                            VALUES(:idprocedure, :idorganization, :idaccount)");
    $stmt->execute(array("idprocedure" => $idProcedure, "idorganization" => $idOrganization,
        "idaccount" => $idAccount));
}

function editProcedurePatient($idProcedure, $idPatient)
{
    global $conn;

    if ($idPatient == -1) {
        $stmt = $conn->prepare("UPDATE Procedure
                            SET idpatient = NULL
                            WHERE idprocedure = :idprocedure");

        $stmt->execute(array("idprocedure" => $idProcedure));
    } else {
        $stmt = $conn->prepare("UPDATE Procedure
                            SET idpatient = :idpatient
                            WHERE idprocedure = :idprocedure");
        $stmt->execute(array("idprocedure" => $idProcedure, "idpatient" => $idPatient));
    }
}

function editProcedureFromOrganization($idProcedure, $idOrganization, $idAccount)
{
    global $conn;

    if ($idOrganization == -1) {
        $stmt = $conn->prepare("DELETE FROM ProcedureOrganization
                            WHERE idProcedure = :idprocedure AND idAccount = :idaccount");

        $stmt->execute(array("idprocedure" => $idProcedure, "idaccount" => $idAccount));
    } else {
        $stmt = $conn->prepare("SELECT 1 FROM ProcedureOrganization
                            WHERE idProcedure = :idprocedure AND idAccount = :idaccount");

        $stmt->execute(array("idprocedure" => $idProcedure, "idaccount" => $idAccount));

        if ($stmt->fetch()) {
            $stmt = $conn->prepare("UPDATE ProcedureOrganization
                            SET idOrganization = :idorganization
                            WHERE idProcedure = :idprocedure AND idAccount = :idaccount");

            $stmt->execute(array("idprocedure" => $idProcedure, "idorganization" => $idOrganization,
                "idaccount" => $idAccount));
        } else addProcedureToOrganization($idProcedure, $idOrganization, $idAccount);
    }
}

function addProcedureToAccount($idProcedure, $idAccount, $role, $readOnly, $personalRemun)
{
    global $conn;

    $stmt = $conn->prepare("INSERT INTO PROCEDUREACCOUNT VALUES(:idprocedure, :idaccount, :role, :readOnly,
                                                                :personalRemun)");
    $stmt->execute(array("idprocedure" => $idProcedure, "idaccount" => $idAccount,
        "role" => $role, "readOnly" => $readOnly, "personalRemun" => $personalRemun));
}

function editProcedureAccount($idProcedure, $idAccount, $role, $readOnly, $personalRemun)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE PROCEDUREACCOUNT SET role = :role, readonly = :readOnly,
                            personalremun = :personalRemun
                            WHERE idProcedure = :idProcedure AND idAccount = :idAccount");
    $stmt->execute(array("idProcedure" => $idProcedure, "idAccount" => $idAccount,
        "role" => $role, "readOnly" => $readOnly, "personalRemun" => $personalRemun));

    $stmt->fetch();
}

function removeSubProcedure($idProcedure, $idProcedureType)
{
    global $conn;

    $stmt = $conn->prepare("DELETE FROM PROCEDUREPROCEDURETYPE WHERE idprocedure = ? AND idproceduretype = ?");

    $stmt->execute(array($idProcedure, $idProcedureType));


    return $stmt->fetch();
}

function deleteProcedure($idProcedure, $idAccount)
{
    global $conn;
    $stmt = $conn->prepare("SELECT readonly FROM PROCEDUREACCOUNT
                WHERE ProcedureAccount.idAccount = :idAccount AND ProcedureAccount.idProcedure = :idProcedure");

    $stmt->execute(array("idProcedure" => $idProcedure, "idAccount" => $idAccount));

    $readonly = $stmt->fetch();

    if ($readonly && !$readonly['readonly'])
        incrementFreeRegisters($idAccount);

    $stmt = $conn->prepare("DELETE FROM ProcedureAccount WHERE idprocedure = :idprocedure
                             AND idaccount = :idaccount");
    $stmt->execute(array("idprocedure" => $idProcedure, "idaccount" => $idAccount));
}

function getProcedureTypes()
{
    global $conn;

    $stmt = $conn->prepare("SELECT * FROM PROCEDURETYPE");

    $stmt->execute();

    return $stmt->fetchAll();
}

function addProfessionalToProcedure($idProfessional, $idProcedure, $role)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE PROCEDURE SET id$role = :id$role WHERE idprocedure = :idprocedure;");
    $stmt->execute(array(":id$role" => $idProfessional, ":idprocedure" => $idProcedure));

    return $stmt->fetch();
}

function getProcedureProfessionals($idAccount, $idProcedure)
{
    global $conn;

    $stmt = $conn->prepare("SELECT idgeneral, idfirstassistant, idsecondassistant, idanesthetist, idinstrumentist, role FROM PROCEDURE, PROCEDUREACCOUNT
                WHERE ProcedureAccount.idAccount = :idAccount AND ProcedureAccount.idProcedure = :idProcedure AND Procedure.idProcedure = ProcedureAccount.idProcedure");

    $stmt->execute(array("idProcedure" => $idProcedure, "idAccount" => $idAccount));

    $ids = $stmt->fetch();
    $professionals = array();

    $stmt = $conn->prepare("SELECT Speciality.name AS speciality, Professional.name, idProfessional, nif, email, licenseid, email FROM SPECIALITY, PROFESSIONAL
                WHERE Professional.idProfessional = :idProfessional
                AND (Professional.idSpeciality IS NULL OR Speciality.idSpeciality = Professional.idSpeciality)");

    $functions = array('idgeneral', 'idfirstassistant', 'idsecondassistant', 'idanesthetist', 'idinstrumentist');
    $functionNames = array('Cirurgião Principal', 'Primeiro Assistente', 'Segundo Assistente', 'Anestesista', 'Instrumentista');
    $i = 0;

    foreach ($functions as $function) {
        $stmt->execute(array("idProfessional" => $ids[$function]));
        $result = $stmt->fetch();

        if ($result) {
            $result['function'] = $functionNames[$i];
            $professionals[substr($function, 2)] = $result;
        }

        $i++;
    }

    return $professionals;
}

function shareProcedure($idprocedure, $idinviting, $licenseid)
{
    global $conn;

    if ($licenseid === 'all') {
        $stmt = $conn->prepare("SELECT share_procedure_with_all(:idprocedure, :idaccount)");
        $stmt->execute(array("idprocedure" => $idprocedure, "idaccount" => $idinviting));
    } else {
        $stmt = $conn->prepare("INSERT INTO ProcedureInvitation(idProcedure, idInvitingAccount, licenseIdInvited)
                                VALUES (:idprocedure, :idaccount, :licenseid)");

        $stmt->execute(array("idprocedure" => $idprocedure, "idaccount" => $idinviting, "licenseid" => $licenseid));
    }
}

function getProcedureInvites($licenseid)
{
    global $conn;

    $stmt = $conn->prepare("SELECT Account.name invitingName,
                            ProcedureInvitation.idProcedure, ProcedureInvitation.idInvitingAccount, wasRejected
                            FROM ProcedureInvitation, Account
                            WHERE ProcedureInvitation.licenseIdInvited = :licenseId
                            AND ProcedureInvitation.idInvitingAccount = Account.idAccount");
    $stmt->execute(array("licenseId" => $licenseid));

    return $stmt->fetchAll();
}

function rejectShared($idProcedure, $idInvitingAccount, $licenseIdInvited)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE ProcedureInvitation SET wasRejected = TRUE
                            WHERE idProcedure = :idProcedure
                            AND idInvitingAccount = :idInvitingAccount
                            AND licenseIdInvited = :licenseIdInvited");

    $stmt->execute(array("idProcedure" => $idProcedure, "idInvitingAccount" => $idInvitingAccount, "licenseIdInvited" => $licenseIdInvited));
}

function deleteShared($idProcedure, $idInvitingAccount, $licenseIdInvited)
{
    global $conn;

    $stmt = $conn->prepare("DELETE FROM ProcedureInvitation
                            WHERE idProcedure = :idProcedure
                            AND idInvitingAccount = :idInvitingAccount
                            AND licenseIdInvited = :licenseIdInvited");

    $stmt->execute(array("idProcedure" => $idProcedure, "idInvitingAccount" => $idInvitingAccount, "licenseIdInvited" => $licenseIdInvited));
}

function acceptShared($idProcedure, $idInvitingAccount, $licenseIdInvited, $idAccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT role, personalremun FROM ProcedureInvitation
                            WHERE idProcedure = :idProcedure
                            AND idInvitingAccount = :idInvitingAccount
                            AND licenseIdInvited = :licenseIdInvited");

    $stmt->execute(array("idProcedure" => $idProcedure, "idInvitingAccount" => $idInvitingAccount,
        "licenseIdInvited" => $licenseIdInvited));

    $result = $stmt->fetch();

    addProcedureToAccount($idProcedure, $idAccount, $result['role'], true, $result['personalremun']);

    deleteShared($idProcedure, $idInvitingAccount, $licenseIdInvited);
}

/*
function cleanShareds()
{
    global $conn;

    $stmt = $conn->prepare("DELETE FROM ProcedureInvitation
                            WHERE date < CURRENT_TIMESTAMP - INTERVAL '7 days'");

    $stmt->execute();
}
*/
function getProcedureTypesForAutocomplete()
{
    global $conn;

    $stmt = $conn->prepare("SELECT idproceduretype id, name AS label, k, c, code FROM proceduretype");
    $stmt->execute();

    return $stmt->fetchAll();
}

function isReadOnly($idProcedure, $idAccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT idaccount
                            FROM procedureaccount
                            WHERE idaccount = :idAccount AND idprocedure = :idProcedure
                            AND readonly = FALSE");
    $stmt->execute(array("idProcedure" => $idProcedure, "idAccount" => $idAccount));

    return $stmt->fetch() == false;
}