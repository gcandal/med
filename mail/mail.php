<?php
require_once '../../lib/swiftmailer/lib/swift_required.php';

$transport = Swift_SmtpTransport::newInstance('smtp.gmail.com', 465, "ssl")
    ->setUsername('gabrielcandal@gmail.com')
    ->setPassword('password');
$mailer = Swift_Mailer::newInstance($transport);

function notifyOrganizationInvite($organizatioName, $nameInvited, $emailInvited, $nameInviting)
{
    global $mailer, $BASE_URL;

    $message = Swift_Message::newInstance('Convite para se juntar a '.$organizatioName)
        ->setFrom(array('gabrielcandal2@gmail.com' => 'Trigonum'))
        ->setTo(array($emailInvited => $nameInvited))
        ->setBody('Recebeu um convite para se juntar à '.$organizatioName.' por '.$nameInviting."\r\n"
                    .'Vá a 192.168.1.80'.$BASE_URL.'pages/organizations/invites.php');

    $mailer->send($message);
}

?>