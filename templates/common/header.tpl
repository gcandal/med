<!DOCTYPE html>
<html>
<head>
    <title>ProjetoX</title>
    <meta charset='utf-8'>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
</head>
<body>
{if $EMAIL}
    {include file='common/menu_logged_in.tpl'}
{else}
    {include file='common/menu_logged_out.tpl'}
{/if}
