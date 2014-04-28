<?php
function isValidLogin($email, $password)
{
    global $conn;
    $stmt = $conn->prepare("SELECT email
                                FROM Account
                                WHERE email = ? AND password = ?");
    $stmt->execute(array($email, $password));
    return $stmt->fetch() == true;
}

function getUserByEmail($email)
{
    global $conn;
    $stmt = $conn->prepare("SELECT *
                                FROM Account
                                WHERE email = ?");
    $stmt->execute(array($email));
    return $stmt->fetch();
}

function createAccount($email, $password, $name, $salt)
{
    global $conn;
    $stmt = $conn->prepare("INSERT INTO Account(password, name, email, salt)
                            VALUES (:password, :name, :email, :salt)");

    $stmt->execute(array("password" => hash('sha512', $password . $salt), "name" => $name, "email" => $email, "salt" => $salt));
    return $stmt->fetch() == true;
}

function logAttempt($idAccount)
{
    global $conn;
    $stmt = $conn->prepare("INSERT INTO loginattempts(idaccount, time)
                            VALUES (:idAccount, :time)");
    $stmt->execute(array("idAccount" => $idAccount, "time" => time()));
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