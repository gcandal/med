{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <form id="formentidade" method="post" action="{$BASE_URL}actions/procedures/editentitypayer.php">
        <input type="hidden" name="identitypayer" value="{$identitypayer}"/>

        <label>
            Nome:
            <input type="text" name="name" placeholder="Nome" value="{$FORM_VALUES.name}"/>
            <span>{$FIELD_ERRORS.name}</span>
        </label>
        <label>
            Início do Contrato:
            <input type="date" name="contractstart" placeholder="Início do Contrato"
                   value="{$FORM_VALUES.contractstart}"/>
        </label>
        <label>
            Fim do Contrato:
            <input type="date" name="contractend" placeholder="Fim do Contrato"
                   value="{$FORM_VALUES.contractend}"/>
        </label>
        <label>
            NIF:
            <input type="number" min="0" name="nif" placeholder="NIF"
                   value="{$FORM_VALUES.nif}" {literal}pattern="\d{9}"{/literal}/>
            <span>{$FIELD_ERRORS.nif}</span>
        </label>
        <label>
            Valor por K:
            <input type="number" min="0" name="valueperk" placeholder="Valor por K"
                   value="{$FORM_VALUES.valueperk}"/>
            <span>{$FIELD_ERRORS.valueperk}</span>
        </label>
        <button type="submit">Editar</button>
        <br>
    </form>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}