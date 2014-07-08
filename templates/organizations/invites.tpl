{include file='common/header.tpl'}

{if $EMAIL}
    <h1>Recebidos</h1>
    {foreach $INVITES as $invite}
        {if !$invite.wasrejected}
            <p>Nome de quem convida: {$invite.invitingname}</p>
            <p>Nome da organização: {$invite.organizationname}</p>
            <p>
                Tipo de convite:
                {if $invite.foradmin}
                    Utilizador Normal
                {else}
                    Administrador
                {/if}
            </p>
            <form action="{$BASE_URL}actions/organizations/acceptinvite.php" method="post">
                <input type="hidden" name="idorganization" value="{$invite.idorganization}"/>
                <input type="hidden" name="idinvitingaccount" value="{$invite.idinvitingaccount}"/>
                <select name="orgauthorization">
                    {if $invite.foradmin}
                        <option value="AdminVisible">Visível</option>
                        <option value="AdminNotVisible">Invisível</option>
                    {else}
                        <option value="NotVisible">Invisível</option>
                        <option value="Visible">Visível</option>
                    {/if}
                </select>
                <button type="submit">Aceitar</button>
            </form>
            <form action="{$BASE_URL}actions/organizations/rejectinvite.php" method="post">
                <input type="hidden" name="idorganization" value="{$invite.idorganization}"/>
                <input type="hidden" name="idinvitingaccount" value="{$invite.idinvitingaccount}"/>
                <button type="submit">Rejeitar</button>
            </form>
        {/if}
    {/foreach}
    <h1>Enviados</h1>
    {foreach $SENT as $invite}
        <p>Cédula do convidado: {$invite.licenseidinvited}</p>
        <p>Nome da organização: {$invite.organizationname}</p>
        <p>
            Tipo de convite:
            {if $invite.foradmin}
                Utilizador Normal
            {else}
                Administrador
            {/if}
        </p>
        <form action="{$BASE_URL}actions/organizations/deleteinvite.php" method="post">
            <input type="hidden" name="idorganization" value="{$invite.idorganization}"/>
            <input type="hidden" name="licenseidinvited" value="{$invite.licenseidinvited}"/>
            <button type="submit">Retirar Convite</button>
        </form>
    {/foreach}
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}