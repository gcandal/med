{include file='common/header.tpl'}

{if $EMAIL}
    <h1>Pacientes</h1>
    {foreach $PATIENTS as $patient}
        <p>Nome: {$patient.name} </p>
        <p>NIF: {$patient.nif} </p>
        <p>Telefone: {$patient.cellphone}</p>
        <p>Nº Beneficiário: {$patient.beneficiarynr}</p>
        <form action="{$BASE_URL}pages/patients/editpatient.php" >
            <input type="hidden" name="idpatient" value="{$patient.idpatient}"/>
            <button type="submit">Editar</button>
        </form>
        <form action="{$BASE_URL}actions/patients/deletepatient.php" method="post">
            <input type="hidden" name="idpatient" value="{$patient.idpatient}"/>
            <button type="submit">Apagar</button>
        </form>
    {/foreach}
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}