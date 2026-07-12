# ScreenUp

ScreenUp é um app para Linux que você cola a URL e abre um popup que fica por cima de todos os outros apps. Sinto que faltava isso no Linux.

## Instalar

Você precisa de **Linux** e **Node.js** (só para rodar o instalador). O resto o script cuida.

```bash
git clone https://github.com/SEU_USUARIO/screenup.git
cd screenup
npm run install
```

Na primeira vez, o instalador pode pedir sua senha (`sudo`) para baixar `mpv`, `yt-dlp` e o que mais faltar no sistema. Depois disso, o **ScreenUp** aparece no menu de aplicativos.

> Ainda não está no npm como pacote global (`npm install screenup` de fora). Por enquanto é clonar o repositório e rodar `npm run install` dentro da pasta.

## Usar

1. Abra **ScreenUp** pelo menu.
2. Cole a URL do YouTube — o vídeo abre sozinho.
3. A janelinha fica por cima enquanto você usa outros programas.

**Controles no vídeo** (passe o mouse):

- Esquerda: voltar 10s
- Centro: pausar / play
- Direita: avançar 10s

## Se der problema

```bash
npm run doctor
```

Mostra o que está faltando. Se preferir instalar as dependências do sistema à mão:

| Distro | Comando |
|--------|---------|
| Fedora | `sudo dnf install python3-gobject gtk4 mpv yt-dlp` |
| Ubuntu / Debian | `sudo apt install python3-gi gir1.2-gtk-4.0 mpv yt-dlp` |
| Arch | `sudo pacman -S python-gobject gtk4 mpv yt-dlp` |

## Licença

MIT
