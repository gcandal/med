{include file='common/header.tpl'}

{if $EMAIL}
    <h1>Profissionais</h1>
    {foreach $PROFESSIONALS as $professional}
        <p>Nome: {$professional.name} </p>
        <p>Cédula OM: {$professional.licenseid}</p>
        <p>NIF: {$professional.nif} </p>
        <p>Especialidade: {$professional.speciality}</p>
        <form action="{$BASE_URL}pages/professionals/editprofessional.php">
            <input type="hidden" name="idprofessional" value="{$professional.idprofessional}"/>
            <button type="submit">Editar</button>
        </form>
        <form action="{$BASE_URL}actions/professionals/deleteprofessional.php" method="post">
            <input type="hidden" name="idprofessional" value="{$professional.idprofessional}"/>
            <button type="submit">Apagar</button>
        </form>
    {/foreach}
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}