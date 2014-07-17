{include file='common/header.tpl'}

{if $EMAIL}
    <h1>{$organization.name}</h1>
    {foreach $organization['members'] as $member}
        <p>Nome: {$member.name}</p>
        <p>Cédula: {$member.licenseid}</p>
        <p>
            Autorização:
            {if $member.orgauthorization == 'AdminVisible'}
                Administrador Visível
            {elseif $member.orgauthorization == 'AdminNotVisible'}
                Administrador Invisível
            {elseif $member.orgauthorization == 'Visible'}
                Visível
            {else}
                Invisível
            {/if}
        </p>
    {/foreach}

    {if $organization.orgauthorization == 'AdminVisible' || $organization.orgauthorization == 'AdminNotVisible'}
        <form action="{$BASE_URL}pages/organizations/editorganization.php" method="post">
            <input type="hidden" name="idorganization" value="{$organization.idorganization}"/>
            <button type="submit">Editar</button>
        </form>
        <form action="{$BASE_URL}actions/organizations/deleteorganization.php" method="post">
            <input type="hidden" name="idorganization" value="{$organization.idorganization}"/>
            <button type="submit">Apagar</button>
        </form>
        <form action="{$BASE_URL}actions/organizations/invitemember.php" method="post">
            <input type="hidden" id="idorganization" name="idorganization" value="{$organization.idorganization}"/>
            <input type="hidden" name="nameorganization" value="{$organization.name}"/>
            <label>
                Cédula:
                <input type="text" id="licenseid" name="licenseid" placeholder="Cédula" value="{$FORM_VALUES.licenseid}"
                       {literal}pattern="\d{9}"{/literal} required/>
                <span id="licenseiderror">{$FIELD_ERRORS.licenseid}</span>
            </label>
            <button type="submit">Convidar</button>
        </form>
    {/if}
{else}
    <p>Tem que fazer login!</p>
{/if}
<script type="text/javascript">
    var baseUrl = {$BASE_URL};
</script>
<script src="{$BASE_URL}javascript/validateinviteform.js"></script>
{include file='common/footer.tpl'}