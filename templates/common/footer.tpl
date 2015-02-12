{if $EMAIL}
    </div>
<!-- end: MAIN CONTAINER -->

<!-- start: FOOTER -->
<div class="footer clearfix">
    <div class="footer-inner">
        &copy; Copyright 2014 Trigonum. All Rights Reserved.
    </div>
    <div class="footer-items">
        <a class="first" href="{$BASE_URL}{$BASE_URL}trigonum/termosdeuso.html">Termos de Uso</a>
        <a> | </a>
        <a href="{$BASE_URL}{$BASE_URL}trigonum/privacidade.html"> Política de Privacidade</a>
    </div>
</div>
<!-- end: FOOTER -->
{/if}
<script src="//ajax.googleapis.com/ajax/libs/jqueryui/1.11.2/jquery-ui.min.js"></script>
<!-- <script src="{$BASE_URL}assets/plugins/jquery-ui/jquery-ui-1.10.2.custom.min.js"></script> -->
<script src="{$BASE_URL}assets/plugins/bootstrap/js/bootstrap.min.js"></script>
<script src="{$BASE_URL}assets/plugins/bootstrap-hover-dropdown/bootstrap-hover-dropdown.min.js"></script>
<script src="{$BASE_URL}assets/plugins/blockUI/jquery.blockUI.js"></script>
<script src="{$BASE_URL}assets/plugins/icheck/jquery.icheck.min.js"></script>
<script src="{$BASE_URL}assets/plugins/perfect-scrollbar/src/jquery.mousewheel.js"></script>
<script src="{$BASE_URL}assets/plugins/perfect-scrollbar/src/perfect-scrollbar.js"></script>
<script src="{$BASE_URL}assets/plugins/less/less-1.5.0.min.js"></script>
<script src="{$BASE_URL}assets/plugins/jquery-cookie/jquery.cookie.js"></script>
<script src="{$BASE_URL}assets/plugins/bootstrap-colorpalette/js/bootstrap-colorpalette.js"></script>
<script src="{$BASE_URL}assets/js/main.js"></script>

{if $EMAIL}
    <!-- start: JAVASCRIPTS REQUIRED FOR THIS PAGE ONLY -->
    <script type="text/javascript" src="{$BASE_URL}assets/plugins/bootbox/bootbox.min.js"></script>
    <script type="text/javascript" src="{$BASE_URL}assets/plugins/jquery-mockjax/jquery.mockjax.js"></script>
    <script type="text/javascript" src="{$BASE_URL}assets/plugins/select2/select2.min.js"></script>
    <script type="text/javascript"
            src="{$BASE_URL}assets/plugins/datatables/media/js/jquery.dataTables.min.js"></script>
    <script type="text/javascript" src="{$BASE_URL}assets/plugins/datatables/media/js/DT_bootstrap.js"></script>
    <script src="{$BASE_URL}assets/js/table-data.js"></script>
    <!-- end: JAVASCRIPTS REQUIRED FOR THIS PAGE ONLY -->
    <script>
        jQuery(document).ready(function () {
            Main.init();
            TableData.init();

            const activeTab = $("#" + $("#activeTab").text());
            activeTab.addClass("active open");
            activeTab.parent().parent().addClass("active open");
        });
    </script>
{else}
    <script src="{$BASE_URL}assets/plugins/jquery-validation/dist/jquery.validate.min.js"></script>
    <script src="{$BASE_URL}assets/js/login.js"></script>
    <!-- end: JAVASCRIPTS REQUIRED FOR THIS PAGE ONLY -->
    <script>
        jQuery(document).ready(function() {
            Main.init();
            Login.init();
        });
    </script>
{/if}

</body></html>