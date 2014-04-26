<?php /* Smarty version Smarty-3.1.15, created on 2014-04-17 21:25:51
         compiled from "/var/www/~lbaw1312/frmk/templates/common/menu_logged_in.tpl" */ ?>
<?php /*%%SmartyHeaderCode:30471975953502abfa0dcf7-78729203%%*/if(!defined('SMARTY_DIR')) exit('no direct access allowed');
$_valid = $_smarty_tpl->decodeProperties(array (
  'file_dependency' => 
  array (
    '074ea0405d60ce65640c58d575354059289a44f0' => 
    array (
      0 => '/var/www/~lbaw1312/frmk/templates/common/menu_logged_in.tpl',
      1 => 1386924324,
      2 => 'file',
    ),
  ),
  'nocache_hash' => '30471975953502abfa0dcf7-78729203',
  'function' => 
  array (
  ),
  'variables' => 
  array (
    'BASE_URL' => 0,
    'USERNAME' => 0,
  ),
  'has_nocache_code' => false,
  'version' => 'Smarty-3.1.15',
  'unifunc' => 'content_53502abfa3b8b2_03775721',
),false); /*/%%SmartyHeaderCode%%*/?>
<?php if ($_valid && !is_callable('content_53502abfa3b8b2_03775721')) {function content_53502abfa3b8b2_03775721($_smarty_tpl) {?><a href="<?php echo $_smarty_tpl->tpl_vars['BASE_URL']->value;?>
actions/users/logout.php">Logout</a>
<span class="username"><?php echo $_smarty_tpl->tpl_vars['USERNAME']->value;?>
</span>
<?php }} ?>
