<?php /* Smarty version Smarty-3.1.15, created on 2014-04-24 16:32:55
         compiled from "/var/www/frmk/templates/common/menu_logged_out.tpl" */ ?>
<?php /*%%SmartyHeaderCode:2041609798535920970bfc48-67402815%%*/if(!defined('SMARTY_DIR')) exit('no direct access allowed');
$_valid = $_smarty_tpl->decodeProperties(array (
  'file_dependency' => 
  array (
    '31cf3d41327f76046502cbb2abc3785fa37804d3' => 
    array (
      0 => '/var/www/frmk/templates/common/menu_logged_out.tpl',
      1 => 1386924324,
      2 => 'file',
    ),
  ),
  'nocache_hash' => '2041609798535920970bfc48-67402815',
  'function' => 
  array (
  ),
  'variables' => 
  array (
    'BASE_URL' => 0,
  ),
  'has_nocache_code' => false,
  'version' => 'Smarty-3.1.15',
  'unifunc' => 'content_535920970c7f10_59337416',
),false); /*/%%SmartyHeaderCode%%*/?>
<?php if ($_valid && !is_callable('content_535920970c7f10_59337416')) {function content_535920970c7f10_59337416($_smarty_tpl) {?><a href="<?php echo $_smarty_tpl->tpl_vars['BASE_URL']->value;?>
pages/users/register.php">Register</a>
<form action="<?php echo $_smarty_tpl->tpl_vars['BASE_URL']->value;?>
actions/users/login.php" method="post">
  <input type="text" placeholder="username" name="username">
  <input type="password" placeholder="password" name="password">
  <input type="submit" value=">">
</form>
<?php }} ?>
