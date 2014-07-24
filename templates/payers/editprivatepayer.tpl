{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <form id="formprivado" method="post" action="{$BASE_URL}actions/payers/editprivatepayer.php">
        <input type="hidden" name="idprivatepayer" value="{$privatepayer.idprivatepayer}"/>

        <label>
            Nome:
            <input type="text" name="name" placeholder="Nome" value="{$FORM_VALUES.name}" maxlength="40"/>
            <span>{$FIELD_ERRORS.name}</span>
        </label>
        <label>
            NIF:
            <input type="number" min="0" id="nifPrivate" name="nif" placeholder="NIF" value="{$FORM_VALUES.nif}"
                   {literal}pattern="\d{9}"{/literal} maxlength="9"/>
            <span id="niferrorPrivate">{$FIELD_ERRORS.nif}</span>
        </label>
        <label>
            Valor por K:
            <input type="number" min="0" name="valueperk" placeholder="Valor por K" value="{$FORM_VALUES.valueperk}"/>
            <span>{$FIELD_ERRORS.valueperk}</span>
        </label>
        <button type="submit">Editar</button>
    </form>
{else}
    <p>Tem que fazer login!</p>
{/if}

<script src="{$BASE_URL}javascript/validateeditprivatepayerform.js"></script>
{include file='common/footer.tpl'}