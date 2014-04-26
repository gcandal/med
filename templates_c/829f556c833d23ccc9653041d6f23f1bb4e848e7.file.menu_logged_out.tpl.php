<?php /* Smarty version Smarty-3.1.15, created on 2014-04-17 21:25:45
         compiled from "/var/www/~lbaw1312/frmk/templates/common/menu_logged_out.tpl" */ ?>
<?php /*%%SmartyHeaderCode:99350046253502ab9867a78-74860136%%*/if(!defined('SMARTY_DIR')) exit('no direct access allowed');
$_valid = $_smarty_tpl->decodeProperties(array (
  'file_dependency' => 
  array (
    '829f556c833d23ccc9653041d6f23f1bb4e848e7' => 
    array (
      0 => '/var/www/~lbaw1312/frmk/templates/common/menu_logged_out.tpl',
      1 => 1386924324,
      2 => 'file',
    ),
  ),
  'nocache_hash' => '99350046253502ab9867a78-74860136',
  'function' => 
  array (
  ),
  'variables' => 
  array (
    'BASE_URL' => 0,
  ),
  'has_nocache_code' => false,
  'version' => 'Smarty-3.1.15',
  'unifunc' => 'content_53502ab986dda6_26778189',
),false); /*/%%SmartyHeaderCode%%*/?>
<?php if ($_valid && !is_callable('content_53502ab986dda6_26778189')) {function content_53502ab986dda6_26778189($_smarty_tpl) {?><a href="<?php echo $_smarty_tpl->tpl_vars['BASE_URL']->value;?>
pages/users/register.php">Register</a>
<form action="<?php echo $_smarty_tpl->tpl_vars['BASE_URL']->value;?>
actions/users/login.php" method="post">
  <input type="text" placeholder="username" name="username">
  <input type="password" placeholder="password" name="password">
  <input type="submit" value=">">
</form>
<?php }} ?>
