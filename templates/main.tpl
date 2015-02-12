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
        <div class="row">
            <div class="col-sm-4">
                <div class="core-box">
                    <div class="heading">
                        <i class="clip-search circle-icon circle-green"></i>
                        <h2>Consultas na base de dados</h2>
                    </div>
                    <div class="content">
                        Encontre rapidamente os registos que procura através de filtros e caixas de pesquisa intuitivos e fáceis de usar.
                    </div>
                </div>
            </div>
            <div class="col-sm-4">
                <div class="core-box">
                    <div class="heading">
                        <i class="clip-file-2 circle-icon circle-teal"></i>
                        <h2>Relatórios de actividade</h2>
                    </div>
                    <div class="content">
                        Crie relatórios com base na sua actividade seleccionando entre várias opções: perspectivas temporais (anual, semestral, trimestral), por pagador ou por tipo de procedimento.
                    </div>
                </div>
            </div>
            <div class="col-sm-4">
                <div class="core-box">
                    <div class="heading">
                        <i class="fa fa-mail-forward circle-icon circle-bricky"></i>
                        <h2>Exportação de dados</h2>
                    </div>
                    <div class="content">
                        Partilhe os seus relatórios por email ou exporte-os para outro formato.
                    </div>
                </div>
            </div>
        </div>
        <div class="row">
            <div class="col-sm-4">
                <div class="core-box">
                    <div class="heading">
                        <i class="fa fa-home circle-icon circle-green"></i>
                        <h2>Upgrade da página inicial</h2>
                    </div>
                    <div class="content">
                        Para aceder imediatamente à informação mais importante para si, esta página será reformulada para mostrar assim que acede à aplicação os dados que mais procura.
                    </div>
                </div>
            </div>
            <div class="col-sm-4">
                <div class="core-box">
                    <div class="heading">
                        <i class="clip-users-3 circle-icon circle-teal"></i>
                        <h2>Fale connosco</h2>
                    </div>
                    <div class="content">
                        Uma plataforma de chat dentro da aplicação vai permitir-lhe falar directamente com a equipa por trás do DocDue. Esperamos poder ajudá-lo com as suas dúvidas e que nos ajude a melhorar a aplicação.
                    </div>
                </div>
            </div>
            <div class="col-sm-4">
                <div class="core-box">
                    <div class="heading">
                        <i class="clip-phone-3 circle-icon circle-bricky"></i>
                        <h2>Sistema de pagamento</h2>
                    </div>
                    <div class="content">
                        Um sistema de pagamento integrado, prático e seguro para facilitar a gestão dos utilizadores.
                    </div>
                </div>
            </div>
        </div>
        <div class="row">
            <div class="col-sm-4">
                <div class="core-box">
                    <div class="heading">
                        <i class="clip-bubbles-2 circle-icon circle-green"></i>
                        <h2>Mensagens in-app</h2>
                    </div>
                    <div class="content">
                        Envie mensagens directamente aos seus contactos através da aplicação. Basta ter o outro utilizador na sua lista de colaboradores para o poder contactar.
                    </div>
                </div>
            </div>
            <div class="col-sm-4">
                <div class="core-box">
                    <div class="heading">
                        <i class="fa fa-desktop circle-icon circle-green"></i>
                        <h2>Melhoria da interface</h2>
                    </div>
                    <div class="content">
                        Queremos destacar-nos sempre pela usabilidade mas também pelo design das nossas aplicações. Trabalhamos constantemente para conseguir melhorá-las.
                    </div>
                </div>
            </div>
        </div>
        <!-- end: PAGE CONTENT-->
    </div>
</div>
<!-- end: PAGE -->
{/if}

{include file='common/footer.tpl'}