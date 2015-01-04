{include file='common/header.tpl'}

{if $EMAIL}
    {foreach $ERROR_MESSAGES as $error}
        <p>{$error}</p>
    {/foreach}
    <form id="formprocedure" method="post" action="{$BASE_URL}actions/procedures/addprocedure.php">

        <span class="errorMessagePrivate" id="errorMessageNamePrivate"></span>
        <span class="errorMessagePrivate" id="errorMessageNifPrivate"></span>
        <span class="errorMessageEntity" id="errorMessageNameEntity"></span>
        <span class="errorMessageEntity" id="errorMessageNifEntity"></span>
        <span class="errorMessage" id="errorMessageNameProfessional"></span>
        <span class="errorMessage" id="errorMessageNifProfessional"></span>
        <span class="errorMessage" id="errorMessageLicenseIdProfessional"></span>
        <span class="errorMessage" id="errorMessageNifPatient"></span>
        <span class="errorMessage" id="errorMessageNamePatient"></span>
        <span class="errorMessage" id="errorMessageCellphonePatient"></span>
        <span class="errorMessage" id="errorMessageNrBeneficiaryPatient"></span>

        <label>
            Data:
            <input type="date" name="date" placeholder="Data do Registo" value="{$FORM_VALUES.DATE}"/>
        </label>
        <label>
            Função:
            <select id="role" name="role" required>
                <option value="General">Cirurgião Principal</option>
                <option value="FirstAssistant">Primeiro Asistente</option>
                <option value="SecondAssistant">Segundo Assistente</option>
                <option value="Instrumentist">Insturmentista</option>
                <option value="Anesthetist">Anestesista</option>
            </select>
        </label>
        <button id="submitButton" type="submit" disabled>Submeter</button>
        <br>

        <label>
            Estado de pagamento:
            <select name="status" required>
                <option value="Pendente">Pendente</option>
                <option value="Recebi">Recebi</option>
                <option value="Paguei">Paguei</option>
            </select>
        </label>


        <p>Cirurgias</p>

        <p id="subProcedureMenu">
            <input type="hidden" name="nSubProcedures" id="nSubProcedures" value="0">
            <button type="button" id="addSubProcedure">Adicionar</button>
        </p>
        <br>

        <p id="subProcedures"></p>

        <label>
            Organização:
            <select name="organization" required>
                <option value="-1">Nenhuma</option>
                {foreach $ORGANIZATIONS as $organization}
                    <option value="{$organization.idorganization}">{$organization.name}</option>
                {/foreach}
            </select>
        </label><br/>

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
                           value="{$FORM_VALUES.nifPrivate}"/>
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
                           value="{$FORM_VALUES.nifEntity}"/>
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
        </span><br/>

        <label>
            Paciente:
            <select name="idPatient" id="idPatient">
                <option value="-1">Nenhum</option>
                <option value="-2">Novo paciente</option>
                {foreach $PATIENTS as $patient}
                    <option value="{$patient.idpatient}">{$patient.name}</option>
                {/foreach}
            </select>
        </label>

        <span id="patientForm">
            <label>
                Nome:
                <input type="text" name="namePatient" id="namePatient" placeholder="Nome" value="{$FORM_VALUES.name}" required
                       maxlength="40"/>
                <span>{$FIELD_ERRORS.name}</span>
            </label>

            <label>
                NIF:
                <input type="number" id="nifPatient" min="0" name="nifPatient" placeholder="NIF"
                       value="{$FORM_VALUES.nif}"/>
                <span>{$FIELD_ERRORS.nif}</span>
            </label>

            <label>
                Telefone:
                <input type="text" name="cellphonePatient" id="cellphonePatient" placeholder="Telefone"
                       value="{$FORM_VALUES.cellphone}"/>
                <span>{$FIELD_ERRORS.cellphone}</span>
            </label>

            <label>
                Nº Beneficiário:
                <input type="number" min="0" id="beneficiaryNrPatient" name="beneficiaryNrPatient"
                       placeholder="Nº Beneficiário"
                       value="{$FORM_VALUES.beneficiarynr}"/>
                <span>{$FIELD_ERRORS.nrbeneficiary}</span>
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
                           value="{$FORM_VALUES.GENERALNAME}"/></td>
                <td>Cirurgião Principal</td>
                <td><input type="text" name="generaltLicenseId" class="professionalLicenseId"
                           value="{$FORM_VALUES.GENERALLICENSEID}"/></td>
                <td id="generalK">100%</td>
                <td><input type="text" name="generalRemun" id="generalRemun"
                           style="background-color: lightgrey" readonly
                           value="0"></td>
            </tr>
            <tr id="FirstAssistantRow">
                <td><input type="text" name="firstAssistantName" class="professionalName" id="firstAssistantName"
                           value="{$FORM_VALUES.FIRSTASSISTANTNAME}"/></td>
                <td>1º Ajudante</td>
                <td><input type="text" name="firstAssistantLicenseId" class="professionalLicenseId"
                           value="{$FORM_VALUES.FIRSTASSISTANTLICENSEID}"/></td>
                <td>20%</td>
                <td><input type="text" name="firstAssistantRemun" id="firstAssistantRemun"
                           style="background-color: lightgrey" readonly
                           value="0"></td>
            </tr>
            <tr id="SecondAssistantRow">
                <td><input type="text" name="secondAssistantName" class="professionalName" id="secondAssistantName"
                           value="{$FORM_VALUES.SECONDASSISTANTNAME}"/></td>
                <td>2º Ajudante</td>
                <td><input type="text" name="secondAssistantLicenseId" class="professionalLicenseId"
                           value="{$FORM_VALUES.SECONDASSISTANTLICENSEID}"/></td>
                <td>10%</td>
                <td><input type="text" name="secondAssistantRemun" id="secondAssistantRemun"
                           style="background-color: lightgrey" readonly
                           value="0"></td>
            </tr>
            <tr id="InstrumentistRow">
                <td><input type="text" name="instrumentistName" class="professionalName" id="instrumentistName"
                           value="{$FORM_VALUES.INSTRUMENTISTNAME}"/></td>
                <td>Instrumentista</td>
                <td><input type="text" name="instrumentistAssistantLicenseId" class="professionalLicenseId"
                           value="{$FORM_VALUES.INSTRUMENTISTLICENSEID}"/></td>
                <td>10%</td>
                <td><input type="text" name="instrumentistRemun" id="instrumentistRemun"
                           style="background-color: lightgrey" readonly
                           value="0"></td>
            </tr>

            <tr id="AnesthetistRow">
                <td><input type="text" name="anesthetistName" class="professionalName" id="anesthetistName"
                           value="{$FORM_VALUES.ANESTHETISTNAME}"/></td>
                <td>Anestesista</td>
                <td><input type="text" name="anesthetistAssistantLicenseId" class="professionalLicenseId"
                           value="{$FORM_VALUES.ANESTHETISTLICENSEID}"/></td>
                <td>
                    <select id="anesthetistK" name="anesthetistK">
                        <option value="25">25%</option>
                        <option value="30">30%</option>
                        <option value="table">Tabela OM</option>
                    </select>
                </td>
                <td><input type="text" name="anesthetistRemun" id="anesthetistRemun"
                           style="background-color: lightgrey" readonly value="0">
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
                           readonly value="0"></td>
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
                <label>
                    Nome:
                    <input class="subProcedureName" value="Consultas no Consultório - Não Especialista-1a. Consulta" type="text">
                </label>
                <label>
                    K:
                    <input value="10" type="text" size="3" disabled>
                </label>
                <label>
                    C:
                    <input value="0" type="text" size="3" disabled>
                </label>
                <label>
                    Código:
                    <input class="subProcedureCode" value="01.00.00.01" type="text" size="12">
                </label>
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
        var patients = {$PATIENTS|json_encode};
        var baseUrl = {$BASE_URL};
        var method = "addProcedure";
        $("#entityType").val("{$ENTITYTYPE}");
    </script>
    <script src="{$BASE_URL}javascript/addpayer.js"></script>
    <script src="{$BASE_URL}javascript/addprocedure.js"></script>
    <script src="{$BASE_URL}javascript/validatepayerform.js"></script>
    <script src="{$BASE_URL}javascript/validateprofessionalform.js"></script>
    <script src="{$BASE_URL}javascript/validatepatientform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}