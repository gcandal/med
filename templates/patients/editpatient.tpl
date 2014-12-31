{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <span class="errorMessage" id="errorMessageNifPatient"></span>
    <span class="errorMessage" id="errorMessageNamePatient"></span>
    <span class="errorMessage" id="errorMessageCellphonePatient"></span>
    <span class="errorMessage" id="errorMessageNrBeneficiaryPatient"></span>
    <form method="post" action="{$BASE_URL}actions/patients/editpatient.php">
        <input type="hidden" name="idpatient" value="{$patient.idpatient}"/>

        <label>
            Nome:
            <input type="text" name="name" id="namePatient" placeholder="{$patient.name}" value="{$FORM_VALUES.name}"
                   maxlength="40"/>
            <span>{$FIELD_ERRORS.name}</span>
        </label>
        <label>
            NIF:
            <input type="number" min="0" id="nifPatient" name="nif" placeholder="{$patient.nif}"
                   value="{$FORM_VALUES.nif}"/>
            <span>{$FIELD_ERRORS.nif}</span>
        </label>
        <label>
            Telefone:
            <input type="text" name="cellphone" id="cellphonePatient" placeholder="{$patient.cellphone}"
                   value="{$FORM_VALUES.cellphone}"/>
            <span>{$FIELD_ERRORS.cellphone}</span>
        </label>
        <label>
            Nº Beneficiário:
            <input type="number" min="0" id="beneficiaryNrPatient" name="beneficiarynr"
                   placeholder="{$patient.beneficiarynr}" value="{$FORM_VALUES.nrbeneficiary}"/>
            <span>{$FIELD_ERRORS.beneficiarynr}</span>
        </label>
        <button type="submit" id="submitButton">Editar</button>
    </form>
    <script>
        const isEdit = true;
    </script>
    <script src="{$BASE_URL}javascript/validatepatientform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}
{include file='common/footer.tpl'}