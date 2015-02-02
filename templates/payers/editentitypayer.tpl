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
                            <div class="alert alert-danger" role="alert" style="display: none;">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span id="errorMessageNamePrivate" class="errorMessagePrivate"></span>
                            </div>
                            <div class="alert alert-danger" role="alert" style="display: none;">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span id="errorMessageNifPrivate" class="errorMessagePrivate"></span>
                            </div>
                            <div class="alert alert-danger" role="alert" style="display: none;">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span id="errorMessageNameEntity" class="errorMessageEntity"></span>
                            </div>
                            <div class="alert alert-danger" role="alert" style="display: none;">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span id="errorMessageNifEntity" class="errorMessageEntity"></span>
                            </div>
                            <div class="alert alert-danger" role="alert" style="display: none;">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span id="errorMessageDate" class="errorMessageEntity"></span>
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
                                    {if $FIELD_ERRORS.nif}
                                        <div class="alert alert-danger" role="alert">
                                            <span class="glyphicon glyphicon-exclamation-sign"
                                                  aria-hidden="true"></span>
                                            <span>{$FIELD_ERRORS.nif}</span>
                                        </div>
                                    {/if}
                                    <form id="formentidade" method="post"
                                          action="{$BASE_URL}actions/payers/editentitypayer.php">
                                        <input type="hidden" name="type" id="entityType" value="NewEntity" required/>
                                        <input type="hidden" name="identitypayer" value="{$entitypayer.identitypayer}"/>

                                        <div class="form-group">
                                            <label class="control-label">
                                                Nome
                                            </label>

                                            <input type="text" name="name" id="nameEntity"
                                                   placeholder="{$entitypayer.name}"
                                                   value="{$FORM_VALUES.name}"
                                                   maxlength="40" class="form-control"/>
                                            <span>{$FIELD_ERRORS.name}</span>
                                        </div>

                                        <div class="form-group">
                                            <label class="control-label">
                                                Início do contracto
                                            </label>

                                            <input type="date" name="contractstart" id="contractstart"
                                                   placeholder="{$entitypayer.contractstart}" class="form-control"
                                                   value="{$FORM_VALUES.contractstart}"/>
                                        </div>

                                        <div class="form-group">
                                            <label class="control-label">
                                                Fim do contracto
                                            </label>

                                            <input type="date" name="contractend" id="contractend"
                                                   placeholder="{$entitypayer.contractend}" class="form-control"
                                                   value="{$FORM_VALUES.contractend}"/>
                                            <span id="dateerror"></span>
                                        </div>
                                        <div class="form-group">
                                            <label class="control-label">
                                                NIF
                                            </label>

                                            <input type="number" min="0" name="nif" id="nifEntity"
                                                   placeholder="{$entitypayer.nif}"
                                                   value="{$FORM_VALUES.nif}" class="form-control"/>
                                            <span id="niferrorEntity">{$FIELD_ERRORS.nif}</span>
                                        </div>
                                        <div class="form-group">
                                            <label class="control-label">
                                                K cirúrgico
                                            </label>

                                            <input type="number" min="0" step="0.01" name="valueperk"
                                                   placeholder="{$entitypayer.valueperk}"
                                                   value="{$FORM_VALUES.valueperk}"
                                                   class="form-control"/>
                                            <span>{$FIELD_ERRORS.valueperk}</span>
                                        </div>

                                        <div class="row">
                                            <div class="col-md-3">
                                                <button id="submitButtonEntity" class="btn btn-blue btn-block"
                                                        type="submit">
                                                    Editar <i class="fa fa-arrow-circle-right"></i>
                                                </button>
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
        var isEdit = true;
    </script>
    <script src="{$BASE_URL}javascript/validatepayerform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}