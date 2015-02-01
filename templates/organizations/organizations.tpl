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
                            <a href="#"> Organizações </a>
                        </li>
                    </ol>
                    <div class="page-header">
                        <h1>Ver organizações</h1>
                    </div>
                    <!-- end: PAGE TITLE & BREADCRUMB -->
                </div>
            </div>
            <!-- end: PAGE HEADER -->
            <!-- start: PAGE CONTENT -->
            <div class="row">
                {foreach $ORGANIZATIONS as $organization}
                    <div class="col-sm-4">
                        <h4>{$organization.name}</h4>

                        <div class="well">
                            <ul class="list-unstyled">
                                <li>
                                    <form action="{$BASE_URL}actions/organizations/editvisibility.php"
                                          method="post">
                                        <input type="hidden" name="idorganization"
                                               value="{$organization.idorganization}">
                                        <label>
                                            <strong>Autorização:</strong>
                                            <select name="visibility">
                                                {if $organization.orgauthorization == 'Visible'}
                                                    <option value="Visible">Visível</option>
                                                    <option value="NotVisible">Invisível</option>
                                                {elseif $organization.orgauthorization == 'AdminVisible'}
                                                    <option value="AdminVisible">Visível</option>
                                                    <option value="AdminNotVisible">Invisível</option>
                                                {elseif $organization.orgauthorization == 'AdminNotVisible'}
                                                    <option value="AdminNotVisible">Invisível</option>
                                                    <option value="AdminVisible">Visível</option>
                                                {else}
                                                    <option value="NotVisible">Invisível</option>
                                                    <option value="Visible">Visível</option>
                                                {/if}
                                            </select>
                                        </label>

                                        <button class="btn btn-clear" type="submit"><i class="fa fa-save"></i>
                                            Gravar
                                        </button>
                                    </form>
                                </li>

                                <li>
                                    <form style="display: inline"
                                          action="{$BASE_URL}pages/organizations/organization.php"
                                          method="get">
                                        <input type="hidden" name="idorganization" value="1">
                                        <button type="submit" class="btn btn-blue">Ver detalhes</button>
                                    </form>
                                    <form style="display: inline"
                                          action="{$BASE_URL}pages/organizations/editorganization.php">
                                        <input type="hidden" name="idorganization" value="1">
                                        <button type="submit" class="btn-clear"><i class="fa fa-edit"></i></button>
                                    </form>
                                    <form style="display: inline"
                                          action="{$BASE_URL}actions/organizations/deleteorganization.php"
                                          method="post">
                                        <input type="hidden" name="idorganization" value="1">
                                        <button type="submit" class="btn-clear"><i class="fa fa-trash-o"></i></button>
                                    </form>
                                </li>
                            </ul>
                        </div>
                    </div>
                {/foreach}
            </div>
            <!-- end: PAGE CONTENT-->
        </div>
    </div>
    <!-- end: PAGE -->
    <span style="display: none" id="activeTab">organizations</span>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}