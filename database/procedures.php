<?php

function createProcedure($paymentStatus, $idPrivatePayer, $idEntityPayer)
{
    global $conn;
    if ($idPrivatePayer == 0 && $idEntityPayer != 0) {
        $code = hash('sha256', $paymentStatus+$idEntityPayer+date('Y-m-d H:i:s')); // NEEDS TO BE CHANGED
        $stmt = $conn->prepare("INSERT INTO PROCEDURE (paymentstatus, idEntityPayer, date, code)
                            VALUES (:paymentStatus, :idEntityPayer, CURRENT_TIMESTAMP, :code)");
        $stmt->execute(array(":paymentStatus" => $paymentStatus, ":idEntityPayer" => $idEntityPayer, ":code" => $code));
    } else if ($idPrivatePayer != 0 && $idEntityPayer == 0){
        $code = hash('sha256', $paymentStatus+$idPrivatePayer+date('Y-m-d H:i:s')); // NEEDS TO BE CHANGED
        $stmt = $conn->prepare("INSERT INTO PROCEDURE (paymentstatus, idPrivatePayer, date, code)
                            VALUES (:paymentStatus, :idEntityPayer, CURRENT_TIMESTAMP, :code)");
        $stmt->execute(array(":paymentStatus" => $paymentStatus, ":idEntityPayer" => $idEntityPayer, ":code" => $code));
    }

    return $stmt->fetch() == true;
}

function addSubProcedures($subProcedures)
{
    global $conn;

    $conn->beginTransaction();

    foreach ($subProcedures as $subProcedure) {
        $stmt = $conn->prepare("INSERT INTO PROCEDUREPROCEDURETYPE (idprocedure, idproceduretype)
                              VALUES (:idProcedure, :idProcedureType)");

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
                                    VALUES (:idProcedure, :idProfessional, :nonDefault)");
            $stmt->execute(array(":idProcedure" => $professional['idProcedure'], ":idProfessional" => $professional['idProfessional'],
                ":nonDefault" => $professional['nonDefault']));

        } else {
            $stmt = $conn->prepare("INSERT INTO PROCEDUREPROFESSIONAL(idprocedure, idprofessional)
                                    VALUES (:idProcedure, :idProfessional)");
            $stmt->execute(array(":idProcedure" => $professional['idProcedure'], ":idProfessional" => $professional['idProfessional']));
        }

    }

    return $conn->commit() == true;
}

function createEntityPayer($name, $contractstart, $contractend, $type, $nif, $valueperk, $idaccount)
{
    global $conn;
    $stmt = $conn->prepare("INSERT INTO EntityPayer(name, contractstart, contractend, type, nif, valueperk, idaccount)
                            VALUES (:name, :contractstart, :contractend, :type, :nif, :valueperk, :idaccount)");

    $stmt->execute(array("name" => $name, "contractstart" => $contractstart, "contractend" => $contractend,
        "type" => $type, "nif" => $nif, "valueperk" => $valueperk, "idaccount" => $idaccount));

    return $stmt->fetch() == true;
}

function createPrivatePayer($name, $accountId)
{
    global $conn;
    $stmt = $conn->prepare("INSERT INTO PrivatePayer(name, idaccount) VALUES (:name, :accountId)");
    $stmt->execute(array("name" => $name, "accountId" => $accountId));

    return $stmt->fetch() == true;
}

function getEntityPayers($idAccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT *
                            FROM entitypayer
                            WHERE identitypayer = :idAccount");
    $stmt->execute(array("idAccount" => $idAccount));

    return $stmt->fetchAll();
}

function getPrivatePayers($idAccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT *
                            FROM privatepayer
                            WHERE idaccount = :idAccount");
    $stmt->execute(array("idAccount" => $idAccount));

    return $stmt->fetchAll();
}

function checkBrute($idAccount)
{
    global $conn;
    $valid_attempts = time() - (2 * 60 * 60); // All login attempts since 2 hours ago

    $stmt = $conn->prepare("SELECT time
                            FROM loginattempts
                            WHERE idaccount = :idAccount
                            AND time > :time");
    $stmt->execute(array("idAccount" => $idAccount, "time" => $valid_attempts));

    return count($stmt->fetchAll()) > 5;
}

?>