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
                            VALUES (currval('Organization_idOrganization_seq'), :accountId, 'Admin')");
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
                            AND orgAuthorization = 'Admin'");
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

?>