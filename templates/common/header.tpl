<!DOCTYPE html>
<html>
  <head>
    <title>ProjetoX</title>
    <meta charset='utf-8'>
    <script src="http://code.jquery.com/jquery-1.10.2.min.js"></script>
  </head>
  <body>
  {if $USERNAME}
      {include file='common/menu_logged_in.tpl'}
  {else}
      {include file='common/menu_logged_out.tpl'}
  {/if}
