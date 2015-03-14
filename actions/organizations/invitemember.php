<?php
    include_once('../../config/init.php');
    include_once($BASE_DIR . 'database/organizations.php');
    include_once($BASE_DIR . 'database/users.php');
    //include_once($BASE_DIR . 'mail/mail.php');

    if (!$_SESSION['email']) {
        $_SESSION['error_messages'][] = 'Tem que fazer login';
        header('Location: ' . $BASE_URL);

        exit;
    }

    if ($_POST['licenseid']) {
        $licenseid = $_POST['licenseid'];
        $idinviting = $_SESSION['idaccount'];
        $idorganization = $_POST['idorganization'];
        $nameorganization = $_POST['nameorganization'];
        $foradmin = 'FALSE';

        try {
            if (!isAdministrator($idinviting, $idorganization)) {
                $_SESSION['error_messages'][] = 'Só os administradores podem convidar para uma organização';

                header("Location: $BASE_URL" . 'pages/organizations/organization.php?idorganization=' . $idorganization);
                exit;
            }
        } catch (PDOException $e) {
            $_SESSION['error_messages'][] = 'Erro a convidar para organização ';// . $e->getMessage();

            header("Location: $BASE_URL" . 'pages/organizations/organization.php?idorganization=' . $idorganization);
            exit;
        }

        try {
            inviteForOrganization($idorganization, $idinviting, $licenseid, $foradmin);
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'orginvitation_pkey') !== false) {
                $_SESSION['error_messages'][] = 'Já enviou um convite para esse membro.';
            } else  $_SESSION['error_messages'][] = 'Erro a editar entidade ';// . $e->getMessage();

            header("Location: $BASE_URL" . 'pages/organizations/organization.php?idorganization=' . $idorganization);
            exit;
        }

        $invitedUser = getNameAndEmailFromLicenseId($licenseid);
        $invitedName = $invitedUser['name'];
        $invitedEmail = $invitedUser['email'];

        if ($invitedName) {
            /*
            $invitedEmail = 'gabrielcandal@gmail.com';
            notifyOrganizationInvite($nameorganization, $nameInvited, $invitedEmail, $_SESSION['name']);
            */
        }
    }

    $_SESSION['success_messages'][] = 'Membro convidado com sucesso';

    header("Location: $BASE_URL" . 'pages/organizations/organization.php?idorganization=' . $idorganization);
?>