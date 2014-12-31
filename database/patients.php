<?php

function getPatient($idPatient)
{
    global $conn;

    $stmt = $conn->prepare("SELECT * FROM patient
                            WHERE idpatient = ?");
    $stmt->execute(array($idPatient));

    return $stmt->fetch();
}

function getPatients($idAccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT * FROM patient
                            WHERE idaccount = :idAccount ORDER BY name");
    $stmt->execute(array("idAccount" => $idAccount));

    return $stmt->fetchAll();
}

function createPatient($name, $accountId, $nif, $cellphone, $beneficiarynr)
{
    global $conn;
    $conn->beginTransaction();

    $stmt = $conn->prepare("INSERT INTO Patient(name, nif, cellphone, beneficiaryNr, idaccount)
                            VALUES(:name, :nif, :cellphone, :beneficiarynr, :accountId)");
    $stmt->execute(array("name" => $name, "accountId" => $accountId, "nif" => $nif, "cellphone" => $cellphone,
                            "beneficiarynr" => $beneficiarynr));

    if ($conn->commit()) {
        $id = $conn->lastInsertId('patient_idpatient_seq');
        return $id;
    } else {
        return 0;
    }
}

function deletePatient($accountid, $idpatient)
{
    global $conn;
    $stmt = $conn->prepare("DELETE FROM patient WHERE idpatient = :idpatient AND idaccount = :accountid");
    $stmt->execute(array("accountid" => $accountid, "idpatient" => $idpatient));

    return $stmt->rowCount() > 0;
}

function editPatientName($accountid, $name, $idpatient)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE patient SET name = :name
                            WHERE idaccount = :accountid AND idpatient = :idpatient");
    $stmt->execute(array("name" => $name, "accountid" => $accountid, "idpatient" => $idpatient));
}

function editPatientNif($accountid, $nif, $idpatient)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE patient SET nif = :nif
                            WHERE idaccount = :accountid AND idpatient = :idpatient");
    $stmt->execute(array("nif" => $nif, "accountid" => $accountid, "idpatient" => $idpatient));
}

function editPatientCellphone($accountid, $cellphone, $idpatient)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE patient SET cellphone = :cellphone
                            WHERE idaccount = :accountid AND idpatient = :idpatient");
    $stmt->execute(array("cellphone" => $cellphone, "accountid" => $accountid, "idpatient" => $idpatient));
}

function editPatientBeneficiaryNr($accountid, $beneficiarynr, $idpatient)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE patient SET beneficiarynr = :beneficiarynr
                            WHERE idaccount = :accountid AND idpatient = :idpatient");
    $stmt->execute(array("beneficiarynr" => $beneficiarynr, "accountid" => $accountid, "idpatient" => $idpatient));
}