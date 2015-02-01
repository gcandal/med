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
                        <h1>{$organization.name}</h1>
                    </div>
                    <!-- end: PAGE TITLE & BREADCRUMB -->
                </div>
            </div>
            <!-- end: PAGE HEADER -->
            <!-- start: PAGE CONTENT -->
            <div class="row">
                {if $organization.orgauthorization == 'AdminVisible' || $organization.orgauthorization == 'AdminNotVisible'}
                    <div class="col-sm-4 pull-right">
                        <h3>Convidar novo membro</h3>
                        <p>(Só válido para utilizadores registados no DocDue)</p>

                        <div class="alert alert-danger" role="alert" style="display: none;">
                            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                            <span id="licenseIdError"></span>
                        </div>

                        <form action="{$BASE_URL}actions/organizations/invitemember.php" class="form-register"
                              method="post">
                            <input type="hidden" id="idorganization" name="idorganization"
                                   value="{$organization.idorganization}">
                            <input type="hidden" name="nameorganization" value="{$organization.name}">
                            <input class="form-control" type="text" id="licenseid" name="licenseid" placeholder="Cédula"
                                   value="" min="0" required="">
                            <button type="submit" class="btn btn-blue pull-right" id="submitButton" disabled="disabled">
                                Convidar
                            </button>
                        </form>
                    </div>
                {/if}

                {foreach $organization['members'] as $member}
                    <div class="col-sm-4 pull-left">
                        <h4>
                            {if $member.orgauthorization == 'AdminVisible'}
                                Administrador Visível
                            {elseif $member.orgauthorization == 'AdminNotVisible'}
                                Administrador Invisível
                            {elseif $member.orgauthorization == 'Visible'}
                                Visível
                            {else}
                                Invisível
                            {/if}
                        </h4>
                        <ul class="list-unstyled invoice-details">
                            <li>
                                <strong>Nome:</strong> {$member.name}
                            </li>
                            <li>
                                <strong>Cédula:</strong> {$member.licenseid}
                            </li>
                        </ul>
                    </div>
                {/foreach}
            </div>
            <!-- end: PAGE CONTENT-->
        </div>
    </div>
    <!-- end: PAGE -->
{else}
    <p>Tem que fazer login!</p>
{/if}
<script type="text/javascript">
    var baseUrl = {$BASE_URL};
</script>
<script src="{$BASE_URL}javascript/validateinviteform.js"></script>
{include file='common/footer.tpl'}