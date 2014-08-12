{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <form id="formprocedure" method="post" action="{$BASE_URL}actions/procedures/addprocedure.php">

        <label>
            Função a Desempenhar:
            <select id="function" name="function">
                <option value="Principal">Cirurgião Principal</option>
                <option value="Ajudante">Ajudante</option>
                <option value="Anestesista">Anestesista</option>
            </select>
        </label>
        <label>
            Data:
            <input type="date" name="date" placeholder="Data do Procedimento" value="{$FORM_VALUES.DATE}"/>
        </label>
        <button type="submit">Submeter</button>

        <hr>
        <span id="principal">
            <label>
                Estado de pagamento:
                <select name="status" required>
                    <option value="Pendente">Pendente</option>
                    <option value="Recebi">Recebi</option>
                    <option value="Paguei">Paguei</option>
                </select>
            </label>
            <label>
                <select id="entityType" required>
                    <option value="Privado">Privado</option>
                    <option value="Entidade">Entidade</option>
                    <option value="Novo Privado">Novo Privado</option>
                    <option value="Nova Entidade">Nova Entidade</option>
                </select>

                <script>
                    if ("{$ENTITYTYPE}" !== 'None') {
                        if ("{$ENTITYTYPE}" === 'Private')
                            $("select#entityType").val("Novo Privado");
                        else
                            $("select#entityType").val("Nova Entidade");
                    }
                </script>
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

        <input type="hidden" id="payerType" name="payerType" value="None" required/>

        <span id="valuePerK">
            <label>
                Valor por K:
                <input type="text" name="valuePerK" value="{$FORM_VALUES.VALUEPERK}"/>
            </label>
        </span>


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
            </table>
            <p>Sub-Procedimentos </p>
        <span id="subProcedureMenu">
            <input type="hidden" name="nSubProcedures" value="0">
            <button type="button" id="addSubProcedure">Adicionar</button>
            <button type="button" id="removeSubProcedure">Remover</button>
            <br>
        </span>

        <span id="subProcedures">
        </span>
        </span>
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
                        <td><input type="text" name="masterName" value="{$FORM_VALUES.MASTERNAME}"/></td>
                        <td><input type="text" name="masterNIF" value="{$FORM_VALUES.MASTERNIF}"</td>
                        <td><input type="text" name="masterLicense" value="{$FORM_VALUES.MASTERLICENCE}"</td>
                        <td><input type="text" name="masterEmail" value="{$FORM_VALUES.MASTEREMAIL}"</td>
                        <td><input type="text" name="masterCell" value="{$FORM_VALUES.MASTERPHONE}"></td>
                    </tr>
                </table>


</span>
        <table>
            <tr>
                <td></td>
                <td></td>
                <td></td>
                <td>Remuneração Pessoal</td>
                <td><input type="text" name="personalRemun" readonly value="0"></td>
            </tr>
        </table>
        <br>
        <hr>

    </form>
    <script type="text/javascript">
        var subProcedureTypes = {$PROCEDURETYPES|json_encode};
        var privatePayers = {$ENTITIES['Privado']|json_encode};
        var entityPayers = {$ENTITIES['Entidade']|json_encode};
        var baseUrl = {$BASE_URL};
    </script>
    <script src="{$BASE_URL}lib/handlebars-v1.3.0.js" type="text/javascript"></script>
    <script id="newPrivatePayer-template" type="text/x-handlebars-template">
        <span id="newPrivatePayer">
            <label>
                Nome:
                <input type="text" name="name" placeholder="Nome" value="{$FORM_VALUES.name}" maxlength="40" required/>
                <span>{$FIELD_ERRORS.name}</span>
            </label>

            <label>
                NIF:
                <input type="number" id="nifPrivate" min="0" name="nif" placeholder="NIF" value="{$FORM_VALUES.nif}"
                       {literal}pattern="\d{9}"{/literal} maxlength="9" required />
                <span id="niferrorPrivate">{$FIELD_ERRORS.nif}</span>
            </label>
        </span>
    </script>
    <script id="newEntityPayer-template" type="text/x-handlebars-template">
        <span id="newEntityPayer">
            <label>
                Nome:
                <input type="text" name="name" placeholder="Nome" value="{$FORM_VALUES.name}" maxlength="40" required/>
                <span>{$FIELD_ERRORS.name}</span>
            </label>
            <label>
                Início do Contrato:
                <input type="date" name="contractstart" id="contractstart" placeholder="Início do Contrato"
                       value="{$FORM_VALUES.contractstart}"/>
            </label>
            <label>
                Fim do Contrato:
                <input type="date" name="contractend" id="contractend" placeholder="Fim do Contrato"
                       value="{$FORM_VALUES.contractend}"/>
            </label>
            <span id="dateerror"></span>
            <label>
                NIF:
                <input type="number" min="0" name="nif" id="nifEntity" placeholder="NIF" value="{$FORM_VALUES.nif}"
                       {literal}pattern="\d{9}"{/literal} maxlength="9" required/>
                <span id="niferrorEntity">{$FIELD_ERRORS.nif}</span>
            </label>
        </span>
    </script>
    <script src="{$BASE_URL}javascript/addprocedure.js"></script>
    <script src="{$BASE_URL}javascript/validateaddprocedureform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}