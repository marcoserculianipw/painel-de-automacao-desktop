# Painel de Automação Desktop

[![Plataforma](https://img.shields.io/badge/plataforma-Windows%2010%20%7C%2011-0078D4.svg)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE.svg)](https://learn.microsoft.com/powershell/)
[![Interface](https://img.shields.io/badge/UI-WPF%20XAML-252525.svg)](https://learn.microsoft.com/dotnet/desktop/wpf/)
[![Licença](https://img.shields.io/badge/licença-MIT-green.svg)](LICENSE)

Aplicação desktop leve desenvolvida em PowerShell e Windows Presentation Foundation (WPF) para automação e inicialização ordenada de rotinas de trabalho no Windows 11.

---

## Visão Geral

O projeto automatiza o processo de abertura de ferramentas corporativas e ambientes de trabalho diários (planilhas Google Sheets, Microsoft Outlook, Microsoft Teams, WhatsApp Desktop, sistemas web e ferramentas locais).

Diferente de alternativas empacotadas com Electron ou navegadores embarcados, a aplicação é executada de forma nativa sobre o subsistema WPF do Windows:
- Não requer instalação de interpretadores ou runtimes de terceiros (como Node.js ou Python).
- Consumo mínimo de recursos (~35 MB de memória em execução).
- Interface declarativa em XAML seguindo os padrões do Windows 11 (modo escuro, cantos arredondados e tipografia Segoe UI Variable).
- Execução desacoplada via VBScript, eliminando a exibição de janelas de console do prompt de comando.

---

## Funcionalidades

- **Inicialização em lote ordenada:** Lançamento sequencial de programas e links com intervalo de tempo configurável para evitar sobrecarga de I/O.
- **Seleção granular de rotina:** Cada item possui controle de estado (Abrir / Pular) para permitir a execução parcial conforme a demanda do dia.
- **Ações rápidas de seleção:** Botões para seleção e desseleção em lote com atualização dinâmica de contadores.
- **Prevenção de processos duplicados:** Verificação prévia de instâncias em execução antes do disparo de novos processos.
- **Integração com Google Chrome:** Abertura sequencial de planilhas e URLs em abas organizadas do navegador.
- **Gerenciador de recursos integrado:**
  - Interface para cadastro de novos itens (Planilhas, URLs, Executáveis e Pastas).
  - Remoção direta de itens da rotina.
- **Painel de preferências:**
  - Configuração do nome do operador.
  - Formato de saudação (automático por período do dia ou mensagem customizada).
  - Paleta de cores de destaque (Azul Windows, Verde Office, Roxo e Cinza Grafite).
  - Comportamento de encerramento pós-inicialização.
- **Modo CLI / Headless:** Script complementar (`iniciar.ps1`) para execução silenciosa em pipelines ou Agendador de Tarefas do Windows.

---

## Requisitos

- Windows 10 ou Windows 11 (64-bit)
- Windows PowerShell 5.1 ou superior (nativo do sistema operacional)
- Google Chrome (recomendado para links de planilhas)

---

## Instalação e Execução

### 1. Clonar o repositório
```bash
git clone https://github.com/marcoserculianipw/painel-de-automacao-desktop.git
```

### 2. Gerar o atalho da Área de Trabalho
Execute o instalador auxiliar de atalho:
```cmd
Criar_Atalho_Area_de_Trabalho.bat
```
O atalho `iniciartudo` será gerado automaticamente na Área de Trabalho com o ícone do sistema.

### 3. Utilização
- Dê um duplo clique no atalho `iniciartudo`.
- Ajuste os itens que deseja iniciar no painel.
- Clique em **Iniciar rotina de trabalho**.

---

## Estrutura do Repositório

```text
├── minipainel.ps1                   # Interface gráfica principal em WPF e motor de eventos
├── config.json                      # Configurações do usuário e relação de itens cadastrados
├── config.example.json              # Modelo de configuração para referência
├── iniciar.ps1                      # Executor de linha de comando para automação headless
├── iniciar_tudo.vbs                 # Wrapper de execução silenciosa (SW_HIDE)
├── iniciar_tudo.bat                 # Script de inicialização auxiliar
├── criar_atalho.ps1                 # Gerador do atalho .lnk via WScript.Shell
├── Criar_Atalho_Area_de_Trabalho.bat # Script batch de disparo para criação do atalho
├── .gitignore                       # Filtro de arquivos locais e temporários
└── assets/                          # Recursos visuais e logotipos em alta definição
    ├── sheets.png
    ├── outlook.png
    ├── teams.png
    ├── whatsapp.png
    ├── chrome.png
    └── folder.png
```

---

## Formato de Configuração (`config.json`)

As definições da aplicação residem em `config.json`. A estrutura suporta os tipos `url`, `app` e `folder`:

```json
{
  "user": {
    "name": "Marcos",
    "greetingType": "auto",
    "customGreeting": "",
    "closeAfterLaunch": true,
    "accentColor": "#0067C0"
  },
  "settings": {
    "delaySeconds": 0.8,
    "preventDuplicates": true
  },
  "items": [
    {
      "id": "planilha_exemplo",
      "name": "Planilha de Agendamento",
      "category": "Planilha",
      "type": "url",
      "target": "https://docs.google.com/spreadsheets/d/SEU_ID_AQUI",
      "processName": "",
      "args": "",
      "enabled": true
    },
    {
      "id": "outlook",
      "name": "Microsoft Outlook",
      "category": "E-mail",
      "type": "app",
      "target": "C:\\Program Files\\Microsoft Office\\root\\Office16\\OUTLOOK.EXE",
      "processName": "OUTLOOK",
      "args": "",
      "enabled": true
    },
    {
      "id": "whatsapp",
      "name": "WhatsApp",
      "category": "Mensagens",
      "type": "app",
      "target": "whatsapp:",
      "processName": "",
      "args": "",
      "enabled": true
    }
  ]
}
```

---

## Licença

Distribuído sob a licença [MIT](LICENSE). Consulte o arquivo para mais informações.
