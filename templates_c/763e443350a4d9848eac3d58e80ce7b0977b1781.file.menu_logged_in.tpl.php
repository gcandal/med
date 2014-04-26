<?php /* Smarty version Smarty-3.1.15, created on 2014-04-25 15:52:12
         compiled from "/var/www/med/templates/common/menu_logged_in.tpl" */ ?>
<?php /*%%SmartyHeaderCode:1110015155535a683ae2f393-44514204%%*/if(!defined('SMARTY_DIR')) exit('no direct access allowed');
$_valid = $_smarty_tpl->decodeProperties(array (
  'file_dependency' => 
  array (
    '763e443350a4d9848eac3d58e80ce7b0977b1781' => 
    array (
      0 => '/var/www/med/templates/common/menu_logged_in.tpl',
      1 => 1398433913,
      2 => 'file',
    ),
  ),
  'nocache_hash' => '1110015155535a683ae2f393-44514204',
  'function' => 
  array (
  ),
  'version' => 'Smarty-3.1.15',
  'unifunc' => 'content_535a683ae5b438_71161242',
  'variables' => 
  array (
    'USERNAME' => 0,
    'EMAIL' => 0,
    'BASE_URL' => 0,
  ),
  'has_nocache_code' => false,
),false); /*/%%SmartyHeaderCode%%*/?>
<?php if ($_valid && !is_callable('content_535a683ae5b438_71161242')) {function content_535a683ae5b438_71161242($_smarty_tpl) {?><p><?php echo $_smarty_tpl->tpl_vars['USERNAME']->value;?>
</p>
<p><?php echo $_smarty_tpl->tpl_vars['EMAIL']->value;?>
</p>
<form action="<?php echo $_smarty_tpl->tpl_vars['BASE_URL']->value;?>
actions/users/logout.php">
    <button type="submit">Logout</button>
</form><?php }} ?>
