{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <span id="errorMessageName"></span>
    <span id="errorMessageNif"></span>
    <span id="errorMessageLicenseId"></span>
    <form action="{$BASE_URL}actions/professionals/addprofessional.php" method="POST">
        <label>
            Nome:
            <input type="text" name="name" class="professionalName" value="{$FORM_VALUES.name}"/>
        </label>

        <label>
            Função:
            <select id="professionalType">
                <option value="Assistant">Assistente</option>
                <option value="Instrumentist">Instrumentista</option>
                <option value="Anesthetist">Anestesista</option>
            </select>
        </label>

        <label>
            Cédula:
            <input type="text" name="licenseId" class="professionalLicenseId" value="{$FORM_VALUES.licenseId}"/>
        </label>

        <label>
            NIF:
            <input type="text" name="nif" class="professionalNif" value="{$FORM_VALUES.nif}"/>
        </label>

        <label id="specialityLabel">
            Especialidade:
            <select name="speciality" id="specialityId">
                <option value="3">Nenhuma</option>
                {foreach $SPECIALITIES as $speciality}
                    <option value="{$speciality.idspeciality}">{$speciality.name}</option>
                {/foreach}
            </select>
        </label>

        <button type="submit" id="submitButton">Adicionar</button>
    </form>

    {if $FORM_VALUES.type}
        <script>
            $("select#professionalType").val("{$FORM_VALUES.type}");
        </script>
    {/if}
    <script>
        var isAddProfessional = true;
    </script>
    <script src="{$BASE_URL}javascript/addprofessional.js"></script>
    <script src="{$BASE_URL}javascript/validateprofessionalform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}