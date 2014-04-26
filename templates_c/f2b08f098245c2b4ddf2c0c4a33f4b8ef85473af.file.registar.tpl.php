<?php /* Smarty version Smarty-3.1.15, created on 2014-04-26 16:31:37
         compiled from "/var/www/med/templates/users/registar.tpl" */ ?>
<?php /*%%SmartyHeaderCode:101112668535a6bb9968ef1-81845802%%*/if(!defined('SMARTY_DIR')) exit('no direct access allowed');
$_valid = $_smarty_tpl->decodeProperties(array (
  'file_dependency' => 
  array (
    'f2b08f098245c2b4ddf2c0c4a33f4b8ef85473af' => 
    array (
      0 => '/var/www/med/templates/users/registar.tpl',
      1 => 1398437447,
      2 => 'file',
    ),
  ),
  'nocache_hash' => '101112668535a6bb9968ef1-81845802',
  'function' => 
  array (
  ),
  'version' => 'Smarty-3.1.15',
  'unifunc' => 'content_535a6bb99a6696_30376841',
  'variables' => 
  array (
    'USERNAME' => 0,
    'ERROR_MESSAGES' => 0,
    'error' => 0,
    'BASE_URL' => 0,
    'FORM_VALUES' => 0,
    'FIELD_ERRORS' => 0,
  ),
  'has_nocache_code' => false,
),false); /*/%%SmartyHeaderCode%%*/?>
<?php if ($_valid && !is_callable('content_535a6bb99a6696_30376841')) {function content_535a6bb99a6696_30376841($_smarty_tpl) {?><?php echo $_smarty_tpl->getSubTemplate ('common/header.tpl', $_smarty_tpl->cache_id, $_smarty_tpl->compile_id, 0, null, array(), 0);?>


<?php if ($_smarty_tpl->tpl_vars['USERNAME']->value) {?>
    <p>Já está registado!</p>
<?php } else { ?>
    <?php  $_smarty_tpl->tpl_vars['error'] = new Smarty_Variable; $_smarty_tpl->tpl_vars['error']->_loop = false;
 $_from = $_smarty_tpl->tpl_vars['ERROR_MESSAGES']->value; if (!is_array($_from) && !is_object($_from)) { settype($_from, 'array');}
foreach ($_from as $_smarty_tpl->tpl_vars['error']->key => $_smarty_tpl->tpl_vars['error']->value) {
$_smarty_tpl->tpl_vars['error']->_loop = true;
?>
        <p><?php echo $_smarty_tpl->tpl_vars['error']->value;?>
</p>
    <?php } ?>

    <form method="post" action="<?php echo $_smarty_tpl->tpl_vars['BASE_URL']->value;?>
actions/users/registar.php">
        <label>
            Nome:
            <input type="text" name="name" placeholder="Nome" value="<?php echo $_smarty_tpl->tpl_vars['FORM_VALUES']->value['name'];?>
" required/>
            <span><?php echo $_smarty_tpl->tpl_vars['FIELD_ERRORS']->value['username'];?>
</span>
        </label>
        <label>
            Nome de utilizador:
            <input type="text" name="username" placeholder="Nome de utilizador" value="<?php echo $_smarty_tpl->tpl_vars['FORM_VALUES']->value['username'];?>
" required/>
            <span><?php echo $_smarty_tpl->tpl_vars['FIELD_ERRORS']->value['username'];?>
</span>
        </label>
        <label>
            Email:
            <input type="email" name="email" placeholder="Email" value="<?php echo $_smarty_tpl->tpl_vars['FORM_VALUES']->value['email'];?>
" required/>
            <span><?php echo $_smarty_tpl->tpl_vars['FIELD_ERRORS']->value['email'];?>
</span><br/>
        </label>
        <label>
            Password:
            <input type="password" name="password" placeholder="Password" required/>
            <span><?php echo $_smarty_tpl->tpl_vars['FIELD_ERRORS']->value['password'];?>
</span><br/>
        </label>
        <label>
            Confirmar Password:
            <input type="password" name="passwordconfirm" placeholder="Confirmar Password" required/>
            <span><?php echo $_smarty_tpl->tpl_vars['FIELD_ERRORS']->value['passwordconfirm'];?>
</span><br/>
        </label>
        <button type="submit">Registar</button><br>
    </form>
<?php }?>

<?php echo $_smarty_tpl->getSubTemplate ('common/footer.tpl', $_smarty_tpl->cache_id, $_smarty_tpl->compile_id, 0, null, array(), 0);?>
<?php }} ?>
