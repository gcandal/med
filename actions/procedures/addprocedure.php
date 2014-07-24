<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/procedures.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $wasAssistant = $_POST['function'] != 'Principal';
    $idAccount = $_SESSION['idaccount'];
    if ($wasAssistant) $wasAssistant = 'true'; else
        $wasAssistant = 'false';

    for ($i = 1; $i <= $_POST['nSubProcedures']; $i++) {
        $subProcedures[] = $_POST["subProcedure$i"];
    }

    if (count($subProcedures) > 0) {
        addProcedure($idAccount, $_POST['status'], $_POST['date'], $wasAssistant, $_POST['totalRemun'], $_POST['personalRemun'], $_POST['valuePerK'], $subProcedures);
    } else {
        addProcedure($idAccount, $_POST['status'], $_POST['date'], $wasAssistant, $_POST['totalRemun'], $_POST['personalRemun'], $_POST['valuePerK']);
    }

    exit;