{include file='common/header.tpl'}

{if $EMAIL}
    <p>Já está registado!</p>
{else}
    <span id="userNameError"></span>
    <span id="emailError"></span>
    <span id="licenseIdError"></span>
    <span id="passwordError"></span>
    <form id="registerform" method="post" action="{$BASE_URL}actions/users/register.php">
        <label>
            Nome:
            <input type="text" name="name" id="userName" placeholder="Nome" value="{$FORM_VALUES.name}" required
                   maxlength="40"/>
            <span>{$FIELD_ERRORS.name}</span>
        </label>
        <label>
            Email:
            <input type="email" name="email" id="email" placeholder="Email" value="{$FORM_VALUES.email}" required
                   maxlength="254"/>
            <span>{$FIELD_ERRORS.email}</span><br/>
        </label>
        <label>
            Cédula:
            <input type="text" name="licenseid" id="licenseId" placeholder="Cédula" value="{$FORM_VALUES.licenseid}" required/>
            <span>{$FIELD_ERRORS.licenseid}</span><br/>
        </label>
        <label id="specialityLabel">
            Especialidade:
            <select name="speciality" id="specialityId">
                <option value="3">Nenhuma</option>
                {foreach $SPECIALITIES as $speciality}
                    {if $speciality.idspeciality != 3}
                        <option value="{$speciality.idspeciality}">{$speciality.name}</option>
                    {/if}
                {/foreach}
            </select>
        </label>
        <label>
            Password:
            <input type="password" id="password" name="password" placeholder="Password" required/>
            <span>{$FIELD_ERRORS.password}</span><br/>
        </label>
        <label>
            Confirmar Password:
            <input type="password" id="passwordconfirm" name="passwordconfirm" placeholder="Confirmar Password" required/>
            <span>{$FIELD_ERRORS.passwordconfirm}</span><br/>
        </label>
        <button type="submit" id="submitButton">Registar</button>
        <br>
    </form>
{/if}
<script>
    var isEdit = false;
</script>
<script src="{$BASE_URL}javascript/validateuserform.js"></script>
{include file='common/footer.tpl'}