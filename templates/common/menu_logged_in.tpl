<p>{$EMAIL}</p>
<p>{$LICENSEID}</p>
<p>Válida até: {$VALIDUNTIL}</p>
<p>Registos por usar:
    {if $FREEREGISTERS == -1}
        ilimitado
    {else}
        {$FREEREGISTERS}
    {/if}</p>

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

<form action="{$BASE_URL}pages/payers/addpayer.php">
    <button type="submit">Adicionar Pagador</button>
</form>

<form action="{$BASE_URL}pages/organizations/organizations.php">
    <button type="submit">Ver Organizações</button>
</form>

<form action="{$BASE_URL}pages/organizations/addorganization.php">
    <button type="submit">Adicionar Organização</button>
</form>

<form action="{$BASE_URL}pages/organizations/invites.php">
    <button type="submit">Ver Convites Organizações</button>
</form>

<form action="{$BASE_URL}pages/procedures/procedures.php">
    <button type="submit">Ver Registos</button>
</form>

<form action="{$BASE_URL}pages/procedures/addprocedure.php">
    <button type="submit">Adicionar Registo</button>
</form>

<form action="{$BASE_URL}pages/procedures/invites.php">
    <button type="submit">Ver Convites Registos</button>
</form>

<form action="{$BASE_URL}pages/professionals/professionals.php">
    <button type="submit">Ver Profissionais</button>
</form>

<form action="{$BASE_URL}pages/professionals/addprofessional.php">
    <button type="submit">Adicionar Profissional</button>
</form>