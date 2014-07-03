{include file='common/header.tpl'}

{if $EMAIL}
    <h1>Organizações</h1>
    {foreach $ORGANIZATIONS as $organization}
        <p>Nome: {$organization.name}</p>
        <form action="{$BASE_URL}pages/organizations/organization.php" method="get">
            <input type="hidden" name="idorganization" value="{$organization.idorganization}"/>
            <button type="submit">Ver detalhes</button>
        </form>
    {/foreach}
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}