<?php /* Smarty version Smarty-3.1.15, created on 2014-04-25 15:50:05
         compiled from "/var/www/med/templates/common/header.tpl" */ ?>
<?php /*%%SmartyHeaderCode:1388420042535a4311b3fd18-69160374%%*/if(!defined('SMARTY_DIR')) exit('no direct access allowed');
$_valid = $_smarty_tpl->decodeProperties(array (
  'file_dependency' => 
  array (
    '1b1ba544dcd2ee315548a1f691f6453860ae0925' => 
    array (
      0 => '/var/www/med/templates/common/header.tpl',
      1 => 1398433545,
      2 => 'file',
    ),
  ),
  'nocache_hash' => '1388420042535a4311b3fd18-69160374',
  'function' => 
  array (
  ),
  'version' => 'Smarty-3.1.15',
  'unifunc' => 'content_535a4311b59c73_75076236',
  'variables' => 
  array (
    'USERNAME' => 0,
  ),
  'has_nocache_code' => false,
),false); /*/%%SmartyHeaderCode%%*/?>
<?php if ($_valid && !is_callable('content_535a4311b59c73_75076236')) {function content_535a4311b59c73_75076236($_smarty_tpl) {?><!DOCTYPE html>
<html>
  <head>
    <title>ProjetoX</title>
    <meta charset='utf-8'>
    <script src="http://code.jquery.com/jquery-1.10.2.min.js"></script>
  </head>
  <body>
  <?php if ($_smarty_tpl->tpl_vars['USERNAME']->value) {?>
      <?php echo $_smarty_tpl->getSubTemplate ('common/menu_logged_in.tpl', $_smarty_tpl->cache_id, $_smarty_tpl->compile_id, 0, null, array(), 0);?>

  <?php } else { ?>
      <?php echo $_smarty_tpl->getSubTemplate ('common/menu_logged_out.tpl', $_smarty_tpl->cache_id, $_smarty_tpl->compile_id, 0, null, array(), 0);?>

  <?php }?>
<?php }} ?>
