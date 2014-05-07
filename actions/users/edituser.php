<?php
include_once('../../config/init.php');
include_once($BASE_DIR .'database/users.php');

if(!$_SESSION['email']) {
    header('Location: ' . $BASE_URL);

    exit;
}

$email = $_SESSION['email'];
$password = $_POST['oldpassword'];

if(checkBrute($email)) {
    $_SESSION['error_messages'][] = 'Bruteforce detetado, conta bloqueada';

    header('Location: ' . $_SERVER['HTTP_REFERER']);
    exit;
}

$current_user = getUserByEmail($email);
$password = hash('sha512', $password . $current_user['salt']);

if ($current_user['password'] !== $password) {

    try {
        logAttempt($current_user['idaccount']);
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = $e->getMessage();
    }

    $_SESSION['field_errors']['oldpassword'] = 'Password inválida.';

    header('Location: ' . $_SERVER['HTTP_REFERER']);
    exit;
}

$new_email = $_POST['email'];
$new_password = $_POST['password'];
$new_passwordconfirm = $_POST['passwordconfirm'];

if($new_password !== $new_passwordconfirm) {
    $_SESSION['field_errors']['passwordconfirm'] = 'As palavras-passe não coincidem';
    $_SESSION['form_values'] = $_POST;

    header("Location: $BASE_URL" . 'pages/users/edituser.php');
    exit;
} elseif($new_password) {
    $salt = hash('sha512', uniqid(openssl_random_pseudo_bytes(16), TRUE));

    try {
        editPassword($email, $new_password, $salt);
        $_SESSION['success_messages'][] = 'Password edited successfully';
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = $e->getMessage();
    }
}

if($new_email) {
    try {

        editEmail($email, $new_email);
        $_SESSION['success_messages'][] = 'Email edited successfully ';
        $_SESSION['email'] = $new_email;
    } catch (PDOException $e) {
        $_SESSION['error_messages'][] = $e->getMessage();
    }
} else $_SESSION['success_messages'][] = 'null';

header("Location: " . $BASE_URL);
?>