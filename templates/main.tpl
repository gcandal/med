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
                    <li class="active">
                        <i class="clip-home-3"></i>
                        Home
                    </li>
                </ol>
                <div class="page-header">
                    <h1>Homepage</h1>
                </div>
                <!-- end: PAGE TITLE & BREADCRUMB -->
            </div>
        </div>
        <!-- end: PAGE HEADER -->
        <!-- start: PAGE CONTENT -->
        <div class="row">
            <div class="col-sm-4 pull-left">
                <p>{$EMAIL}</p>
                <p>{$LICENSEID}</p>
                <p>Válida até: {$VALIDUNTIL}</p>
                <p>Registos por usar:
                    {if $FREEREGISTERS == -1}
                        ilimitado
                    {else}
                        {$FREEREGISTERS}
                    {/if}
                </p>
            </div>
        </div>
        <!-- end: PAGE CONTENT-->
    </div>
</div>
<!-- end: PAGE -->
{/if}

{include file='common/footer.tpl'}