{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <form>
        <label>
            Nome:
            <input type="text" name="name" value="{$FORM_VALUES.name}"/>
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
            <input type="text" name="licenseId" value="{$FORM_VALUES.licenseId}"/>
        </label>

        <label>
            NIF:
            <input type="text" name="nif" value="{$FORM_VALUES.nif}"/>
        </label>

        <label id="specialityLabel">
            Especialidade:
            <select>
                <option value=""></option>
                {foreach $SPECIALITIES as $speciality}
                    <option value="{$speciality.idspeciality}">{$speciality.name}</option>
                {/foreach}
            </select>
        </label>

        <button type="submit">Adicionar</button>
    </form>

    <script src="{$BASE_URL}javascript/addprofessional.js"></script>
    {if $FORM_VALUES.type}
        <script>
            $("select#professionalType").val("{$FORM_VALUES.type}");
        </script>
    {/if}
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}