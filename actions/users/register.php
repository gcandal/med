<?php

include_once('../../config/init.php');
include_once($BASE_DIR . 'database/users.php');

if (!$_POST['email'] || !$_POST['password'] || !$_POST['passwordconfirm'] || !$_POST['name']
    || !$_POST['licenseid'] || !isset($_POST['speciality']) || !isset($_POST['title'])) {

    $_SESSION['error_messages'][] = 'Todos os campos são obrigatórios';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/main.php?box=register');
    exit;
}

$name = $_POST["name"];
$email = $_POST['email'];
$password = $_POST['password'];
$licenseid = $_POST['licenseid'];
$passwordconfirm = $_POST['passwordconfirm'];
$idspeciality = $_POST['speciality'];
$title = $_POST['title'];

if (strlen($name) > 40) {
    $_SESSION['error_messages'][] = 'Nome demasiado grande';
    $_SESSION['field_errors']['name'] = 'O nome só pode ter até 40 caratéres';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/main.php?box=register');
    exit;
}

if (strlen($email) > 254) {
    $_SESSION['error_messages'][] = 'Email demasiado grande';
    $_SESSION['field_errors']['email'] = 'O email só pode ter até 254 caratéres';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/main.php?box=register');
    exit;
}

if ($password !== $passwordconfirm) {
    $_SESSION['field_errors']['passwordconfirm'] = 'As palavras-passe não coincidem';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/main.php?box=register');
    exit;
}

$random_salt = hash('sha512', uniqid(openssl_random_pseudo_bytes(16), true));

try {
    createAccount($email, $password, $name, $random_salt, $licenseid, $idspeciality, $title);
} catch (PDOException $e) {

    if (strpos($e->getMessage(), 'account_email_key') !== false) {
        $_SESSION['error_messages'][] = 'Email duplicado';
    } elseif (strpos($e->getMessage(), 'validlicenseid') !== false) {
        $_SESSION['error_messages'][] = 'Número de cédula inválido';
    } elseif (strpos($e->getMessage(), 'validmeail') !== false) {
        $_SESSION['error_messages'][] = 'Email inválido';
    } elseif (strpos($e->getMessage(), 'account_licenseid_key') !== false) {
        $_SESSION['error_messages'][] = 'Número de cédula já em uso';
    } else $_SESSION['error_messages'][] = 'Erro a criar conta ' . $e->getMessage();

    $_SESSION['form_values'] = $_POST;
    header("Location: $BASE_URL" . 'pages/main.php?box=register');

    exit;
}

session_regenerate_id(true);

$current_user = getUserByEmail($email);
$_SESSION['email'] = $current_user['email'];
$_SESSION['name'] = $current_user['name'];
$_SESSION['validuntil'] = $current_user['validuntil'];
$_SESSION['freeregisters'] = $current_user['freeregisters'];
$_SESSION['idaccount'] = $current_user['idaccount'];
$_SESSION['licenseid'] = $current_user['licenseid'];

header("Location: $BASE_URL");