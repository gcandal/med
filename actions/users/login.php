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

$password = hash('sha512', $password . $current_user['salt']);

if ($current_user['password'] === $password) {
    $_SESSION['idconta'] = $current_user['idconta'];
    $_SESSION['username'] = $current_user['username'];
    $_SESSION['email'] = $current_user['email'];

    $_SESSION['success_messages'][] = 'Login successful';
} else {
    $_SESSION['error_messages'][] = 'Email e password inválidos. '.$password.'|||'.$current_user['password'];
}

header('Location: ' . $_SERVER['HTTP_REFERER']);
?>