<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/procedures.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $idaccount = $_SESSION['idaccount'];
    $entities['Entidade'] = getEntityPayers($idaccount);
    $entities['Privado'] = getPrivatePayers($idaccount);
    $procedureTypes = getProcedureTypes();
    $smarty->assign('ENTITIES', $entities);
    $smarty->assign('PROCEDURETYPES', $procedureTypes);
    $smarty->display('procedures/addprocedure.tpl');
?>