{include file='common/header.tpl'}

{if $EMAIL}

    <!-- start: PAGE -->
<div class="main-content">
    <div class="container">
        <!-- start: PAGE HEADER -->
        <div class="row">
            <div class="col-sm-12">
                <!-- start: PAGE TITLE & BREADCRUMB -->
                <ol class="breadcrumb">
                    <li>
                        <i class="clip-grid-6 active"></i>
                        <a href="#"> Procedimentos </a>
                    </li>
                </ol>
                <div class="page-header">
                    {if $PROCEDURE.readonly}
                        <h1>Ver registo</h1>
                    {else}
                        <h1>Editar registo</h1>
                    {/if}

                </div>
                <!-- end: PAGE TITLE & BREADCRUMB -->
            </div>
        </div>
        <!-- end: PAGE HEADER -->
        <!-- start: PAGE CONTENT -->
        <div class="row">
            <div class="col-md-12">
                <!-- start: FORM VALIDATION 1 PANEL -->
                <div class="panel panel-default">
                    <div class="panel-heading">
                        <i class="fa fa-file-text-o"></i>
                        {if $PROCEDURE.readonly}
                            Ver registo
                        {else}
                            Editar registo
                        {/if}
                    </div>

                    <div class="panel-body">
                        <div class="alert alert-danger" role="alert" style="display: none">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="errorMessageNamePrivate" class="errorMessage"></span>
                        </div>
                        <div class="alert alert-danger" role="alert" style="display: none">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="errorMessageNameProfessional" class="errorMessage"></span>
                        </div>
                        <div class="alert alert-danger" role="alert" style="display: none">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="errorMessageNifProfessional" class="errorMessage"></span>
                        </div>
                        <div class="alert alert-danger" role="alert" style="display: none">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="errorMessageLicenseIdProfessional" class="errorMessage"></span>
                        </div>
                        <div class="alert alert-danger" role="alert" style="display: none">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="errorMessageNifPatient" class="errorMessage"></span>
                        </div>
                        <div class="alert alert-danger" role="alert" style="display: none">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="errorMessageNamePatient" class="errorMessage"></span>
                        </div>
                        <div class="alert alert-danger" role="alert" style="display: none">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="errorMessageCellphonePatient" class="errorMessage"></span>
                        </div>
                        <div class="alert alert-danger" role="alert" style="display: none">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="errorMessageKs" class="errorMessage"></span>
                        </div>

                        {if $FIELD_ERRORS.name}
                            <div class="alert alert-danger" role="alert">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span>{$FIELD_ERRORS.name}</span>
                            </div>
                        {/if}
                        {if $FIELD_ERRORS.namePrivate}
                            <div class="alert alert-danger" role="alert">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span>{$FIELD_ERRORS.namePrivate}</span>
                            </div>
                        {/if}
                        <form action="{$BASE_URL}actions/procedures/editprocedure.php" role="form" id="form"
                              method="post">
                            <input type="hidden" id="idProcedure" name="idprocedure" value="{$PROCEDURE.idprocedure}"/>
                            {if $PROCEDURE.readonly}
                                <input type="hidden" id="readOnly" name="readonly" value="1"/>
                            {else}
                                <input type="hidden" id="readOnly" name="readonly" value="0"/>
                            {/if}
                            <div class="row">
                                <div class="col-md-12">
                                    <div class="errorHandler alert alert-danger no-display">
                                        <i class="fa fa-times-sign"></i> Ocorreu um erro. Por favor verifique o
                                        formulário.
                                    </div>
                                    <div class="successHandler alert alert-success no-display">
                                        <i class="fa fa-ok"></i> Profissional registado com sucesso
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="form-group">
                                        <label class="control-label">
                                            Data
                                        </label>
                                        <input value="{$PROCEDURE.date}" type="date" placeholder="DD/MM/AAAA"
                                               name="date" class="form-control">
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="form-group">
                                        <label class="control-label">
                                            Função
                                        </label>
                                        <select id="role" name="role" class="form-control">
                                            <option value="General">Cirurgião Principal</option>
                                            <option value="FirstAssistant">Primeiro Asistente</option>
                                            <option value="SecondAssistant">Segundo Assistente</option>
                                            <option value="Instrumentist">Insturmentista</option>
                                            <option value="Anesthetist">Anestesista</option>
                                        </select>
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="form-group">
                                        <label class="control-label">
                                            Estado do pagamento
                                        </label>
                                        <select name="status" id="paymentStatus" class="form-control">
                                            <option value="Pendente">Pendente</option>
                                            <option value="Recebi">Recebi</option>
                                            <option value="Paguei">Paguei</option>
                                        </select>
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="form-group">
                                        <label class="control-label">
                                            Organização
                                        </label>
                                        <select name="organization" id="idOrganization" class="form-control">
                                            <option value="-1">Nenhuma</option>
                                            {foreach $ORGANIZATIONS as $organization}
                                                <option value="{$organization.idorganization}">{$organization.name}</option>
                                            {/foreach}
                                        </select>
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-12">
                                    <h2><i class="fa fa-user"></i> Identificação do doente</h2>
                                    <hr>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label class="control-label">
                                            Escolha o paciente
                                        </label>
                                        <select id="idPatient" name="idPatient" class="form-control">
                                            <option value="-2">Novo doente</option>
                                            <option value="-1">Nenhum</option>
                                            {foreach $PATIENTS as $patient}
                                                <option value="{$patient.idpatient}">{$patient.name}</option>
                                            {/foreach}
                                        </select>
                                    </div>

                                    {if !$PROCEDURE.readonly}
                                        <span id="patientForm">
                                            <div class="form-group">
                                                <label class="control-label">
                                                    Nome <span class="symbol required"></span>
                                                </label>
                                                <input type="text" placeholder="Nome" class="form-control"
                                                       id="namePatient"
                                                       name="namePatient" value>
                                            </div>
                                            <div class="form-group">
                                                <label class="control-label">
                                                    Contacto
                                                </label>
                                                <input type="text" placeholder="Contacto" class="form-control"
                                                       id="cellphonePatient" name="cellphonePatient">
                                            </div>
                                            <div class="form-group">
                                                <label class="control-label">
                                                    NIF
                                                </label>
                                                <input type="text" placeholder="NIF" class="form-control"
                                                       id="nifPatient"
                                                       name="nifPatient">
                                            </div>
                                            <div class="form-group">
                                                <label class="control-label">
                                                    Nº de beneficiário
                                                </label>
                                                <input type="text" placeholder="Nº de beneficiário" class="form-control"
                                                       id="beneficiaryNrPatient" name="beneficiaryNrPatient">
                                            </div>
                                        </span>
                                    {/if}
                                </div>
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label class="control-label">
                                            Escolha o responsável
                                        </label>
                                        <select id="idPayer" name="idPrivatePayer" class="form-control">
                                            <option value="NewPrivate">Novo privado</option>
                                            {foreach $ENTITIES['Privado'] as $entity}
                                                196
                                                <option value="{$entity.idprivatepayer}">{$entity.name}</option>
                                                197                                                {/foreach}
                                        </select>
                                    </div>

                                    {if !$PROCEDURE.readonly}
                                        <span id="newPrivatePayer">
                                            <div class="form-group">
                                                <label class="control-label">
                                                    Nome <span class="symbol required"></span>
                                                </label>
                                                <input type="text" name="namePrivate" id="namePrivate"
                                                       placeholder="Nome"
                                                       value="{$FORM_VALUES.namePrivate}"
                                                       maxlength="40"/>
                                            </div>
                                        </span>
                                    {/if}

                                    <div class="form-group">
                                        <label class="control-label">
                                            Valor por K:
                                        </label>
                                        <input type="number" name="valuePerK" id="valuePerK" min="0" step="0.01"
                                               value="{$FORM_VALUES.VALUEPERK}"/>
                                    </div>
                                </div>
                            </div>
                            <div class="row" id="subProcedures">
                                <div class="col-md-12">
                                    <h2><i class="fa fa-medkit"></i> Actos médicos</h2>
                                    <hr>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-group" id="subProcedureMenu">
                                        <input type="hidden" name="nSubProcedures" id="nSubProcedures" value="0">
                                        <button class="btn btn-blue btn-block" id="addSubProcedure">
                                            Adicionar <i class="fa fa-plus"></i>
                                        </button>
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-12">
                                    <h2><i class="fa fa-user-md"></i> Equipa</h2>
                                    <hr>
                                </div>
                                <div class="col-md-12">
                                    <table class="teamTable table table-hover">
                                        <thead>
                                        <tr>
                                            <th class="center">Nome</th>
                                            <th class="center hidden-xs">Função</th>
                                            <th class="center hidden-xs">Cédula</th>
                                            <th class="center"></th>
                                            <th class="center hidden-xs">% de K</th>
                                            <th class="center">Remuneração</th>
                                        </tr>
                                        </thead>
                                        <tbody>
                                        <tr id="GeneralRow">
                                            <td>
                                                <input type="text" name="generalName" class="professionalName form-control"
                                                       id="generalName"
                                                       value="{$PROCEDURE.professionals.general.name}"/></td>
                                            <td class="center hidden-xs">Cirurgião Principal</td>
                                            <td class="center hidden-xs">
                                                <input type="text" name="generaltLicenseId"
                                                       class="professionalLicenseId form-control"
                                                       value="{$PROCEDURE.professionals.general.licenseid}"/>
                                            </td>
                                            <td></td>
                                            <td class="center">
                                                <input type="number" class="kValue form-control" min="0" max="100" value="{$PROCEDURE.generalk}"
                                                       name="generalK" id="generalK" required/>
                                            </td>
                                            <td class="center">
                                                <input type="text" name="generalRemun" id="generalRemun" class="form-control"
                                                       style="background-color: lightgrey" value="0" readonly></td>
                                        </tr>
                                        <tr id="FirstAssistantRow">
                                            <td><input type="text" name="firstAssistantName" class="professionalName form-control"
                                                       id="firstAssistantName"
                                                       value="{$PROCEDURE.professionals.firstassistant.name}"/></td>
                                            <td class="center hidden-xs ">1º Ajudante</td>
                                            <td class="center hidden-xs"><input type="text"
                                                                                name="firstAssistantLicenseId"
                                                                                class="professionalLicenseId form-control"
                                                                                value="{$PROCEDURE.professionals.firstassistant.licenseid}"/>
                                            </td>
                                            <td></td>
                                            <td class="center">
                                                <input type="number" class="kValue form-control" min="0" max="100" value="{$PROCEDURE.firstassistantk}"
                                                       name="firstAssistantK" id="firstAssistantK" required/>
                                            </td>
                                            <td class="center"><input type="text" name="firstAssistantRemun"
                                                                      id="firstAssistantRemun" class="form-control"
                                                                      style="background-color: lightgrey" value="0"
                                                                      readonly></td>
                                        </tr>
                                        <tr id="SecondAssistantRow">
                                            <td><input type="text" name="secondAssistantName" class="professionalName form-control"
                                                       id="secondAssistantName"
                                                       value="{$PROCEDURE.professionals.secondassistant.name}"/></td>
                                            <td class="center hidden-xs">2º Ajudante</td>
                                            <td class="center hidden-xs"><input type="text"
                                                                                name="secondAssistantLicenseId"
                                                                                class="professionalLicenseId form-control"
                                                                                value="{$PROCEDURE.professionals.secondassistant.licenseid}"/>
                                            </td>
                                            <td></td>
                                            <td class="center">
                                                <input type="number" class="kValue form-control" min="0" max="100" value="{$PROCEDURE.secondassistantk}"
                                                       name="secondAssistantK" id="secondAssistantK" required/>
                                            </td>
                                            <td class="center"><input type="text" name="secondAssistantRemun"
                                                                      id="secondAssistantRemun" class="form-control"
                                                                      style="background-color: lightgrey" value="0"
                                                                      readonly></td>
                                        </tr>
                                        <tr id="InstrumentistRow">
                                            <td><input type="text" name="instrumentistName" class="professionalName form-control"
                                                       id="instrumentistName"
                                                       value="{$PROCEDURE.professionals.instrumentist.name}"/></td>
                                            <td class="center hidden-xs">Instrumentista</td>
                                            <td class="center hidden-xs"><input type="text"
                                                                                name="instrumentistAssistantLicenseId"
                                                                                class="professionalLicenseId form-control"
                                                                                value="{$PROCEDURE.professionals.instrumentist.licenseid}"/>
                                            </td>
                                            <td></td>
                                            <td class="center">
                                                <input type="number" class="kValue form-control" min="0" max="100" value="{$PROCEDURE.instrumentistk}"
                                                       name="instrumentistK" id="instrumentistK" required/>
                                            </td>
                                            <td class="center"><input type="text" name="instrumentistRemun"
                                                                      id="instrumentistRemun" class="form-control"
                                                                      style="background-color: lightgrey" value="0"
                                                                      readonly></td>
                                        </tr>

                                        <tr id="AnesthetistRow">
                                            <td><input type="text" name="anesthetistName" class="professionalName form-control"
                                                       id="anesthetistName"
                                                       value="{$PROCEDURE.professionals.anesthetist.name}"/></td>
                                            <td class="center hidden-xs">Anestesista</td>
                                            <td class="center hidden-xs"><input type="text"
                                                                                name="anesthetistAssistantLicenseId"
                                                                                class="professionalLicenseId form-control"
                                                                                value="{$PROCEDURE.professionals.anesthetist.licenseid}"/>
                                            </td>
                                            <td class="center">
                                                <a data-toggle="modal" class="btn" role="button" href="#myModal2"><i class="clip-search-2"></i></a>
                                            </td>
                                            <td class="center">
                                                <input type="number" class="kValue form-control" min="0" max="100" value="{$PROCEDURE.anesthetistk}"
                                                       name="anesthetistK" id="anesthetistK" required/>
                                            </td>
                                            <td class="center"><input type="text" name="anesthetistRemun"
                                                                      id="anesthetistRemun" class="form-control"
                                                                      style="background-color: lightgrey" value="0"
                                                                      readonly>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td></td>
                                            <td class="hidden-xs"></td>
                                            <td class="hidden-xs"></td>
                                            <td class="center">Total
                                                <select name="totalType" id="totalType">
                                                    <option value="auto">Por K</option>
                                                    <!-- <option value="manual">Manual</option> -->
                                                </select></td>
                                            <td class="center"><input type="text" name="totalRemun" id="totalRemun"
                                                                      style="background-color: lightgrey" value="0" class="form-control"
                                                                      readonly value="{$PROCEDURE.totalremun}"></td>
                                        </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                            <div class="modal fade" id="myModal2" tabindex="-1" role="dialog" aria-hidden="true" style="display: none;">
                                <div class="modal-dialog">
                                    <div class="modal-content">
                                        <div class="modal-header">
                                            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">
                                                ×
                                            </button>
                                            <h4 class="modal-title">TNVROM - Anestesia</h4>
                                        </div>
                                        <div class="modal-body">
                                            <p>
                                                Cirurgia superior a 900K: 300K
                                                <br> Cirurgia de 900 a 801K: 255K
                                                <br> Cirurgia de 800 a 701K: 225K
                                                <br> Cirurgia de 700 a 601K: 195K
                                                <br> Cirurgia de 600 a 561K: 175K
                                                <br> Cirurgia de 560 a 511K: 160K
                                                <br> Cirurgia de 510 a 481K: 150K
                                                <br> Cirurgia de 480 a 461K: 140K
                                                <br> Cirurgia de 460 a 421K: 130K
                                                <br> Cirurgia de 420 a 401K: 120K
                                                <br> Cirurgia de 400 a 341K: 110K
                                                <br> Cirurgia de 340 a 301K: 95K
                                                <br> Cirurgia de 300 a 281K: 87K
                                                <br> Cirurgia de 280 a 241K: 78K
                                                <br> Cirurgia de 240 a 201K: 66K
                                                <br> Cirurgia de 200 a 181K: 57K
                                                <br> Cirurgia de 180 a 161K: 51K
                                                <br> Cirurgia de 160 a 141K: 45K
                                                <br> Cirurgia de 140 a 121K: 39K
                                                <br> Cirurgia de 120 a 101K: 33K
                                                <br> Cirurgia de 100 a 81K: 27K
                                                <br> Cirurgia inferior a 81K: 27K
                                            </p>
                                        </div>
                                        <div class="modal-footer">
                                            <button class="btn btn-default" data-dismiss="modal">
                                                Fechar
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <hr>
                                <div class="col-md-3">
                                    <div class="form-group">
                                        <button class="btn btn-blue btn-block" type="submit" id="submitButton">
                                            Editar <i class="fa fa-save"></i>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
                <!-- end: FORM VALIDATION 1 PANEL -->
            </div>
        </div>
        <!-- end: PAGE CONTENT-->

        <span style="display: none" id="activeTab">procedure</span>
        <script src="{$BASE_URL}lib/handlebars-v1.3.0.js" type="text/javascript"></script>
        <script id="subProcedure-template" type="text/x-handlebars-template">
            {literal}
                <div id="subProcedure{{number}}">
                    <div class="col-md-12">
                        <div class="form-group">
                            <label class="control-label">
                            </label>
                            <select name="subProcedure{{number}}" class="subProcedure form-control">
                                {{{type}}}
                            </select>
                        </div>
                    </div>

                    <div class="col-md-6">
                        <div class="form-group">
                            <label class="control-label">
                                Código OM <span class="symbol required"></span>
                            </label>
                            <input class="subProcedureCode form-control" value="01.00.00.01" type="text" size="12">
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="form-group">
                            <label class="control-label">
                                K
                            </label>
                            <input value="10" type="text" size="3" class="form-control" disabled>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="form-group">
                            <label class="control-label">
                                C
                            </label>
                            <input value="0" type="text" size="3" class="form-control" disabled>
                        </div>
                    </div>
                    <div class="col-md-9">
                        <div class="form-group">
                            <label class="control-label">
                                Procedimento
                            </label>
                            <input class="subProcedureName  form-control"
                                   value="Consultas no Consultório - Não Especialista-1a. Consulta"
                                   type="text">
                        </div>
                    </div>
                    <!--
                    <div class="col-md-2">
                        <div class="form-group">
                            <label class="control-label">
                                Anestesia local
                            </label>

                            <div class="form-control" style="border: 0px; box-shadow: none">
                                <input id="localanesthesia" name="localanesthesia" type="checkbox">
                            </div>
                        </div>
                    </div>
                    -->
                    <div class="col-md-1">
                        <div class="form-group">
                            <label class="control-label">
                                Apagar
                            </label>
                            <button class="btn btn-red btn-block removeSubProcedureButton" subProcedureNr="{{number}}">
                                <i class="fa fa-times"></i>
                            </button>
                        </div>
                    </div>
                </div>
            {/literal}
        </script>
        <script type="text/javascript">
            var isEdit = false;
            var myName = "{$NAME}";
            var myLicenseId = "{$LICENSEID}";
            var privatePayers = {$ENTITIES['Privado']|json_encode};
            var patients = {$PATIENTS|json_encode};
            var baseUrl = {$BASE_URL};
            var method = "editProcedure";

            $("#paymentStatus").val("{$PROCEDURE.paymentstatus}");
            $("#idOrganization").val("{$PROCEDURE.idorganization}");
            $("#idPatient").val("{$PROCEDURE.idpatient}");
            $("#role").val("{$PROCEDURE.role}");

            var editValuePerK = {$PROCEDURE.valueperk};
            var editProcedurePayerId = {$PROCEDURE.idpayer};
            var editSubProcedures = {$PROCEDURE.subprocedures|json_encode};
            var editAnesthetistK = "{$PROCEDURE.anesthetistk}";

            {if $PROCEDURE.hasmanualk}
            var editHasManualK = true;
            {else}
            var editHasManualK = false;
            {/if}

            {if $PROCEDURE.localanesthesia}
            $("#localanesthesia").prop("checked", "true");
            {/if}

            {if $PROCEDURE.readonly}
            var isReadOnly = true;
            $("#addSubProcedure, #submitButton, input, select").attr("disabled", true);
            $("#idOrganization, #readOnly, #idProcedure").attr("disabled", false);
            {else}
            var isReadOnly = false;
            {/if}
        </script>
        <script src="{$BASE_URL}javascript/addprocedure.js"></script>
        {if !$PROCEDURE.readonly}
            <script src="{$BASE_URL}javascript/subprocedureslist.js"></script>
            <script src="{$BASE_URL}javascript/subprocedureslist2.js"></script>
            <script src="{$BASE_URL}javascript/validatepayerform.js"></script>
            <script src="{$BASE_URL}javascript/validateprofessionalform.js"></script>
            <script src="{$BASE_URL}javascript/validatepatientform.js"></script>
        {/if}
        {else}
        <p>Tem que fazer login!</p>
        {/if}

{include file='common/footer.tpl'}