<?php /* Smarty version Smarty-3.1.15, created on 2014-04-25 16:27:18
         compiled from "/var/www/med/templates/common/menu_logged_out.tpl" */ ?>
<?php /*%%SmartyHeaderCode:721249132535a680d0f8924-34687918%%*/if(!defined('SMARTY_DIR')) exit('no direct access allowed');
$_valid = $_smarty_tpl->decodeProperties(array (
  'file_dependency' => 
  array (
    '68272ecf6235f439b629f177ebf3d985530e7e6f' => 
    array (
      0 => '/var/www/med/templates/common/menu_logged_out.tpl',
      1 => 1398436034,
      2 => 'file',
    ),
  ),
  'nocache_hash' => '721249132535a680d0f8924-34687918',
  'function' => 
  array (
  ),
  'version' => 'Smarty-3.1.15',
  'unifunc' => 'content_535a680d109f31_79159413',
  'variables' => 
  array (
    'ERROR_MESSAGES' => 0,
    'error' => 0,
    'BASE_URL' => 0,
    'FORM_VALUES' => 0,
  ),
  'has_nocache_code' => false,
),false); /*/%%SmartyHeaderCode%%*/?>
<?php if ($_valid && !is_callable('content_535a680d109f31_79159413')) {function content_535a680d109f31_79159413($_smarty_tpl) {?><?php  $_smarty_tpl->tpl_vars['error'] = new Smarty_Variable; $_smarty_tpl->tpl_vars['error']->_loop = false;
 $_from = $_smarty_tpl->tpl_vars['ERROR_MESSAGES']->value; if (!is_array($_from) && !is_object($_from)) { settype($_from, 'array');}
foreach ($_from as $_smarty_tpl->tpl_vars['error']->key => $_smarty_tpl->tpl_vars['error']->value) {
$_smarty_tpl->tpl_vars['error']->_loop = true;
?>
    <p><?php echo $_smarty_tpl->tpl_vars['error']->value;?>
</p>
<?php } ?>

<form method="post" action="<?php echo $_smarty_tpl->tpl_vars['BASE_URL']->value;?>
actions/users/login.php">
    <label>
        Email:
        <input type="email" name="email" placeholder="Email" value="<?php echo $_smarty_tpl->tpl_vars['FORM_VALUES']->value['email'];?>
" required/><br>
    </label>
    <label>
        Password:
        <input type="password" name="password" placeholder="Password" required/><br>
    </label>
    <button type="submit">Entrar</button><br>
</form>

<form action="<?php echo $_smarty_tpl->tpl_vars['BASE_URL']->value;?>
pages/users/registar.php">
    <button type="submit">Registar</button>
</form><?php }} ?>
