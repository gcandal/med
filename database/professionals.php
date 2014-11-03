<?php

function getSpecialities()
{
    global $conn;
    $stmt = $conn->prepare("SELECT * FROM SPECIALITY");
    $stmt->execute();

    return $stmt->fetchAll();
}

function addProfessional($name, $NIF, $idAccount, $licenseID, $email, $cell, $remuneration, $specialityId)
{
    global $conn;

    $conn->beginTransaction();

    if ($NIF != "") {
        $stmt = $conn->prepare("INSERT INTO PROFESSIONAL(name, nif, idaccount) VALUES(:name, :nif, :idaccount);");
        $stmt->execute(array(":name" => $name, ":nif" => $NIF, ":idaccount" => $idAccount));
    } else {
        $stmt = $conn->prepare("INSERT INTO PROFESSIONAL(name, idaccount) VALUES(?, ?);");
        $stmt->execute(array($name, $idAccount));
    }

    $id = $conn->lastInsertId('professional_idprofessional_seq');

    if ($licenseID != "") {
        $stmt = $conn->prepare("UPDATE PROFESSIONAL SET licenseid = :licenseid WHERE idprofessional = :idprofessional;");
        $stmt->execute(array(":licenseid" => $licenseID, ":idprofessional" => $id));
    }

    if ($email != "") {
        $stmt = $conn->prepare("UPDATE PROFESSIONAL SET email = :email WHERE idprofessional = :idprofessional;");
        $stmt->execute(array(":email" => $email, ":idprofessional" => $id));
    }

    if ($cell != "") {
        $stmt = $conn->prepare("UPDATE PROFESSIONAL SET cell = :cell WHERE idprofessional = :idprofessional;");
        $stmt->execute(array(":cell" => $cell, ":idprofessional" => $id));
    }

    if ($remuneration != "") {
        $stmt = $conn->prepare("UPDATE PROFESSIONAL SET remuneration = :remuneration WHERE idprofessional = :idprofessional;");
        $stmt->execute(array(":remuneration" => $remuneration, ":idprofessional" => $id));
    }

    if ($specialityId != "") {
        $stmt = $conn->prepare("UPDATE PROFESSIONAL SET specialityid = :specialityid WHERE idprofessional = :idprofessional;");
        $stmt->execute(array(":specialityid" => $specialityId, ":idprofessional" => $id));
    }

    if ($conn->commit()) {
        return $id;
    } else {
        return 0;
    }
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