{include file='common/header.tpl'}

{if $EMAIL}
    <h1>Organizações</h1>
    {foreach $ORGANIZATIONS as $organization}
        <p>Nome: {$organization.name}</p>
        <p>Autorização: {$organization.orgauthorization}</p>
        {foreach $organization['members'] as $member}
            <p>Nome: {$member.name}</p>
            <p>Cédula: {$member.licenseid}</p>
        {/foreach}

        {if $organization.orgauthorization == 'Administrador'}
            <form action="{$BASE_URL}pages/organizations/editorganization.php" method="post">
                <input type="hidden" name="idorganization" value="{$organization.idorganization}" />
                <button type="submit">Editar</button>
            </form>
            <form action="{$BASE_URL}actions/procedures/deleteorganization.php" method="post">
                <input type="hidden" name="idorganization" value="{$organization.idprivatepayer}" />
                <button type="submit">Apagar</button>
            </form>
        {/if}
    {/foreach}
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}