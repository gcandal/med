<p>{$USERNAME}</p>
<p>{$EMAIL}</p>

{foreach $SUCCESS_MESSAGES as $success}
    <p>{$success}</p>
{/foreach}

<form action="{$BASE_URL}actions/users/logout.php">
    <button type="submit">Logout</button>
</form>

<form action="{$BASE_URL}pages/users/edituser.php">
    <button type="submit">Editar perfil</button>
</form>

<form action="{$BASE_URL}pages/procedures/payers.php">
    <button type="submit">Ver Entidades</button>
</form>

<form action="{$BASE_URL}pages/procedures/addprocedure.php">
    <button type="submit">Adicionar Procedimento</button>
</form>

<form action="{$BASE_URL}pages/procedures/addpayer.php">
    <button type="submit">Adicionar Entidade</button>
</form>