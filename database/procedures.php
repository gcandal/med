<?php

function getProcedures($idAccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT idProcedure, paymentstatus, idprivatepayer, identitypayer, date,
        totalRemun, personalRemun, wasAssistant
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
    }

    return $procedures;
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

function addProcedure($idAccount, $paymentStatus, $date, $wasAssistant, $totalRemun, $personalRemun, $valuePerK, $idprivatepayer, $identitypayer)
{
    global $conn;

    //$code = hash('sha256', $paymentStatus + date('Y-m-d H:i:s')); // NEEDS TO BE CHANGED
    if (!is_numeric($totalRemun) || $totalRemun < 0)
        $totalRemun = 0;

    if (!is_numeric($personalRemun) || $personalRemun < 0)
        $personalRemun = 0;

    if (!is_numeric($valuePerK) || $valuePerK < 0)
        $valuePerK = 0;

    if (strtotime($date)) {
        $stmt = $conn->prepare("INSERT INTO PROCEDURE(idgeneral, paymentstatus, date, wasassistant, identitypayer,
                                idprivatepayer, totalremun, personalremun, valueperk)
                                VALUES(:idaccount, :paymentStatus, :date, :wasassistant, :identitypayer,
                                :idprivatepayer, :totalremun, :personalremun, :valueperk);");

        $stmt->execute(array("idaccount" => $idAccount, "paymentStatus" => $paymentStatus, "date" => $date,
            "wasassistant" => $wasAssistant, "identitypayer" => $identitypayer, "idprivatepayer" => $idprivatepayer,
            "totalremun" => $totalRemun, "personalremun" => $personalRemun, "valueperk" => $valuePerK));
    } else {
        $stmt = $conn->prepare("INSERT INTO PROCEDURE(idgeneral, paymentstatus, date, wasassistant, identitypayer,
                                idprivatepayer, totalremun, personalremun, valueperk)
                                VALUES(:idaccount, :paymentStatus, CURRENT_TIMESTAMP, :wasassistant,
                                :identitypayer, :idprivatepayer, :totalremun, :personalremun, :valueperk);");

        $stmt->execute(array("idaccount" => $idAccount, "paymentStatus" => $paymentStatus, "wasassistant" => $wasAssistant,
            "identitypayer" => $identitypayer, "idprivatepayer" => $idprivatepayer,
                "totalremun" => $totalRemun, "personalremun" => $personalRemun, "valueperk" => $valuePerK));
    }

    $id = $conn->lastInsertId('procedure_idprocedure_seq');

    addProcedureToAccount($id, $idAccount);

    return $id;
}

function addSubProcedures($idProcedure, $subProcedures)
{
    global $conn;

    $groupedSubProcedures = array();

    foreach($subProcedures as &$subProcedure) {
        if($groupedSubProcedures[$subProcedure])
            $groupedSubProcedures[$subProcedure] += 1;
        else
            $groupedSubProcedures[$subProcedure] = 1;
    }

    if (isset($groupedSubProcedures)) {
        foreach ($groupedSubProcedures as $subProcedure => $count) {
            $stmt = $conn->prepare("INSERT INTO PROCEDUREPROCEDURETYPE(idprocedure, idproceduretype, quantity)
                          VALUES(:idProcedure, :idProcedureType, :quantity)");

            $stmt->execute(array(":idProcedure" => $idProcedure, ":idProcedureType" => $subProcedure,
                                 ":quantity" => $count));
        }
    }
}

function addProcedureToAccount($idProcedure, $idAccount)
{
    global $conn;

    $stmt = $conn->prepare("INSERT INTO PROCEDUREACCOUNT VALUES(:idprocedure, :idaccount)");
    $stmt->execute(array("idprocedure" => $idProcedure, "idaccount" => $idAccount));

    return $stmt->fetch();
}

function editProcedurePrivatePayer($idProcedure, $idPrivatePayer)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE PROCEDURE SET idprivatepayer = ?
                                WHERE $idProcedure = ?;");
    $stmt->execute(array($idPrivatePayer, $idProcedure));

    return $stmt->fetch() == true;
}

function editProcedureEntityPayer($idProcedure, $idEntityPayer)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE PROCEDURE SET identitypayer = ?
                                WHERE $idProcedure = ?;");
    $stmt->execute(array($idEntityPayer, $idProcedure));

    return $stmt->fetch() == true;
}

function editProcedureDate($idProcedure, $date)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE PROCEDURE SET date = ?
                                WHERE $idProcedure = ?;");
    $stmt->execute(array($date, $idProcedure));

    return $stmt->fetch() == true;
}

function editProcedureTotalValue($idProcedure, $totalValue)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE PROCEDURE SET totalValue = ?
                                WHERE $idProcedure = ?;");
    $stmt->execute(array($totalValue, $idProcedure));

    return $stmt->fetch() == true;
}

function removeSubProcedure($idProcedure, $idProcedureType)
{
    global $conn;

    $stmt = $conn->prepare("DELETE FROM PROCEDUREPROCEDURETYPE WHERE idprocedure = ? AND idproceduretype = ?");

    $stmt->execute(array($idProcedure, $idProcedureType));

    return $stmt->fetch();
}

function removeProfessionalFromProcedure($idProcedure, $idProfessional)
{
    global $conn;

    $stmt = $conn->prepare("DELETE FROM PROCEDUREPROFESSIONAL WHERE idprocedure = ? AND idprofessional = ?");

    $stmt->execute(array($idProcedure, $idProfessional));

    return $stmt->fetch();
}

function deleteProcedure($idProcedure, $idAccount)
{
    global $conn;
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

function addFirstAssistant($idProfessional, $idProcedure)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE PROCEDURE SET idfirstassistant = :idfirstassistant WHERE idprocedure = :idprocedure;");
    $stmt->execute(array(":idfirstassistant" => $idProfessional, ":idprocedure" => $idProcedure));

    return $stmt->fetch();
}

function addSecondAssistant($idProfessional, $idProcedure)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE PROCEDURE SET idsecondassistant = :idsecondassistant WHERE idprocedure = :idprocedure;");
    $stmt->execute(array(":idsecondassistant" => $idProfessional, ":idprocedure" => $idProcedure));

    return $stmt->fetch();
}

function addInstrumentist($idProfessional, $idProcedure)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE PROCEDURE SET idinstrumentist = :idinstrumentist WHERE idprocedure = :idprocedure;");
    $stmt->execute(array(":idinstrumentist" => $idProfessional, ":idprocedure" => $idProcedure));

    return $stmt->fetch();
}

function addAnesthetist($idProfessional, $idProcedure)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE PROCEDURE SET idanesthetist = :idanesthetist WHERE idprocedure = :idprocedure;");
    $stmt->execute(array(":idanesthetist" => $idProfessional, ":idprocedure" => $idProcedure));

    return $stmt->fetch();
}

function addMaster($idProfessional, $idProcedure)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE PROCEDURE SET idmaster = :idmaster WHERE idprocedure = :idprocedure;");
    $stmt->execute(array(":idmaster" => $idProfessional, ":idprocedure" => $idProcedure));

    return $stmt->fetch();
}

function getProcedureProfessionals($idAccount, $idProcedure)
{
    global $conn;

    $stmt = $conn->prepare("SELECT idfirstassistant, idsecondassistant, idanesthetist, idinstrumentist FROM PROCEDURE, PROCEDUREACCOUNT
                WHERE ProcedureAccount.idAccount = :idAccount AND ProcedureAccount.idProcedure = :idProcedure AND Procedure.idProcedure = ProcedureAccount.idProcedure");

    $stmt->execute(array("idProcedure" => $idProcedure, "idAccount" => $idAccount));

    $ids = $stmt->fetch();
    $professionals = array();

    $stmt = $conn->prepare("SELECT Speciality.name as speciality, Professional.name, idProfessional, nif, licenseid, email, remuneration FROM SPECIALITY, PROFESSIONAL
                WHERE Professional.idProfessional = :idProfessional
                AND (Professional.idSpeciality IS NULL OR Speciality.idSpeciality = Professional.idSpeciality)");

    $functions = array('idfirstassistant', 'idsecondassistant', 'idanesthetist', 'idinstrumentist');
    $functionNames = array('Primeiro Assistente', 'Segundo Assistente', 'Anestesista', 'Instrumentista');
    $i = 0;

    foreach($functions as $function) {
        $stmt->execute(array("idProfessional" => $ids[$function]));
        $result = $stmt->fetch();

        if($result) {
            $result['function'] = $functionNames[$i];
            $professionals[$function] = $result;
        }

        $i++;
    }

    return $professionals;
}

function shareProcedure($idprocedure, $idinviting, $licenseid)
{
    global $conn;
    echo 3;
    if ($licenseid === 'all') {
        echo 1;
        $stmt = $conn->prepare("SELECT share_procedure_with_all(:idprocedure, :idaccount)");
        $stmt->execute(array("idprocedure" => $idprocedure, "idaccount" => $idinviting));
    } else {
        echo 2;
        $stmt = $conn->prepare("INSERT INTO ProcedureInvitation(idProcedure, idInvitingAccount, licenseIdInvited)
                                VALUES (:idprocedure, :idaccount, :licenseid)");

        $stmt->execute(array("idprocedure" => $idprocedure, "idaccount" => $idinviting, "licenseid" => $licenseid));
    }
}

function getInvites($licenseid)
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

    $stmt = $conn->prepare("INSERT INTO ProcedureAccount(idProcedure, idAccount)
                            VALUES (:idProcedure, :idAccount)");

    $stmt->execute(array("idProcedure" => $idProcedure, "idAccount" => $idAccount));

    deleteShared($idProcedure, $idInvitingAccount, $licenseIdInvited);
}

function cleanShareds()
{
    global $conn;

    $stmt = $conn->prepare("DELETE FROM ProcedureInvitation
                            WHERE date < CURRENT_TIMESTAMP - INTERVAL '7 days'");

    $stmt->execute();
}

function getProcedureTypesForAutocomplete() {
    global $conn;

    $stmt = $conn->prepare("SELECT idproceduretype id, name as label FROM proceduretype");
    $stmt->execute();

    return $stmt->fetchAll();
}