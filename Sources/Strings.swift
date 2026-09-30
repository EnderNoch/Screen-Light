import Foundation

/// UI text in the same 43 languages as Prosty Timer. Each row of `table` lists the strings in
/// the order of the properties below. Where macOS has its own name for a thing (Edge Light,
/// Brightness, Color, Quit) the row carries the system's
/// wording, taken from its localization tables; languages macOS doesn't ship keep our own.
struct Strings {
    private let v: [String]

    var bright: String { v[0] }
    var color: String { v[1] }
    var light: String { v[2] }
    var edge: String { v[3] }
    var hint: String { v[4] }
    var boothNote: String { v[5] }
    var width: String { v[6] }
    /// "Open …" with the app's name in it.
    var open: String { String(format: v[7], Model.appName) }
    var quit: String { v[8] }

    private static let count = 9

    static func `for`(_ code: String) -> Strings {
        let row = table[code] ?? []
        return Strings(v: row.count == count ? row : table["en"]!)
    }

    static let rtl: Set = ["ar", "he", "fa"]

    /// First of the system's preferred languages that we have.
    static var detected: String {
        for id in Locale.preferredLanguages {
            if table[id] != nil { return id }
            let lang = Locale.Language(identifier: id)
            guard let code = lang.languageCode?.identifier else { continue }
            if code == "zh" {
                let hant = lang.script?.identifier == "Hant" || ["TW", "HK", "MO"].contains(lang.region?.identifier ?? "")
                return hant ? "zh-Hant" : "zh-Hans"
            }
            if code == "no" || code == "nn" { return "nb" }
            if table[code] != nil { return code }
        }
        return "en"
    }

    static let table: [String: [String]] = [
        "pl": ["Jasność", "Kolor", "Światło", "Doświetlenie ekranem", "Naciśnij dowolny klawisz lub kliknij, aby zgasić światło.", "Gdy Photo Booth jest na wierzchu, wokół podglądu świeci ramka, a pozostałe ekrany świecą w całości.", "Szerokość ramki", "Otwórz %@", "Zakończ"],
        "en": ["Brightness", "Color", "Light", "Edge Light", "Press any key or click to turn the light off.", "While Photo Booth is in front, a frame of light surrounds the preview and other screens light up fully.", "Frame width", "Open %@", "Quit"],
        "de": ["Helligkeit", "Farbe", "Licht", "Kantenlicht", "Beliebige Taste drücken oder klicken, um das Licht auszuschalten.", "Solange Photo Booth vorne ist, umgibt ein Lichtrahmen die Vorschau und andere Bildschirme leuchten vollständig.", "Rahmenbreite", "%@ öffnen", "Beenden"],
        "fr": ["Luminosité", "Couleur", "Lumière", "Cadre lumineux", "Appuyez sur une touche ou cliquez pour éteindre la lumière.", "Quand Photo Booth est au premier plan, un cadre lumineux entoure l’aperçu et les autres écrans s’allument entièrement.", "Largeur du cadre", "Ouvrir %@", "Quitter"],
        "es": ["Brillo", "Color", "Luz", "Marco de luz", "Pulsa cualquier tecla o haz clic para apagar la luz.", "Mientras Photo Booth está delante, un marco de luz rodea la vista previa y las demás pantallas se iluminan por completo.", "Ancho del marco", "Abrir %@", "Salir"],
        "pt": ["Brilho", "Cores", "Luz", "Borda de luz", "Prima qualquer tecla ou clique para apagar a luz.", "Enquanto o Photo Booth está à frente, uma moldura de luz rodeia a pré-visualização e os outros ecrãs acendem por completo.", "Largura da moldura", "Abrir %@", "Sair"],
        "it": ["Luminosità", "Colore", "Luce", "Bordo luminoso", "Premi un tasto qualsiasi o fai clic per spegnere la luce.", "Quando Photo Booth è in primo piano, una cornice di luce circonda l’anteprima e gli altri schermi si illuminano del tutto.", "Larghezza cornice", "Apri %@", "Esci"],
        "nl": ["Helderheid", "Kleur", "Licht", "Randverlichting", "Druk op een toets of klik om het licht uit te zetten.", "Zolang Photo Booth vooraan staat, omringt een lichtrand het voorbeeld en lichten andere schermen volledig op.", "Randbreedte", "Open %@", "Stop"],
        "sv": ["Ljusstyrka", "Färg", "Ljus", "Kantljus", "Tryck på valfri tangent eller klicka för att släcka ljuset.", "När Photo Booth ligger främst omger en ljusram förhandsvisningen och andra skärmar lyser helt.", "Ramens bredd", "Öppna %@", "Avsluta"],
        "da": ["Lysstyrke", "Farve", "Lys", "Kantlys", "Tryk på en vilkårlig tast eller klik for at slukke lyset.", "Når Photo Booth er forrest, omgiver en lysramme eksemplet, og andre skærme lyser helt op.", "Rammebredde", "Åbn %@", "Slut"],
        "nb": ["Lysstyrke", "Farge", "Lys", "Kantlys", "Trykk på en tast eller klikk for å slå av lyset.", "Når Photo Booth ligger fremst, omgir en lysramme forhåndsvisningen, og andre skjermer lyser helt opp.", "Rammebredde", "Åpne %@", "Avslutt"],
        "fi": ["Kirkkaus", "Väri", "Valo", "Reunavalo", "Sammuta valo painamalla mitä tahansa näppäintä tai klikkaamalla.", "Kun Photo Booth on edessä, valokehys ympäröi esikatselua ja muut näytöt valaistuvat kokonaan.", "Kehyksen leveys", "Avaa %@", "Lopeta"],
        "is": ["Birta", "Litur", "Ljós", "Ljósrammi", "Ýttu á einhvern takka eða smelltu til að slökkva ljósið.", "Á meðan Photo Booth er fremst umlykur ljósrammi forskoðunina og aðrir skjáir lýsa alveg.", "Breidd ramma", "Opna %@", "Hætta"],
        "cs": ["Jas", "Barva", "Světlo", "Osvětlení po obvodu", "Světlo zhasnete stiskem libovolné klávesy nebo kliknutím.", "Když je Photo Booth vepředu, náhled obklopí světelný rámeček a ostatní obrazovky se celé rozsvítí.", "Šířka rámečku", "Otevřít %@", "Ukončit"],
        "sk": ["Jas", "Farba", "Svetlo", "Osvetlenie po obvode", "Svetlo zhasnete stlačením ľubovoľného klávesu alebo kliknutím.", "Keď je Photo Booth vpredu, náhľad obklopí svetelný rámik a ostatné obrazovky sa celé rozsvietia.", "Šírka rámika", "Otvoriť %@", "Ukončiť"],
        "sl": ["Svetlost", "Barva", "Luč", "Osvetlitev robov", "Za izklop luči pritisnite katero koli tipko ali kliknite.", "Ko je Photo Booth spredaj, predogled obda svetlobni okvir, drugi zasloni pa zasvetijo v celoti.", "Širina okvirja", "Odpri %@", "Izhod"],
        "hr": ["Svjetlina", "Boja", "Svjetlo", "Rubno svjetlo", "Pritisnite bilo koju tipku ili kliknite za gašenje svjetla.", "Dok je Photo Booth u prvom planu, svjetlosni okvir okružuje pregled, a ostali zasloni svijetle u potpunosti.", "Širina okvira", "Otvori %@", "Zatvori"],
        "sr": ["Осветљеност", "Боја", "Светло", "Светлосни оквир", "Притисните било који тастер или кликните да угасите светло.", "Док је Photo Booth у првом плану, светлосни оквир окружује преглед, а остали екрани светле у потпуности.", "Ширина оквира", "Отвори %@", "Изађи"],
        "bg": ["Яркост", "Цвят", "Светлина", "Светлинна рамка", "Натиснете произволен клавиш или щракнете, за да изгасите светлината.", "Докато Photo Booth е отпред, светлинна рамка обгражда прегледа, а другите екрани светят изцяло.", "Ширина на рамката", "Отвори %@", "Изход"],
        "ro": ["Luminozitate", "Culoare", "Lumină", "Iluminare margine", "Apăsați orice tastă sau faceți clic pentru a stinge lumina.", "Cât timp Photo Booth este în față, un cadru luminos înconjoară previzualizarea, iar celelalte ecrane se luminează complet.", "Lățimea cadrului", "Deschide %@", "Închideți aplicația"],
        "hu": ["Fényerő", "Szín", "Fény", "Keretfény", "A fény kikapcsolásához nyomj meg egy billentyűt vagy kattints.", "Amíg a Photo Booth van elöl, fénykeret veszi körül az előnézetet, a többi képernyő pedig teljesen világít.", "Keretszélesség", "%@ megnyitása", "Kilépés"],
        "el": ["Φωτεινότητα", "Χρώμα", "Φως", "Φωτισμός άκρων", "Πατήστε οποιοδήποτε πλήκτρο ή κάντε κλικ για να σβήσει το φως.", "Όσο το Photo Booth είναι μπροστά, ένα φωτεινό πλαίσιο περιβάλλει την προεπισκόπηση και οι άλλες οθόνες φωτίζονται πλήρως.", "Πλάτος πλαισίου", "Άνοιγμα %@", "Τερματισμός"],
        "tr": ["Parlaklık", "Renk", "Işık", "Kenar Işığı", "Işığı kapatmak için herhangi bir tuşa basın veya tıklayın.", "Photo Booth öndeyken önizlemenin çevresinde bir ışık çerçevesi yanar, diğer ekranlar tamamen aydınlanır.", "Çerçeve genişliği", "%@ uygulamasını aç", "Çık"],
        "uk": ["Яскравість", "Колір", "Світло", "Бокове підсвічування", "Натисніть будь-яку клавішу або клацніть, щоб вимкнути світло.", "Поки Photo Booth на передньому плані, світлова рамка оточує попередній перегляд, а інші екрани світяться повністю.", "Ширина рамки", "Відкрити %@", "Завершити"],
        "ru": ["Яркость", "Цвет", "Свет", "Освещение по контуру", "Нажмите любую клавишу или щёлкните, чтобы выключить свет.", "Пока Photo Booth на переднем плане, световая рамка окружает превью, а другие экраны светятся полностью.", "Ширина рамки", "Открыть %@", "Завершить"],
        "be": ["Яркасць", "Колер", "Святло", "Светлавая рамка", "Націсніце любую клавішу або пстрыкніце, каб выключыць святло.", "Пакуль Photo Booth на пярэднім плане, светлавая рамка акружае папярэдні прагляд, а іншыя экраны свецяцца цалкам.", "Шырыня рамкі", "Адкрыць %@", "Выйсці"],
        "lt": ["Ryškumas", "Spalva", "Šviesa", "Šviesos rėmelis", "Paspauskite bet kurį klavišą arba spustelėkite, kad išjungtumėte šviesą.", "Kol Photo Booth yra priekyje, peržiūrą supa šviesos rėmelis, o kiti ekranai šviečia visi.", "Rėmelio plotis", "Atidaryti %@", "Baigti"],
        "lv": ["Spilgtums", "Krāsa", "Gaisma", "Gaismas rāmis", "Nospiediet jebkuru taustiņu vai noklikšķiniet, lai izslēgtu gaismu.", "Kamēr Photo Booth ir priekšplānā, priekšskatījumu ieskauj gaismas rāmis, bet pārējie ekrāni izgaismojas pilnībā.", "Rāmja platums", "Atvērt %@", "Iziet"],
        "et": ["Heledus", "Värv", "Valgus", "Valgusraam", "Valguse kustutamiseks vajuta suvalist klahvi või klõpsa.", "Kui Photo Booth on ees, ümbritseb eelvaadet valgusraam ja teised ekraanid põlevad täielikult.", "Raami laius", "Ava %@", "Lõpeta"],
        "ca": ["Brillantor", "Color", "Llum", "Marc de llum", "Prem qualsevol tecla o fes clic per apagar la llum.", "Mentre el Photo Booth és al davant, un marc de llum envolta la previsualització i les altres pantalles s’il·luminen del tot.", "Amplada del marc", "Obrir %@", "Surt"],
        "ar": ["الإضاءة", "اللون", "الضوء", "إضاءة الحواف", "اضغط أي مفتاح أو انقر لإطفاء الضوء.", "عندما يكون Photo Booth في المقدمة، يحيط إطار ضوئي بالمعاينة وتضيء الشاشات الأخرى بالكامل.", "عرض الإطار", "فتح %@", "إنهاء"],
        "he": ["בהירות", "צבע", "אור", "תאורת קצוות", "הקש על מקש כלשהו או לחץ כדי לכבות את האור.", "כל עוד Photo Booth בחזית, מסגרת אור מקיפה את התצוגה המקדימה ושאר המסכים מוארים במלואם.", "רוחב המסגרת", "פתח את %@", "סיום"],
        "fa": ["روشنایی", "رنگ", "نور", "قاب نور", "برای خاموش کردن نور هر کلیدی را بزنید یا کلیک کنید.", "وقتی Photo Booth جلو است، قابی از نور پیش‌نمایش را دربر می‌گیرد و صفحه‌های دیگر کامل روشن می‌شوند.", "پهنای قاب", "باز کردن %@", "خروج"],
        "hi": ["ब्राइटनेस", "रंग", "रोशनी", "एज लाइट", "रोशनी बंद करने के लिए कोई भी कुंजी दबाएँ या क्लिक करें।", "जब Photo Booth सामने हो, पूर्वावलोकन के चारों ओर रोशनी का फ़्रेम जलता है और बाकी स्क्रीन पूरी रोशन होती हैं।", "फ़्रेम की चौड़ाई", "%@ खोलें", "बंद करें"],
        "bn": ["উজ্জ্বলতা", "রং", "আলো", "আলোর ফ্রেম", "আলো নিভাতে যেকোনো কী চাপুন বা ক্লিক করুন।", "Photo Booth সামনে থাকলে প্রিভিউয়ের চারপাশে আলোর ফ্রেম জ্বলে এবং অন্য স্ক্রিনগুলো পুরো আলোকিত হয়।", "ফ্রেমের প্রস্থ", "%@ খুলুন", "বন্ধ করুন"],
        "th": ["ความสว่าง", "สี", "แสง", "ไฟขอบ", "กดปุ่มใดก็ได้หรือคลิกเพื่อปิดแสง", "ขณะที่ Photo Booth อยู่ด้านหน้า กรอบแสงจะล้อมภาพตัวอย่าง และหน้าจออื่นจะสว่างเต็มจอ", "ความกว้างกรอบ", "เปิด %@", "ออก"],
        "vi": ["Độ sáng", "Màu", "Đèn", "Đèn viền", "Nhấn phím bất kỳ hoặc bấm chuột để tắt đèn.", "Khi Photo Booth ở phía trước, một khung sáng bao quanh bản xem trước và các màn hình khác sáng toàn bộ.", "Độ rộng khung", "Mở %@", "Thoát"],
        "id": ["Kecerahan", "Warna", "Lampu", "Cahaya Tepi", "Tekan tombol apa saja atau klik untuk mematikan lampu.", "Selama Photo Booth di depan, bingkai cahaya mengelilingi pratinjau dan layar lain menyala penuh.", "Lebar bingkai", "Buka %@", "Tutup"],
        "ms": ["Kecerahan", "Warna", "Lampu", "Lampu Pinggir", "Tekan mana-mana kekunci atau klik untuk memadam lampu.", "Semasa Photo Booth di hadapan, bingkai cahaya mengelilingi pratonton dan skrin lain menyala sepenuhnya.", "Lebar bingkai", "Buka %@", "Keluar"],
        "zh-Hans": ["亮度", "颜色", "灯光", "边缘光", "按任意键或点按以关闭灯光。", "Photo Booth 位于最前面时，光框会环绕预览，其他屏幕全屏发光。", "光框宽度", "打开 %@", "退出"],
        "zh-Hant": ["亮度", "顏色", "燈光", "邊緣光", "按任意鍵或按一下以關閉燈光。", "Photo Booth 位於最前方時，光框會環繞預覽，其他螢幕全螢幕發光。", "光框寬度", "打開 %@", "結束"],
        "ja": ["輝度", "カラー", "ライト", "エッジライト", "いずれかのキーを押すかクリックするとライトが消えます。", "Photo Booth が最前面にある間、プレビューの周りをライトフレームが囲み、ほかのディスプレイは全面が点灯します。", "フレームの幅", "%@ を開く", "終了"],
        "ko": ["밝기", "색상", "조명", "가장자리 조명", "아무 키나 누르거나 클릭하면 조명이 꺼집니다.", "Photo Booth가 앞에 있는 동안 미리보기 주위를 조명 테두리가 감싸고 다른 화면은 전체가 켜집니다.", "테두리 너비", "%@ 열기", "종료"],
    ]
}
