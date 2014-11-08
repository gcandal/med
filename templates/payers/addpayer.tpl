{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <span class="errorMessagePrivate" id="errorMessageNamePrivate"></span>
    <span class="errorMessagePrivate" id="errorMessageNifPrivate"></span>
    <span class="errorMessageEntity" id="errorMessageNameEntity"></span>
    <span class="errorMessageEntity" id="errorMessageNifEntity"></span>
    <span class="errorMessageEntity" id="errorMessageDate"></span>
    <select id="entityType">
        <option value="NewEntity">Hospital</option>
        <option value="NewEntity">Seguro</option>
        <option value="NewPrivate">Privado</option>
    </select>
    {if $FORM_VALUES.type}
        <script>
            $("select#entitytype").val("{$FORM_VALUES.type}");
        </script>
    {/if}

    <form id="formentidade" method="post" action="{$BASE_URL}actions/payers/addpayer.php">
        <input type="hidden" name="type" id="entityTypeInput" value="Insurance" required/>

        <label>
            Nome:
            <input type="text" name="name" id="nameEntity" placeholder="Nome" value="{$FORM_VALUES.name}" required
                   maxlength="40"/>
            <span>{$FIELD_ERRORS.name}</span>
        </label>
        <label>
            Início do Contrato:
            <input type="date" name="contractstart" id="contractstart" placeholder="Início do Contrato"
                   value="{$FORM_VALUES.contractstart}"/>
        </label>
        <label>
            Fim do Contrato:
            <input type="date" name="contractend" id="contractend" placeholder="Fim do Contrato"
                   value="{$FORM_VALUES.contractend}"/>
        </label>
        <span id="dateerror"></span>
        <label>
            NIF:
            <input type="number" min="0" name="nif" id="nifEntity" placeholder="NIF" required value="{$FORM_VALUES.nif}"
                   {literal}pattern="\d{9}"{/literal} maxlength="9"/>
            <span id="niferrorEntity">{$FIELD_ERRORS.nif}</span>
        </label>
        <label>
            Valor por K:
            <input type="number" min="0" step="0.01" name="valueperk" placeholder="Valor por K" value="{$FORM_VALUES.valueperk}"/>
            <span>{$FIELD_ERRORS.valueperk}</span>
        </label>
        <button type="submit" id="submitButtonEntity">Adicionar</button>
        <br>
    </form>
    <form id="formprivado" method="post" action="{$BASE_URL}actions/payers/addpayer.php">
        <input type="hidden" name="type" value="Private" required/>

        <label>
            Nome:
            <input type="text" name="name" id="namePrivate" placeholder="Nome" value="{$FORM_VALUES.name}" required
                   maxlength="40"/>
            <span>{$FIELD_ERRORS.name}</span>
        </label>

        <label>
            NIF:
            <input type="number" id="nifPrivate" min="0" name="nif" placeholder="NIF" required
                   value="{$FORM_VALUES.nif}"
                   {literal}pattern="\d{9}"{/literal} maxlength="9"/>
            <span id="niferrorPrivate">{$FIELD_ERRORS.nif}</span>
        </label>

        <label>
            Valor por K:
            <input type="number" min="0" name="valueperk" placeholder="Valor por K" value="{$FORM_VALUES.valueperk}"/>
            <span>{$FIELD_ERRORS.valueperk}</span>
        </label>
        <button type="submit" id="submitButtonPrivate">Adicionar</button>
    </form>

    <script src="{$BASE_URL}javascript/addpayer.js"></script>
    <script src="{$BASE_URL}javascript/validatepayerform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}