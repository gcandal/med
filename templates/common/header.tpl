<!DOCTYPE html>
<!--[if IE 8]>
<html class="ie8 no-js" lang="pt"><![endif]-->
<!--[if IE 9]>
<html class="ie9 no-js" lang="pt"><![endif]-->
<!--[if !IE]><!-->
<html lang="pt" class="no-js">
<!--<![endif]-->
<head>
    <title>ProjetoX</title>
    <link rel="stylesheet" href="//ajax.googleapis.com/ajax/libs/jqueryui/1.11.2/themes/smoothness/jquery-ui.css"/>

    <meta charset="utf-8"/>
    <!--[if IE]>
    <meta http-equiv='X-UA-Compatible' content="IE=edge,IE=9,IE=8,chrome=1"/><![endif]-->
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0, user-scalable=0, minimum-scale=1.0, maximum-scale=1.0">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black">
    <meta content="" name="description"/>
    <meta content="" name="author"/>
    <link rel="stylesheet" href="{$BASE_URL}assets/plugins/bootstrap/css/bootstrap.css">
    <link rel="stylesheet" href="{$BASE_URL}assets/plugins/font-awesome/css/font-awesome.min.css">
    <link rel="stylesheet" href="{$BASE_URL}assets/fonts/style.css">
    <link rel="stylesheet" href="{$BASE_URL}assets/css/main.css">
    <link rel="stylesheet" href="{$BASE_URL}assets/css/main-responsive.css">
    <link rel="stylesheet" href="{$BASE_URL}assets/plugins/icheck/skins/all.css">
    <link rel="stylesheet" href="{$BASE_URL}assets/plugins/bootstrap-colorpalette/css/bootstrap-colorpalette.css">
    <link rel="stylesheet" href="{$BASE_URL}assets/plugins/perfect-scrollbar/src/perfect-scrollbar.css">
    <link rel="stylesheet" href="{$BASE_URL}assets/css/theme_light.css" type="text/css" id="skin_color">
    <link rel="stylesheet" href="{$BASE_URL}assets/css/print.css" type="text/css" media="print"/>
    <!--[if IE 7]>
    <link rel="stylesheet" href="{$BASE_URL}assets/plugins/font-awesome/css/font-awesome.min.css">
    <![endif]-->

    <style>
        form.inlineForm {
            float: left;
            padding: 3px;
        }

        ;
    </style>

    <!--[if lt IE 9]>
    <script src="{$BASE_URL}assets/plugins/respond.min.js"></script>
    <script src="{$BASE_URL}assets/plugins/excanvas.min.js"></script>
    <script type="text/javascript" src="{$BASE_URL}assets/plugins/jquery-lib/1.10.2/jquery.min.js"></script>
    <![endif]-->
    <!--[if gte IE 9]><!-->
    <script src="{$BASE_URL}assets/plugins/jquery-lib/2.0.3/jquery.min.js"></script>
    <!--<![endif]-->

    <link rel="apple-touch-icon" sizes="57x57" href="/apple-icon-57x57.png">
    <link rel="apple-touch-icon" sizes="60x60" href="/apple-icon-60x60.png">
    <link rel="apple-touch-icon" sizes="72x72" href="/apple-icon-72x72.png">
    <link rel="apple-touch-icon" sizes="76x76" href="/apple-icon-76x76.png">
    <link rel="apple-touch-icon" sizes="114x114" href="/apple-icon-114x114.png">
    <link rel="apple-touch-icon" sizes="120x120" href="/apple-icon-120x120.png">
    <link rel="apple-touch-icon" sizes="144x144" href="/apple-icon-144x144.png">
    <link rel="apple-touch-icon" sizes="152x152" href="/apple-icon-152x152.png">
    <link rel="apple-touch-icon" sizes="180x180" href="/apple-icon-180x180.png">
    <link rel="icon" type="image/png" sizes="192x192"  href="/android-icon-192x192.png">
    <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="96x96" href="/favicon-96x96.png">
    <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
    <link rel="manifest" href="/manifest.json">
    <meta name="msapplication-TileColor" content="#ffffff">
    <meta name="msapplication-TileImage" content="/ms-icon-144x144.png">
    <meta name="theme-color" content="#ffffff">
</head>
{if $EMAIL}
<body>
{include file='common/menu_logged_in.tpl'}
{else}
<body class="login">
{include file='common/menu_logged_out.tpl'}
{/if}
