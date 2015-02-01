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
                        <h1>Convites de organizações</h1>
                    </div>
                    <!-- end: PAGE TITLE & BREADCRUMB -->
                </div>
            </div>
            <!-- end: PAGE HEADER -->
            <!-- start: PAGE CONTENT -->
            <div class="row">
                <div class="col-sm-12">
                    <h1>Enviados</h1>
                </div>
                {foreach $SENT as $invite}
                    <div class="col-sm-4">
                        <div class="well">
                            <ul class="list-unstyled">
                                <li>
                                    <p>Cédula do convidado: {$invite.licenseidinvited}</p>
                                    <p>Nome da organização: {$invite.organizationname}</p>
                                    <p>Para administrador?
                                        {if $invite.foradmin}
                                            Sim
                                        {else}
                                            Não
                                        {/if}
                                    </p>
                                </li>
                                <li>
                                    <form style="display: inline"
                                          action="{$BASE_URL}actions/organizations/deleteinvite.php"
                                          method="post">
                                        <input type="hidden" name="idorganization" value="{$invite.idorganization}">
                                        <input type="hidden" name="licenseidinvited" value="{$invite.licenseidinvited}">
                                        <button type="submit" class="btn btn-blue">Retirar convite</button>
                                    </form>
                                </li>
                            </ul>
                        </div>
                    </div>
                {/foreach}
            </div>

            <div class="row">
                <div class="col-sm-12">
                    <h1>Recebidos</h1>
                </div>
                {foreach $INVITES as $invite}
                    {if !$invite.wasrejected}
                        <div class="col-sm-4">
                            <div class="well">
                                <ul class="list-unstyled">
                                    <li>
                                        <p>Nome da organização: {$invite.organizationname}</p>
                                        <p>Convidado por: {$invite.invitingname}</p>
                                        <p>Para administrador?
                                            {if $invite.foradmin}
                                                Sim
                                            {else}
                                                Não
                                            {/if}
                                        </p>
                                    </li>
                                    <li>
                                        <form style="display: inline" action="{$BASE_URL}actions/organizations/acceptinvite.php"
                                              method="post">
                                            <input type="hidden" name="idorganization" value="{$invite.idorganization}">
                                            <input type="hidden" name="idinvitingaccount" value="{$invite.idinvitingaccount}">
                                            <select name="orgauthorization">
                                                {if $invite.foradmin}
                                                    <option value="AdminVisible">Visível</option>
                                                    <option value="AdminNotVisible">Invisível</option>
                                                {else}
                                                    <option value="NotVisible">Invisível</option>
                                                    <option value="Visible">Visível</option>
                                                {/if}
                                            </select>
                                            <button type="submit" class="btn btn-blue">Aceitar convite</button>
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
    <span style="display: none" id="activeTab">orginvites</span>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}