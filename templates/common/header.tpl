<!DOCTYPE html>
<html>
<head>
    <title>ProjetoX</title>
    <meta charset='utf-8'>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>

    <link rel="stylesheet" href="//code.jquery.com/ui/1.11.0/themes/smoothness/jquery-ui.css">
    <script src="//code.jquery.com/ui/1.11.0/jquery-ui.js"></script>
</head>
<body>
{if $EMAIL}
    {include file='common/menu_logged_in.tpl'}
{else}
    {include file='common/menu_logged_out.tpl'}
{/if}
