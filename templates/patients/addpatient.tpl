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
                            <a href="#"> Doentes </a>
                        </li>
                    </ol>
                    <div class="page-header">
                        <h1>Adicionar doente</h1>
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
                            Formulário de doentes
                        </div>
                        <div class="panel-body">
                            <h2><i class="fa fa-pencil-square teal"></i> Registo de doentes</h2>
                            <hr>

                            <div class="alert alert-danger" role="alert">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span id="errorMessageNifPatient" class="errorMessage"></span>
                            </div>
                            <div class="alert alert-danger" role="alert">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span id="errorMessageNamePatient" class="errorMessage"></span>
                            </div>
                            <div class="alert alert-danger" role="alert">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span id="errorMessageCellphonePatient" class="errorMessage"></span>
                            </div>
                            {if $FIELD_ERRORS.name}
                                <div class="alert alert-danger" role="alert">
                                    <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                    <span>{$FIELD_ERRORS.name}</span>
                                </div>
                            {/if}
                            <form method="post" action="{$BASE_URL}actions/patients/addpatient.php" role="form" id="form">
                                <div class="row">
                                    <div class="col-md-12">
                                        <div class="errorHandler alert alert-danger no-display">
                                            <i class="fa fa-times-sign"></i> Ocorreu um erro. Por favor verifique o formulário.
                                        </div>
                                        <div class="successHandler alert alert-success no-display">
                                            <i class="fa fa-ok"></i> Doente registado com sucesso
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label class="control-label">
                                                Nome <span class="symbol required"></span>
                                            </label>
                                            <input type="text" placeholder="Nome" class="form-control" id="namePatient" name="name" value required>
                                        </div>
                                        <div class="form-group">
                                            <label class="control-label">
                                                NIF
                                            </label>
                                            <input type="number" placeholder="NIF" class="form-control" id="nifPatient" name="nif">
                                        </div>
                                        <div class="form-group">
                                            <label class="control-label">
                                                Telefone
                                            </label>
                                            <input type="number" placeholder="Telefone" class="form-control" name="cellphone" id="cellphonePatient">
                                        </div>
                                        <div class="form-group">
                                            <label class="control-label">
                                                Nº de beneficiário
                                            </label>
                                            <input type="text" placeholder="Nº de beneficiário" class="form-control" id="beneficiaryNrPatient" name="beneficiarynr">
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-12">
                                        <div>
                                            <span class="symbol required"></span>Campos obrigatórios
                                            <hr>
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-3">
                                        <button class="btn btn-blue btn-block" type="submit" id="submitButton">
                                            Registar <i class="fa fa-arrow-circle-right"></i>
                                        </button>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                    <!-- end: FORM VALIDATION 1 PANEL -->
                </div>
            </div>
            <!-- end: PAGE CONTENT-->
        </div>
    </div>
    <!-- end: PAGE -->

    <span style="display: none" id="activeTab">addpatient</span>
    <script>
        const isEdit = false;
    </script>
    <script src="{$BASE_URL}javascript/validatepatientform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}