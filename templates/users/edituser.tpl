{include file='common/header.tpl'}

{if !$EMAIL}
    <p>Tem que fazer login.</p>
{else}
    <span id="emailError"></span>
    <span id="licenseIdError"></span>
    <span id="passwordError"></span>
    <form id="edituserform" method="post" action="{$BASE_URL}actions/users/edituser.php">
        <label>
            Novo Email:
            <input type="email" name="email" id="userName" placeholder="{$EMAIL}" value="{$FORM_VALUES.email}"
                   maxlength="254"/>
            <span>{$FIELD_ERRORS.email}</span><br/>
        </label>
        <label>
            Nova Password:
            <input type="password" id="password" name="password" placeholder="Password"/>
            <span>{$FIELD_ERRORS.password}</span><br/>
        </label>
        <label>
            Confirmar Nova Password:
            <input type="password" id="passwordconfirm" name="passwordconfirm" placeholder="Confirmar Password"/>
            <span>{$FIELD_ERRORS.passwordconfirm}</span><br/>
        </label>

        <label>
            Password Antiga:
            <input type="password" name="oldpassword" placeholder="Password Antiga" required/>
            <span>{$FIELD_ERRORS.oldpassword}</span><br/>
        </label>

        <button type="submit" id="submitButton">Editar</button>
        <br>
    </form>

    <script>
        var isEdit = true;
    </script>
    <script src="{$BASE_URL}javascript/validateuserform.js"></script>
{/if}
{include file='common/footer.tpl'}