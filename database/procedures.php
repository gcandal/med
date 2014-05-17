<?php

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
                            WHERE idaccount = :idAccount");
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

function checkDuplicateEntityName($idaccount, $name)
{
    global $conn;

    $stmt = $conn->prepare("SELECT name FROM privatepayer
                            WHERE idaccount = :idaccount AND name=:name");
    $stmt->execute(array("idaccount" => $idaccount, "name" => $name));

    if(count($stmt->fetchAll()) > 0)
        return true;

    $stmt = $conn->prepare("SELECT name FROM entitypayer
                            WHERE idaccount = :idaccount AND name=:name");
    $stmt->execute(array("idaccount" => $idaccount, "name" => $name));

    return count($stmt->fetchAll()) > 0;
}

function editPrivatePayerName($accountid, $name, $idprivatepayer) {
    global $conn;
    $stmt = $conn->prepare("UPDATE privatepayer SET name = :name
                            WHERE idaccount = :accountid AND idprivatepayer = :idprivatepayer");
    $stmt->execute(array("name" => $name, "accountid" => $accountid, "idprivatepayer" => $idprivatepayer));

    return $stmt->fetch() == true;
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