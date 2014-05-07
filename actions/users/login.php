<?php
include_once('../../config/init.php');
include_once($BASE_DIR .'database/users.php');

if (!$_POST['email'] || !$_POST['password']) {
    $_SESSION['error_messages'][] = 'Não preencheu um dos campos.';
    if(!$_POST['email'])
        $_SESSION['error_messages'][] = 'mail';
    if(!$_POST['password'])
        $_SESSION['error_messages'][] = 'password';
    $_SESSION['form_values'] = $_POST;

    header('Location: ' . $_SERVER['HTTP_REFERER']);
    exit;
}

$email = $_POST['email'];
$password = $_POST['password'];
$current_user = getUserByEmail($email);

if(checkBrute($current_user['idaccount'])) {
    $_SESSION['error_messages'][] = 'Bruteforce detetado, conta bloqueada';

    header('Location: ' . $_SERVER['HTTP_REFERER']);
    exit;
}

$password = hash('sha512', $password . $current_user['salt']);

if ($current_user['password'] === $password) {
    session_regenerate_id(true);
    $_SESSION['email'] = $current_user['email'];

    $_SESSION['success_messages'][] = 'Login successful';
} else {

    try {
        logAttempt($current_user['idaccount']);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = $e->getMessage();
    }

    $_SESSION['error_messages'][] = 'Email e password inválidos.';
}

header('Location: ' . $_SERVER['HTTP_REFERER']);
?>