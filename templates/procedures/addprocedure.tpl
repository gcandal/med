{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <p>Dados do Procedimento</p>
    <hr>
    <form id="formprocedure" method="post" action="{$BASE_URL}actions/procedures/addprocedure.php">
        <label>
            Estado de pagamento:
            <select name="status" required>
                <option value="Pendente">Pendente</option>
                <option value="Recebi">Recebi</option>
                <option value="Paguei">Paguei</option>
            </select>
        </label>
        <label>
            Tipo de pagador:
            <select id="entityType" required>
                <option value="Privado">Privado</option>
                <option value="Entidade">Entidade</option>
                <option value="Novo Privado">Novo Privado</option>
                <option value="Nova Entidade">Nova Entidade</option>
            </select>
        </label>

        <span id="privatePayer">
            <select name="privateName" required>
                {foreach $ENTITIES['Privado'] as $entity}
                    <option value="{$entity.idprivatepayer}">{$entity.name}</option>
                {/foreach}
            </select>
        </span>

        <span id="entityPayer">
            <select name="entityName" required>
            {foreach $ENTITIES['Entidade'] as $entity}
                    <option value="{$entity.identitypayer}">{$entity.name}</option>
                {/foreach}
            </select>
        </span>

        <span id="newEntityPayer">
            <label>
                NIF:
                <input type="text" name="privatePayerNIF" placeholder="123456789" value="{$FORM_VALUES.NIF}"/>
            </label>
        </span>

        <span id="newPrivatePayer">
            <label>
                NIF:
                <input type="text" name="privatePayerNIF" placeholder="123456789" value="{$FORM_VALUES.NIF}"/>
            </label>
            <label>
                Início de Contrato:
                <input type="date" name="contractStartDate" placeholder="Data do Procedimento"
                       value="{$FORM_VALUES.CONTRACTSTARTDATE}"/>
            </label>
            <label>
                Fim de Contrato:
                <input type="date" name="contractEndDate" placeholder="Data do Procedimento"
                       value="{$FORM_VALUES.CONTRACTENDDATE}"/>
            </label>
        </span>

        <span id="valuePerK">
            <label>
                Valor por K:
                <input type="text" name="valuePerK" value="{$FORM_VALUES.VALUEPERK}"/>
            </label>
        </span>

        <label>
        Data:
            <input type="date" name="date" placeholder="Data do Procedimento" value="{$FORM_VALUES.DATE}"/>
        </label>

        <button type="submit">Submeter</button>

        <br>
        <hr>

        <p>Informações Pessoais</p>

        <label>
            Função a Desempenhar:
            <select id="function" name="function">
            <option value="Principal">Cirurgião Principal</option>
                <option value="Ajudante">Ajudante</option>
                <option value="Anestesista">Anestesista</option>
            </select>
        </label>

        <span id="principal">
            <p>Equipa</p>
            <table class="teamTable" border="1">
                <tr>
                    <th>Nome</th>
                    <th>Função</th>
                    <th>NIF</th>
                    <th>Percentagem de K</th>
                    <th>Remuneração</th>
                </tr>
                <tr>
                    <td><input type="text" name="firstAssistantName" value="{$FORM_VALUES.FIRSTASSISTANTNAME}"/></td>
                    <td>1º Ajudante</td>
                    <td><input type="text" name="firstAssistantNIF" value="{$FORM_VALUES.FIRSTASSISTANTNIF}"/></td>
                    <td>20%</td>
                    <td><input type="text" name="firstAssistantRemun" readonly value="0"></td>
                </tr>
                <tr>
                    <td><input type="text" name="secondAssistantName" value="{$FORM_VALUES.SECONDASSISTANTNAME}"/></td>
                    <td>2º Ajudante</td>
                    <td><input type="text" name="secondAssistantNIF" value="{$FORM_VALUES.SECONDASSISTANTNIF}"/></td>
                    <td>10%</td>
                    <td><input type="text" name="secondAssistantRemun" readonly value="0"></td>
                </tr>
                <tr>
                    <td><input type="text" name="instrumentistName" value="{$FORM_VALUES.INSTRUMENTISTNAME}"/></td>
                    <td>Instrumentista</td>
                    <td><input type="text" name="instrumentistNIF" value="{$FORM_VALUES.INSTRUMENTISTNIF}"/></td>
                    <td>10%</td>
                    <td><input type="text" name="instrumentistRemun" readonly value="0"></td>
                </tr>
                <tr>
                    <td><input type="text" name="anesthetistName" value="{$FORM_VALUES.ANESTHETISTNAME}"/></td>
                    <td>Anestesista</td>
                    <td><input type="text" name="anesthetistNIF" value="{$FORM_VALUES.ANESTHETISTNIF}"/></td>
                    <td>
                        <select id="anesthetistK">
                            <option value="25">25%</option>
                            <option value="30">30%</option>
                            <option value="table">Tabela OM</option>
                        </select>
                    </td>
                    <td><input type="text" name="anesthetistRemun" readonly value="0"></td>
                </tr>
                <tr>
                    <td></td>
                    <td></td>
                    <td></td>
                    <td>Total
                        <select name="totalType">
                            <option value="auto">Por K</option>
                            <option value="manual">Manual</option>
                        </select></td>
                    <td><input type="text" name="totalRemun" readonly value="0"></td>
                </tr>
                <tr>
                    <td></td>
                    <td></td>
                    <td></td>
                    <td>Pessoal</td>
                    <td><input type="text" name="personalRemun" readonly value="0"></td>
                </tr>
            </table>
        </span>

        <span id="ajudante">
            <p>Responsável</p>
                <table class="teamTable" border="1">
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
        <span id="subProcedureMenu">
            <input type="hidden" id="nSubProcedures" value="0">
            <button type="button" id="addSubProcedure">Adicionar</button>
            <button type="button" id="removeSubProcedure">Remover</button>
            <br>
        </span>

        <span id="subProcedures">
        </span>
    </form>
    <script type="text/javascript">
        var subProcedures = 1;
        var subProcedureTypes = {$PROCEDURETYPES|json_encode};
        var privatePayers = {$ENTITIES['Privado']|json_encode};
        var entityPayers = {$ENTITIES['Entidade']|json_encode};
        var baseUrl = {$BASE_URL};
    </script>
    <script src="{$BASE_URL}javascript/addprocedure.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}