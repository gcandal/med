{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <span id="errorMessage"></span>
    <form method="post" action="{$BASE_URL}actions/organizations/addorganization.php">
        <label>
            Nome:
            <input type="text" id="name" name="name" placeholder="Nome" value="{$FORM_VALUES.name}" required
                   maxlength="40" />
            <span>{$FIELD_ERRORS.name}</span>
        </label>
        <button type="submit" id="submitButton">Adicionar</button>
    </form>
{else}
    <p>Tem que fazer login!</p>
{/if}
<script type="text/javascript">
    var baseUrl = {$BASE_URL};
    var isEdit = false;
</script>
<script src="{$BASE_URL}javascript/validateorganizationform.js"></script>
{include file='common/footer.tpl'}