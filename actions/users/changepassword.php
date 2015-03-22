<?php

include_once('../../config/init.php');
include_once($BASE_DIR . 'database/users.php');
include_once($BASE_DIR . 'mail/mail.php');

if (!$_POST['email'] || !$_POST['password'] || !$_POST['passwordconfirm'] || !$_POST['token']) {
    $_SESSION['error_messages'][] = 'Todos os campos são obrigatórios';
    $_GET['token'] = $_POST['token'];

    header("Location: $BASE_URL" . 'pages/main.php?box=forgot');
    exit;
}

$email = $_POST['email'];
$password = $_POST['password'];
$passwordconfirm = $_POST['passwordconfirm'];
$token = $_POST['token'];

if ($password !== $passwordconfirm) {
    $_SESSION['field_errors']['passwordconfirm'] = 'As palavras-passe não coincidem';
    $_GET['token'] = $_POST['token'];

    header("Location: $BASE_URL" . 'pages/main.php?box=forgot');
    exit;
}

if(!isValidToken($token, $email)) {
    $_SESSION['error_messages'][] = 'O token é inválido';

    header("Location: $BASE_URL" . 'pages/main.php?box=forgot&token=' . $token);
    exit;
}

try {
    editPassword($email, $password, false);
} catch (PDOException $e) {
    $_SESSION['error_messages'][] = 'Erro a alterar a palavra-passe ' . $e->getMessage();

    header("Location: $BASE_URL" . 'pages/main.php?box=forgot&token=' . $token);
    exit;
}


$current_user = getUserByEmail($email);
$_SESSION['email'] = $current_user['email'];
$_SESSION['name'] = $current_user['name'];
$_SESSION['validuntil'] = $current_user['validuntil'];
$_SESSION['freeregisters'] = $current_user['freeregisters'];
$_SESSION['idaccount'] = $current_user['idaccount'];
$_SESSION['licenseid'] = $current_user['licenseid'];

header("Location: $BASE_URL");