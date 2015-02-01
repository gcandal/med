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
                            <a href="#"> Equipa </a>
                        </li>
                    </ol>
                    <div class="page-header">
                        <h1>Consulta de profissionais</h1>
                    </div>
                    <!-- end: PAGE TITLE & BREADCRUMB -->
                </div>
            </div>
            <!-- end: PAGE HEADER -->
            <!-- start: PAGE CONTENT -->
            <div class="row">
                <div class="col-md-12">
                    <!-- start: BASIC TABLE PANEL -->
                    <div class="panel panel-default">
                        <div class="panel-body">
                            <table class="table table-hover" id="sample-table-1">
                                <thead>
                                <tr>
                                    <th class="center">Nome</th>
                                    <th class="center">Cédula</th>
                                    <th class="center hidden-xs">NIF</th>
                                    <th class="center hidden-xs">Especialidade</th>
                                    <th class="center"></th>
                                </tr>
                                </thead>
                                <tbody>
                                {foreach $PROFESSIONALS as $professional}
                                    <tr>
                                        <td>{$professional.name}</td>
                                        <td class="center">{$professional.licenseid}</td>
                                        <td class="center hidden-xs">{$professional.nif}</td>
                                        <td>{$professional.speciality}</td>
                                        <td class="center">
                                            <div class="visible-md visible-lg hidden-sm hidden-xs">
                                                <form class="inlineForm"
                                                      action="{$BASE_URL}pages/professionals/editprofessional.php">
                                                    <input type="hidden" name="idprofessional"
                                                           value="{$professional.idprofessional}"/>
                                                    <button type="submit" class="btn btn-xs btn-blue tooltips"
                                                            data-placement="top"
                                                            data-original-title="Editar">
                                                        <i class="fa fa-edit"></i>
                                                    </button>
                                                </form>

                                                <form class="inlineForm"
                                                      action="{$BASE_URL}actions/professionals/deleteprofessional.php"
                                                      method="post">
                                                    <input type="hidden" name="idprofessional"
                                                           value="{$professional.idprofessional}"/>
                                                    <button type="submit" class="btn btn-xs btn-bricky tooltips"
                                                            data-placement="top"
                                                            data-original-title="Remover">
                                                        <i class="fa fa-times fa fa-white"></i>
                                                    </button>
                                                </form>
                                            </div>
                                            <div class="visible-xs visible-sm hidden-md hidden-lg">
                                                <div class="btn-group">
                                                    <a class="btn btn-primary dropdown-toggle btn-sm"
                                                       data-toggle="dropdown"
                                                       href="#">
                                                        <i class="fa fa-cog"></i> <span class="caret"></span>
                                                    </a>
                                                    <ul role="menu" class="dropdown-menu pull-right">
                                                        <li role="presentation">
                                                            <form role="menuitem" tabindex="-1"
                                                                  class="inlineForm"
                                                                  action="{$BASE_URL}pages/professionals/editprofessional.php">
                                                                <input type="hidden" name="idprofessional"
                                                                       value="{$professional.idprofessional}"/>
                                                                <button type="submit"
                                                                        class="btn btn-xs btn-blue tooltips"
                                                                        data-placement="top"
                                                                        data-original-title="Editar">
                                                                    <i class="fa fa-edit"></i> Editar
                                                                </button>
                                                            </form>
                                                        </li>
                                                        <li role="presentation">
                                                            <form role="menuitem" tabindex="-1"
                                                                  class="inlineForm"
                                                                  action="{$BASE_URL}actions/professionals/deleteprofessional.php"
                                                                  method="post">
                                                                <input type="hidden" name="idprofessional"
                                                                       value="{$professional.idprofessional}"/>
                                                                <button type="submit"
                                                                        class="btn btn-xs btn-bricky tooltips"
                                                                        data-placement="top"
                                                                        data-original-title="Remover">
                                                                    <i class="fa fa-times fa fa-white"></i> Remover
                                                                </button>
                                                            </form>
                                                        </li>
                                                    </ul>
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                {/foreach}

                                </tbody>
                            </table>
                        </div>
                    </div>
                    <!-- end: BASIC TABLE PANEL -->
                </div>
            </div>
            <!-- end: PAGE CONTENT-->
        </div>
    </div>
    <!-- end: PAGE -->
    <span style="display: none" id="activeTab">professionals</span>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}