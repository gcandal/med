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
                <div class="col-md-12">
                    <!-- start: BASIC TABLE PANEL -->
                    <div class="panel panel-default">
                        <div class="panel-body">
                            <table class="table table-hover" id="sample-table-1">
                                <thead>
                                <tr>
                                    <th class="center">Data</th>
                                    <th class="center">Estado</th>
                                    <th class="center hidden-xs">Organização</th>
                                    <th class="center">Responsável</th>
                                    <th class="center hidden-xs">Cirurgias</th>
                                    <th class="center hidden-xs">Função</th>
                                    <th class="center">Valor</th>
                                    <th class="center"></th>
                                </tr>
                                </thead>
                                <tbody>
                                {foreach $PROCEDURES as $procedure}
                                    <tr>
                                        <td>{$procedure.date}</td>
                                        <td class="center">{$procedure.paymentstatus}</td>
                                        <td class="center hidden-xs">
                                            {if $procedure.idorganization}
                                                <a href="{$BASE_URL}pages/organizations/organization.php?idorganization={$procedure.idorganization}">
                                                    {$procedure.organizationName}
                                                </a>
                                            {/if}
                                        </td>
                                        <td class="center">
                                            <a href="{$BASE_URL}pages/payers/payers.php">{$procedure.payerName}</a>
                                        </td>
                                        <td class="center hidden-xs">
                                            {foreach $procedure.subprocedures as $subprocedure}
                                                {$subprocedure.quantity}x {$subprocedure.name};
                                            {/foreach}
                                        </td>
                                        <td class="center hidden-xs">
                                            {if $procedure.role == 'General'}
                                                Cirurgião Principal
                                            {elseif $procedure.role == 'FirstAssistant'}
                                                Primeiro Assitente
                                            {elseif $procedure.role == 'SecondAssistant'}
                                                Segundo Assistente
                                            {elseif $procedure.role == 'Anesthetist'}
                                                Anestesista
                                            {elseif $procedure.role == 'Instrumentist'}
                                                Instrumentista
                                            {/if}
                                        </td>
                                        <td class="center">Pessoal: {$procedure.personalremun}€; Total: {$procedure.totalremun}€</td>
                                        <td class="center">
                                            <div class="visible-md visible-lg hidden-sm hidden-xs">
                                                <a href="/med/actions/procedures/shareprocedure.php"
                                                   class="btn btn-xs btn-blue tooltips" data-placement="top"
                                                   data-original-title="Share"><i class="fa fa-share"></i></a>
                                                <a href="/med/actions/procedures/editprocedure.php"
                                                   class="btn btn-xs btn-blue tooltips" data-placement="top"
                                                   data-original-title="Edit"><i class="fa fa-edit"></i></a>
                                                <a href="/med/actions/procedures/deleteprocedure.php"
                                                   class="btn btn-xs btn-bricky tooltips" data-placement="top"
                                                   data-original-title="Remove"><i class="fa fa-times fa fa-white"></i></a>
                                            </div>
                                            <div class="visible-xs visible-sm hidden-md hidden-lg">
                                                <div class="btn-group">
                                                    <a class="btn btn-primary dropdown-toggle btn-sm"
                                                       data-toggle="dropdown" href="#">
                                                        <i class="fa fa-cog"></i> <span class="caret"></span>
                                                    </a>
                                                    <ul role="menu" class="dropdown-menu pull-right">
                                                        <li role="presentation">
                                                            <a role="menuitem" tabindex="-1"
                                                               href="/med/actions/procedures/shareprocedure.php">
                                                                <i class="fa fa-share"></i> Partilhar
                                                            </a>
                                                        </li>
                                                        <li role="presentation">
                                                            <a role="menuitem" tabindex="-1"
                                                               href="/med/actions/procedures/editprocedure.php">
                                                                <i class="fa fa-edit"></i> Editar
                                                            </a>
                                                        </li>
                                                        <li role="presentation">
                                                            <a role="menuitem" tabindex="-1"
                                                               href="/med/actions/procedures/deleteprocedure.php">
                                                                <i class="fa fa-times"></i> Eliminar
                                                            </a>
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