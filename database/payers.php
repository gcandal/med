<?php

function createPrivatePayer($name, $accountId, $valuePerK)
{
    global $conn;
    $conn->beginTransaction();

    $stmt = $conn->prepare("INSERT INTO PrivatePayer(name, idaccount, valuePerK)
                            VALUES(:name, :accountId, :valueperk)");
    $stmt->execute(array("name" => $name, "accountId" => $accountId, "valueperk" => $valuePerK));

    if ($conn->commit()) {
        $id = $conn->lastInsertId('privatepayer_idprivatepayer_seq');
        return $id;
    } else {
        return 0;
    }
}

function getPrivatePayers($idAccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT * FROM privatepayer
                            WHERE idaccount = :idAccount ORDER BY name");
    $stmt->execute(array("idAccount" => $idAccount));

    return $stmt->fetchAll();
}

function getPrivatePayer($idPrivatePayer)
{
    global $conn;

    $stmt = $conn->prepare("SELECT * FROM privatepayer
                            WHERE idprivatepayer = ?");
    $stmt->execute(array($idPrivatePayer));

    return $stmt->fetch();
}

function checkDuplicateEntityName($idaccount, $name)
{
    global $conn;

    $stmt = $conn->prepare("SELECT name FROM privatepayer
                            WHERE idaccount = :idaccount AND name =:name");
    $stmt->execute(array("idaccount" => $idaccount, "name" => $name));

    return count($stmt->fetchAll()) > 0;
}

function editPrivatePayerName($accountid, $name, $idprivatepayer)
{
    global $conn;
    $stmt = $conn->prepare("UPDATE privatepayer SET name = :name
                            WHERE idaccount = :accountid AND idprivatepayer = :idprivatepayer");
    $stmt->execute(array("name" => $name, "accountid" => $accountid, "idprivatepayer" => $idprivatepayer));

    return $stmt->fetch() == true;
}

function editPrivatePayerValuePerK($accountid, $idprivatepayer, $valueperk)
{
    global $conn;
    $stmt = $conn->prepare("UPDATE privatepayer SET valueperk = :valueperk
                            WHERE idaccount = :accountid AND idprivatepayer = :idprivatepayer");
    $stmt->execute(array("valueperk" => $valueperk, "accountid" => $accountid, "idprivatepayer" => $idprivatepayer));

    return $stmt->fetch() == true;
}

function deletePrivatePayer($accountid, $idprivatepayer)
{
    global $conn;
    $stmt = $conn->prepare("DELETE FROM privatepayer WHERE idprivatepayer = :idprivatepayer AND idaccount = :accountid");
    $stmt->execute(array("accountid" => $accountid, "idprivatepayer" => $idprivatepayer));

    return $stmt->rowCount() > 0;
}