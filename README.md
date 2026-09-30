# Światło ekranu (Screen Light)

Lampa doświetlająca z ekranu Maca, do rozmów wideo i zdjęć. Ustawiasz jasność i kolor,
klikasz **Światło** — cały ekran świeci tym kolorem, a podświetlenie idzie na wybrany poziom.
Dowolny klawisz albo kliknięcie gasi światło i przywraca poprzednią jasność.

*English: a macOS fill light for video calls and photos — the screen lights your face. The app
follows the system language, look, accent color and Liquid Glass. Download below.*

<p>
  <img src="Screenshots/light-purple.jpg" width="200" alt="Jasny wygląd, akcent fioletowy">
  <img src="Screenshots/light-blue.jpg" width="200" alt="Jasny wygląd, akcent niebieski">
  <img src="Screenshots/light-green.jpg" width="200" alt="Jasny wygląd, akcent zielony">
  <img src="Screenshots/light-tinted.jpg" width="200" alt="Szkło zabarwione">
</p>

*Wygląd idzie za Ustawieniami systemowymi → Wygląd: od lewej akcent fioletowy, niebieski
i zielony, na końcu suwak Liquid Glass przesunięty na „zabarwione”.*

## Pobieranie i instalacja

1. Pobierz [Screen-Light.zip](https://github.com/EnderNoch/Screen-Light/raw/main/Screen-Light.zip).
2. Otwórz plik zip.
3. Przeciągnij **Screen Light.app** do folderu Aplikacje.

Wymaga macOS 26 lub nowszego na Macu z procesorem Apple.

### Pierwsze uruchomienie

Aplikacja nie jest notaryzowana przez Apple, więc za pierwszym razem macOS ją zablokuje:

1. Kliknij dwukrotnie **Screen Light.app** — pojawi się ostrzeżenie; zamknij je.
2. Otwórz **Ustawienia systemowe → Prywatność i ochrona**.
3. Przewiń w dół do komunikatu o Screen Light i kliknij **Otwórz mimo to**.

Wystarczy raz.

## Co potrafi

- **Światło** — cały ekran (i każdy podłączony monitor) świeci wybranym kolorem.
- **Doświetlenie ekranem** — pas światła wokół krawędzi ekranu, wzorowany na systemowym
  Doświetleniu ekranem: nie zasłania pracy, kliknięcia przez niego przechodzą, a przy kursorze
  gaśnie. Grubość ustawiasz suwakiem.
- **Photo Booth** — gdy Photo Booth jest na wierzchu, ramka włącza się sama wokół podglądu,
  inne ekrany świecą w całości, a po wyjściu z Photo Booth wszystko gaśnie.
- **Tarcza jasności** — przeciągasz po pierścieniu albo klikasz liczbę i wpisujesz wartość.
- **Kolory** — biały, ciepły, różowy, chłodny albo dowolny z systemowego panelu kolorów.
- **Pasek menu** — jasność, kolory i oba rodzaje światła pod ręką. Ikonę chowa się systemowo:
  Ustawienia systemowe → Pasek menu → Pozwalaj na pasku menu.
- **Wszystko z systemu** — język (43 języki), jasny i ciemny wygląd, kolor akcentu, suwak
  Liquid Glass i styl ikony (Domyślny, Ciemny, Przejrzysty, Matowy). Aplikacja nie ma własnych
  przełączników tam, gdzie system już je ma; zmiany w Ustawieniach widać od razu.
- **Otwiera się przy logowaniu** od pierwszego uruchomienia; wyłączasz w Ustawieniach
  systemowych → Ogólne → Rzeczy otwierane podczas logowania.

Samego światła nie widać na zrzutach ekranu — tak jak systemowego Doświetlenia ekranem.

## Budowanie ze źródeł

Wymaga Xcode (dla `actool`, który składa ikonę):

```bash
./build.sh
```

Skrypt kompiluje `Sources/`, składa ikonę z warstw `ScreenLight.icon`, podpisuje aplikację
ad hoc, odświeża `Screen-Light.zip` i instaluje ją w `/Applications` (działającą kopię
zamyka i otwiera już nową).

| Część | Plik |
| --- | --- |
| Aplikacja, okno i pasek menu (SwiftUI `Window` + `MenuBarExtra`) | `Sources/ScreenLightApp.swift` |
| Ustawienia (`@Observable`, UserDefaults), akcent z systemu, logowanie (`SMAppService`) | `Sources/Model.swift` |
| Podświetlenie, okna światła, Doświetlenie ekranem, Photo Booth | `Sources/Light.swift` |
| Okno i panel paska menu | `Sources/Views.swift` |
| Tłumaczenia (nazwa aplikacji w każdym języku jest w `build.sh`) | `Sources/Strings.swift` |
| Ikona z Icon Composera | `ScreenLight.icon` |

Jasność podświetlenia ustawia prywatny framework `DisplayServices` (na procesorach Apple nie ma
do tego publicznego API) i dotyczy wbudowanego ekranu; zewnętrzne monitory świecą samym obrazem.

## Licencja

Wszelkie prawa zastrzeżone — patrz [LICENSE](LICENSE). Aplikację wolno pobrać i używać;
kodu nie wolno kopiować, rozpowszechniać, zmieniać ani używać do trenowania modeli AI.

Część zestawu [Atypical Maker Mac Apps](https://github.com/EnderNoch/Atypical-Maker-Mac-Apps).
