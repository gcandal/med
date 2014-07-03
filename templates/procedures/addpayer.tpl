{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <select id="entitytype">
        <option value="Hospital">Hospital</option>
        <option value="Insurance">Seguro</option>
        <option value="Private">Privado</option>
    </select>
    {if $FORM_VALUES.type}
        <script>
            $("select#entitytype").val("{$FORM_VALUES.type}");
        </script>
    {/if}
    <script src="{$BASE_URL}javascript/addpayer.js"></script>
    <form id="formentidade" method="post" action="{$BASE_URL}actions/procedures/addpayer.php">
        <input type="hidden" name="type" value="Insurance" required/>

        <label>
            Nome:
            <input type="text" name="name" placeholder="Nome" value="{$FORM_VALUES.name}" required/>
            <span>{$FIELD_ERRORS.name}</span>
        </label>
        <label>
            Início do Contrato:
            <input type="date" name="contractstart" placeholder="Início do Contrato"
                   value="{$FORM_VALUES.contractstart}"/>
        </label>
        <label>
            Fim do Contrato:
            <input type="date" name="contractend" placeholder="Fim do Contrato"
                   value="{$FORM_VALUES.contractend}"/>
        </label>
        <label>
            NIF:
            <input type="number" min="0" name="nif" placeholder="NIF" required
                   value="{$FORM_VALUES.nif}" {literal}pattern="\d{9}"{/literal}/>
            <span>{$FIELD_ERRORS.nif}</span>
        </label>
        <label>
            Valor por K:
            <input type="number" min="0" name="valueperk" placeholder="Valor por K"
                   value="{$FORM_VALUES.valueperk}"/>
            <span>{$FIELD_ERRORS.valueperk}</span>
        </label>
        <button type="submit">Adicionar</button>
        <br>
    </form>
    <form id="formprivado" method="post" action="{$BASE_URL}actions/procedures/addpayer.php">
        <input type="hidden" name="type" value="Private" required/>

        <label>
            Nome:
            <input type="text" name="name" placeholder="Nome" value="{$FORM_VALUES.name}"/>
            <span>{$FIELD_ERRORS.name}</span>
        </label>
        <button type="submit">Adicionar</button>
    </form>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}