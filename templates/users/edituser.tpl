{include file='common/header.tpl'}

{if !$EMAIL}
    <p>Tem que fazer login.</p>
{else}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}

    <form method="post" action="{$BASE_URL}actions/users/edituser.php">
        <label>
            Novo Email:
            <input type="email" name="email" placeholder="{$EMAIL}" value="{$FORM_VALUES.email}"/>
            <span>{$FIELD_ERRORS.email}</span><br/>
        </label>
        <label>
            Nova Password:
            <input type="password" name="password" placeholder="Password"/>
            <span>{$FIELD_ERRORS.password}</span><br/>
        </label>
        <label>
            Confirmar Nova Password:
            <input type="password" name="passwordconfirm" placeholder="Confirmar Password"/>
            <span>{$FIELD_ERRORS.passwordconfirm}</span><br/>
        </label>

        <label>
            Password Antiga:
            <input type="password" name="oldpassword" placeholder="Password Antiga" required/>
            <span>{$FIELD_ERRORS.oldpassword}</span><br/>
        </label>

        <button type="submit">Editar</button><br>
    </form>
{/if}

{include file='common/footer.tpl'}