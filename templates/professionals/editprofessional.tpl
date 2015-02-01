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
                            <a href="#"> Equipa </a>
                        </li>
                    </ol>
                    <div class="page-header">
                        <h1>Modificar profissional</h1>
                    </div>
                    <!-- end: PAGE TITLE & BREADCRUMB -->
                </div>
            </div>
            <!-- end: PAGE HEADER -->
            <!-- start: PAGE CONTENT -->
            <div class="row">
                <div class="col-md-12">
                    <!-- start: FORM VALIDATION 1 PANEL -->
                    <div class="panel panel-default">
                        <div class="panel-heading">
                            <i class="fa fa-file-text-o"></i>
                            Formulário de profissionais
                        </div>
                        <div class="panel-body">
                            <h2><i class="fa fa-pencil-square teal"></i> Registo de profissionais</h2>
                            <hr>

                            <div class="alert alert-danger" role="alert">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span id="errorMessageNameProfessional" class="errorMessage"></span>
                            </div>
                            <div class="alert alert-danger" role="alert">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span id="errorMessageNifProfessional" class="errorMessage"></span>
                            </div>
                            <div class="alert alert-danger" role="alert">
                                <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
                                <span id="errorMessageLicenseIdProfessional" class="errorMessage"></span>
                            </div>
                            <form action="{$BASE_URL}actions/professionals/editprofessional.php" role="form" id="form" novalidate="novalidate" method="post">
                                <input type="hidden" name="idprofessional" value="{$professional.idprofessional}">
                                <div class="row">
                                    <div class="col-md-12">
                                        <div class="errorHandler alert alert-danger no-display">
                                            <i class="fa fa-times-sign"></i> Ocorreu um erro. Por favor verifique o formulário.
                                        </div>
                                        <div class="successHandler alert alert-success no-display">
                                            <i class="fa fa-ok"></i> Profissional registado com sucesso
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label class="control-label">
                                                Nome <span class="symbol required"></span>
                                            </label>
                                            <input type="text" placeholder="{$professional.name}" class="form-control professionalName" name="name" value>
                                        </div>
                                        <div class="form-group">
                                            <label class="control-label">
                                                Função
                                            </label>
                                            <select id="professionalType" class="form-control">
                                                {if $professional.idspeciality > 2}
                                                    <option value="Assistant">Assistente</option>
                                                {elseif $professional.idspeciality == 1}
                                                    <option value="Instrumentist">Instrumentista</option>
                                                {else}
                                                    <option value="Anesthetist">Anestesista</option>
                                                {/if}
                                            </select>
                                        </div>
                                        <div class="form-group">
                                            <label class="control-label">
                                                Cédula
                                            </label>
                                            <input type="text" placeholder="{$professional.licenseid}" class="form-control professionalLicenseId" name="licenseId">
                                        </div>
                                        <div class="form-group">
                                            <label class="control-label">
                                                NIF
                                            </label>
                                            <input type="text" placeholder="{$professional.nif}" class="form-control professionalNif" name="nif">
                                        </div>
                                        <div class="form-group">
                                            <label class="control-label">
                                                Especialidade
                                            </label>
                                            {if $professional.idspeciality > 2}
                                                <select name="speciality" id="specialityId">
                                                    {foreach $SPECIALITIES as $speciality}
                                                        {if $speciality.idspeciality > 2}
                                                            <option value="{$speciality.idspeciality}">{$speciality.name}</option>
                                                        {/if}
                                                    {/foreach}
                                                </select>
                                            {elseif $professional.idspeciality == 1}
                                                Anestesiologia
                                            {else}
                                                Enfermagem
                                            {/if}
                                            <select name="speciality" id="specialityId" class="form-control">
                                                {if $professional.idspeciality > 2}
                                                    <option value="3">Nenhuma</option>
                                                    <option value="4">Anatomia Patológica</option>
                                                    <option value="5">Angiologia e Cirurgia Vascular</option>
                                                    <option value="6">Cardiologia</option>
                                                    <option value="7">Cardiologia Pediátrica</option>
                                                    <option value="8">Cirurgia Cardiotorácica</option>
                                                    <option value="9">Cirurgia Geral</option>
                                                    <option value="10">Cirurgia Maxilo-Facial</option>
                                                    <option value="11">Cirurgia Pediátrica</option>
                                                    <option value="12">Cirurgia Plástica Reconstrutiva e Estética</option>
                                                    <option value="13">Dermato-Venereologia</option>
                                                    <option value="14">Doenças Infecciosas</option>
                                                    <option value="15">Endocrinologia e Nutrição</option>
                                                    <option value="16">Estomatologia</option>
                                                    <option value="17">Gastrenterologia</option>
                                                    <option value="18">Genética Médica</option>
                                                    <option value="19">Ginecologia/Obstetrícia</option>
                                                    <option value="20">Imunoalergologia</option>
                                                    <option value="21">Imunohemoterapia</option>
                                                    <option value="22">Farmacologia Clínica</option>
                                                    <option value="23">Hematologia Clínica</option>
                                                    <option value="24">Medicina Desportiva</option>
                                                    <option value="25">Medicina do Trabalho</option>
                                                    <option value="26">Medicina Física e de Reabilitação</option>
                                                    <option value="27">Medicina Geral e Familiar</option>
                                                    <option value="28">Medicina Interna</option>
                                                    <option value="29">Medicina Legal</option>
                                                    <option value="30">Medicina Nuclear</option>
                                                    <option value="31">Medicina Tropical</option>
                                                    <option value="32">Nefrologia</option>
                                                    <option value="33">Neurocirurgia</option>
                                                    <option value="34">Neurologia</option>
                                                    <option value="35">Neurorradiologia</option>
                                                    <option value="36">Oftalmologia</option>
                                                    <option value="37">Oncologia Médica</option>
                                                    <option value="38">Ortopedia</option>
                                                    <option value="39">Otorrinolaringologia</option>
                                                    <option value="40">Patologia Clínica</option>
                                                    <option value="41">Pediatria</option>
                                                    <option value="42">Pneumologia</option>
                                                    <option value="43">Psiquiatria</option>
                                                    <option value="44">Psiquiatria da Infância e da Adolescência</option>
                                                    <option value="45">Radiologia</option>
                                                    <option value="46">Radioncologia</option>
                                                    <option value="47">Reumatologia</option>
                                                    <option value="48">Saúde Pública</option>
                                                    <option value="49">Urologia</option>
                                                {elseif $professional.idspeciality == 1}
                                                    <option value="1">Anestesiologia</option>
                                                {else}
                                                    <option value="2">Enfermagem</option>
                                                {/if}
                                            </select>
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-12">
                                        <div>
                                            <span class="symbol required"></span>Campos obrigatórios
                                            <hr>
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-3">
                                        <button class="btn btn-blue btn-block" type="submit" id="submitButton">
                                            Guardar alterações <i class="fa fa-arrow-circle-right"></i>
                                        </button>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                    <!-- end: FORM VALIDATION 1 PANEL -->
                </div>
            </div>
            <!-- end: PAGE CONTENT-->
        </div>
    </div>
    <!-- end: PAGE -->

    <span style="display: none" id="activeTab">editprofessional</span>
    {if $professional.idspeciality}
        <script>
            $("#specialityId").val("{$professional.idspeciality}");
        </script>
    {/if}
    <script>
        const method = "editProfessional";
    </script>
    <script src="{$BASE_URL}javascript/validateprofessionalform.js"></script>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}