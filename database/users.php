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

function getNameAndEmailFromLicenseId($licenseId)
{
    global $conn;
    $stmt = $conn->prepare("SELECT name, email
                                FROM Account
                                WHERE licenseId = ?");
    $stmt->execute(array($licenseId));
    return $stmt->fetch();
}

function getUserById($id)
{
    global $conn;
    $stmt = $conn->prepare("SELECT *
                                FROM Account
                                WHERE idaccount = ?");
    $stmt->execute(array($id));

    return $stmt->fetch();
}

function getUserByEmail($email)
{
    global $conn;
    $stmt = $conn->prepare("SELECT Account.name AS name, email, password, salt, licenseid, validuntil, freeregisters,
                                Speciality.name AS speciality, idaccount, title
                                FROM Account, Speciality
                                WHERE email = ? AND Speciality.idspeciality = speciality");
    $stmt->execute(array($email));

    return $stmt->fetch();
}

function createAccount($email, $password, $name, $salt, $licenseid, $idspeciality, $title)
{
    global $conn;
    $stmt = $conn->prepare("INSERT INTO Account(password, name, email, salt, licenseid, speciality, title)
                            VALUES (:password, :name, :email, :salt, :licenseid, :idspeciality, :title)");

    $stmt->execute(array("password" => hash('sha512', $password . $salt), "name" => $name, "email" => $email,
        "salt" => $salt, "licenseid" => $licenseid, "idspeciality" => $idspeciality, "title" => $title));

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

function checkBrute($email)
{
    global $conn;
    $valid_attempts = time() - (2 * 60 * 60); // All login attempts since 2 hours ago

    $stmt = $conn->prepare("SELECT time
                            FROM loginattempts, account
                            WHERE account.email = :email AND loginattempts.idaccount = account.idaccount
                            AND time > :time");
    $stmt->execute(array("email" => $email, "time" => $valid_attempts));

    return count($stmt->fetchAll()) > 5;
}

function editPassword($email, $password, $salt)
{
    global $conn;

    if(!$salt)
        $salt = hash('sha512', uniqid(openssl_random_pseudo_bytes(16), true));

    $stmt = $conn->prepare("UPDATE account SET password = :password, salt = :salt
                            WHERE email = :email");

    $stmt->execute(array("password" => hash('sha512', $password . $salt), "email" => $email, "salt" => $salt));

    return $stmt->fetch() == true;
}

function editEmail($email, $new_email)
{
    global $conn;
    $stmt = $conn->prepare("UPDATE account SET email = :newemail
                            WHERE email = :email");

    $stmt->execute(array("newemail" => $new_email, "email" => $email));

    return $stmt->fetch() == true;
}

function generateResetToken($email)
{
    global $conn;

    /*
        $stmt = $conn->prepare("SELECT email, token, validuntil > CURRENT_TIMESTAMP as valid
                                FROM ResetTokens WHERE email = :email");
        $stmt->execute(array("email" => $email));
        $result = $stmt->fetch();

        if($result && !$result['valid']) {
            $stmt = $conn->prepare("DELETE FROM ResetTokens WHERE email = :email");
            $stmt->execute(array("email" => $email));
        }
    */

    $stmt = $conn->prepare("DELETE FROM ResetTokens WHERE email = :email");
    $stmt->execute(array("email" => $email));

    do {
        $token = base64_encode(uniqid(openssl_random_pseudo_bytes(20), true));

        $stmt = $conn->prepare("SELECT 1 FROM ResetTokens
                                    WHERE token = :token");

        $stmt->execute(array("token" => hash('sha512', $token)));
    } while ($stmt->fetch());

    $stmt = $conn->prepare("INSERT INTO ResetTokens
                                VALUES (:email, :token, DEFAULT)");
    $stmt->execute(array("email" => $email, "token" => hash('sha512', $token)));


    return $token;
}

function getEmailFromToken($token)
{
    if (!$token)
        return "";

    global $conn;

    $stmt = $conn->prepare("SELECT email FROM ResetTokens WHERE token = :token");
    $stmt->execute(array("token" => hash('sha512', $token)));
    $result = $stmt->fetch();

    return $result['email'];
}

;

function isValidToken($token, $email)
{

    global $conn;

    $stmt = $conn->prepare("SELECT validuntil > CURRENT_TIMESTAMP AS valid FROM ResetTokens
                            WHERE token = :token AND email = :email");
    $stmt->execute(array("token" => hash('sha512', $token), "email" => $email));
    $result = $stmt->fetch();

    return $result['valid'];
}

;