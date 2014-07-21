<?php

function getSpecialities()
{
    global $conn;
    $stmt = $conn->prepare("SELECT * FROM SPECIALITY");
    $stmt->execute();

    return $stmt->fetchAll();
}

function getProcedures($idAccount)
{
    global $conn;
    $stmt = $conn->prepare("SELECT * FROM PROCEDURE NATURAL JOIN PROCEDUREACCOUNT WHERE idAccount = ? ORDER BY date DESC");
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

function getProcedureCollaborators($idProcedure)
{
    global $conn;
    $stmt = $conn->prepare("SELECT * FROM PROCEDUREPROFESSIONAL WHERE idProcedure = ?");
    $stmt->execute(array($idProcedure));

    return $stmt->fetchAll();
}

function addProcedure($idAccount, $paymentStatus, $date, $wasAssistant, $totalRemun, $personalRemun, $valuePerK)
{
    global $conn;

    $conn->beginTransaction();

    $code = hash('sha256', $paymentStatus + date('Y-m-d H:i:s')); // NEEDS TO BE CHANGED
    if (strtotime($date)) {
        echo "TRUE CARALHO";
        $stmt = $conn->prepare("INSERT INTO PROCEDURE(paymentstatus, date, wasassistant)
                            VALUES(:paymentStatus, :date, :wasassistant);");
        $stmt->execute(array("paymentStatus" => $paymentStatus, "date" => $date, "wasassistant" => $wasAssistant));
    } else {
        echo "FALSE CARALHO";
        $stmt = $conn->prepare("INSERT INTO PROCEDURE(paymentstatus, date, wasassistant)
                            VALUES(:paymentStatus, CURRENT_TIMESTAMP, :wasassistant);");

        $stmt->execute(array("paymentStatus" => $paymentStatus, "wasassistant" => $wasAssistant));
    }

    $id = $conn->lastInsertId('procedure_idprocedure_seq');

    if (isset($totalRemun)) {
        $stmt = $conn->prepare("UPDATE PROCEDURE SET totalremun = :totalremun WHERE idprocedure = :idprocedure;");

        $stmt->execute(array("totalremun" => $totalRemun, "idprocedure" => $id));
    }

    if (isset($personalRemun)) {
        $stmt = $conn->prepare("UPDATE PROCEDURE SET personalremun = :personalremun WHERE idprocedure = :idprocedure;");

        $stmt->execute(array("personalremun" => $personalRemun, "idprocedure" => $id));
    }

    if (isset($valuePerK)) {
        $stmt = $conn->prepare("UPDATE PROCEDURE SET valueperk = :valueperk WHERE idprocedure = :idprocedure;");

        $stmt->execute(array("valueperk" => $valuePerK, "idprocedure" => $id));
    }

    $stmt = $conn->prepare("INSERT INTO PROCEDUREACCOUNT VALUES(:idprocedure, :idaccount)");
    $stmt->execute(array("idprocedure" => $id, "idaccount" => $idAccount));

    /*
    if ($idPrivatePayer == 0 && $idEntityPayer != 0) {

        $code = hash('sha256', $paymentStatus + $idEntityPayer + date('Y-m-d H:i:s')); // NEEDS TO BE CHANGED

        $stmt = $conn->prepare("INSERT INTO PROCEDURE(paymentstatus, idEntityPayer, date, code)
                        VALUES(:paymentStatus, :idEntityPayer, CURRENT_TIMESTAMP, :code);");

        $stmt->execute(array(":paymentStatus" => $paymentStatus, ":idEntityPayer" => $idEntityPayer, ":code" => $code));

    } else if ($idPrivatePayer != 0 && $idEntityPayer == 0) {

        $code = hash('sha256', $paymentStatus + $idPrivatePayer + date('Y-m-d H:i:s')); // NEEDS TO BE CHANGED

        $stmt = $conn->prepare("INSERT INTO PROCEDURE(paymentstatus, idPrivatePayer, date, code)
                        VALUES(:paymentStatus, :idEntityPayer, CURRENT_TIMESTAMP, :code);");

        $stmt->execute(array(":paymentStatus" => $paymentStatus, ":idEntityPayer" => $idEntityPayer, ":code" => $code));

function deleteProcedure($idProcedure, $idAccount)
{
global $conn;
$stmt = $conn->prepare("DELETE FROM ProcedureAccount WHERE idprocedure = :idprocedure
                        AND idaccount = :idaccount");
$stmt->execute(array("idprocedure" => $idProcedure, "idaccount" => $idAccount));
}
    }
    */

    $stmt->fetch();

    return $conn->commit() == true;
}

function deleteProcedure($idProcedure, $idAccount)
{
    global $conn;
    $stmt = $conn->prepare("DELETE FROM ProcedureAccount WHERE idprocedure = :idprocedure
                            AND idaccount = :idaccount");
    $stmt->execute(array("idprocedure" => $idProcedure, "idaccount" => $idAccount));
}

function editProcedurePaymentStatus($idProcedure, $paymentStatus)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE PROCEDURE SET paymentstatus = ?
                                WHERE $idProcedure = ?;");
    $stmt->execute(array($paymentStatus, $idProcedure));

    return $stmt->fetch() == true;
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

function getProcedureTypes()
{
    global $conn;

    $stmt = $conn->prepare("SELECT * FROM PROCEDURETYPE");

    $stmt->execute();

    return $stmt->fetchAll();
}

function addSubProcedures($subProcedures)
{
    global $conn;

    $conn->beginTransaction();

    foreach ($subProcedures as $subProcedure) {
        $stmt = $conn->prepare("INSERT INTO PROCEDUREPROCEDURETYPE(idprocedure, idproceduretype)
                              VALUES(:idProcedure, :idProcedureType)");

        $stmt->execute(array(":idProcedure" => $subProcedure['idProcedure'], ":idProcedureType" => $subProcedure["idProcedureType"]));
    }

    return $conn->commit() == true;
}

function addProfessionals($professionals)
{
    global $conn;

    $conn->beginTransaction();

    foreach ($professionals as $professional) {
        if (isset($professional['nonDefault'])) {
            $stmt = $conn->prepare("INSERT INTO PROCEDUREPROFESSIONAL(idprocedure, idprofessional, nondefault)
                                    VALUES(:idProcedure, :idProfessional, :nonDefault)");
            $stmt->execute(array(":idProcedure" => $professional['idProcedure'], ":idProfessional" => $professional['idProfessional'], ":nonDefault" => $professional['nonDefault']));

        } else {
            $stmt = $conn->prepare("INSERT INTO PROCEDUREPROFESSIONAL(idprocedure, idprofessional)
                                    VALUES(:idProcedure, :idProfessional)");
            $stmt->execute(array(":idProcedure" => $professional['idProcedure'], ":idProfessional" => $professional['idProfessional']));
        }

    }

    return $conn->commit() == true;
}

function getRecentProfessionals($idaccount, $speciality, $name)
{
    global $conn;
    if ($speciality == 'any') {
        $stmt = $conn->prepare("SELECT Professional . name, Professional . nif, Professional . licenseid, Professional.idProfessional
                            FROM Professional
                            WHERE Professional . idAccount = :idAccount AND Professional . name LIKE :name
                            ORDER BY Professional . createdOn DESC
                            LIMIT 3");

        $stmt->execute(array("idAccount" => $idaccount, "name" => $name . '%'));

    } else {
        $stmt = $conn->prepare("SELECT Professional . name, Professional . nif, Professional . licenseid, Professional.idProfessional
                            FROM Speciality, Professional
                            WHERE Speciality . name = :speciality AND Professional . idSpeciality = Speciality . idSpeciality AND Professional . idAccount = :idAccount AND Professional . name LIKE :name
                            ORDER BY Professional . createdOn DESC
                            LIMIT 3");

        $stmt->execute(array("idAccount" => $idaccount, "speciality" => $speciality, "name" => $name . '%'));

    }

    return $stmt->fetchAll();
}

function shareProcedure($idprocedure, $idinviting, $licenseid)
{
    global $conn;

    if ($licenseid == 'all') {
        $stmt = $conn->prepare("SELECT share_procedure_with_all(:idprocedure, :idaccount)");
        $stmt->execute(array("idprocedure" => $idprocedure, "idaccount" => $idinviting));
    } else {
        $stmt = $conn->prepare("INSERT INTO ProcedureInvitation(idProcedure, idInvitingAccount, licenseIdInvited)
                                VALUES (:idprocedure, :idaccount, :licenseid)");

        $stmt->execute(array("idprocedure" => $idprocedure, "idaccount" => $idinviting, "licenseid" => $licenseid));
    }
}

?>