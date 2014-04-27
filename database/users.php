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

function isUsernameAvailable($username) {
    global $conn;
    $stmt = $conn->prepare("SELECT *
                                FROM Account
                                WHERE username = :username");
    $stmt->execute(array("username" => $username));
    return $stmt->fetch() == false;
}

function isEmailAvailable($email) {
    global $conn;
    $stmt = $conn->prepare("SELECT *
                                FROM Account
                                WHERE email = :email");
    $stmt->execute(array("email" => $email));
    return $stmt->fetch() == false;
}

function getUserByEmail($email) {
    global $conn;
    $stmt = $conn->prepare("SELECT *
                                FROM Account
                                WHERE email = ?");
    $stmt->execute(array($email));
    return $stmt->fetch();
}

function createAccount($username, $email, $password, $name, $salt) {
    global $conn;
    $stmt = $conn->prepare("INSERT INTO Account(username, password, name, email, salt)
                            VALUES (:username, :password, :name, :email, :salt)");

    $stmt->execute(array("username" => $username, "password" => hash('sha512', $password . $salt), "name" => $name, "email" => $email, "salt" => $salt));
    return $stmt->fetch() == true;
}
?>