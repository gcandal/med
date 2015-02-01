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
                        <h1>Consulta de pagadores</h1>
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
                        <div class="panel-heading">
                            <i class="clip-world"></i>
                            Entidades
                        </div>
                        <div class="panel-body">
                            <table class="table table-hover" id="sample-table-1">
                                <thead>
                                <tr>
                                    <th class="center">Nome</th>
                                    <th class="center hidden-xs">Início de contrato</th>
                                    <th class="center hidden-xs">Fim do contrato</th>
                                    <th class="center">NIF</th>
                                    <th class="center">Valor por K</th>
                                    <th class="center"></th>
                                </tr>
                                </thead>
                                <tbody>
                                {foreach $ENTITIES['Entidade'] as $entity}
                                    <tr>
                                        <td>{$entity.name}</td>
                                        <td class="center hidden-xs">{$entity.contractstart}</td>
                                        <td class="center hidden-xs">{$entity.contractend}</td>
                                        <td class="center">{$entity.nif}</td>
                                        <td class="center">
                                            {if $entity.valueperk}
                                                {$entity.valueperk}€
                                            {/if}
                                        </td>
                                        <td class="center">
                                            <div class="visible-md visible-lg hidden-sm hidden-xs">
                                                <form class="inlineForm"
                                                      action="{$BASE_URL}pages/payers/editentitypayer.php">
                                                    <input type="hidden" name="identitypayer"
                                                           value="{$entity.identitypayer}"/>
                                                    <button type="submit" class="btn btn-xs btn-blue tooltips"
                                                            data-placement="top"
                                                            data-original-title="Editar">
                                                        <i class="fa fa-edit"></i>
                                                    </button>
                                                </form>

                                                <form class="inlineForm"
                                                      action="{$BASE_URL}actions/payers/deleteentitypayer.php"
                                                      method="post">
                                                    <input type="hidden" name="identitypayer"
                                                           value="{$entity.identitypayer}"/>
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
                                                                  action="{$BASE_URL}pages/payers/editentitypayer.php">
                                                                <input type="hidden" name="identitypayer"
                                                                       value="{$entity.identitypayer}"/>
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
                                                                  action="{$BASE_URL}actions/payers/deleteentitypayer.php"
                                                                  method="post">
                                                                <input type="hidden" name="identitypayer"
                                                                       value="{$entity.identitypayer}"/>
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
            <div class="row">
                <div class="col-md-12">
                    <!-- start: BASIC TABLE PANEL -->
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            <i class="clip-user-5"></i>
                            Particulares
                        </div>
                        <div class="panel-body">
                            <table class="table table-hover" id="sample-table-1">
                                <thead>
                                <tr>
                                    <th class="center">Nome</th>
                                    <th class="center">NIF</th>
                                    <th class="center">Valor por K</th>
                                    <th class="center"></th>
                                </tr>
                                </thead>
                                <tbody>
                                {foreach $ENTITIES['Privado'] as $entity}
                                    <tr>
                                        <td>{$entity.name}</td>
                                        <td class="center">{$entity.nif}</td>
                                        <td class="center">
                                            {if $entity.valueperk}
                                                {$entity.valueperk}€
                                            {/if}
                                        </td>
                                        <td class="center">
                                            <div class="visible-md visible-lg hidden-sm hidden-xs">
                                                <form class="inlineForm"
                                                      action="{$BASE_URL}pages/payers/editprivatepayer.php">
                                                    <input type="hidden" name="idprivatepayer"
                                                           value="{$entity.idprivatepayer}"/>
                                                    <button type="submit" class="btn btn-xs btn-blue tooltips"
                                                            data-placement="top"
                                                            data-original-title="Editar">
                                                        <i class="fa fa-edit"></i>
                                                    </button>
                                                </form>

                                                <form class="inlineForm"
                                                      action="{$BASE_URL}actions/payers/deleteprivatepayer.php"
                                                      method="post">
                                                    <input type="hidden" name="idprivatepayer"
                                                           value="{$entity.idprivatepayer}"/>
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
                                                                  action="{$BASE_URL}pages/payers/editprivatepayer.php">
                                                                <input type="hidden" name="idprivatepayer"
                                                                       value="{$entity.idprivatepayer}"/>
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
                                                                  action="{$BASE_URL}actions/payers/deleteprivatepayer.php"
                                                                  method="post">
                                                                <input type="hidden" name="idprivatepayer"
                                                                       value="{$entity.idprivatepayer}"/>
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

    <span style="display: none" id="activeTab">payers</span>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}