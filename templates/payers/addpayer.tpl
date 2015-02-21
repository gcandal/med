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
                            <a href="#"> Pagadores </a>
                        </li>
                    </ol>
                    <div class="page-header">
                        <h1>Adicionar pagador</h1>
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
                            Formulário de pagadores
                        </div>
                        <div class="panel-body">
                            <h2><i class="fa fa-pencil-square teal"></i> Registo de pagadores</h2>
                            <hr>

                            <span style="display: none" id="activeTab">addpayer</span>
                            <!-- end: PAGE -->
                            <div class="alert alert-danger" role="alert">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span id="errorMessageNamePrivate" class="errorMessagePrivate"></span>
                            </div>

                            <div class="row">
                                <div class="col-md-6">
                                    {if $FIELD_ERRORS.name}
                                        <div class="alert alert-danger" role="alert">
                                            <span class="glyphicon glyphicon-exclamation-sign"
                                                  aria-hidden="true"></span>
                                            <span>{$FIELD_ERRORS.name}</span>
                                        </div>
                                    {/if}

                                    <form id="formprivado" method="post"
                                          action="{$BASE_URL}actions/payers/addpayer.php">
                                        <input type="hidden" name="type" value="Private" required/>

                                        <div class="form-group">
                                            <label class="control-label">
                                                Nome<span class="symbol required"></span>
                                            </label>

                                            <input type="text" name="name" id="namePrivate" placeholder="Nome"
                                                   value="{$FORM_VALUES.name}" required class="form-control"
                                                   maxlength="40"/>
                                            <span>{$FIELD_ERRORS.name}</span>
                                        </div>
                                        <div class="form-group">
                                            <label class="control-label">
                                                K cirúrgico
                                            </label>

                                            <input type="number" min="0" name="valueperk" placeholder="Valor por K"
                                                   value="{$FORM_VALUES.valueperk}" class="form-control"/>
                                            <span>{$FIELD_ERRORS.valueperk}</span>
                                        </div>
                                        <div class="form-group">
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
                                                    <button id="submitButton" class="btn btn-blue btn-block"
                                                            type="submit">
                                                        Registar <i class="fa fa-plus-square"></i>
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                    </form>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- end: FORM VALIDATION 1 PANEL -->
                </div>
            </div>
            <!-- end: PAGE CONTENT-->
        </div>
    </div>
    <script>
        var isEdit = false;
    </script>
    <script src="{$BASE_URL}javascript/validatepayerform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}