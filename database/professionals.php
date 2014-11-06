<?php

function getSpecialities()
{
    global $conn;
    $stmt = $conn->prepare("SELECT * FROM SPECIALITY");
    $stmt->execute();

    return $stmt->fetchAll();
}

function addProfessional($name, $NIF, $idAccount, $licenseID, $email, $remuneration, $specialityId)
{
    global $conn;

    if($NIF === "")
        $NIF = NULL;
    if($licenseID === "")
        $licenseID = NULL;
    if($email === "")
        $email = NULL;
    if($remuneration === "")
        $remuneration = NULL;
    if($specialityId === NULL || $specialityId === 0)
        $specialityId = 3;

    $stmt = $conn->prepare("INSERT INTO PROFESSIONAL(name, nif, idaccount, licenseid, email, remuneration, idspeciality)
                            VALUES(:name, :nif, :idaccount, :licenseid, :email, :remuneration, :idspeciality);");

    $stmt->execute(array(":name" => $name, ":nif" => $NIF, ":idaccount" => $idAccount,
                          ":licenseid" => $licenseID, ":email" => $email, ":remuneration" => $remuneration,
                          ":idspeciality" => $specialityId));

    return $conn->lastInsertId('professional_idprofessional_seq');
}

function getRecentProfessionals($idaccount, $speciality, $name)
{
    global $conn;
    if ($speciality == 'any') {
        $stmt = $conn->prepare("SELECT Professional . name, Professional . nif, Professional . licenseid, idspeciality, Professional.idProfessional
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

function getProfessionals($idaccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT Professional . name, Professional . nif, Professional . licenseid, Speciality.name AS speciality, Professional.idProfessional
                            FROM Professional, Speciality
                            WHERE Professional . idAccount = :idAccount AND Professional.idspeciality = Speciality.idspeciality");

    $stmt->execute(array("idAccount" => $idaccount));

    return $stmt->fetchAll();
}

function getProfessional($idaccount, $idprofessional)
{
    global $conn;

    $stmt = $conn->prepare("SELECT name, nif, licenseid, idProfessional, idspeciality
                            FROM Professional
                            WHERE Professional.idprofessional = :idProfessional AND Professional . idAccount = :idAccount");

    $stmt->execute(array("idAccount" => $idaccount, "idProfessional" => $idprofessional));

    return $stmt->fetch();
}

function deleteProfessional($accountid, $idprofessional)
{
    global $conn;
    $stmt = $conn->prepare("DELETE FROM professional WHERE idprofessional = :idprofessional AND idaccount = :accountid");
    $stmt->execute(array("accountid" => $accountid, "idprofessional" => $idprofessional));

    return $stmt->rowCount() > 0;
}

function editProfessionalName($accountId, $idprofessional, $name) {
    global $conn;

    $stmt = $conn->prepare("UPDATE professional SET name = :name
                            WHERE idaccount = :idaccount AND idprofessional = :idprofessional");

    $stmt->execute(array("idaccount" => $accountId, "idprofessional" => $idprofessional, "name" => $name));
}

function editProfessionalNif($accountId, $idprofessional, $nif) {
    global $conn;

    $stmt = $conn->prepare("UPDATE professional SET nif = :nif
                            WHERE idaccount = :idaccount AND idprofessional = :idprofessional");

    $stmt->execute(array("idaccount" => $accountId, "idprofessional" => $idprofessional, "nif" => $nif));
}

function editProfessionalLicenseId($accountId, $idprofessional, $licenseid) {
    global $conn;

    $stmt = $conn->prepare("UPDATE professional SET licenseid = :licenseid
                            WHERE idaccount = :idaccount AND idprofessional = :idprofessional");

    $stmt->execute(array("idaccount" => $accountId, "idprofessional" => $idprofessional, "licenseid" => $licenseid));
}

function editProfessionalSpeciality($accountId, $idprofessional, $speciality) {
    global $conn;

    $stmt = $conn->prepare("UPDATE professional SET idspeciality = :idspeciality
                            WHERE idaccount = :idaccount AND idprofessional = :idprofessional");

    $stmt->execute(array("idaccount" => $accountId, "idprofessional" => $idprofessional, "idspeciality" => $speciality));
}