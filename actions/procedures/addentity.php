<?php
include_once('../../config/init.php');
include_once($BASE_DIR .'database/procedures');

if (!$_POST['type']) {
    $_SESSION['error_messages'][] = 'Tipo indefinido';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/procedures/addentity.php');
    exit;
}

if($_POST['type'] === 'Privado') {
    if(!$_POST['name']) {
        $_SESSION['error_messages'][] = 'Alguns campos em falta';
        $_SESSION['field_errors']['name'] = 'Nome é obrigatório';
        $_SESSION['form_values'] = $_POST;

        header("Location: $BASE_URL" . 'pages/procedures/addentity.php');
        exit;
    }

    createPrivateEntity($_POST['name']);
}

/*
$name = $_POST["name"];
$email = $_POST['email'];
$password = $_POST['password'];
$passwordconfirm = $_POST['passwordconfirm'];

try {
    createAccount($email, $password, $name, $random_salt);
} catch (PDOException $e) {

    if (strpos($e->getMessage(), 'account_email_key') !== false) {
        $_SESSION['error_messages'][] = 'Email duplicado';
        $_SESSION['field_errors']['email'] = 'Email já existe';
    }
    else $_SESSION['error_messages'][] = 'Erro a criar conta '.$e->getMessage();

    $_SESSION['form_values'] = $_POST;
    header("Location: $BASE_URL" . 'pages/users/registar.php');
    exit;
}
$_SESSION['success_messages'][] = 'User registered successfully';
header("Location: $BASE_URL");
*/
?>