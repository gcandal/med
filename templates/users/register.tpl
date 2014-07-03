{include file='common/header.tpl'}

{if $EMAIL}
    <p>Já está registado!</p>
{else}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <form method="post" action="{$BASE_URL}actions/users/register.php">
        <label>
            Nome:
            <input type="text" name="name" placeholder="Nome" value="{$FORM_VALUES.name}" required/>
            <span>{$FIELD_ERRORS.username}</span>
        </label>
        <label>
            Email:
            <input type="email" name="email" placeholder="Email" value="{$FORM_VALUES.email}" required/>
            <span>{$FIELD_ERRORS.email}</span><br/>
        </label>
        <label>
            Cédula Médica:
            <input type="text" name="licenseid" placeholder="Cédula Médica" value="{$FORM_VALUES.licenseid}"
                   {literal}pattern="\d{9}"{/literal} required/>
            <span>{$FIELD_ERRORS.licenseid}</span><br/>
        </label>
        <label>
            Password:
            <input type="password" name="password" placeholder="Password" required/>
            <span>{$FIELD_ERRORS.password}</span><br/>
        </label>
        <label>
            Confirmar Password:
            <input type="password" name="passwordconfirm" placeholder="Confirmar Password" required/>
            <span>{$FIELD_ERRORS.passwordconfirm}</span><br/>
        </label>
        <button type="submit">Registar</button>
        <br>
    </form>
{/if}

{include file='common/footer.tpl'}