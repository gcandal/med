{foreach $ERROR_MESSAGES as $error}
    <p>{$error}</p>
{/foreach}

<form method="post" action="{$BASE_URL}actions/users/login.php">
    <label>
        Email:
        <input type="email" name="email" placeholder="Email" value="{$FORM_VALUES.email}" required/><br>
    </label>
    <label>
        Password:
        <input type="password" name="password" placeholder="Password" required/><br>
    </label>
    <button type="submit">Entrar</button><br>
</form>

<form action="{$BASE_URL}pages/users/register.php">
    <button type="submit">Registar</button>
</form>