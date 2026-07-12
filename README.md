# ScreenUp

ScreenUp e um app de Picture-in-Picture para Linux/Wayland, com suporte direto a
GNOME Shell e KDE Plasma/KWin.

Ele nao usa iframe, HTML ou Electron para tocar o video. O app GTK recebe uma URL
do YouTube, inicia o `mpv` com `yt-dlp` e o compositor do desktop mantem a janela
do player acima das outras janelas.

## Dependencias Fedora

```bash
sudo dnf install python3-gobject gtk4 mpv yt-dlp
```

No GNOME, instale tambem `gnome-extensions-app`. No KDE Plasma, o instalador usa
as ferramentas do KWin, como `kwriteconfig6`/`kreadconfig6`.

Mantenha o `yt-dlp` atualizado se o YouTube parar de carregar videos.

## Instalar No Sistema

```bash
npm run install
```

Esse comando instala duas coisas:

- o app `ScreenUp` no menu do sistema.
- o icone `screenup` no tema local de icones, em SVG e PNGs de varios tamanhos.
- a extensao `ScreenUp PiP` no GNOME Shell, quando voce estiver no GNOME.
- a regra `screenup-pip-keep-above` no KWin, quando voce estiver no KDE Plasma.

Depois disso, confirme o estado do ambiente:

```bash
npm run doctor
```

Em Wayland, se a extensao GNOME ou a regra KWin nao aplicar imediatamente, saia e
entre novamente na sessao.

## Como Rodar

Para uso normal, abra `ScreenUp` pelo menu de aplicativos do sistema.

Para desenvolvimento, voce ainda pode abrir pelo terminal:

```bash
npm run preview
```

Cole uma URL do YouTube e clique em `Tocar`. A janela de video aberta pelo `mpv`
deve ir para o canto inferior direito e ficar acima das outras janelas.

O app tambem tem botoes de tamanho (`480p`, `720p`, `900p`). A janela do `mpv`
mantem borda para permitir redimensionamento manual pelo compositor.

Na janela do video, passe o mouse por cima para mostrar controles rapidos:

- esquerda: voltar 10 segundos.
- centro: pausar ou retomar.
- direita: avancar 10 segundos.

## Scripts

```bash
npm run install
npm run doctor
npm run preview
npm run lint
npm run reload:extension
```

## Como Funciona

- `src/screenup/__main__.py`: app GTK que recebe URL e controla o player.
- `src/screenup/mpv_player.py`: inicia o `mpv` com socket IPC local.
- `src/screenup/mpv/pip_controls.lua`: desenha os controles de hover dentro da
  janela do video.
- `src/screenup/youtube.py`: valida URLs comuns do YouTube.
- `gnome-extension/screenup-pip@screenup.local/extension.js`: extensao GNOME que
  identifica a janela `ScreenUp PiP` e chama APIs do compositor para mantê-la
  acima.
- `scripts/install-app.sh`: cria `~/.local/bin/screenup` e
  `~/.local/share/applications/screenup.desktop`.
- `assets/screenup.svg`: icone do aplicativo instalado no menu do sistema.
- `scripts/install-kwin-rule.sh`: cria uma regra KWin para forcar a janela
  `ScreenUp PiP` acima das outras no KDE Plasma.
- `scripts/doctor.sh`: verifica dependencias, estado da extensao e logs recentes.

## Validacao

```bash
npm run lint
```
