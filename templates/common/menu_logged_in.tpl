<p>{$EMAIL}</p>
<p>{$LICENSEID}</p>

{foreach $SUCCESS_MESSAGES as $success}
    <p>{$success}</p>
{/foreach}

{foreach $ERROR_MESSAGES as $error}
    <p>{$error}</p>
{/foreach}

<form action="{$BASE_URL}actions/users/logout.php">
    <button type="submit">Logout</button>
</form>

<form action="{$BASE_URL}pages/users/edituser.php">
    <button type="submit">Editar perfil</button>
</form>

<form action="{$BASE_URL}pages/payers/payers.php">
    <button type="submit">Ver Pagadores</button>
</form>

<form action="{$BASE_URL}pages/organizations/organizations.php">
    <button type="submit">Ver Organizações</button>
</form>

<form action="{$BASE_URL}pages/organizations/invites.php">
    <button type="submit">Ver Convites Organizações</button>
</form>

<form action="{$BASE_URL}pages/procedures/invites.php">
    <button type="submit">Ver Convites Procedimentos</button>
</form>

<form action="{$BASE_URL}pages/organizations/addorganization.php">
    <button type="submit">Adicionar Organização</button>
</form>

<form action="{$BASE_URL}pages/procedures/addprocedure.php">
    <button type="submit">Adicionar Procedimento</button>
</form>

<form action="{$BASE_URL}pages/procedures/procedures.php">
    <button type="submit">Ver Procedimentos</button>
</form>

<form action="{$BASE_URL}pages/payers/addpayer.php">
    <button type="submit">Adicionar Pagador</button>
</form>