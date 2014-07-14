<?php

function getOrganizations($idAccount)
{
    global $conn;

    $stmt = $conn->prepare("SELECT *
                            FROM organization, orgauthorization
                            WHERE orgauthorization.idAccount = :idAccount
                            AND organization.idOrganization = orgauthorization.idOrganization
                            ORDER BY organization.name");
    $stmt->execute(array("idAccount" => $idAccount));

    return $stmt->fetchAll();
}

function getOrganization($idAccount, $idOrganization)
{
    global $conn;

    $stmt = $conn->prepare("SELECT *
                            FROM organization, orgauthorization
                            WHERE orgauthorization.idAccount = :idAccount
                            AND orgauthorization.idOrganization = :idOrganization
                            AND organization.idOrganization = orgauthorization.idOrganization");

    $stmt->execute(array("idAccount" => $idAccount, "idOrganization" => $idOrganization));

    return $stmt->fetch();
}

function createOrganization($name, $accountId)
{
    global $conn;
    $conn->beginTransaction();

    $stmt = $conn->prepare("INSERT INTO Organization(name) VALUES (:name)");
    $stmt->execute(array("name" => $name));

    $stmt = $conn->prepare("INSERT INTO OrgAuthorization(idOrganization, idaccount, orgauthorization)
                            VALUES (currval('Organization_idOrganization_seq'), :accountId, 'AdminVisible')");
    $stmt->execute(array("accountId" => $accountId));

    $conn->commit();
}

function deleteOrganization($idOrganization)
{
    global $conn;

    $stmt = $conn->prepare("DELETE FROM organization
                            WHERE idOrganization = :idOrganization");

    $stmt->execute(array("idOrganization" => $idOrganization));

    return $stmt->fetch();
}

function getMembersFromOrganization($idorganization)
{
    global $conn;

    $stmt = $conn->prepare("SELECT name, licenseid, orgauthorization
                            FROM account, orgauthorization
                            WHERE orgauthorization.idOrganization = :idorganization
                            AND account.idAccount = orgauthorization.idAccount");
    $stmt->execute(array("idorganization" => $idorganization));

    return $stmt->fetchAll();
}

function isAdministrator($idAccount, $idOrganization)
{
    global $conn;

    $stmt = $conn->prepare("SELECT idaccount
                            FROM orgauthorization
                            WHERE idaccount = :idAccount AND idorganization = :idOrganization
                            AND (orgAuthorization = 'AdminVisible' OR orgauthorization = 'AdminNotVisible')");
    $stmt->execute(array("idOrganization" => $idOrganization, "idAccount" => $idAccount));

    return $stmt->fetch() == true;
}

function isMember($idAccount, $idOrganization)
{
    global $conn;

    $stmt = $conn->prepare("SELECT idaccount
                            FROM orgauthorization
                            WHERE idaccount = :idAccount AND idorganization = :idOrganization");
    $stmt->execute(array("idOrganization" => $idOrganization, "idAccount" => $idAccount));

    return $stmt->fetch() == true;
}

function editOrganizationName($name, $idorganization)
{
    global $conn;
    $stmt = $conn->prepare("UPDATE organization SET name = :name
                            WHERE idorganization = :idorganization");
    $stmt->execute(array("name" => $name, "idorganization" => $idorganization));
}



function inviteForOrganization($idorganization, $idinviting, $licenseid, $foradmin)
{
    global $conn;
    $stmt = $conn->prepare("INSERT INTO OrgInvitation(idorganization, idinvitingaccount, licenseIdInvited, foradmin, date)
                            VALUES (:idorganization, :idinvitingaccount, :licenseIdInvited, :foradmin, DEFAULT)");

    $stmt->execute(array("idorganization" => $idorganization, "idinvitingaccount" => $idinviting, "licenseIdInvited" => $licenseid, "foradmin" => $foradmin));
}

function editOrganizationVisibility($idorganization, $accountid, $visibility)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE orgauthorization SET orgauthorization = :visibility
                            WHERE idaccount = :idAccount AND idorganization = :idOrganization");

    $stmt->execute(array("idOrganization" => $idorganization, "idAccount" => $accountid, "visibility" => $visibility));
}

function getInvites($licenseid)
{
    global $conn;

    $stmt = $conn->prepare("SELECT Account.name invitingName, Organization.Name organizationName, forAdmin,
                            OrgInvitation.idOrganization, OrgInvitation.idInvitingAccount, wasRejected
                            FROM OrgInvitation, Account, Organization
                            WHERE OrgInvitation.licenseIdInvited = :licenseId
                            AND OrgInvitation.idInvitingAccount = Account.idAccount
                            AND OrgInvitation.idOrganization = Organization.idOrganization");
    $stmt->execute(array("licenseId" => $licenseid));

    return $stmt->fetchAll();
}

function getSentInvites($accountId) {
    global $conn;

    $stmt = $conn->prepare("SELECT Organization.Name organizationName, forAdmin, OrgInvitation.idOrganization,
                            OrgInvitation.idInvitingAccount, OrgInvitation.licenseIdInvited
                            FROM Account, OrgInvitation, Organization
                            WHERE Account.idAccount = :idAccount
                            AND OrgInvitation.idInvitingAccount = Account.idAccount
                            AND OrgInvitation.idOrganization = Organization.idOrganization");
    $stmt->execute(array("idAccount" => $accountId));

    return $stmt->fetchAll();
}

function deleteInvite($idOrganization, $idInvitingAccount, $licenseIdInvited)
{
    global $conn;

    $stmt = $conn->prepare("DELETE FROM OrgInvitation
                            WHERE idOrganization = :idOrganization
                            AND idInvitingAccount = :idInvitingAccount
                            AND licenseIdInvited = :licenseIdInvited");

    $stmt->execute(array("idOrganization" => $idOrganization, "idInvitingAccount" => $idInvitingAccount,
        "licenseIdInvited" => $licenseIdInvited));
}

function rejectInvite($idOrganization, $idInvitingAccount, $licenseIdInvited)
{
    global $conn;

    $stmt = $conn->prepare("UPDATE OrgInvitation SET wasRejected = TRUE
                            WHERE idOrganization = :idOrganization
                            AND idInvitingAccount = :idInvitingAccount
                            AND licenseIdInvited = :licenseIdInvited");

    $stmt->execute(array("idOrganization" => $idOrganization, "idInvitingAccount" => $idInvitingAccount,
        "licenseIdInvited" => $licenseIdInvited));
}

function acceptInvite($idOrganization, $idInvitingAccount, $licenseIdInvited, $idAccount, $orgAuthorization)
{
    global $conn;

    $stmt = $conn->prepare("INSERT INTO OrgAuthorization(idOrganization, idAccount, orgAuthorization)
                            VALUES (:idOrganization, :idAccount, :orgAuthorization)");

    $stmt->execute(array("idOrganization" => $idOrganization, "orgAuthorization" => $orgAuthorization,
        "idAccount" => $idAccount));

    deleteInvite($idOrganization, $idInvitingAccount, $licenseIdInvited);
}

function cleanInvites() {
    global $conn;

    $stmt = $conn->prepare("DELETE FROM OrgInvitation
                            WHERE date < CURRENT_TIMESTAMP - interval '7 days'");

    $stmt->execute();
}
?>