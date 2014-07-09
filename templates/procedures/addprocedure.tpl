{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <script src="{$BASE_URL}javascript/addprocedure.js"></script>
    <p>Dados do Procedimento</p>
    <hr>
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
            <label>
                Valor por K:
                <input type="text" name="valuePerK" placeholder="2" value="{$FORM_VALUES.VALUEPERK}"/>
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

        <span id="chefe">
            <p>Colaboradores</p>
            <table class="colabTable" border="1">
                <tr>
                    <th>Nome</th>
                    <th>Função</th>
                    <th>NIF</th>
                    <th>Percentagem de K</th>
                    <th>Remuneração</th>
                </tr>
                <tr>
                    <td><input type="text" name="firstAssistantName" value="{$FORM_VALUES.FIRSTASSISTANTNAME}"/></td>
                    <td>1º Assistente</td>
                    <td><input type="text" name="firstAssistantNIF" value="{$FORM_VALUES.FIRSTASSISTANTNIF}"/></td>
                    <td>20%</td>
                    <td><input type="text" name="firstAssistantRemun" readonly></td>
                </tr>
                <tr>
                    <td><input type="text" name="secondAssistantName" value="{$FORM_VALUES.SECONDASSISTANTNAME}"/></td>
                    <td>2º Assistente</td>
                    <td><input type="text" name="secondAssistantNIF" value="{$FORM_VALUES.SECONDASSISTANTNIF}"/></td>
                    <td>10%</td>
                    <td><input type="text" name="SecondAssistantRemun" readonly></td>
                </tr>
                <tr>
                    <td><input type="text" name="instrumentistName" value="{$FORM_VALUES.INSTRUMENTISTNAME}"/></td>
                    <td>Instrumentista</td>
                    <td><input type="text" name="instrumentistNIF" value="{$FORM_VALUES.INSTRUMENTISTNIF}"/></td>
                    <td>10%</td>
                    <td><input type="text" name="instrumentistRemun" readonly></td>
                </tr>
                <tr>
                    <td><input type="text" name="anesthetistName" value="{$FORM_VALUES.ANESTHETISTNAME}"/></td>
                    <td>Anestesista</td>
                    <td><input type="text" name="anesthetistNIF" value="{$FORM_VALUES.ANESTHETISTNIF}"/></td>
                    <td><input type="number" name="firstAssistantK" value="{$FORM_VALUES.FIRSTASSISTANTK}" min="25"/>%
                    </td>
                    <td><input type="text" name="anesthetistRemun" readonly></td>
                </tr>
            </table>
        </span>

        <span id="assistente">
            <p>Responsável</p>
                <table class="colabTable" border="1">
                    <tr>
                        <th>Nome</th>
                        <th>NIF</th>
                        <th>Cédula</th>
                        <th>Email</th>
                        <th>Telefone</th>
                    </tr>
                    <tr>
                        <td><input type="text" name="accountableName" value="{$FORM_VALUES.ACCOUNTABLENAME}"/></td>
                        <td><input type="text" name="accountableNIF" value="{$FORM_VALUES.ACCOUNTABLENIF}"</td>
                        <td><input type="text" name="accountableLicense" value="{$FORM_VALUES.ACCOUNTABLELICENCE}"</td>
                        <td><input type="text" name="accountableEmail" value="{$FORM_VALUES.ACCOUNTABLEEMAIL}"</td>
                        <td><input type="text" name="accountbalePhone" value="{$FORM_VALUES.ACCOUNTABLEPHONE}"></td>
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
        /*var specialities = {$SPECIALITIES|json_encode};

         fillSpecialities();*/
        $(document).ready(function () {

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