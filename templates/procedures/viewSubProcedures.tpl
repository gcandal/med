{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $SUBPROCEDURES as $subProcedure}
        <p>{$subProcedure.name}</p>
    {/foreach}

{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}