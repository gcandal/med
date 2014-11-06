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
    <button id="submitButton" type="submit" disabled>Submeter</button>

    <hr/>
        <span id="principal">
            <label>
                Estado de pagamento:
                <select name="status" required>
                    <option value="Pendente">Pendente</option>
                    <option value="Recebi">Recebi</option>
                    <option value="Paguei">Paguei</option>
                </select>
            </label>
     <br/><br/>

    <span class="errorMessagePrivate" id="errorMessageNamePrivate"></span>
    <span class="errorMessagePrivate" id="errorMessageNifPrivate"></span>
    <span class="errorMessageEntity" id="errorMessageNameEntity"></span>
    <span class="errorMessageEntity" id="errorMessageNifEntity"></span>
    <span class="errorMessageEntity" id="errorMessageDate"></span>
    <span class="errorMessage" id="errorMessageNameProfessional"></span>
    <span class="errorMessage" id="errorMessageNifProfessional"></span>
    <span class="errorMessage" id="errorMessageLicenseIdProfessional"></span>


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
                    <input type="number" id="nifPrivate" min="0" name="nifPrivate" placeholder="NIF"
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
                <input type="text" name="valuePerK" id="valuePerK" value="{$FORM_VALUES.VALUEPERK}"/>
            </label>
        </span>


            <p>Equipa</p>
            <table class="teamTable" border="1">
                <tr>
                    <th>Nome</th>
                    <th>Função</th>
                    <th>Cédula</th>
                    <th>NIF</th>
                    <th>Especialidade</th>
                    <th>Percentagem de K</th>
                    <th>Remuneração</th>
                </tr>
                <tr>
                    <td><input type="text" name="firstAssistantName" class="professionalName" id="firstAssistantName"
                               value="{$FORM_VALUES.FIRSTASSISTANTNAME}"/></td>
                    <td>1º Ajudante</td>
                    <td><input type="text" name="firstAssistantLicenseId" class="professionalLicenseId"
                               value="{$FORM_VALUES.FIRSTASSISTANTLICENSEID}"/></td>
                    <td><input type="text" name="firstAssistantNIF" class="professionalNif"
                               value="{$FORM_VALUES.FIRSTASSISTANTNIF}"/></td>
                    <td>
                        <select name="firstAssistantIdSpeciality" id="firstAssistantIdSpeciality">
                            <option value="3">Nenhuma</option>
                            {foreach $SPECIALITIES as $speciality}
                                <option value="{$speciality.idspeciality}">{$speciality.name}</option>
                            {/foreach}
                        </select>
                    </td>
                    <td>20%</td>
                    <td><input type="text" name="firstAssistantRemun" id="firstAssistantRemun"
                               style="background-color: lightgrey" readonly
                               value="0"></td>
                </tr>
                <tr>
                    <td><input type="text" name="secondAssistantName" class="professionalName" id="secondAssistantName"
                               value="{$FORM_VALUES.SECONDASSISTANTNAME}"/></td>
                    <td>2º Ajudante</td>
                    <td><input type="text" name="secondAssistantLicenseId" class="professionalLicenseId"
                               value="{$FORM_VALUES.SECONDASSISTANTLICENSEID}"/></td>
                    <td><input type="text" name="secondAssistantNIF" class="professionalNif"
                               value="{$FORM_VALUES.SECONDASSISTANTNIF}"/></td>
                    <td>
                        <select name="secondAssistantIdSpeciality" id="secondAssistantIdSpeciality">
                            <option value="3">Nenhuma</option>
                            {foreach $SPECIALITIES as $speciality}
                                <option value="{$speciality.idspeciality}">{$speciality.name}</option>
                            {/foreach}
                        </select>
                    </td>
                    <td>10%</td>
                    <td><input type="text" name="secondAssistantRemun" id="secondAssistantRemun"
                               style="background-color: lightgrey" readonly
                               value="0"></td>
                </tr>
                <tr>
                    <td><input type="text" name="instrumentistName" class="professionalName" id="instrumentistName"
                               value="{$FORM_VALUES.INSTRUMENTISTNAME}"/></td>
                    <td>Instrumentista</td>
                    <td><input type="text" name="instrumentistAssistantLicenseId" class="professionalLicenseId"
                               value="{$FORM_VALUES.INSTRUMENTISTLICENSEID}"/></td>
                    <td><input type="text" name="instrumentistNIF" class="professionalNif"
                               value="{$FORM_VALUES.INSTRUMENTISTNIF}"/></td>
                    <td>
                    </td>
                    <td>10%</td>
                    <td><input type="text" name="instrumentistRemun" id="instrumentistRemun"
                               style="background-color: lightgrey" readonly
                               value="0"></td>
                </tr>

                <tr>
                    <td><input type="text" name="anesthetistName" class="professionalName" id="anesthetistName"
                               value="{$FORM_VALUES.ANESTHETISTNAME}"/></td>
                    <td>Anestesista</td>
                    <td><input type="text" name="anesthetistAssistantLicenseId" class="professionalLicenseId"
                               value="{$FORM_VALUES.ANESTHETISTLICENSEID}"/></td>
                    <td><input type="text" name="anesthetistNIF" class="professionalNif"
                               value="{$FORM_VALUES.ANESTHETISTNIF}"/></td>
                    <td>
                    </td>
                    <td>
                        <select id="anesthetistK">
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
            <p>Sub-Procedimentos </p>
        <span id="subProcedureMenu">
            <input type="hidden" name="nSubProcedures" id="nSubProcedures" value="0">
            <button type="button" id="addSubProcedure">Adicionar</button>
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
            <td><input type="text" name="personalRemun" id="personalRemun" style="background-color: lightgrey" readonly
                       value="0"></td>
        </tr>
    </table>
    <br>
    </form>
    <script src="{$BASE_URL}lib/handlebars-v1.3.0.js" type="text/javascript"></script>
    <script id="subProcedure-template" type="text/x-handlebars-template">
        {literal}
            <span id="subProcedure{{number}}">
                <select name="subProcedure{{number}}" class="subProcedure">
                    {{{type}}}<br>
                </select>
                <button class="removeSubProcedureButton" subProcedureNr="{{number}}">X</button>
            </span>
        {/literal}
    </script>
    <script type="text/javascript">
        var subProcedureTypes = {$PROCEDURETYPES|json_encode};
        var privatePayers = {$ENTITIES['Privado']|json_encode};
        var entityPayers = {$ENTITIES['Entidade']|json_encode};
        var baseUrl = {$BASE_URL};
        var method = "addProcedure";
        $("#entityType").val("{$ENTITYTYPE}");
    </script>
    <script src="{$BASE_URL}javascript/addpayer.js"></script>
    <script src="{$BASE_URL}javascript/addprocedure.js"></script>
    <script src="{$BASE_URL}javascript/validatepayerform.js"></script>
    <script src="{$BASE_URL}javascript/validateprofessionalform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}