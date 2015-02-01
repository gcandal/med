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
                    <h1>Criar registo</h1>
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
                        Novo registo
                    </div>

                    <div class="panel-body">
                        <div class="alert alert-danger" role="alert" style="display: none">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="errorMessageNamePrivate" class="errorMessagePrivate"></span>
                        </div>
                        <div class="alert alert-danger" role="alert" style="display: none">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="errorMessageNifPrivate" class="errorMessagePrivate"></span>
                        </div>
                        <div class="alert alert-danger" role="alert" style="display: none">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="errorMessageNameEntity" class="errorMessageEntity"></span>
                        </div>
                        <div class="alert alert-danger" role="alert" style="display: none">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="errorMessageNifEntity" class="errorMessageEntity"></span>
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

                        <form action="{$BASE_URL}actions/professionals/addprofessional.php" role="form" id="form"
                              novalidate="novalidate" method="post">
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
                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label class="control-label">
                                            Data
                                        </label>
                                        <input type="date" placeholder="DD/MM/AAAA" name="date" class="form-control">
                                    </div>
                                </div>
                                <div class="col-md-4">
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
                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label class="control-label">
                                            Estado do pagamento
                                        </label>
                                        <select name="status" class="form-control">
                                            <option value="Pendente">Pendente</option>
                                            <option value="Recebi">Recebi</option>
                                            <option value="Paguei">Paguei</option>
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
                                        <select id="idPatient" class="form-control">
                                            <option value="-2">Novo doente</option>
                                            <option value="-1">Nenhum</option>
                                            {foreach $PATIENTS as $patient}
                                                <option value="{$patient.idpatient}">{$patient.name}</option>
                                            {/foreach}
                                        </select>
                                    </div>


                                    <span id="patientForm">
                                        <div class="form-group">
                                            <label class="control-label">
                                                Nome <span class="symbol required"></span>
                                            </label>
                                            <input type="text" placeholder="Nome" class="form-control" id="namePatient"
                                                   name="namePatient" value required>
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
                                            <input type="text" placeholder="NIF" class="form-control" id="nifPatient"
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
                                </div>
                                <div class="col-md-6">
                                    <div class="form-group">
                                        <label class="control-label">
                                            Escolha o responsável
                                        </label>
                                        <select id="entityType" class="form-control">
                                            <option value="Private">Privado</option>
                                            <option value="Entity">Seguradora/Hospital</option>
                                            <option value="NewPrivate">Novo privado</option>
                                            <option value="NewEntity">Nova Seguradora</option>
                                        </select>
                                    </div>

                                    <input type="hidden" id="payerType" name="payerType" value="None"/>

                                    <span id="privatePayer">
                                        <div class="form-group">
                                            <select name="privateName" id="privateName" class="form-control">
                                                {foreach $ENTITIES['Privado'] as $entity}
                                                    <option value="{$entity.idprivatepayer}">{$entity.name}</option>
                                                {/foreach}
                                            </select>
                                        </div>
                                    </span>
                                    <span id="entityPayer">
                                        <div class="form-group">
                                            <select name="entityName" id="entityName" class="form-control">
                                                {foreach $ENTITIES['Entidade'] as $entity}
                                                    <option value="{$entity.identitypayer}">{$entity.name}</option>
                                                {/foreach}
                                            </select>
                                        </div>
                                    </span>
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
                                        <div class="form-group">
                                            <label class="control-label">
                                                NIF <span class="symbol required"></span>
                                            </label>
                                            <input type="number" name="nifPrivate" id="nifPrivate"
                                                   placeholder="NIF"
                                                   value="{$FORM_VALUES.nifPrivate}"/>
                                        </div>
                                    </span>
                                    <span id="newEntityPayer">
                                        <div class="form-group">
                                            <label class="control-label">
                                                Nome <span class="symbol required"></span>
                                            </label>
                                            <input type="text" name="nameEntity" id="nameEntity"
                                                   placeholder="Nome"
                                                   value="{$FORM_VALUES.nameEntity}"
                                                   maxlength="40"/>
                                        </div>
                                        <div class="form-group">
                                            <label class="control-label">
                                                NIF <span class="symbol required"></span>
                                            </label>
                                            <input type="number" name="nifEntity" id="nifEntity"
                                                   placeholder="NIF"
                                                   value="{$FORM_VALUES.nifEntity}"/>
                                        </div>
                                    </span>

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
                                    <table class="table table-hover" id="sample-table-1">
                                        <thead>
                                        <tr>
                                            <th class="center">Nome</th>
                                            <th class="center hidden-xs">Função</th>
                                            <th class="center hidden-xs">Cédula</th>
                                            <th class="center hidden-xs">% de K</th>
                                            <th class="center">Remuneração</th>
                                        </tr>
                                        </thead>
                                        <tbody>
                                        <tr>
                                            <td>José Silva</td>
                                            <td class="center hidden-xs">Cirurgião</td>
                                            <td class="center hidden-xs">123123</td>
                                            <td class="center">30%</td>
                                            <td class="center">120€</td>
                                        </tr>
                                        <tr>
                                            <td>João Silva</td>
                                            <td class="center hidden-xs">1º Ajudante</td>
                                            <td class="center hidden-xs">156123</td>
                                            <td class="center">20%</td>
                                            <td class="center">80€</td>
                                        </tr>
                                        <tr>
                                            <td>Ana Silva</td>
                                            <td class="center hidden-xs">2º Ajudante</td>
                                            <td class="center hidden-xs">156623</td>
                                            <td class="center">10%</td>
                                            <td class="center">40€</td>
                                        </tr>
                                        <tr>
                                            <td>Carlos Silva</td>
                                            <td class="center hidden-xs">Instrumentista</td>
                                            <td class="center hidden-xs">887333</td>
                                            <td class="center">10%</td>
                                            <td class="center">40€</td>
                                        </tr>
                                        <tr>
                                            <td>António Silva</td>
                                            <td class="center hidden-xs">Anestesista</td>
                                            <td class="center hidden-xs">1872223</td>
                                            <td class="center">30%</td>
                                            <td class="center">120€</td>
                                        </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                            <div class="row">
                                <hr>
                                <div class="col-md-3">
                                    <div class="form-group">
                                        <button class="btn btn-blue btn-block" type="submit" id="submitButton">
                                            Guardar <i class="fa fa-save"></i>
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

        <span style="display: none" id="activeTab">addprocedure</span>
        <script src="{$BASE_URL}lib/handlebars-v1.3.0.js" type="text/javascript"></script>
        <script id="subProcedure-template" type="text/x-handlebars-template">
            {literal}
                <div id="subProcedure{{number}}">
                    <select name="subProcedure{{number}}" class="subProcedure" style="display: none">
                        {{{type}}}
                    </select>

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