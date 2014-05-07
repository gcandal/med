{include file='common/header.tpl'}

{if $EMAIL}
    <h1>Privado</h1>
    {foreach $ENTITIES['Privado'] as $entity}
        <p>Nome: {$entity.nome}</p>
    {/foreach}

    <h1>Hospital/Seguro</h1>
    {foreach $ENTITIES['Resto'] as $entity}
        <p>Nome: {$entity.nome}</p>
        <p>Início do Contrato: {$entity.contractstart}</p>
        <p>Fim do Contrato: {$entity.contractend}</p>
        <p>NIF: {$entity.Snif}</p>
        <p>Valor por K: {$entity.valueperk}</p>
    {/foreach}
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}