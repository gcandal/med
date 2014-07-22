{include file='common/header.tpl'}

{if $EMAIL}
    <h1>Recebidos</h1>
    {foreach $INVITES as $invite}
        {if !$invite.wasrejected}
            <p>Nome de quem convida: {$invite.invitingname}</p>

            <form action="{$BASE_URL}actions/procedures/acceptsharedprocedure.php" method="post">
                <input type="hidden" name="idprocedure" value="{$invite.idprocedure}"/>
                <input type="hidden" name="idinvitingaccount" value="{$invite.idinvitingaccount}"/>
                <button type="submit">Aceitar</button>
            </form>
            <form action="{$BASE_URL}actions/procedures/rejectsharedprocedure.php" method="post">
                <input type="hidden" name="idprocedure" value="{$invite.idprocedure}"/>
                <input type="hidden" name="idinvitingaccount" value="{$invite.idinvitingaccount}"/>
                <button type="submit">Rejeitar</button>
            </form>
        {/if}
    {/foreach}
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}