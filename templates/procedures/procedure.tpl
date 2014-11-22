{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}


    <form id="formprocedure" method="post" action="{$BASE_URL}actions/procedures/editprocedure.php">
        <input type="hidden" name="idprocedure" value="{$PROCEDURE.idprocedure}"/>
        <span class="errorMessagePrivate" id="errorMessageNamePrivate"></span>
        <span class="errorMessagePrivate" id="errorMessageNifPrivate"></span>
        <span class="errorMessageEntity" id="errorMessageNameEntity"></span>
        <span class="errorMessageEntity" id="errorMessageNifEntity"></span>
        <span class="errorMessage" id="errorMessageNameProfessional"></span>
        <span class="errorMessage" id="errorMessageNifProfessional"></span>
        <span class="errorMessage" id="errorMessageLicenseIdProfessional"></span>

        <label>
            Data:
            <input type="date" name="date" placeholder="Data do Registo" value="{$PROCEDURE.date}"/>
        </label>
        <label>
            Função:
            <select id="role" name="role" required>
                <option value="General">Cirurgião Principal</option>
                <option value="FirstAssistant">Primeiro Asistente</option>
                <option value="SecondAssistant">Segundo Assistente</option>
                <option value="Anesthetist">Anestesista</option>
                <option value="Instrumentist">Insturmentista</option>
            </select>
        </label>
        <button id="submitButton" type="submit" disabled>Editar</button>
        <br>

        <label>
            Estado de pagamento:
            <select name="status" id="paymentStatus" required>
                <option value="Pendente">Pendente</option>
                <option value="Recebi">Recebi</option>
                <option value="Paguei">Paguei</option>
            </select>
        </label>

        <p>Cirurgias</p>

        <p id="subProcedureMenu">
            <input type="hidden" name="nSubProcedures" id="nSubProcedures" value="0">
            <button type="button" id="addSubProcedure">Adicionar</button>
            <br>
        </p>
        <p id="subProcedures"></p>

        <label>
            Pagador:
            <select id="entityType" required>
                <option value="Private">Privado</option>
                <option value="Entity">Entidade</option>
                <option value="NewPrivate">Novo Privado</option>
                <option value="NewEntity">Nova Entidade</option>
            </select>
        </label>

            <span id="privatePayer">
                <select name="privateName" id="privateName">
                    {foreach $ENTITIES['Privado'] as $entity}
                        <option value="{$entity.idprivatepayer}">{$entity.name}</option>
                    {/foreach}
                </select>
            </span>

            <span id="entityPayer">
                <select name="entityName" id="entityName">
                    {foreach $ENTITIES['Entidade'] as $entity}
                        <option value="{$entity.identitypayer}">{$entity.name}</option>
                    {/foreach}
                </select>
            </span>

            <span id="newPrivatePayer">
                <label>
                    Nome:
                    <input type="text" name="namePrivate" id="namePrivate" placeholder="Nome"
                           value="{$FORM_VALUES.namePrivate}"
                           maxlength="40"/>
                    <span>{$FIELD_ERRORS.name}</span>
                </label>

                <label>
                    NIF:
                    <input type="number" id="nifPrivate" name="nifPrivate" placeholder="NIF"
                           value="{$FORM_VALUES.nifPrivate}"
                           {literal}pattern="\d{9}"{/literal} maxlength="9"/>
                    <span id="niferrorPrivate">{$FIELD_ERRORS.nif}</span>
                </label>
            </span>

            <span id="newEntityPayer">
                <label>
                    Nome:
                    <input type="text" name="nameEntity" id="nameEntity" placeholder="Nome" value="{$FORM_VALUES.name}"
                           maxlength="40"/>
                    <span>{$FIELD_ERRORS.nameEntity}</span>
                </label>
                <label>
                    NIF:
                    <input type="number" min="0" name="nifEntity" id="nifEntity" placeholder="NIF"
                           value="{$FORM_VALUES.nifEntity}"
                           {literal}pattern="\d{9}"{/literal} maxlength="9"/>
                    <span id="niferrorEntity">{$FIELD_ERRORS.nif}</span>
                </label>
            </span>

        <input type="hidden" id="payerType" name="payerType" value="None"/>

        <span>
            <label>
                Valor por K:
                <input type="number" name="valuePerK" id="valuePerK" min="0" step="0.01"
                       value="{$FORM_VALUES.VALUEPERK}"/>
            </label>
        </span>


        <p>Equipa</p>
        <table class="teamTable" border="1">
            <tr>
                <th>Nome</th>
                <th>Função</th>
                <th>Cédula</th>
                <th>Percentagem de K</th>
                <th>Remuneração</th>
            </tr>
            <tr id="GeneralRow">
                <td><input type="text" name="generalName" class="professionalName" id="generalName"
                           value="{$PROCEDURE.professionals.general.name}"/></td>
                <td>Cirurgião Principal</td>
                <td><input type="text" name="generaltLicenseId" class="professionalLicenseId"
                           value="{$PROCEDURE.professionals.general.licenseid}"/></td>
                <td id="generalK">100%</td>
                <td><input type="text" name="generalRemun" id="generalRemun"
                           style="background-color: lightgrey" readonly></td>
            </tr>
            <tr id="FirstAssistantRow">
                <td><input type="text" name="firstAssistantName" class="professionalName" id="firstAssistantName"
                           value="{$PROCEDURE.professionals.firstassistant.name}"/></td>
                <td>1º Ajudante</td>
                <td><input type="text" name="firstAssistantLicenseId" class="professionalLicenseId"
                           value="{$PROCEDURE.professionals.firstassistant.licenseid}"/></td>
                <td>20%</td>
                <td><input type="text" name="firstAssistantRemun" id="firstAssistantRemun"
                           style="background-color: lightgrey" readonly></td>
            </tr>
            <tr id="SecondAssistantRow">
                <td><input type="text" name="secondAssistantName" class="professionalName" id="secondAssistantName"
                           value="{$PROCEDURE.professionals.secondassistant.name}"/></td>
                <td>2º Ajudante</td>
                <td><input type="text" name="secondAssistantLicenseId" class="professionalLicenseId"
                           value="{$PROCEDURE.professionals.secondassistant.licenseid}"/></td>
                <td>10%</td>
                <td><input type="text" name="secondAssistantRemun" id="secondAssistantRemun"
                           style="background-color: lightgrey" readonly></td>
            </tr>
            <tr id="InstrumentistRow">
                <td><input type="text" name="instrumentistName" class="professionalName" id="instrumentistName"
                           value="{$PROCEDURE.professionals.instrumentist.name}"/></td>
                <td>Instrumentista</td>
                <td><input type="text" name="instrumentistAssistantLicenseId" class="professionalLicenseId"
                           value="{$PROCEDURE.professionals.instrumentist.licenseid}"/></td>
                <td>10%</td>
                <td><input type="text" name="instrumentistRemun" id="instrumentistRemun"
                           style="background-color: lightgrey" readonly></td>
            </tr>

            <tr id="AnesthetistRow">
                <td><input type="text" name="anesthetistName" class="professionalName" id="anesthetistName"
                           value="{$PROCEDURE.professionals.anesthetist.name}"/></td>
                <td>Anestesista</td>
                <td><input type="text" name="anesthetistAssistantLicenseId" class="professionalLicenseId"
                           value="{$PROCEDURE.professionals.anesthetist.licenseid}"/></td>
                <td>
                    <select id="anesthetistK" name="anesthetistK">
                        <option value="25">25%</option>
                        <option value="30">30%</option>
                        <option value="table">Tabela OM</option>
                    </select>
                </td>
                <td><input type="text" name="anesthetistRemun" id="anesthetistRemun"
                           style="background-color: lightgrey" readonly>
                </td>
            </tr>
            <tr>
                <td></td>
                <td></td>
                <td></td>
                <td>Total
                    <select name="totalType" id="totalType">
                        <option value="auto">Por K</option>
                        <option value="manual">Manual</option>
                    </select></td>
                <td><input type="text" name="totalRemun" id="totalRemun" style="background-color: lightgrey"
                           readonly value="{$PROCEDURE.totalremun}"></td>
            </tr>
        </table>
    </form>
    <script src="{$BASE_URL}lib/handlebars-v1.3.0.js" type="text/javascript"></script>
    <script id="subProcedure-template" type="text/x-handlebars-template">
        {literal}
            <span id="subProcedure{{number}}">
                <select name="subProcedure{{number}}" class="subProcedure">
                    {{{type}}}<br>
                </select>
                <input value="15" type="text" size="3" disabled>
                <input class="subProcedureName" value="Queratoscopia fotográfica" type="text">
                <button class="removeSubProcedureButton" subProcedureNr="{{number}}">X</button>
            </span>
        {/literal}
    </script>
    <script type="text/javascript">
        var myName = "{$NAME}";
        var myLicenseId = "{$LICENSEID}";
        var subProcedureTypes = {$PROCEDURETYPES|json_encode};
        var privatePayers = {$ENTITIES['Privado']|json_encode};
        var entityPayers = {$ENTITIES['Entidade']|json_encode};
        var baseUrl = {$BASE_URL};
        var method = "editProcedure";

        $("#paymentStatus").val("{$PROCEDURE.paymentstatus}");
        $("#role").val("{$PROCEDURE.role}");

        var editProcedurePayer = {literal}{{/literal}id: {$PROCEDURE.idpayer}{literal}}{/literal};
        var editSubProcedures = {$PROCEDURE.subprocedures|json_encode};
        var editAnesthetistK = "{$PROCEDURE.anesthetistk}";


        {if $PROCEDURE.hasmanualk}
        var editHasManualK = true;
        {else}
        var editHasManualK = false;
        {/if}

        {if $PROCEDURE.idprivatepayer > 0}
        editProcedurePayer['payerType'] = "Private";
        {else}
        editProcedurePayer['payerType'] = "Entity";
        {/if}
    </script>
    <script src="{$BASE_URL}javascript/addpayer.js"></script>
    <script src="{$BASE_URL}javascript/addprocedure.js"></script>
    <script src="{$BASE_URL}javascript/validatepayerform.js"></script>
    <script src="{$BASE_URL}javascript/validateprofessionalform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}