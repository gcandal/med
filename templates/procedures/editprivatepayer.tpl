{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <form id="formprivado" method="post" action="{$BASE_URL}actions/procedures/editprivatepayer.php">
        <input type="hidden" name="idprivatepayer" value="{$idprivatepayer}"/>

        <label>
            Nome:
            <input type="text" name="name" placeholder="Nome" value="{$FORM_VALUES.name}" maxlength="40"/>
            <span>{$FIELD_ERRORS.name}</span>
        </label>
        <label>
            NIF:
            <input type="number" min="0" name="nif" placeholder="NIF" value="{$FORM_VALUES.nif}"
                   {literal}pattern="\d{9}"{/literal} maxlength="9"/>
            <span>{$FIELD_ERRORS.nif}</span>
        </label>

        <button type="submit">Editar</button>
    </form>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}