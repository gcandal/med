{include file='common/header.tpl'}

{if $EMAIL}
    <h1>Dr. {$USERNAME.name},</h1>
    <h2>Tem {$OPENPROCEDURES.number} procedimentos por concluir.</h2>
    <p><a href="{$BASE_URL}pages/procedures/addprocedure.php">Adicionar Pagamento</a></p>
    <table class="procedureTable" border="1">
        <tr>
            <th>Data</th>
            <th>Estado</th>
            <th>Pagador</th>
            <th>Sub-Procedumentos</th>
            <th>Equipa</th>
            <th>Valor Total</th>
            <th>Partilhar</th>
            <th>Apagar</th>
        </tr>

        {foreach $PROCEDURES as $procedure}
            <tr>
                <td>{$procedure.date}</td>
                <td>{$procedure.paymentstatus}</td>
                {if $procedure.payerId = 0}
                    <td>{$procedure.payerName}</td>
                {else}
                    <td>
                        <a href="{$BASE_URL}pages/payer/payer.php?idpayer={$procedure.idpayer}">{$procedure.payerName}</a>
                    </td>
                {/if}
                <td>
                    <form action="{$BASE_URL}pages/procedures/viewSubProcedures.php?idProcedure={$procedure.idprocedure}">
                        <button type="submit">Ver</button>
                    </form>
                </td>
                <td>
                    <form action="{$BASE_URL}pages/procedures/viewTeam.php?idProcedure={$procedure.idprocedure}">
                        <button type="submit">Ver</button>
                    </form>
                </td>
                <td>{$procedure.totalremun}&euro;</td>
                <td>
                    <form action="{$BASE_URL}actions/procedures/shareprocedure.php" method="post">
                        <input type="hidden" value="{$procedure.idprocedure}" name="idprocedure">
                        <button type="submit">Partilhar</button>
                    </form>
                </td>
                <td>
                    <form action="{$BASE_URL}actions/procedures/deleteprocedure.php" method="post">
                        <input type="hidden" value="{$procedure.idprocedure}" name="idprocedure">
                        <button type="submit">X</button>
                    </form>
                </td>
            </tr>
        {/foreach}

    </table>
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}