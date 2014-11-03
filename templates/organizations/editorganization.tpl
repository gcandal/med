{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <span id="errorMessage"></span>
    <form method="post" action="{$BASE_URL}actions/organizations/editorganization.php">
        <input type="hidden" name="idorganization" value="{$organization.idorganization}"/>

        <label>
            Nome:
            <input type="text" id="name" name="name" placeholder="{$organization.name}" value="{$FORM_VALUES.name}"
                   maxlength="40" />
            <span>{$FIELD_ERRORS.name}</span>
        </label>
        <button type="submit">Editar</button>
    </form>
{else}
    <p>Tem que fazer login!</p>
{/if}
<script type="text/javascript">
    var baseUrl = {$BASE_URL};
    var isEdit = true;
</script>
<script src="{$BASE_URL}javascript/validateorganizationform.js"></script>
{include file='common/footer.tpl'}