# Manual do MM Radio

## Introdução
O MM Radio é um sistema de comunicação por rádio moderno para FiveM com UI elegante, efeitos de submix para áudio realista, canais configuráveis com restrições de job/gang, sistema de bateria, jammers e overlay de jogadores.

## Funcionalidades Principais
- UI de rádio moderna e redimensionável
- Efeitos de submix para áudio realista de rádio
- Restrições de canais por job/gang
- Sistema de bateria configurável
- Overlay mostrando jogadores no rádio
- Sistema de jammer (bloqueio de sinal)
- Nomes de exibição de canais personalizáveis
- Otimizado: 0.00ms resmon
- Integração com pma-voice e bl_bridge

## Frameworks Suportados
| Framework | Status |
|-----------|--------|
| QBCore | Completo |
| ESX | Completo |
| QBox | Completo |
| ND Core | Completo |
| Standalone | Completo (apenas lista de jobs) |

## Dependências
| Dependência | Obrigatório | Notas |
|------------|-----------|-------|
| ox_lib | Sim | Biblioteca utilitária |
| pma-voice | Sim | Sistema de voz |
| bl_bridge | Sim | Bridge de framework |
| OneSync | Sim | Deve estar habilitado |

## Configuração (`shared/config.lua`)
```lua
Config = {
    EnableSubmix = true,
    EnableBattery = false,
    DefaultChannel = 1,
    EnableOverlay = true,
    OverlayPosition = {x = 0.5, y = 0.95},
    OverlaySize = 1.0,
    EnableJammers = true,
    DefaultJammerRange = 50.0,
    AllowedFrequencies = {1, 2, 3},
    RestrictedChannels = {
        [1] = {jobs = {'police', 'sheriff'}},
        [2] = {gangs = {'ballas', 'families'}}
    }
}
```

## Comandos
| Comando | Descrição | Permissão |
|---------|-------------|------------|
| `/radio [channel]` | Entrar no canal | Todos |
| `/jammer` | Colocar/remover jammer | Job configurado |
| `/setchannelname [channel] [name]` | Definir nome do canal | Admin |

## Keybinds
- Tecla padrão: `LMENU` (Left Alt) para falar no rádio quando conectado
- Configure em `Esc > Settings > Keybinds > FiveM`

## Eventos
### Cliente
| Evento | Parâmetros | Descrição |
|-------|-------------|-------------|
| `mm_radio:client:JoinRadio` | `channel` (int) | Entrar no canal |
| `mm_radio:client:LeaveRadio` | — | Sair do canal |
| `mm_radio:client:UpdateOverlay` | `players` (table) | Atualizar overlay |

### Servidor
| Evento | Parâmetros | Descrição |
|-------|-------------|-------------|
| `mm_radio:server:JoinRadio` | `source, channel` | Jogador entrou no rádio |
| `mm_radio:server:PlaceJammer` | `source, coords` | Jammer colocado |
| `mm_radio:server:RemoveJammer` | `source, jammerId` | Jammer removido |

## Exports
### Cliente
| Export | Descrição | Parâmetros |
|--------|-------------|-------------|
| `JoinRadio` | Entrar no canal | `channel` (number) |
| `LeaveRadio` | Sair do canal atual | Nenhum |
| `SetRadioEnabled` | Habilitar/desabilitar rádio | `enabled` (boolean) |
| `SetChannelName` | Definir nome do canal | `channel` (int), `name` (string) |

### Servidor
| Export | Descrição | Parâmetros |
|--------|-------------|-------------|
| `AddPlayerToRadio` | Adicionar ao canal | `source` (int), `channel` (int) |
| `RemovePlayerFromRadio` | Remover do canal | `source` (int) |
| `GetPlayersInChannel` | Obter jogadores no canal | `channel` (int) |
| `AddJammer` | Adicionar jammer | `coords` (vector3), `range` (float) |
| `RemoveJammer` | Remover jammer | `jammerId` (int) |

## Solução de Problemas
- **Rádio não conecta**: Verifique se o pma-voice e bl_bridge estão iniciados antes do mm_radio.
- **Submix não funciona**: Confira se o `EnableSubmix` está habilitado em `config.lua`.
- **Jammers não funcionam**: Certifique-se de que o `EnableJammers` está habilitado e o jogador tem permissão.
