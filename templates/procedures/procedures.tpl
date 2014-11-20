{include file='common/header.tpl'}

<style>
    .procedurePendente {
        background-color: red;
    }

    .procedureRecebi {
        background-color: yellow;
    }

    .procedurePaguei {
        background-color: green;
    }
</style>

{if $EMAIL}
    <h1>Dr. {$NAME},</h1>
    <h2>Tem {$OPENPROCEDURES.number} registos por concluir.</h2>
    <p><a href="{$BASE_URL}pages/procedures/addprocedure.php">Adicionar Registo</a></p>
    <table class="procedureTable" border="1">
        <tr>
            <th>Data</th>
            <th>Estado</th>
            <th>Pagador</th>
            <th>Cirurgias</th>
            <th>Função</th>
            <th>Valor</th>
            <th>Partilhar</th>
            <th>Detalhes</th>
            <th>Apagar</th>
        </tr>

        {foreach $PROCEDURES as $procedure}
            <tr class="procedure{$procedure.paymentstatus}">
                <td>{$procedure.date}</td>
                <td>{$procedure.paymentstatus}</td>
                {if $procedure.idpayer == 0}
                    <td>{$procedure.payerName}</td>
                {else}
                    <td>
                        <a href="{$BASE_URL}pages/payers/payers.php">{$procedure.payerName}</a>
                    </td>
                {/if}
                <td>
                    {foreach $procedure.subprocedures as $subprocedure}
                        {$subprocedure.quantity}x {$subprocedure.name}
                        <br>
                    {/foreach}
                </td>
                <td>
                    {if $procedure.role == 'General'}
                        Cirurgião Principal
                    {elseif $procedure.role == 'FirstAssistant'}
                        Primeiro Assitente
                    {elseif $procedure.role == 'SecondAssistant'}
                        Segundo Assistente
                    {elseif $procedure.role == 'Anesthetist'}
                        Anestesista
                    {elseif $procedure.role == 'Instrumentist'}
                        Instrumentista
                    {/if}
                </td>
                <td>
                    Pessoal: {$procedure.personalremun}&euro;<br>
                    Total: {$procedure.totalremun}&euro;
                </td>
                <td>
                    {if !$procedure.readonly}
                        <form action="{$BASE_URL}actions/procedures/shareprocedure.php" method="post">
                            <input type="hidden" value="{$procedure.idprocedure}" name="idprocedure">
                            <button type="submit">Partilhar</button>
                        </form>
                    {/if}
                </td>
                <td>
                    {if !$procedure.readonly}
                        <form action="{$BASE_URL}pages/procedures/editprocedure.php" method="post">
                            <input type="hidden" value="{$procedure.idprocedure}" name="idprocedure">
                            <button type="submit">Ver</button>
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