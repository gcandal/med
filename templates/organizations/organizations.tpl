{include file='common/header.tpl'}

{if $EMAIL}
    <h1>Organizações</h1>
    {foreach $ORGANIZATIONS as $organization}
        <p>Nome: {$organization.name}</p>
        {if $organization.orgauthorization == 'Admin'}
            <p>Autorização: Administrador</p>
        {else}
            <form action="{$BASE_URL}actions/organizations/editvisibility.php" method="post">
                <input type="hidden" name="idorganization" value="{$organization.idorganization}"/>

                <label>
                    Autorização:
                    <select name="visibility">
                        {if $organization.orgauthorization == 'Visible'}
                            <option value="Visible">Visível</option>
                            <option value="NotVisible">Invisível</option>
                        {elseif $organization.orgauthorization == 'AdminVisible'}
                            <option value="AdminVisible">Visível</option>
                            <option value="AdminNotVisible">Invisível</option>
                        {elseif $organization.orgauthorization == 'AdminNotVisible'}
                            <option value="AdminNotVisible">Invisível</option>
                            <option value="AdminVisible">Visível</option>
                        {else}
                            <option value="NotVisible">Invisível</option>
                            <option value="Visible">Visível</option>
                        {/if}
                    </select>
                </label>

                <button type="submit">Gravar alteração</button>
            </form>
        {/if}
        <form action="{$BASE_URL}pages/organizations/organization.php" method="get">
            <input type="hidden" name="idorganization" value="{$organization.idorganization}"/>
            <button type="submit">Ver detalhes</button>
        </form>
    {/foreach}
{else}
    <p>Tem que fazer login!</p>
{/if}

{include file='common/footer.tpl'}