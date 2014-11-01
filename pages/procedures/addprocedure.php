<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/procedures.php');
    include_once($BASE_DIR . 'database/users.php');
    include_once($BASE_DIR . 'database/payers.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    $idaccount = $_SESSION['idaccount'];
    $username = getUserById($idaccount);
    $entities['Entidade'] = getEntityPayers($idaccount);
    $entities['Privado'] = getPrivatePayers($idaccount);
    $procedureTypes = getProcedureTypes();
    $specialities = getSpecialities();
    $smarty->assign('USERNAME', $username);
    $smarty->assign('ENTITIES', $entities);
    $smarty->assign('PROCEDURETYPES', $procedureTypes);
    $smarty->assign('SPECIALITIES', $specialities);

    //if(!$_SESSION['entityType'])
        $_SESSION['entityType'] = "NewPrivate";

    $smarty->assign('ENTITYTYPE', $_SESSION['entityType']);

    $smarty->display('procedures/addprocedure.tpl');
?>