{include file='common/header.tpl'}

{if !$EMAIL}
    <p>Tem que fazer login.</p>
{else}
    <!-- start: PAGE -->
    <div class="main-content">
        <div class="container">
            <!-- start: PAGE HEADER -->
            <div class="row">
                <div class="col-sm-12">
                    <!-- start: PAGE TITLE & BREADCRUMB -->
                    <ol class="breadcrumb">
                        <li>
                            <i class="clip-home-3 active"></i>
                            <a href="#">
                                O meu perfil
                            </a>
                        </li>
                    </ol>
                    <div class="page-header">
                        <h1>Perfil de utilizador</h1>
                    </div>
                    <!-- end: PAGE TITLE & BREADCRUMB -->
                </div>
            </div>
            <!-- end: PAGE HEADER -->
            <!-- start: PAGE CONTENT -->
            <div class="row">
                <div class="col-sm-12">
                    <div class="tabbable">
                        <div class="tab-content">
                            <div id="panel_overview" class="tab-pane in active">
                                <div class="row">
                                    <div class="col-sm-5 col-md-4">
                                        <div class="user-left">
                                            <div class="center">
                                                <h4>{$NAME}</h4>
                                            </div>
                                            <table class="table table-condensed table-hover">
                                                <thead>
                                                <tr>
                                                    <th colspan="3">Detalhes</th>
                                                </tr>
                                                </thead>
                                                <tbody>
                                                <tr>
                                                    <td>email:</td>
                                                    <td> {$EMAIL}</td>
                                                </tr>
                                                <tr>
                                                    <td>Especialidade</td>
                                                    <td>{$SPECIALITY}</td>
                                                </tr>
                                                <tr>
                                                    <td>Cédula</td>
                                                    <td>{$LICENSEID}</td>
                                                </tr>
                                                <tr>
                                                    <td>Licença válida até:</td>
                                                    <td>{$VALIDUNTIL}</td>
                                                </tr>
                                                <tr>
                                                    <td>Registos por usar:</td>
                                                    <td>{if $FREEREGISTERS == -1}
                                                            ilimitado
                                                        {else}
                                                            {$FREEREGISTERS}
                                                        {/if}
                                                    </td>
                                                </tr>
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                    <div class="col-sm-7 col-md-8">
                                        <div class="alert alert-danger" role="alert">
                                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                            <span id="emailError" class="errorMessage"></span>
                                        </div>
                                        <div class="alert alert-danger" role="alert">
                                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                            <span id="passwordError" class="errorMessage"></span>
                                        </div>
                                        {if $FIELD_ERRORS.oldpassword}
                                            <div class="alert alert-danger" role="alert">
                                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                                <span id="oldPasswordError" class="errorMessage">{$FIELD_ERRORS.oldpassword}</span>
                                            </div>
                                        {/if}
                                        {if $FIELD_ERRORS.passwordconfirm}
                                            <div class="alert alert-danger" role="alert">
                                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                                <span id="oldPasswordError" class="errorMessage">{$FIELD_ERRORS.passwordconfirm}</span>
                                            </div>
                                        {/if}
                                        <form action="{$BASE_URL}actions/users/edituser.php" role="form" id="form" method="post">
                                            <div class="row">
                                                <div class="col-md-12">
                                                    <h3>Editar perfil</h3>
                                                    <hr>
                                                </div>
                                                <div class="col-md-6">
                                                    <div class="form-group">
                                                        <label class="control-label">
                                                            Novo email
                                                        </label>
                                                        <input type="email" placeholder="{$EMAIL}" class="form-control"
                                                               id="email" name="email">
                                                    </div>
                                                    <div class="form-group">
                                                        <label class="control-label">
                                                            Nova palavra-passe
                                                        </label>
                                                        <input type="password" placeholder="Palavra-passe"
                                                               class="form-control" name="password" id="password">
                                                    </div>
                                                    <div class="form-group">
                                                        <label class="control-label">
                                                            Confirmar nova palavra-passe
                                                        </label>
                                                        <input type="password" placeholder="Palavra-passe"
                                                               class="form-control" id="passwordconfirm"
                                                               name="passwordconfirm">
                                                    </div>
                                                    <div class="form-group">
                                                        <label class="control-label">
                                                            Palavra-passe antiga
                                                        </label>
                                                        <input type="password" placeholder="Palavra-passe"
                                                               class="form-control" name="oldpassword" id="oldpassword">
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="row">
                                                <div class="col-md-4 push-left">
                                                    <button class="btn btn-blue btn-block" type="submit"
                                                            id="submitButton">
                                                        Actualizar <i class="fa fa-arrow-circle-right"></i>
                                                    </button>
                                                </div>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <!-- end: PAGE CONTENT-->
        </div>
    </div>
    <!-- end: PAGE -->
    <span style="display: none" id="activeTab">edituser</span>
    <script>
        var isEdit = true;
    </script>
    <script src="{$BASE_URL}javascript/validateuserform.js"></script>
{/if}
{include file='common/footer.tpl'}