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
                        <h1>Nova Organização</h1>
                    </div>
                    <!-- end: PAGE TITLE & BREADCRUMB -->
                </div>
            </div>
            <!-- end: PAGE HEADER -->
            <!-- start: PAGE CONTENT -->
            <div class="row">
                <div class="col-sm-4 pull-left">
                    <h3>Criar nova organização</h3>

                    <div class="alert alert-danger" role="alert">
                        <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                        <span id="errorMessage"></span>
                    </div>
                    <form action="{$BASE_URL}actions/organizations/addorganization.php" class="form-register"method="post">
                        <input class="form-control" type="text" id="name" name="name" placeholder="Nome" value="" min="0" required="" >
                        <button type="submit" class="btn btn-blue pull-right" id="submitButton" disabled="disabled">Adicionar</button>
                    </form>
                </div>
            </div>
            <!-- end: PAGE CONTENT-->
        </div>
    </div>
    <!-- end: PAGE -->

    <span style="display: none" id="activeTab">addorganization</span>
    <script type="text/javascript">
        var baseUrl = {$BASE_URL};
        var isEdit = false;
    </script>
    <script src="{$BASE_URL}javascript/validateorganizationform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}