<?php

function createEntityPayer($name, $contractstart, $contractend, $type, $nif, $valueperk, $idaccount)
{
    global $conn;

    $conn->beginTransaction();
    $id = $conn->lastInsertId('entitypayer_identitypayer_seq');

    $stmt = $conn->prepare("INSERT INTO EntityPayer(name, contractstart, contractend, type, nif, valueperk, idaccount)
                            VALUES(:name, :contractstart, :contractend, :type, :nif, :valueperk, :idaccount)");

    $stmt->execute(array("name" => $name, "contractstart" => $contractstart, "contractend" => $contractend, "type" => $type, "nif" => $nif, "valueperk" => $valueperk, "idaccount" => $idaccount));

    if ($conn->commit()) {
        return $id;
    } else {
        return 0;
    }
}

function createPrivatePayer($name, $accountId, $nif, $valuePerK)
{
    global $conn;
    $conn->beginTransaction();

    $stmt = $conn->prepare("INSERT INTO PrivatePayer(name, idaccount, nif, valuePerK)
                            VALUES(:name, :accountId, :nif, :valueperk)");
    $stmt->execute(array("name" => $name, "accountId" => $accountId, "nif" => $nif, "valueperk" => $valuePerK));

    if ($conn->commit()) {
        $id = $conn->lastInsertId('privatepayer_idprivatepayer_seq');
        return $id;
    } else {
        return 0;
    }
}

function getEntityPayers($idAccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT * FROM entitypayer
                            WHERE idaccount = :idAccount ORDER BY name");
    $stmt->execute(array("idAccount" => $idAccount));

    return $stmt->fetchAll();
}

function getEntityPayer($idEntityPayer)
{
    global $conn;

    $stmt = $conn->prepare("SELECT * FROM entitypayer
                            WHERE identitypayer = ?");
    $stmt->execute(array($idEntityPayer));

    return $stmt->fetch();
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

    if (count($stmt->fetchAll()) > 0) return true;

    $stmt = $conn->prepare("SELECT name FROM entitypayer
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

function editPrivatePayerNIF($accountid, $identitypayer, $nif)
{
    global $conn;
    $stmt = $conn->prepare("UPDATE privatepayer SET nif = :nif
                            WHERE idaccount = :accountid AND idprivatepayer = :identitypayer");
    $stmt->execute(array("nif" => $nif, "accountid" => $accountid, "identitypayer" => $identitypayer));

    return $stmt->fetch() == true;
}

function editPrivatePayerValuePerK($accountid, $identitypayer, $valueperk)
{
    global $conn;
    $stmt = $conn->prepare("UPDATE privatepayer SET valueperk = :valueperk
                            WHERE idaccount = :accountid AND idprivatepayer = :identitypayer");
    $stmt->execute(array("valueperk" => $valueperk, "accountid" => $accountid, "identitypayer" => $identitypayer));

    return $stmt->fetch() == true;
}

function editEntityPayerName($accountid, $identitypayer, $name)
{
    global $conn;
    $stmt = $conn->prepare("UPDATE entitypayer SET name = :name
                            WHERE idaccount = :accountid AND identitypayer = :identitypayer");
    $stmt->execute(array("name" => $name, "accountid" => $accountid, "identitypayer" => $identitypayer));

    return $stmt->fetch() == true;
}

function editEntityPayerNIF($accountid, $identitypayer, $nif)
{
    global $conn;
    $stmt = $conn->prepare("UPDATE entitypayer SET nif = :nif
                            WHERE idaccount = :accountid AND identitypayer = :identitypayer");
    $stmt->execute(array("nif" => $nif, "accountid" => $accountid, "identitypayer" => $identitypayer));

    return $stmt->fetch() == true;
}

function editEntityPayerContractStart($accountid, $identitypayer, $contractstart)
{
    global $conn;
    $stmt = $conn->prepare("UPDATE entitypayer SET contractstart = :contractstart
                            WHERE idaccount = :accountid AND identitypayer = :identitypayer");
    $stmt->execute(array("contractstart" => $contractstart, "accountid" => $accountid, "identitypayer" => $identitypayer));

    return $stmt->fetch() == true;
}

function editEntityPayerContractEnd($accountid, $identitypayer, $contractend)
{
    global $conn;
    $stmt = $conn->prepare("UPDATE entitypayer SET contractend = :contractend
                            WHERE idaccount = :accountid AND identitypayer = :identitypayer");
    $stmt->execute(array("contractend" => $contractend, "accountid" => $accountid, "identitypayer" => $identitypayer));

    return $stmt->fetch() == true;
}

function editEntityPayerValuePerK($accountid, $identitypayer, $valueperk)
{
    global $conn;
    $stmt = $conn->prepare("UPDATE entitypayer SET valueperk = :valueperk
                            WHERE idaccount = :accountid AND identitypayer = :identitypayer");
    $stmt->execute(array("valueperk" => $valueperk, "accountid" => $accountid, "identitypayer" => $identitypayer));

    return $stmt->fetch() == true;
}

function deleteEntityPayer($accountid, $identitypayer)
{
    global $conn;
    $stmt = $conn->prepare("DELETE FROM entitypayer WHERE identitypayer = :identitypayer AND idaccount = :accountid");
    $stmt->execute(array("accountid" => $accountid, "identitypayer" => $identitypayer));

    return $stmt->rowCount() > 0;
}

function deletePrivatePayer($accountid, $idprivatepayer)
{
    global $conn;
    $stmt = $conn->prepare("DELETE FROM privatepayer WHERE idprivatepayer = :idprivatepayer AND idaccount = :accountid");
    $stmt->execute(array("accountid" => $accountid, "idprivatepayer" => $idprivatepayer));

    return $stmt->rowCount() > 0;
}