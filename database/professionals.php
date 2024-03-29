<?php

function getSpecialities()
{
    global $conn;
    $stmt = $conn->prepare("SELECT * FROM SPECIALITY");
    $stmt->execute();

    return $stmt->fetchAll();
}

function addProfessional($name, $NIF, $idAccount, $licenseID, $email, $specialityId)
{
    global $conn;

    if ($NIF === "")
        $NIF = NULL;
    if ($licenseID === "")
        $licenseID = NULL;
    if ($email === "")
        $email = NULL;
    if ($specialityId === NULL || $specialityId === 0)
        $specialityId = 3;

    $stmt = $conn->prepare("INSERT INTO PROFESSIONAL(name, nif, idaccount, licenseid, email, idspeciality)
                            VALUES(:name, :nif, :idaccount, :licenseid, :email, :idspeciality);");
    $stmt->execute(array(":name" => $name, ":nif" => $NIF, ":idaccount" => $idAccount,
        ":licenseid" => $licenseID, ":email" => $email, ":idspeciality" => $specialityId));

    // Due to possible non-insertion because of trigger,
    // otherwise use $conn->lastInsertId('professional_idprofessional_seq')

    $stmt = $conn->prepare("SELECT idprofessional FROM Professional
                                WHERE idAccount = :idAccount AND name = :name");
    $stmt->execute(array(":idAccount" => $idAccount, ":name" => $name));

    $result = $stmt->fetch();
    return $result['idprofessional'];
}

function getRecentProfessionals($idaccount, $speciality, $name)
{
    global $conn;

    /*
    if ($speciality == -1) {
        $stmt = $conn->prepare("SELECT Professional . name, Professional . nif, Professional . licenseid, idspeciality, Professional . idProfessional
                            FROM Professional
                            WHERE Professional . idAccount = :idAccount AND Professional . name LIKE :name
                            ORDER BY Professional . createdOn DESC
                            LIMIT 3");

        $stmt->execute(array("idAccount" => $idaccount, "name" => $name . '%'));

    } else {
        $stmt = $conn->prepare("SELECT Professional . name, Professional . nif, Professional . licenseid, Professional . idProfessional
                            FROM Professional
                            WHERE Professional . idSpeciality = :speciality AND Professional . idAccount = :idAccount AND Professional . name LIKE :name
                            ORDER BY Professional . createdOn DESC
                            LIMIT 3");

        $stmt->execute(array("idAccount" => $idaccount, "speciality" => $speciality, "name" => $name . '%'));
    }
    */
    $stmt = $conn->prepare("SELECT Professional . name, Professional . nif, Professional . licenseid, idspeciality, Professional . idProfessional
                            FROM Professional
                            WHERE Professional . idAccount = :idAccount
                            ORDER BY Professional . createdOn DESC");

    $stmt->execute(array("idAccount" => $idaccount));


    return $stmt->fetchAll();
}

function getProfessionals($idaccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT Professional . name, Professional . nif, Professional . licenseid, Speciality . name AS speciality, Professional . idProfessional
                            FROM Professional, Speciality
                            WHERE Professional . idAccount = :idAccount AND Professional . idspeciality = Speciality . idspeciality");

    $stmt->execute(array("idAccount" => $idaccount));

    return $stmt->fetchAll();
}

function getProfessional($idaccount, $idprofessional)
{
    global $conn;

    $stmt = $conn->prepare("SELECT name, nif, licenseid, idProfessional, idspeciality
                            FROM Professional
                            WHERE Professional . idprofessional = :idProfessional AND Professional . idAccount = :idAccount");

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

function editProfessionalName($accountId, $idprofessional, $name)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE professional SET name = :name
                            WHERE idaccount = :idaccount AND idprofessional = :idprofessional");

    $stmt->execute(array("idaccount" => $accountId, "idprofessional" => $idprofessional, "name" => $name));
}

function editProfessionalNif($accountId, $idprofessional, $nif)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE professional SET nif = :nif
                            WHERE idaccount = :idaccount AND idprofessional = :idprofessional");

    $stmt->execute(array("idaccount" => $accountId, "idprofessional" => $idprofessional, "nif" => $nif));
}

function editProfessionalLicenseId($accountId, $idprofessional, $licenseid)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE professional SET licenseid = :licenseid
                            WHERE idaccount = :idaccount AND idprofessional = :idprofessional");

    $stmt->execute(array("idaccount" => $accountId, "idprofessional" => $idprofessional, "licenseid" => $licenseid));
}

function editProfessionalSpeciality($accountId, $idprofessional, $speciality)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE professional SET idspeciality = :idspeciality
                            WHERE idaccount = :idaccount AND idprofessional = :idprofessional");

    $stmt->execute(array("idaccount" => $accountId, "idprofessional" => $idprofessional, "idspeciality" => $speciality));
}