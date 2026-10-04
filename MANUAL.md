# mm_radio: Manual

Rádio com NUI arrastável, canais restritos por job/gang, sistema de bateria e jammers de sinal, integrado ao `pma-voice`. Esta é a versão do Qbox (`Qbox-project/mm_radio`), que fala direto com o `qbx_core` e o `ox_inventory`, sem `bl_bridge`.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Itens](#itens)
4. [Configuração](#configuração)
5. [Canais restritos](#canais-restritos)
6. [Bateria](#bateria)
7. [Jammer](#jammer)
8. [Comandos](#comandos)
9. [Teclas de atalho](#teclas-de-atalho)
10. [Integrações](#integrações)
11. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
12. [Localização](#localização)
13. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `pma-voice` | Sim | Canal de rádio, volume e estado de fala |
| `ox_lib` | Sim | Versão mínima **3.14.0**. Zonas, keybinds, callbacks, comandos, locale |
| `qbx_core` | Sim | Dados do jogador (`@qbx_core/modules/playerdata.lua` e `exports.qbx_core`) |
| `ox_inventory` | Sim | Itens, metadados do rádio e contagem de rádios do jogador |
| OneSync | Sim | Declarado como `/onesync` no `fxmanifest.lua` |

Na inicialização, o recurso confere a versão do `ox_lib` e a existência de `build/index.html`. Se alguma checagem falhar, `Shared.Ready` vira `false` e os comandos não são registrados.

---

## Instalação

1. Copie a pasta `mm_radio` para `resources/`.
2. Adicione ao `server.cfg`, depois do `pma-voice`, do `ox_lib`, do `qbx_core` e do `ox_inventory`:
   ```
   ensure mm_radio
   ```
3. Cadastre os itens no `ox_inventory` (ver [Itens](#itens)). O uso é registrado pelo próprio recurso.
4. Confirme que o `build/` está presente. Nesta fork ele é versionado no repositório.

---

## Itens

Os itens são registrados como usáveis em runtime (`server/items.lua`), com `exports.qbx_core:CreateUseableItem`. No `ox_inventory/data/items.lua` basta o cadastro comum do item, sem `client.event`:

```lua
['radio'] = {
    label = 'Rádio',
    weight = 1000,
    stack = false,
    allowArmed = true,
},
```

O `jammer` só é registrado com `Shared.Jammer.state = true`, e o `radiocell` só com `Shared.Battery.state = true`.

| Item | Uso | Observação |
|---|---|---|
| `radio` | Abre a UI do rádio | Registra cada nome de `Shared.RadioItem`, que aceita mais de um item |
| `jammer` | Coloca um jammer à frente do jogador | O servidor confere a permissão e remove o item ao colocar |
| `radiocell` | Recarrega a bateria do rádio para 100% | O servidor remove uma célula ao recarregar |

Com a bateria ligada, cada item `radio` recebe um `radioId` nos metadados no primeiro uso. É esse id que identifica a carga daquele rádio específico. Com a bateria desligada, o rádio aparece como `PERSONAL` e sempre com 100%.

---

## Configuração

A configuração está dividida em dois arquivos carregados como `shared_script`.

### `shared/init.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `Shared.Ready` | bool | Sim | Definido pelo próprio recurso. Vira `false` se o build ou o `ox_lib` estiverem faltando |
| `Shared.UseCommand` | bool | Sim | Registra os comandos `/radio`, `/jammer` e `/rechargeradio`. Padrão: `true` |
| `Shared.Debug` | bool | Sim | Desenha as esferas das zonas de jammer. Padrão: `false` |
| `Shared.Overlay` | string | Sim | Overlay com a lista de jogadores no canal: `default` (o jogador escolhe), `always` ou `never` |

### `shared/shared.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `Shared.MaxFrequency` | number | Sim | Frequência máxima aceita. Padrão: `500.00` |
| `Shared.LeaveOnDeath` | bool | Sim | Sai do canal ao morrer ou cair em last stand. Padrão: `true` |
| `Shared.RadioItem` | string[] | Sim | Nomes dos itens que funcionam como rádio. Padrão: `{'radio'}` |
| `Shared.RadioNames` | tabela | Não | Rótulo de exibição por canal. A chave `"1"` casa com o canal exato; `"1.%"` casa com qualquer subfrequência de 1 |
| `Shared.RestrictedChannels` | tabela | Não | Canais bloqueados por job ou gang (ver abaixo) |
| `Shared.Jammer.state` | bool | Sim | Liga o sistema de jammer. Padrão: `false` |
| `Shared.Jammer.model` | string | Sim | Prop do jammer. Padrão: `sm_prop_smug_jammer` |
| `Shared.Jammer.permission` | string[] | Sim | Jobs ou gangs que podem colocar e configurar jammers. Padrão: `{"police"}` |
| `Shared.Jammer.default` | tabela | Não | Jammers criados automaticamente no start. Cada item aceita `coords`, `id`, `range`, `allowedChannels` e `canDamage` |
| `Shared.Jammer.range` | tabela | Sim | `min`, `max`, `step` e `default` do slider de alcance |
| `Shared.Battery.state` | bool | Sim | Liga o consumo de bateria. Padrão: `false` |
| `Shared.Battery.consume` | number | Sim | Quanto de carga (0 a 100) é consumido a cada ciclo. Padrão: `1` |
| `Shared.Battery.depletionTime` | number | Sim | Intervalo do ciclo de consumo, em minutos. Padrão: `1` |

---

## Canais restritos

`Shared.RestrictedChannels` é indexado pelo número inteiro do canal. Subfrequências (ex.: `1.25`) herdam a restrição do canal inteiro, porque a checagem usa `math.floor(channel)`.

```lua
Shared.RestrictedChannels = {
    [1] = {
        type = 'job',           -- 'job' ou 'gang'
        name = {"police", "ambulance"}
    },
    [420] = {
        type = 'gang',
        name = {"ballas"}
    },
}
```

- `type = 'job'`: o jogador precisa ter o job **e estar em serviço** (`onDuty`).
- `type = 'gang'`: basta pertencer à gang.

O servidor também confere o job ou a gang antes de colocar o jogador na lista do canal, então a restrição não depende só do cliente.

Os canais aos quais o jogador tem direito entram automaticamente na lista de favoritos dele ao carregar o personagem.

---

## Bateria

Desligada por padrão. Ativa com `Shared.Battery.state = true` (e o item `radiocell` cadastrado).

- Cada rádio começa com 100 de carga, identificado pelo `radioId` nos metadados do item.
- A cada `Shared.Battery.depletionTime` minutos, o cliente avisa o servidor e a carga cai `Shared.Battery.consume`. O servidor ignora avisos antes do intervalo e só desconta dos rádios que o jogador realmente tem.
- Ao chegar em zero, o jogador é desconectado do canal automaticamente (`mm_radio:client:nocharge`).
- Usar o item `radiocell` (ou o comando `/rechargeradio`) consome a célula e devolve a carga a 100.
- As cargas são gravadas em `battery.json` no `onResourceStop` e recarregadas no `onResourceStart`. Reinícios do recurso preservam o estado, mas um crash do servidor não.

---

## Jammer

Desligado por padrão. Ativo com `Shared.Jammer.state = true` (e o item `jammer` cadastrado).

Um jogador com job ou gang listado em `Shared.Jammer.permission` usa o item `jammer` (ou o comando `/jammer`) e o prop é colocado à sua frente. O servidor confere a permissão, a distância (até 3 m do jogador) e remove o item. O jammer cria duas esferas: a **zona de bloqueio**, com o alcance configurado, e uma esfera de 2,5 m em volta do prop que exibe `[E] Configure Jammer`.

Dentro da zona de bloqueio, quem estiver em um canal fora da lista de canais permitidos daquele jammer tem o canal do `pma-voice` zerado até sair, e não consegue entrar em nenhum canal bloqueado enquanto estiver lá dentro.

Pressionando `E` junto ao prop, quem tem permissão abre o menu de configuração (o servidor exige estar a até 3 m do prop):

| Opção | Efeito |
|---|---|
| Toggle Jammer Switch | Liga/desliga o jammer sem removê-lo |
| Remove Jammer | Remove o prop. Só aparece habilitada se o jammer tiver `canRemove`. Devolve o item `jammer` ao jogador, exceto se o prop tiver sido destruído |
| Change Jammer Range | Slider de alcance, limitado por `Shared.Jammer.range` |
| Allowed Channel | Adiciona ou remove canais que continuam funcionando dentro da zona (até 32) |

Jammers criados por jogadores nascem com `canDamage = true`: podem ser destruídos a tiros. Ao chegarem a 0 de vida, param de bloquear e não podem mais ser configurados. Jammers de `Shared.Jammer.default` nascem com `canRemove = false`.

Todos os jammers ativos são deletados quando o recurso para. Eles não sobrevivem a um restart, exceto os declarados em `Shared.Jammer.default`.

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/radio` | Todos | Abre a UI do rádio. Registrado apenas se `Shared.UseCommand = true` |
| `/jammer` | Todos (job/gang conferido no servidor) | Coloca um jammer. Registrado sob a mesma condição do `/radio` |
| `/rechargeradio` | Todos | Recarrega a bateria consumindo um `radiocell`. Registrado sob a mesma condição do `/radio` |
| `/remradiodata` | Todos | Apaga as preferências locais do jogador (favoritos, nome, posição e tamanho da UI) e recria os padrões |

As preferências da UI ficam no KVP local do cliente, na chave `radioSettings2`, não no banco de dados.

---

## Teclas de atalho

Registradas via `lib.addKeybind` e remapeáveis pelo jogador em `Esc > Configurações > Atalhos de teclado > FiveM`.

| Ação | Tecla padrão | Descrição |
|---|---|---|
| `radio` | `=` (EQUALS) | Abre o rádio. Só funciona se o jogador tiver o item |
| `+channel` | `.` (PERIOD) | Sobe um canal |
| `-channel` | `,` (COMMA) | Desce um canal |

---

## Integrações

### pma-voice

É o transporte de voz do rádio. O `mm_radio` chama `setVoiceProperty("radioEnabled", ...)`, `setRadioChannel(...)` e `setRadioVolume(...)`, e escuta `pma-voice:radioActive` e `pma-voice:setTalkingOnRadio` para acender o indicador de quem está falando na lista.

### qbx_core

O cliente lê `QBX.PlayerData` e reage a `QBCore:Client:OnPlayerLoaded`, `OnPlayerUnload`, `OnJobUpdate`, `OnGangUpdate`, `SetDuty` e `QBCore:Player:SetPlayerData`. O servidor usa `exports.qbx_core:GetPlayer` para job, gang e nome do personagem.

### qbx_medical

O statebag `qbx_medical:deathState` do jogador marca morte e last stand. Com `Shared.LeaveOnDeath = true`, o jogador sai do canal nesse momento.

### ox_inventory

O uso dos itens chega pelo `CreateUseableItem` do `qbx_core`, que o `ox_inventory` chama ao usar o item. O `radioId` é gravado com `exports.ox_inventory:SetMetadata`, e o evento `ox_inventory:updateInventory` dispara a recontagem dos rádios que o jogador tem. Ao perder o último rádio, o jogador sai do canal.

---

## Entrypoints para outros recursos

### Exports de cliente

```lua
-- Conecta o jogador a um canal. Passa pelas mesmas validações da UI:
-- jammer, frequência máxima (Shared.MaxFrequency) e canais restritos.
exports.mm_radio:JoinRadio(channel)

-- Desconecta do canal atual.
exports.mm_radio:LeaveRadio()
```

### Eventos de cliente

```lua
-- Abre a UI do rádio (é o que o item 'radio' dispara).
TriggerClientEvent('mm_radio:client:use', source)

-- Coloca um jammer à frente do jogador.
TriggerClientEvent('mm_radio:client:usejammer', source)

-- Recarrega a bateria consumindo um radiocell.
TriggerClientEvent('mm_radio:client:recharge', source)

-- Fecha a UI do rádio.
TriggerEvent('mm_radio:client:remove')

-- Apaga as preferências locais do jogador.
TriggerClientEvent('mm_radio:client:removedata', source)
```

### Callbacks de servidor

```lua
-- Carga atual (0-100) e id do rádio que o jogador está carregando.
local battery, radioId = lib.callback.await('mm_radio:server:getradiodata', false)

-- Lista de todos os jammers ativos no servidor.
local jammers = lib.callback.await('mm_radio:server:getjammer', false)
```

---

## Localização

As strings vêm do locale do `ox_lib` (`lib.locale()`). Os arquivos ficam em `locales/`: `cs`, `de`, `en`, `es`, `fr`, `ja`, `pl`, `pt-br` e `tr`.

O locale ativo é definido pela convar no `server.cfg`:

```
setr ox:locale "pt-br"
```

Os textos do menu do jammer (`Jammer Configuration`, `[E] Configure Jammer`, etc.) estão em inglês fixo no código, fora do sistema de locale.

---

## Estrutura de arquivos

```
mm_radio/
├── client/
│   ├── interface.lua     # tabela de estado Radio e evento de reset das preferências
│   ├── function.lua      # conexão ao canal, animação, jammers, bateria, keybinds, exports
│   ├── event.lua         # eventos de rede, sync dos jammers, morte, qbx_core, pma-voice
│   └── nui.lua           # callbacks da NUI (join, leave, volume, favoritos, layout)
├── server/
│   ├── main.lua          # canais, jammers, bateria, validações, comandos, callbacks
│   └── items.lua         # registro dos itens usáveis (radio, jammer, radiocell)
├── shared/
│   ├── init.lua          # flags gerais e checagem de dependências
│   └── shared.lua        # frequência máxima, itens, jammer, bateria, canais restritos, nomes de canal
├── build/                # UI compilada (Svelte), versionada nesta fork
├── web/                  # código-fonte da UI
├── locales/              # cs, de, en, es, fr, ja, pl, pt-br, tr
├── battery.json          # carga dos rádios, gravada no stop e lida no start
└── fxmanifest.lua
```
