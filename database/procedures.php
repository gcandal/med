<?php

function createEntity($name, $contractstart, $contractend, $type, $nif, $valueperk)
{
    global $conn;
    $stmt = $conn->prepare("INSERT INTO EntityPayer(name, contractstart, contractend, type, nif, valueperk)
                            VALUES (:name, :contractstart, :contractend, :type, :nif, :valueperk)");

    $stmt->execute(array("name" => $name, "contractstart" => $contractstart, "contractend" => $contractend,
        "type" => $type, "nif" => $nif, "valueperk" => $valueperk));

    return $stmt->fetch() == true;
}

function createPrivateEntity($name)
{
    global $conn;
    $stmt = $conn->prepare("INSERT INTO PrivatePayer(name) VALUES (:name)");
    $stmt->execute(array("name" => $name));

    return $stmt->fetch() == true;
}

function getAllEntities($email) {
    global $conn;

    $stmt = $conn->prepare("SELECT *
                            FROM privatepayer
                            WHERE idaccount = :idAccount
                            AND time > :time");
    $stmt->execute(array("idAccount" => $idAccount, "time" => $valid_attempts));
}

function getAllPrivateEntities($email) {

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