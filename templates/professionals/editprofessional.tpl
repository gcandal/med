{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <span id="errorMessageName"></span>
    <span id="errorMessageNif"></span>
    <span id="errorMessageLicenseId"></span>

    <form action="{$BASE_URL}actions/professionals/editprofessional.php" method="POST">
        <input type="hidden" name="idprofessional" value="{$professional.idprofessional}">
        <label>
            Nome:
            <input type="text" name="name" placeholder="{$professional.name}" class="professionalName" value="{$FORM_VALUES.name}"/>
        </label>

        <label>
            Função:
            {if $professional.idspeciality > 2}
                Assistente
            {elseif $professional.idspeciality == 1}
                Anestesista
            {else}
                Instrumentista
            {/if}
        </label>

        <label>
            Cédula:
            <input type="text" name="licenseid" placeholder="{$professional.licenseid}" class="professionalLicenseId"
                   value="{$FORM_VALUES.licenseId}"/>
        </label>

        <label>
            NIF:
            <input type="text" name="nif" placeholder="{$professional.nif}" class="professionalNif" value="{$FORM_VALUES.nif}"/>
        </label>


        <label id="specialityLabel">
            Especialidade:

            {if $professional.idspeciality > 2}
                <select name="speciality" id="specialityId">
                    {foreach $SPECIALITIES as $speciality}
                        {if $speciality.idspeciality > 2}
                            <option value="{$speciality.idspeciality}">{$speciality.name}</option>
                        {/if}
                    {/foreach}
                </select>
            {elseif $professional.idspeciality == 1}
                Anestesiologia
            {else}
                Enfermagem
            {/if}
        </label>


        <button type="submit" id="submitButton">Adicionar</button>
    </form>
    {if $professional.idspeciality}
        <script>
            $("#specialityId").val("{$professional.idspeciality}");
        </script>
    {/if}
    <script>
        var isAddProfessional = false;
    </script>
    <script src="{$BASE_URL}javascript/validateprofessionalform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}