# Maje naładki dla VimWiki dla siabroŭ

Prabačcie, niama času aformić heta ŭsio ŭ jakaści plugin.
Zaraz heta prosta nabor kanfiguracyjnych fajłaŭ.

- `vimrc` - tolki padłučeńnie dadatkaŭ
- `dotfiles/vim-commons.vim` - amal usie naładki, vyniesienyja ŭ asobny fajl, tamu što ŭžyvaliś jak dla Vim tak i dla NeoVim.
- `dotfiles/vw-wrap.vim` - usie funkcyi datyčnyja VimWiki
- `dotfiles/cal-wrap.vim` - naładki i funkcyi dla `itchyny/calendar.vim`. Integracyja z VimWiki

Kanfiguracyja davoli aktyŭna ŭžyvaje `BurntSushi/ripgrep`. U hetym vyhladzie "hard-coded" dla Windows, bo najčaściej
užyvajecca na pracoŭnym kamputary. Dla Linux treba źmianić symbali katalohu ŭ niekatorych miescach.

## Kamandy dla VimWiki

### `VWA` (funkcyja `VwAgenda()`)

Stvaryć ci pierajści da redahavańnia fajła agendy (`agenda.md`). Sabrać tudy zadačy z budučych dzionnych natatak.

### `VWD` (funkcyja `VwDailcyCopy()`)

Stvaryć siońniašniuju štodzionnyju natatku. Sabrać tudy niavykananyja zadačy ź minułych dzionnych natatak. Pošuk
spyniajecca kali znojdzienaja natatka z zahałoŭkam `vikinote` u YAML siekcyi.

### `VWC` (funkcyja `VwCalSync()`)

Sinchranizavać zadačy z štodzionnych natatak z kalandarom `itchyny/calendar.vim` i adlustravać kalandar.
Dadaje ŭ kalandar zadačy, paznačanyja zoračkaj, ihnaruje tyja, što pačynajucca z rysački:

```
- [ ] inharujecca
* [ ] dadajecca ŭ kalandar
```

Možna taksama paznačyć čas vykanańnia ŭ dužkach u pačatku apisańnia:

```
* [ ] (15:00-14:30) sustreča
```
