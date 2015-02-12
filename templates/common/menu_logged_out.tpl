<div class="main-login col-md-4 col-md-offset-4 col-sm-6 col-sm-offset-3">
    <!-- start: LOGIN BOX -->
    <div class="box-login">
        <h3>Entre na sua conta</h3>

        <p>
            Insira o seu nome de utilizador e palavra-passe para aceder.
        </p>

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

        <form class="form-login" action="{$BASE_URL}actions/users/login.php" method="post">
            <div class="errorHandler alert alert-danger no-display">
                <span class="input-icon"><i class="fa fa-remove-sign"></i></span> Ocorreu um erro. Por favor reveja o
                formulário.
            </div>
            <fieldset>
                <div class="form-group">
                            <span class="input-icon">
                                <input type="email" class="form-control" name="email" placeholder="E-mail"
                                       value="{$FORM_VALUES.email}">
                                <i class="fa fa-user"></i> </span>
                    <!-- To mark the incorrectly filled input, you must add the class "error" to the input -->
                    <!-- example: <input type="text" class="login error" name="login" value="Username" /> -->
                </div>
                <div class="form-group form-actions">
                            <span class="input-icon">
                                <input type="password" class="form-control" name="password"
                                       placeholder="Password">
                                <i class="fa fa-lock"></i>
                                <a class="forgot" href="?box=forgot">
                                    Esqueceu-se da senha?
                                </a> </span>
                </div>
                <div class="form-actions">
                    <label for="remember" class="checkbox-inline">
                        <input type="checkbox" class="grey remember" id="remember" name="remember">
                        Lembrar da senha
                    </label>
                    <button type="submit" class="btn btn-blue pull-right">
                        Entrar <i class="fa fa-arrow-circle-right"></i>
                    </button>
                </div>
                <div class="new-account">
                    Ainda não está registado?
                    <a href="?box=register" class="register">
                        Crie uma conta
                    </a>
                </div>
            </fieldset>
        </form>
    </div>
    <!-- end: LOGIN BOX -->
    <!-- start: FORGOT BOX -->
    <div class="box-forgot">
        <h3>Recuperação de palavra-passe</h3>

        <p>
            Insira o seu email para recuperar a palavra-passe.
        </p>

        <form class="form-forgot">
            <div class="errorHandler alert alert-danger no-display">
                <i class="fa fa-remove-sign"></i> Alguma coisa correu mal. Por favor reveja o formulário.
            </div>
            <fieldset>
                <div class="form-group">
                            <span class="input-icon">
                                <input type="email" class="form-control" name="email" placeholder="Email" disabled>
                                <i class="fa fa-envelope"></i> </span>
                </div>
                <div class="form-actions">
                    <a href="?box=login" class="btn btn-light-grey go-back">
                        <i class="fa fa-circle-arrow-left"></i> Para trás
                    </a>
                    <button type="submit" class="btn btn-blue pull-right" disabled>
                        Enviar <i class="fa fa-arrow-circle-right"></i>
                    </button>
                </div>
            </fieldset>
        </form>
    </div>
    <!-- end: FORGOT BOX -->
    <!-- start: REGISTER BOX -->
    <div class="box-register">
        <h3>Registar-se</h3>

        <p>
            Preencha os seus dados:
        </p>

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

        <div class="alert alert-danger" role="alert" style="display: none;">
            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
            <span id="userNameError"></span>
        </div>
        <div class="alert alert-danger" role="alert" style="display: none;">
            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
            <span id="emailError"></span>
        </div>
        <div class="alert alert-danger" role="alert" style="display: none;">
            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
            <span id="licenseIdError"></span>
        </div>
        <div class="alert alert-danger" role="alert" style="display: none;">
            <span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span>
            <span id="passwordError"></span>
        </div>

        <form action="{$BASE_URL}actions/users/register.php" method="post">
            <div class="errorHandler alert alert-danger no-display">
                <i class="fa fa-remove-sign"></i> Ocorreu um erro. Por favor reveja o formulário.
            </div>
            <fieldset>
                <div class="form-group">
                            <span class="input-icon">
                                <input type="text" value="{$FORM_VALUES.name}" required class="form-control" name="name" id="userName"
                                       placeholder="Nome clínico" maxlength="40">
                                <i class="fa fa-user"></i> </span>
                </div>
                <div class="form-group">
                            <span class="input-icon">
                                <input type="text" value="{$FORM_VALUES.licenseid}" required class="form-control" name="licenseid" id="licenseId"
                                       placeholder="Cédula">
                                <i class="fa fa-edit"></i></span>
                </div>
                <div class="form-group">
                    <select name="speciality" id="specialityId" class="form-control">
                        <option value="3">Nenhuma</option>
                        <option value="1">Anestesiologia</option>
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
                    </select>
                </div>
                <p>
                    Preencha as informações da conta:
                </p>

                <div class="form-group">
                            <span class="input-icon">
                                <input type="email" class="form-control" value="{$FORM_VALUES.email}" required name="email" id="email"
                                       placeholder="Email" maxlength="254">
                                <i class="fa fa-envelope"></i> </span>
                </div>
                <div class="form-group">
                            <span class="input-icon">
                                <input type="password" class="form-control" required id="password" name="password"
                                       placeholder="Palavra-passe">
                                <i class="fa fa-lock"></i> </span>
                </div>
                <div class="form-group">
                            <span class="input-icon">
                                <input type="password" class="form-control" id="passwordconfirm" name="passwordconfirm"
                                       placeholder="Repita a palavra-passe">
                                <i class="fa fa-lock"></i> </span>
                </div>
                <!--
                <div class="form-group">
                    <div>
                        <label for="agree" class="checkbox-inline">
                            <input type="checkbox" class="grey agree" value required id="agree" name="agree">

                            <p>
                                Li e aceito com os Termos de Uso e a Política de Privacidade
                            </p>
                        </label>
                    </div>
                </div>
                -->
                <div class="form-actions">
                    <a href="?box=login" class="btn btn-light-grey go-back">
                        <i class="fa fa-circle-arrow-left"></i> Para trás
                    </a>
                    <button type="submit" class="btn btn-blue pull-right" id="submitButton">
                        Enviar <i class="fa fa-arrow-circle-right"></i>
                    </button>
                </div>
            </fieldset>
        </form>
    </div>
    <!-- end: REGISTER BOX -->
    <!-- start: COPYRIGHT -->
    <div class="copyright">
        <a class="first" href="">Termos de Uso</a>
        <a> | </a>
        <a href=""> Política de Privacidade</a>
    </div>
    <div class="copyright" style="margin-bottom: 10px">
        &copy; Copyright 2014 Trigonum. All Rights Reserved.
    </div>
    <!-- end: COPYRIGHT -->
</div>

<script>
    var isEdit = false;
</script>
<script src="{$BASE_URL}javascript/validateuserform.js"></script>