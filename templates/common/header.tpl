<!DOCTYPE html>
<html>
<head>
    <title>ProjetoX</title>
    <meta charset='utf-8'>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
    <link rel="stylesheet" href="//ajax.googleapis.com/ajax/libs/jqueryui/1.11.2/themes/smoothness/jquery-ui.css"/>
    <script src="//ajax.googleapis.com/ajax/libs/jqueryui/1.11.2/jquery-ui.min.js"></script>
</head>
<body>
{if $EMAIL}
    {include file='common/menu_logged_in.tpl'}
{else}
    {include file='common/menu_logged_out.tpl'}
{/if}
