<?php
include_once('../../config/init.php');
include_once($BASE_DIR .'database/users.php');

if (!$_POST['username'] || !$_POST['email'] || !$_POST['password'] || !$_POST['passwordconfirm'] || !$_POST['name']) {
    $_SESSION['error_messages'][] = 'Todos os campos são obrigatórios';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/users/registar.php');
    exit;
}

$name = $_POST["name"];
$username = $_POST['username'];
$email = $_POST['email'];
$password = $_POST['password'];
$passwordconfirm = $_POST['passwordconfirm'];

if($password !== $passwordconfirm) {
    $_SESSION['field_errors']['passwordconfirm'] = 'As palavras-passe não coincidem';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/users/registar.php');
    exit;
}

try {
    $random_salt = hash('sha512', uniqid(openssl_random_pseudo_bytes(16), TRUE));
    createAccount($username, $email, $password, $name, $random_salt);
} catch (PDOException $e) {

    if (strpos($e->getMessage(), 'conta_email_key') !== false) {
        $_SESSION['error_messages'][] = 'Email duplicado';
        $_SESSION['field_errors']['email'] = 'Email já existe';
    }
    elseif(strpos($e->getMessage(), 'conta_username_key') !== false) {
        $_SESSION['error_messages'][] = 'Nome de utilizador duplicado';
        $_SESSION['field_errors']['username'] = 'Nome de utilizador já existe';
    }
    else $_SESSION['error_messages'][] = 'Erro a criar conta '.$e->getMessage();

    $_SESSION['form_values'] = $_POST;
    header("Location: $BASE_URL" . 'pages/users/registar.php');
    exit;
}
$_SESSION['success_messages'][] = 'User registered successfully';
header("Location: $BASE_URL");
?>