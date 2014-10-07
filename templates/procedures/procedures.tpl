{include file='common/header.tpl'}

{if $EMAIL}
    <h1>Dr. {$USERNAME},</h1>
    <h2>Tem {$OPENPROCEDURES.number} procedimentos por concluir.</h2>
    <p><a href="{$BASE_URL}pages/procedures/addprocedure.php">Adicionar Procedimento</a></p>
    <table class="procedureTable" border="1">
        <tr>
            <th>Data</th>
            <th>Estado</th>
            <th>Pagador</th>
            <th>Sub-Procedumentos</th>
            <th>Equipa</th>
            <th>Valor</th>
            <th>Partilhar</th>
            <th>Apagar</th>
        </tr>

        {foreach $PROCEDURES as $procedure}
            <tr>
                <td>{$procedure.date}</td>
                <td>{$procedure.paymentstatus}</td>
                {if $procedure.idpayer == 0}
                    <td>{$procedure.payerName}</td>
                {else}
                    <td>
                        <a href="{$BASE_URL}pages/payers/payers.php">{$procedure.payerName}</a>
                    </td>
                {/if}
                <td>{$procedure.subprocedures}</td>
                <td>
                    <a href="{$BASE_URL}pages/procedures/professionals.php?idProcedure={$procedure.idprocedure}">Ver</a>
                </td>
                <td>
                    {if $procedure.wasassistant}
                        Pessoal: {$procedure.personalremun}
                    {else}
                        Total: {$procedure.totalremun}
                    {/if}
                    &euro;</td>
                <td>
                    {if !$procedure.wasassistant}
                        <form action="{$BASE_URL}actions/procedures/shareprocedure.php" method="post">
                            <input type="hidden" value="{$procedure.idprocedure}" name="idprocedure">
                            <button type="submit">Partilhar</button>
                        </form>
                    {/if}
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