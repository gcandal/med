{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <form id="formentidade" method="post" action="{$BASE_URL}actions/payers/editentitypayer.php">
        <input type="hidden" name="identitypayer" value="{$entitypayer.identitypayer}"/>

        <label>
            Nome:
            <input type="text" name="name" placeholder="{$entitypayer.name}" value="{$FORM_VALUES.name}"/>
            <span>{$FIELD_ERRORS.name}</span>
        </label>
        <label>
            Início do Contrato:
            <input type="date" id="contractstart" name="contractstart" placeholder="Início do Contrato"
                   value="{$FORM_VALUES.contractstart}"/>
        </label>
        <label>
            Fim do Contrato:
            <input type="date" id="contractend" name="contractend" placeholder="Fim do Contrato" value="{$FORM_VALUES.contractend}"/>
        </label>
        <span id="dateerror"></span>
        <label>
            NIF:
            <input type="number" min="0" id="nifEntity" name="nif" placeholder="{$entitypayer.nif}" value="{$FORM_VALUES.nif}"
                   {literal}pattern="\d{9}"{/literal}/>
            <span id="niferrorEntity">{$FIELD_ERRORS.nif}</span>
        </label>
        <label>
            Valor por K:
            <input type="number" min="0" name="valueperk" placeholder="{$entitypayer.valueperk}" value="{$FORM_VALUES.valueperk}"/>
            <span>{$FIELD_ERRORS.valueperk}</span>
        </label>
        <button type="submit">Editar</button>
        <br>
    </form>
{else}
    <p>Tem que fazer login!</p>
{/if}

<script src="{$BASE_URL}javascript/validateeditentitypayerform.js"></script>
{include file='common/footer.tpl'}