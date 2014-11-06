{include file='common/header.tpl'}

{if $EMAIL}
    <h1>Privado</h1>
    {foreach $ENTITIES['Privado'] as $entity}
        <p>Nome: {$entity.name} </p>
        <p>NIF: {$entity.nif} </p>
        <p>Valor por K: {$entity.valueperk}</p>
        <form action="{$BASE_URL}pages/payers/editprivatepayer.php" >
            <input type="hidden" name="idprivatepayer" value="{$entity.idprivatepayer}"/>
            <button type="submit">Editar</button>
        </form>
        <form action="{$BASE_URL}actions/payers/deleteprivatepayer.php" >
            <input type="hidden" name="idprivatepayer" value="{$entity.idprivatepayer}"/>
            <button type="submit">Apagar</button>
        </form>
    {/foreach}
    <h1>Hospital/Seguro</h1>
    {foreach $ENTITIES['Entidade'] as $entity}
        <p>Nome: {$entity.name}</p>
        <p>Início do Contrato: {$entity.contractstart}</p>
        <p>Fim do Contrato: {$entity.contractend}</p>
        <p>NIF: {$entity.nif}</p>
        <p>Valor por K: {$entity.valueperk}</p>
        <form action="{$BASE_URL}pages/payers/editentitypayer.php" method="post">
            <input type="hidden" name="identitypayer" value="{$entity.identitypayer}"/>
            <button type="submit">Editar</button>
        </form>
        <form action="{$BASE_URL}actions/payers/deleteentitypayer.php" method="post">
            <input type="hidden" name="identitypayer" value="{$entity.identitypayer}"/>
            <button type="submit">Apagar</button>
        </form>
    {/foreach}
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}