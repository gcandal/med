<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/users.php');

    if ($_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer logout';
        header('Location: ' . $BASE_URL);

        exit;
    }

    if (!$_POST['email'] || !$_POST['password']) {
        $_SESSION['error_messages'][] = 'Não preencheu um dos campos.';
        if (!$_POST['email']) $_SESSION['error_messages'][] = 'mail';
        if (!$_POST['password']) $_SESSION['error_messages'][] = 'password';
        $_SESSION['form_values'] = $_POST;

        header('Location: ' . $_SERVER['HTTP_REFERER']);
        exit;
    }

    $email = $_POST['email'];
    $password = $_POST['password'];
    $current_user = getUserByEmail($email);

    if (!$current_user) {
        $_SESSION['error_messages'][] = 'Email e password inválidos.';

        header('Location: ' . $_SERVER['HTTP_REFERER']);
        exit;
    }

    if (checkBrute($current_user['idaccount'])) {
        $_SESSION['error_messages'][] = 'Bruteforce detetado, conta bloqueada';

        header('Location: ' . $_SERVER['HTTP_REFERER']);
        exit;
    }

    if( strtotime($current_user['validuntil']) < strtotime("now")) {
        $_SESSION['error_messages'][] = 'A sua conta expirou em ' . $current_user['validuntil'];

        header('Location: ' . $_SERVER['HTTP_REFERER']);
        exit;
    }
    $password = hash('sha512', $password . $current_user['salt']);

    if ($current_user['password'] === $password) {
        session_regenerate_id(true);
        $_SESSION['email'] = $current_user['email'];
        $_SESSION['name'] = $current_user['name'];
        $_SESSION['validuntil'] = $current_user['validuntil'];
        $_SESSION['freeregisters'] = $current_user['freeregisters'];
        $_SESSION['idaccount'] = $current_user['idaccount'];
        $_SESSION['licenseid'] = $current_user['licenseid'];

        $_SESSION['success_messages'][] = 'Login successful ';
        var_dump($_SESSION);
    } else {
        try {
            logAttempt($current_user['idaccount']);
        } catch (PDOException $e) {
            $_SESSION['error_messages'][] = $e->getMessage();
        }

        $_SESSION['error_messages'][] = 'Email e password inválidos.';
    }

    header('Location: ' . $BASE_URL);
?>