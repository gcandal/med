<!-- start: HEADER -->
<div class="navbar navbar-inverse navbar-fixed-top">
    <!-- start: TOP NAVIGATION CONTAINER -->
    <div class="container">
        <div class="navbar-header">
            <!-- start: RESPONSIVE MENU TOGGLER -->
            <button data-target=".navbar-collapse" data-toggle="collapse" class="navbar-toggle" type="button">
                <span class="clip-list-2"></span>
            </button>
            <!-- end: RESPONSIVE MENU TOGGLER -->
            <!-- start: LOGO -->
            <a class="navbar-brand" href="{$BASE_URL}pages/main.php">
                <img height="30px" width="130px" src="{$BASE_URL}img/logo.svg">
            </a>
            <!-- end: LOGO -->
        </div>
        <div class="navbar-tools">
            <!-- start: TOP NAVIGATION MENU -->
            <ul class="nav navbar-right">
                <!-- start: USER DROPDOWN -->
                <li class="dropdown current-user">
                    <a data-toggle="dropdown" data-hover="dropdown" class="dropdown-toggle" data-close-others="true"
                       href="#">
                        Dr. <span class="username">{$NAME}</span>
                        <i class="clip-chevron-down"></i>
                    </a>
                    <ul class="dropdown-menu">
                        <li>
                            <a href="{$BASE_URL}pages/users/edituser.php">
                                <i class="clip-user-2"></i>
                                &nbsp;O meu perfil
                            </a>
                        </li>
                        <li>
                            <a href="{$BASE_URL}actions/users/logout.php">
                                <i class="clip-exit"></i>
                                &nbsp;Sair
                            </a>
                        </li>
                    </ul>
                </li>
                <!-- end: USER DROPDOWN -->
            </ul>
            <!-- end: TOP NAVIGATION MENU -->
        </div>
    </div>
    <!-- end: TOP NAVIGATION CONTAINER -->
</div>
<!-- end: HEADER -->
<!-- start: MAIN CONTAINER -->
<div class="main-container">
    <div class="navbar-content">
        <!-- start: SIDEBAR -->
        <div class="main-navigation navbar-collapse collapse">
            <!-- start: MAIN MENU TOGGLER BUTTON -->
            <div class="navigation-toggler">
                <i class="clip-chevron-left"></i>
                <i class="clip-chevron-right"></i>
            </div>
            <!-- end: MAIN MENU TOGGLER BUTTON -->
            <!-- start: MAIN NAVIGATION MENU -->
            <ul class="main-navigation-menu">
                <li>
                    <a href="{$BASE_URL}pages/main.php"><i class="clip-home-3"></i>
                        <span class="title"> Home </span><span class="selected"></span>
                    </a>
                </li>
                <li>
                    <a href="javascript:void(0)"><i class="clip-file-2"></i>
                        <span class="title"> Registos operatórios </span><i class="icon-arrow"></i>
                        <span class="selected"></span>
                    </a>
                    <ul class="sub-menu">
                        <li id="procedures">
                            <a href="{$BASE_URL}pages/procedures/procedures.php">
                                <span class="title"> Consultar registos </span>
                            </a>
                        </li>
                        <li id="addprocedure">
                            <a href="{$BASE_URL}pages/procedures/addprocedure.php">
                                <span class="title"> Adicionar novo </span>
                            </a>
                        </li>
                        <li id="invites">
                            <a href="{$BASE_URL}pages/procedures/invites.php">
                                <span class="title"> Registos partilhados </span>
                            </a>
                        </li>
                    </ul>
                </li>
                <li>
                    <a href="javascript:void(0)" target="_blank"><i class="clip-users"></i>
                        <span class="title"> Equipa cirúrgica </span><i class="icon-arrow"></i>
                        <span class="selected"></span>
                    </a>
                    <ul class="sub-menu">
                        <li id="professionals">
                            <a href="{$BASE_URL}pages/professionals/professionals.php">
                                <span class="title"> Elementos da equipa </span>
                            </a>
                        </li>
                        <li id="addprofessional">
                            <a href="{$BASE_URL}pages/professionals/addprofessional.php">
                                <span class="title"> Adicionar elemento </span>
                            </a>
                        </li>
                    </ul>
                </li>
                <li>
                    <a href="javascript:void(0)"><i class="fa fa-medkit"></i>
                        <span class="title"> Pacientes registados </span><i class="icon-arrow"></i>
                        <span class="selected"></span>
                    </a>
                    <ul class="sub-menu">
                        <li id="patients">
                            <a href="{$BASE_URL}pages/patients/patients.php">
                                <span class="title"> Consultar </span>
                            </a>
                        </li>
                        <li id="addpatient">
                            <a href="{$BASE_URL}pages/patients/addpatient.php">
                                <span class="title"> Adicionar novo </span>
                            </a>
                        </li>
                    </ul>
                </li>
                <li>
                    <a href="javascript:void(0)"><i class="fa fa-money"></i>
                        <span class="title"> Pagadores </span><i class="icon-arrow"></i>
                        <span class="selected"></span>
                    </a>
                    <ul class="sub-menu">
                        <li id="payers">
                            <a href="{$BASE_URL}pages/payers/payers.php">
                                <span class="title">Consultar a lista</span>
                            </a>
                        </li>
                        <li id="addpayer">
                            <a href="{$BASE_URL}pages/payers/addpayer.php">
                                <span class="title">Adicionar novo</span>
                            </a>
                        </li>
                    </ul>
                </li>
                <li>
                    <a href="javascript:void(0)"><i class="fa fa-building"></i>
                        <span class="title"> Organizações </span><i class="icon-arrow"></i>
                        <span class="selected"></span>
                    </a>
                    <ul class="sub-menu">
                        <li id="organizations">
                            <a href="{$BASE_URL}pages/organizations/organizations.php">
                                <span class="title">Ver informações</span>
                            </a>
                        </li>
                        <li id="addorganization">
                            <a href="{$BASE_URL}pages/organizations/addorganization.php">
                                <span class="title">Criar nova</span>
                            </a>
                        </li>
                        <li id="orginvites">
                            <a href="{$BASE_URL}pages/organizations/invites.php">
                                <span class="title">Pedidos pendentes</span>
                            </a>
                        </li>
                    </ul>
                </li>
                {foreach $SUCCESS_MESSAGES as $success}
                    <div class="alert alert-success" role="alert">
                        <span class="glyphicon glyphicon-ok-sign" aria-hidden="true"></span>
                        <span>{$success}</span>
                    </div>
                {/foreach}

                {foreach $ERROR_MESSAGES as $error}
                    <div class="alert alert-danger" role="alert">
                        <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                        <span>{$error}</span>
                    </div>
                {/foreach}
            </ul>
            <!-- end: MAIN NAVIGATION MENU -->
        </div>
        <!-- end: SIDEBAR -->
    </div>