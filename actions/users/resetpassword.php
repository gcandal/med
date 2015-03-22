<?php

include_once('../../config/init.php');
include_once($BASE_DIR . 'mail/mail.php');
include_once($BASE_DIR . 'database/users.php');

if (!$_POST['email']) {
    $_SESSION['error_messages'][] = 'E-mail obrigatório';

    header("Location: $BASE_URL" . 'pages/main.php?box=forgot');
    exit;
}

$email = $_POST['email'];

if (!getUserByEmail($email)) {
    if (sendPasswordResetNoAccount($email))
        $_SESSION['success_messages'][] = 'Foi-lhe enviado um e-mail com instruções de como alterar a palavra-passe';
    else
        $_SESSION['error_messages'][] = 'A alteração da palavra-passe falhou';

    header("Location: $BASE_URL" . 'pages/main.php?box=forgot');
    exit;
}

$token = generateResetToken($email);

if (sendPasswordResetToken($email, $token))
    $_SESSION['success_messages'][] = 'Foi-lhe enviado um e-mail com instruções de como alterar a palavra-passe';
else
    $_SESSION['error_messages'][] = 'A alteração da palavra-passe falhou';

echo $token; exit;

header("Location: $BASE_URL" . 'pages/main.php?box=forgot');
exit;