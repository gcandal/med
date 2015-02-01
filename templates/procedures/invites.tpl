{include file='common/header.tpl'}

{if $EMAIL}
    <h1>Recebidos</h1>
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
                        <h1>Partilha de registos</h1>
                    </div>
                    <!-- end: PAGE TITLE & BREADCRUMB -->
                </div>
            </div>
            <!-- end: PAGE HEADER -->
            <!-- start: PAGE CONTENT -->
            <div class="row">
                {foreach $INVITES as $invite}
                    {if !$invite.wasrejected}
                        <div class="col-sm-4">
                            <div class="well">
                                <ul class="list-unstyled">
                                    <li>
                                        <h4>{$invite.invitingname}</h4>

                                        <form style="display: inline"
                                              action="{$BASE_URL}actions/procedures/acceptsharedprocedure.php"
                                              method="post">
                                            <input type="hidden" name="idprocedure" value="{$invite.idprocedure}"/>
                                            <input type="hidden" name="idinvitingaccount"
                                                   value="{$invite.idinvitingaccount}"/>
                                            <button type="submit" class="btn btn-blue">Aceitar <i
                                                        class="fa fa-check"></i></button>
                                        </form>
                                        <form style="display: inline"
                                              action="{$BASE_URL}actions/procedures/rejectsharedprocedure.php"
                                              method="post">
                                            <input type="hidden" name="idprocedure" value="{$invite.idprocedure}"/>
                                            <input type="hidden" name="idinvitingaccount"
                                                   value="{$invite.idinvitingaccount}"/>
                                            <button type="submit" class="btn btn-red">Rejeitar <i
                                                        class="fa fa-times"></i></button>
                                        </form>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    {/if}
                {/foreach}
            </div>
            <!-- end: PAGE CONTENT-->
        </div>
    </div>
    <!-- end: PAGE -->
    <span style="display: none" id="activeTab">invites</span>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}