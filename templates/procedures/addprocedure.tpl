{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <script src="{$BASE_URL}javascript/addprocedure.js"></script>
    <form id="formprocedure" method="post" action="{$BASE_URL}actions/procedures/addprocedure.php">
        <label>
            Estado de pagamento:
            <select name="status" required>
                <option value="Nada">Nada</option>
                <option value="Recebi">Recebi</option>
                <option value="Paguei">Paguei</option>
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
            <input type="date" name="date" placeholder="Data do Procedimento" value="{$FORM_VALUES.date}"/>
        </label>

        <button type="submit">Submeter</button>

        <br>
        <hr>

        <p>Informações Pessoais</p>

        <label>
            Função a Desempenhar:
            <select id="function">
                <option value="Chefe">Chefe</option>
                <option value="Assistente">Assistente</option>
                <option value="Anestesista">Anestesista</option>
            </select>
        </label>

        <p>Colaboradores</p>

        <span id="chefe">
            <table class="colabTable" border="1">
                <tr>
                    <th>Nome</th>
                    <th>Especialidade</th>
                    <th>Função</th>
                    <th>Cédula</th>
                    <th>Telefone/Telemóvel</th>
                    <th>Email</th>
                    <th>K</th>
                    <th>Remuneração</th>
                </tr>
                <tr>
                    <td><input type="text" name="firstAssistantName" value="{$FORM_VALUES.FIRSTASSISTANTNAME}"/></td>
                    <td>
                        <select name="firstAssistantSpeciality" id="specialities">
                        </select>
                    </td>
                    <td>1º Assistente</td>
                    <td>Row:1 Cell:4</td>
                    <td>Row:1 Cell:5</td>
                </tr>
                <tr>
                    <td>Row:2 Cell:1</td>
                    <td>
                        <select name="secondAssistantSpeciality" id="specialities">
                        </select>
                    </td>
                    <td>2º Assistente</td>
                    <td>Row:2 Cell:4</td>
                    <td>Row:2 Cell:5</td>
                </tr>
                <tr>
                    <td>Row:3 Cell:1</td>
                    <td>
                        -
                    </td>
                    <td>Instrumentista</td>
                    <td>Row:3 Cell:4</td>
                    <td>Row:3 Cell:5</td>
                </tr>
                <tr>
                    <td>Row:4 Cell:1</td>
                    <td>
                        <select>
                            <option>Anestesista</option>
                        </select>
                    </td>
                    <td>Anestesista</td>
                    <td>Row:4 Cell:4</td>
                    <td>Row:4 Cell:5</td>
                </tr>
            </table>
        </span>
        <br>
        <hr>

        <p>Sub-Procedimentos </p>
        <span class="subProcedureMenu">
            <input type="hidden" id="nSubProcedures" value="0">
            <button type="button" id="addSubProcedure">Adicionar</button>
            <button type="button" id="removeSubProcedure">Remover</button>
            <br>
        </span>
        <span id="subProcedures">
        </span>
        <br>
        <button type="submit">Submeter</button>
    </form>
    <script type="text/javascript">
        var subProcedures = 1;
        var subProcedureTypes = {$PROCEDURETYPES|json_encode};
        var specialities = {$SPECIALITIES|json_encode};

        $(document).ready(function () {
            fillSpecialities();

            addSubProcedure();

            $('#addSubProcedure').click(function () {
                subProcedures++;
                addSubProcedure();
                $('#nSubProcedures').value = subProcedures;
                console.log(subProcedures);
            });


            $('#removeSubProcedure').click(function () {
                removeSubProcedure();
                $('#nSubProcedures').value = subProcedures;
                console.log(subProcedures);
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

        var fillSpecialities = function () {
            var result = "";
            for (var i = 0; i < specialities.length; i++) {
                result += '<option value = "' + specialities[i].idspeciality + '">' + specialities[i].name +
                        '</option>';
            }
            console.log(result);
            $('select#specialities').append(result);
        }

        var addSubProcedure = function () {
            $('<select name="subProcedure' + subProcedures + '" id="subProcedure">' + getSubProcedureTypes() +
                    '</select><br>').fadeIn('slow').appendTo('#subProcedures');

        }
        var removeSubProcedure = function () {
            if (subProcedures > 1) {
                $('#subProcedures br:last').remove();
                $('#subProcedures select:last').remove();
                subProcedures--;
            }
        }
    </script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}