{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <span class="errorMessage" id="errorMessageNifPatient"></span>
    <span class="errorMessage" id="errorMessageNamePatient"></span>
    <span class="errorMessage" id="errorMessageCellphonePatient"></span>
    <span class="errorMessage" id="errorMessageNrBeneficiaryPatient"></span>
    <form method="post" action="{$BASE_URL}actions/patients/addpatient.php">
        <label>
            Nome:
            <input type="text" name="name" id="namePatient" placeholder="Nome" value="{$FORM_VALUES.name}" required
                   maxlength="40"/>
            <span>{$FIELD_ERRORS.name}</span>
        </label>

        <label>
            NIF:
            <input type="number" id="nifPatient" min="0" name="nif" placeholder="NIF"
                   value="{$FORM_VALUES.nif}"/>
            <span>{$FIELD_ERRORS.nif}</span>
        </label>

        <label>
            Telefone:
            <input type="text" name="cellphone" id="cellphonePatient" placeholder="{$privatepayer.cellphone}"
                   value="{$FORM_VALUES.cellphone}"/>
            <span>{$FIELD_ERRORS.cellphone}</span>
        </label>

        <label>
            Nº Beneficiário:
            <input type="number" min="0" id="beneficiaryNrPatient" name="beneficiarynr"
                   placeholder="{$patient.beneficiarynr}"
                   value="{$FORM_VALUES.beneficiarynr}"/>
            <span>{$FIELD_ERRORS.nrbeneficiary}</span>
        </label>
        <button type="submit" id="submitButton">Adicionar</button>
    </form>
    <script>
        const isEdit = false;
    </script>
    <script src="{$BASE_URL}javascript/validatepatientform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}