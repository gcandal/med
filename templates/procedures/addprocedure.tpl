{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <script src="{$BASE_URL}javascript/addprocedure.js"></script>
    <form id="formprocedure" method="post" action="{$BASE_URL}actions/procedures/addprocedure.php">
        {$PROCEDURETYPES}
        <label>
            Estado de pagamento:
            <select name="status" required>
                <option value="Recebi">Recebi</option>
                <option value="Paguei">Paguei</option>
                <option value="Nada">Nada</option>
            </select>
        </label>
        <label>
            Tipo de pagador:
            <select id="entityType" required>
                <option value="Privado">Privado</option>
                <option value="Entidade">Entidade</option>
            </select>
        </label>

        <span id="privatePayer">
            <label>
                NIF:
                <input type="text" name="privatePayerNIF" placeholder="123456789" value="{$FORM_VALUES.NIF}"/>
            </label>
        </span>

        <span id="entityPayer">
            <select name="entity" required>
                {foreach $ENTITIES['Entidade'] as $entity}
                    <option value="{$entity.identitypayer}">{$entity.name}</option>
                {/foreach}
            </select>
        </span>

        <label>
            Data:
            <input type="date" name="date" placeholder="Data do Procedimento"
                   value="{$FORM_VALUES.date}"/>
        </label>
        <button type="submit">Submeter</button>
        <br>
        <hr>
        <p>
            Sub-Procedimentos
        </p>
        <span id="subProcedures">
            <input type="hidden" id="nSubProcedures" value="0">
            <button type="button" id="addSubProcedure">Adicionar</button>
            <button type="button" id="removeSubProcedure">Remover</button>
            <br>
        </span>
    </form>
    <script type="text/javascript">
        var subProcedures = 1;
        var subProcedureTypes = {$PROCEDURETYPES|json_encode}
                $(document).ready(function () {
                    addSubProcedure();

                    $('#addSubProcedure').click(function () {
                        addSubProcedure();
                        subProcedures++;
                        console.log(subProcedures);
                        $('#nSubProcedures').value = subProcedures;
                    });


                    $('#removeSubProcedure').click(function () {
                        removeSubProcedure();
                        subProcedures--;
                        $('#nSubProcedures').value = subProcedures;
                    })

                });

        var getSubProcedureTypes = function () {
            var result = "";
            for (var i = 0; i < subProcedureTypes.length; i++) {
                result += '<option value = "' + subProcedureTypes[i].idproceduretype + '">' + subProcedureTypes[i].name + '</option>';
            }
            return result;
            console.log(result);
        }

        var addSubProcedure = function () {
            $('<select name="subProcedure"+subProcedures>' + getSubProcedureTypes() + '</select>').fadeIn('slow').appendTo('#subProcedures');
        }

        var removeSubProcedure = function () {
            console.log(subProcedures);
            if (subProcedures > 1) {
                $('#subProcedures:last').remove();
            }
            console.log(subProcedures);
        }
    </script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}