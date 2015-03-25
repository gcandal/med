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
                        <h1>Registo de procedimentos</h1>
                    </div>
                    <!-- end: PAGE TITLE & BREADCRUMB -->
                </div>
            </div>
            <!-- end: PAGE HEADER -->
            <!-- start: PAGE CONTENT -->
            <div class="row">
                <div class="col-md-12 space20">
                    <div class="btn-group pull-right">
                        <button data-toggle="dropdown" class="btn btn-blue dropdown-toggle">
                            Exportar <i class="fa fa-angle-down"></i>
                        </button>
                        <ul class="dropdown-menu dropdown-light pull-right">
                            <li>
                                <a href="#" class="export-excel" data-table="#sample-table-1">
                                    Para Excel
                                </a>
                            </li>
                            <li>
                                <a href="#" class="export-doc" data-table="#sample-table-1">
                                    Para Word
                                </a>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
            <div class="row">
                <div class="col-md-12">
                    <!-- start: BASIC TABLE PANEL -->
                    <div class="panel panel-default">
                        <div class="panel-body">
                            <table class="table table-hover" id="sample-table-1">
                                <thead>
                                <tr>
                                    <th class="center">Data</th>
                                    <th>Doente</th>
                                    <th class="center">Nº beneficiário</th>
                                    <th class="center">Responsável</th>
                                    <th class="center">Intervenção</th>
                                    <th class="center hidden-xs">Valor</th>
                                    <th class="center">Estado</th>
                                    <th class="center">Opções</th>
                                </tr>
                                </thead>
                                <tbody>
                                {foreach $PROCEDURES as $procedure}
                                    <tr>
                                        <td class="center">{$procedure.date}</td>
                                        <td>
                                            {if $procedure.idpatient}
                                                <a href="{$BASE_URL}pages/organizations/organization.php?idorganization={$procedure.idorganization}">
                                                    {$procedure.patientName}
                                                </a>
                                            {/if}
                                        </td>
                                        <td>
                                            {if $procedure.idpatient}
                                                <a href="{$BASE_URL}pages/organizations/organization.php?idorganization={$procedure.idorganization}">
                                                    {$procedure.patientBeneficiaryNr}
                                                </a>
                                            {/if}
                                        </td>
                                        <td class="center">
                                            <a href="{$BASE_URL}pages/payers/payers.php">{$procedure.payerName}</a>
                                        </td>
                                        <td class="center">
                                            {foreach $procedure.subprocedures as $subprocedure}
                                                {$subprocedure.quantity}x {$subprocedure.name};
                                            {/foreach}
                                        </td>
                                        <td class="center hidden-xs">Pessoal: {$procedure.personalremun}€;
                                            Total: {$procedure.totalremun}€
                                        </td>
                                        <td class="center">{$procedure.paymentstatus}</td>
                                        <td class="center">
                                            <div class="hidden-md hidden-lg hidden-sm hidden-xs">
                                                <form class="inlineForm"
                                                      action="{$BASE_URL}actions/procedures/shareprocedure.php">
                                                    <input type="hidden" name="idprocedure"
                                                           value="{$procedure.idprocedure}"/>
                                                    <button type="submit" class="btn btn-xs btn-blue tooltips"
                                                            data-placement="top"
                                                            data-original-title="Partilhar">
                                                        <i class="fa fa-share"></i>
                                                    </button>
                                                </form>

                                                <form class="inlineForm"
                                                      action="{$BASE_URL}pages/procedures/procedure.php">
                                                    <input type="hidden" name="idprocedure"
                                                           value="{$procedure.idprocedure}"/>
                                                    <button type="submit" class="btn btn-xs btn-blue tooltips"
                                                            data-placement="top"
                                                            data-original-title="Editar">
                                                        <i class="fa fa-edit"></i>
                                                    </button>
                                                </form>

                                                <form class="inlineForm"
                                                      action="{$BASE_URL}actions/procedures/deleteprocedure.php"
                                                      method="post">
                                                    <input type="hidden" name="idprocedure"
                                                           value="{$procedure.idprocedure}"/>
                                                    <button type="submit" class="btn btn-xs btn-bricky tooltips"
                                                            data-placement="top"
                                                            data-original-title="Remover">
                                                        <i class="fa fa-times fa fa-white"></i>
                                                    </button>
                                                </form>
                                            </div>
                                            <div class="visible-xs visible-sm visible-md visible-lg">
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
                                                                  action="{$BASE_URL}actions/procedures/shareprocedure.php">
                                                                <input type="hidden" name="idprocedure"
                                                                       value="{$procedure.idprocedure}"/>
                                                                <button type="submit"
                                                                        class="btn btn-xs btn-blue tooltips"
                                                                        data-placement="top"
                                                                        data-original-title="Editar">
                                                                    <i class="fa fa-share"></i> Partilhar
                                                                </button>
                                                            </form>
                                                        </li>
                                                        <li role="presentation">
                                                            <form role="menuitem" tabindex="-1"
                                                                  class="inlineForm"
                                                                  action="{$BASE_URL}pages/procedures/procedure.php">
                                                                <input type="hidden" name="idprocedure"
                                                                       value="{$procedure.idprocedure}"/>
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
                                                                  action="{$BASE_URL}actions/procedures/deleteprocedure.php"
                                                                  method="post">
                                                                <input type="hidden" name="idprocedure"
                                                                       value="{$procedure.idprocedure}"/>
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
    <span style="display: none" id="activeTab">procedures</span>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}

<!-- start: JAVASCRIPTS REQUIRED FOR THIS PAGE ONLY -->
<script type="text/javascript" src="{$BASE_URL}assets/plugins/select2/select2.min.js"></script>
<script src="{$BASE_URL}assets/plugins/bootbox/bootbox.min.js"></script>
<script type="text/javascript" src="{$BASE_URL}assets/plugins/jquery-mockjax/jquery.mockjax.js"></script>
<script type="text/javascript" src="{$BASE_URL}assets/plugins/datatables/media/js/jquery.dataTables.min.js"></script>
<script type="text/javascript" src="{$BASE_URL}assets/plugins/datatables/media/js/DT_bootstrap.js"></script>
<script src="{$BASE_URL}assets/plugins/tableexport/tableExport.js"></script>
<script src="{$BASE_URL}assets/plugins/tableexport/jquery.base64.js"></script>
<script src="{$BASE_URL}assets/plugins/tableexport/html2canvas.js"></script>
<script src="{$BASE_URL}assets/plugins/tableexport/jspdf/libs/sprintf.js"></script>
<script src="{$BASE_URL}assets/plugins/tableexport/jspdf/jspdf.js"></script>
<script src="{$BASE_URL}assets/plugins/tableexport/jspdf/libs/base64.js"></script>
<script src="{$BASE_URL}assets/js/table-export.js"></script>

<script>
    jQuery(document).ready(function() {
        TableExport.init();
    });
</script>

<!-- end: JAVASCRIPTS REQUIRED FOR THIS PAGE ONLY -->