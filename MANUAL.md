# mm_radio — Manual

Rádio com NUI arrastável, canais restritos por job/gang, sistema de bateria e jammers de sinal, integrado ao `pma-voice`.

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
| `bl_bridge` | Sim | Versão mínima **1.2.2**. Bridge de framework e inventário |
| OneSync | Sim | Declarado como `/onesync` no `fxmanifest.lua` |

O recurso valida as versões de `ox_lib` e `bl_bridge` na inicialização e a existência de `build/index.html`. Se qualquer uma das checagens falhar, ele aborta com `Cannot Start Resource, MISSING DEPENDENCIES`.

---

## Instalação

1. Copie a pasta `mm_radio` para `resources/`.
2. Adicione ao `server.cfg`, depois do `pma-voice`, do `ox_lib` e do `bl_bridge`:
   ```
   ensure mm_radio
   ```
3. Cadastre os itens `radio`, `jammer` e `radiocell` no inventário do servidor (ver [Itens](#itens)).
4. Confirme que o `build/` está presente. O recurso não sobe sem `build/index.html`.

O framework e o inventário não são configurados no recurso: eles vêm das convars do `bl_bridge`.

```
setr bl:framework "qb"
setr bl:inventory "qb"
```

Valores de inventário reconhecidos no código: `ox`, `qb`, `ps` e `qs`. Se a convar `bl:inventory` não resolver para nenhum deles, os metadados de rádio (e portanto a bateria) não são gravados.

---

## Itens

| Item | Uso | Observação |
|---|---|---|
| `radio` | Abre a UI do rádio | O nome vem de `Shared.RadioItem`, que aceita mais de um item |
| `jammer` | Coloca um jammer à frente do jogador | Registrado como item usável apenas se `Shared.Jammer.state = true` |
| `radiocell` | Recarrega a bateria do rádio para 100% | Registrado como item usável apenas se `Shared.Battery.state = true` |

Cada item `radio` recebe um `radioId` nos metadados no primeiro uso. É esse id que identifica a carga da bateria daquele rádio específico.

---

## Configuração

A configuração está dividida em dois arquivos carregados como `shared_script`.

### `shared/init.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `Shared.Ready` | bool | Sim | Definido pelo próprio recurso. Vira `false` se o build ou uma dependência estiver faltando |
| `Shared.UseCommand` | bool | Sim | Registra os comandos `/radio`, `/jammer` e `/rechargeradio`. Padrão: `true` |
| `Shared.Core` | string | Sim | Framework, lido da convar `bl:framework`. Padrão: `qb` |
| `Shared.Inventory` | string | Sim | Inventário, lido da convar `bl:inventory`. Padrão: `qb`. Aceita `ox`, `qb`, `ps`, `qs` |
| `Shared.Debug` | bool | Sim | Desenha as esferas das zonas de jammer. Padrão: `false` |
| `Shared.Overlay` | string | Sim | Overlay com a lista de jogadores no canal: `default` (o jogador escolhe), `always` ou `never` |

### `shared/shared.lua`

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `Shared.MaxFrequency` | number | Sim | Frequência máxima aceita. Padrão: `500.00` |
| `Shared.RadioItem` | string[] | Sim | Nomes dos itens que funcionam como rádio. Padrão: `{'radio'}` |
| `Shared.RadioNames` | tabela | Não | Rótulo de exibição por canal. A chave `"1"` casa com o canal exato; `"1.%"` casa com qualquer subfrequência de 1 |
| `Shared.RestrictedChannels` | tabela | Não | Canais bloqueados por job ou gang (ver abaixo) |
| `Shared.Jammer.state` | bool | Sim | Liga o sistema de jammer |
| `Shared.Jammer.model` | string | Sim | Prop do jammer. Padrão: `sm_prop_smug_jammer` |
| `Shared.Jammer.permission` | string[] | Sim | Jobs ou gangs que podem colocar e configurar jammers. Padrão: `{"police"}` |
| `Shared.Jammer.default` | tabela | Não | Jammers criados automaticamente no start. Cada item aceita `coords`, `id`, `range`, `allowedChannels` e `canDamage` |
| `Shared.Jammer.range` | tabela | Sim | `min`, `max`, `step` e `default` do slider de alcance |
| `Shared.Battery.state` | bool | Sim | Liga o consumo de bateria |
| `Shared.Battery.consume` | number | Sim | Quanto de carga (0–100) é consumido a cada ciclo. Padrão: `1` |
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

- `type = 'job'` — o jogador precisa ter o job **e estar em serviço** (`onDuty`).
- `type = 'gang'` — basta pertencer à gang. Só é avaliado quando `bl:framework` é `qb`.

Os canais aos quais o jogador tem direito entram automaticamente na lista de favoritos dele ao carregar o personagem.

---

## Bateria

Ativa com `Shared.Battery.state = true`.

- Cada rádio começa com 100 de carga, identificado pelo `radioId` nos metadados do item.
- A cada `Shared.Battery.depletionTime` minutos, o cliente informa o servidor e a carga cai `Shared.Battery.consume`.
- Ao chegar em zero, o jogador é desconectado do canal automaticamente (`mm_radio:client:nocharge`).
- Usar o item `radiocell` (ou o comando `/rechargeradio`) consome a célula e devolve a carga a 100.
- As cargas são gravadas em `battery.json` no `onResourceStop` e recarregadas no `onResourceStart` — reinícios do recurso preservam o estado, mas um crash do servidor não.

---

## Jammer

Ativo com `Shared.Jammer.state = true`.

Um jogador com job ou gang listado em `Shared.Jammer.permission` usa o item `jammer` (ou o comando `/jammer`) e o prop é colocado à sua frente. O jammer cria duas esferas: a **zona de bloqueio**, com o alcance configurado, e uma esfera de 2,5 m em volta do prop que exibe `[E] Configure Jammer`.

Dentro da zona de bloqueio, quem estiver em um canal que não esteja na lista de canais permitidos daquele jammer tem o canal do `pma-voice` zerado até sair — e não consegue entrar em nenhum canal bloqueado enquanto estiver lá dentro.

Pressionando `E` junto ao prop, quem tem permissão abre o menu de configuração:

| Opção | Efeito |
|---|---|
| Toggle Jammer Switch | Liga/desliga o jammer sem removê-lo |
| Remove Jammer | Remove o prop. Só aparece habilitada se o jammer tiver `canRemove`. Devolve o item `jammer` ao jogador, exceto se o prop tiver sido destruído |
| Change Jammer Range | Slider de alcance, limitado por `Shared.Jammer.range` |
| Allowed Channel | Adiciona ou remove canais que continuam funcionando dentro da zona |

Jammers criados por jogadores nascem com `canDamage = true`: podem ser destruídos a tiros. Ao chegarem a 0 de vida, param de bloquear e não podem mais ser configurados. Jammers de `Shared.Jammer.default` nascem com `canRemove = false`.

Todos os jammers ativos são deletados quando o recurso para — eles não sobrevivem a um restart, exceto os declarados em `Shared.Jammer.default`.

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/radio` | Todos | Abre a UI do rádio. Registrado apenas se `Shared.UseCommand = true` ou se não houver inventário |
| `/jammer` | Todos (o job/gang é checado no cliente) | Coloca um jammer. Registrado sob a mesma condição do `/radio` |
| `/rechargeradio` | Todos | Recarrega a bateria consumindo um `radiocell`. Registrado sob a mesma condição do `/radio` |
| `/remradiodata` | Todos | Apaga as preferências locais do jogador (favoritos, nome, posição e tamanho da UI) e recria os padrões |

As preferências da UI ficam no KVP local do cliente, na chave `radioSettings2` — não no banco de dados.

---

## Teclas de atalho

Registradas via `lib.addKeybind` e remapeáveis pelo jogador em `Esc > Configurações > Atalhos de teclado > FiveM`.

| Ação | Tecla padrão | Descrição |
|---|---|---|
| `radio` | `=` (EQUALS) | Abre o rádio. Só funciona se o jogador tiver o item (ou se o recurso rodar sem inventário) |
| `+channel` | `.` (PERIOD) | Sobe um canal |
| `-channel` | `,` (COMMA) | Desce um canal |

---

## Integrações

### pma-voice

É o transporte de voz do rádio. O `mm_radio` chama `setVoiceProperty("radioEnabled", ...)`, `setRadioChannel(...)` e `setRadioVolume(...)`, e escuta `pma-voice:radioActive` e `pma-voice:setTalkingOnRadio` para acender o indicador de quem está falando na lista.

### bl_bridge

Abstrai framework e inventário. O `mm_radio` usa `Framework.core` (dados do jogador, `RegisterUsableItem`) e `Framework.inventory`, e reage aos eventos `bl_bridge:client:playerLoaded`, `playerUnloaded`, `jobUpdated` e `gangUpdated`.

### ox_inventory

Quando `bl:inventory` é `ox`, o `radioId` é gravado com `exports.ox_inventory:SetMetadata`. O evento `ox_inventory:updateInventory` dispara a recontagem dos rádios que o jogador tem.

### qs-inventory

Quando `bl:inventory` é `qs`, o `radioId` é gravado com `exports['qs-inventory']:SetItemMetadata`.

### QBCore

Além do bridge, o recurso escuta diretamente `QBCore:Player:SetPlayerData` (para detectar morte/last stand e mudanças de inventário) e `QBCore:Client:SetDuty` (serviço, exigido pelos canais restritos por job).

### ND Core

O evento `ND:updateCharacter` é escutado para acompanhar o estado de morte do personagem.

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

-- Coloca um jammer à frente do jogador (checa Shared.Jammer.permission).
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
-- Carga atual (0-100) do rádio que o jogador está carregando.
local battery = lib.callback.await('mm_radio:server:getbatterydata', false)

-- Lista de todos os jammers ativos no servidor.
local jammers = lib.callback.await('mm_radio:server:getjammer', false)
```

---

## Localização

As strings vêm do locale do `ox_lib` (`lib.locale()`). Os arquivos ficam em `locales/`:

- `cs.json` — tcheco
- `de.json` — alemão
- `en.json` — inglês
- `es.json` — espanhol
- `fr.json` — francês
- `pt-br.json` — português do Brasil

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
│   ├── interface.lua     — tabela de estado Radio e evento de reset das preferências
│   ├── function.lua      — conexão ao canal, animação, jammers, bateria, keybinds, exports
│   ├── event.lua         — eventos de rede, sync dos jammers, morte, framework, pma-voice
│   └── nui.lua           — callbacks da NUI (join, leave, volume, favoritos, layout)
├── server/
│   └── main.lua          — canais, jammers, bateria, itens usáveis, comandos, callbacks
├── shared/
│   ├── init.lua          — flags gerais, convars de framework/inventário, checagem de dependências
│   └── shared.lua        — frequência máxima, itens, jammer, bateria, canais restritos, nomes de canal
├── build/                — UI compilada (Svelte). Sem build/index.html o recurso não inicia
├── locales/              — cs, de, en, es, fr, pt-br
├── battery.json          — carga dos rádios, gravada no stop e lida no start
└── fxmanifest.lua
```
