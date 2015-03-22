<?php

require_once(__DIR__ . '/../vendor/autoload.php');

function sendPasswordResetToken($email, $token)
{
    $mail = new PHPMailer;

    //$mail->SMTPDebug = 3;
    $mail->isSMTP();
    $mail->Host = 'smtp-pt.securemail.pro';
    $mail->SMTPAuth = true;
    $mail->Username = 'geral@trigonum.pt';
    $mail->Password = '2014trigonum';
    $mail->Port = 25;
    $mail->From = 'geral@trigonum.pt';
    $mail->FromName = 'Trigonum DocDue';

    $mail->addAddress($email);

    $mail->Subject = 'Restabelecer a password';
    $mail->isHTML(true);
    $mail->Body = "<a href='http://trigonum.pt/docdue/pages/main.php?box=forgot&token=$token'>Clique aqui</a>";

    return $mail->send();

    /*
    if (!$mail->send()) {
        echo 'Message could not be sent.';
        return 'Mailer Error: ' . $mail->ErrorInfo;
    } else {
        return 'Message has been sent';
    }
    */
}

function sendPasswordResetSuccess($email)
{
    $mail = new PHPMailer;

    //$mail->SMTPDebug = 3;
    $mail->isSMTP();
    $mail->Host = 'smtp-pt.securemail.pro';
    $mail->SMTPAuth = true;
    $mail->Username = 'geral@trigonum.pt';
    $mail->Password = '2014trigonum';
    $mail->Port = 25;
    $mail->From = 'geral@trigonum.pt';
    $mail->FromName = 'Trigonum DocDue';

    $mail->addAddress($email);

    $mail->Subject = 'Palavra-passe recuperada';
    $mail->isHTML(true);
    $mail->Body = "A sua palavra-passe foi alterada com sucesso.";

    return $mail->send();

    /*
    if (!$mail->send()) {
        echo 'Message could not be sent.';
        return 'Mailer Error: ' . $mail->ErrorInfo;
    } else {
        return 'Message has been sent';
    }
    */
}

function sendPasswordResetNoAccount($email)
{
    $mail = new PHPMailer;

    //$mail->SMTPDebug = 3;
    $mail->isSMTP();
    $mail->Host = 'smtp-pt.securemail.pro';
    $mail->SMTPAuth = true;
    $mail->Username = 'geral@trigonum.pt';
    $mail->Password = '2014trigonum';
    $mail->Port = 25;
    $mail->From = 'geral@trigonum.pt';
    $mail->FromName = 'Trigonum DocDue';

    $mail->addAddress($email);

    $mail->Subject = 'Tentativa de restabelecer password';
    $mail->isHTML(true);
    $mail->Body = "Foi pedido que a password para este e-mail fosse restabelecida. No entanto, este e-mail não se encontra registado.";

    return $mail->send();

    /*
    if (!$mail->send()) {
        echo 'Message could not be sent.';
        return 'Mailer Error: ' . $mail->ErrorInfo;
    } else {
        return 'Message has been sent';
    }
    */
}