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
                                    <th class="center hidden-xs">Data</th>
                                    <th class="center">Estado</th>
                                    <th class="center hidden-xs">Organização</th>
                                    <th class="center">Responsável</th>
                                    <th class="center">Cirurgias</th>
                                    <th class="center hidden-xs">Função</th>
                                    <th class="center hidden-xs">Valor</th>
                                    <th class="center"></th>
                                </tr>
                                </thead>
                                <tbody>
                                {foreach $PROCEDURES as $procedure}
                                    <tr>
                                        <td class="center hidden-xs">{$procedure.date}</td>
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
                                        <td class="center">
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
                                        <td class="center hidden-xs">Pessoal: {$procedure.personalremun}€;
                                            Total: {$procedure.totalremun}€
                                        </td>
                                        <td class="center">
                                            <div class="hidden-md hidden-lg hidden-sm hidden-xs">
                                                <form class="inlineForm"
                                                      action="{$BASE_URL}actions/procedures/shareprocedure.php"
                                                      method="post">
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
                                                                  action="{$BASE_URL}actions/procedures/shareprocedure.php"
                                                                  method="post">
                                                                <input type="hidden" name="idprocedure"
                                                                       value="{$procedure.idprocedure}"/>
                                                                <button type="submit"
                                                                        class="btn btn-xs btn-blue tooltips"
                                                                        data-placement="top"
                                                                        {if $procedure.readonly}
                                                                            data-original-title="Ver"
                                                                        {else}
                                                                            data-original-title="Editar"
                                                                        {/if}>
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
                                                                        {if $procedure.readonly}
                                                                            data-original-title="Ver"
                                                                        {else}
                                                                            data-original-title="Editar"
                                                                        {/if}>
                                                                    <i class="fa fa-edit"></i>
                                                                    {if $procedure.readonly}
                                                                        Ver
                                                                    {else}
                                                                        Editar
                                                                    {/if}
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