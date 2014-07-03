<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/procedures.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $accountId = $_SESSION['idaccount'];
    $idProcedure = $_POST['idprocedure'];

    if (!deleteProcedure($idProcedure)) {
        $_SESSION['error_messages'][] = 'Este procedimento não existe ou já foi previamente apagado';
    }

    header("Location: $BASE_URL" . "pages/procedures/procedures.php");

?>