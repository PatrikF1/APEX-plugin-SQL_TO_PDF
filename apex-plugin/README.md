# SQL/PL-SQL Report Generator Plugin

Oracle APEX plugin koji automatski dodaje gumb "Generiraj Izvještaj" ispod bilo kojeg textarea polja i generira HTML izvještaj s SQL kodom i rezultatima.

## 🚀 Brza instalacija

### Korak 1: Upload skripte

1. Otvorite APEX
2. **SQL Workshop** → **SQL Scripts** → **Upload**
3. Uploadajte datoteku **`EXPORT_SQL_REPORT_PLUGIN.sql`**
4. Kliknite **Run**

### Korak 2: Kreirajte plugin

1. **Shared Components** → **Plug-ins** → **Create** → **From Scratch**
2. Unesite:
   - **Name**: `SQL Report Generator`
   - **Internal Name**: `SQL_REPORT_GENERATOR`
   - **Type**: `Dynamic Action`
   - **Category**: `Execute`
3. **Source**:
   - **Render Function**: `pkg_sql_report_plugin.render`
   - **AJAX Function**: `pkg_sql_report_plugin.ajax`
4. **Standard Attributes**: ✅ `Fire on Initialization`
5. Kliknite **Create Plug-in**

### Korak 3: Dodajte atribute

Otvorite plugin → **Custom Attributes** → **Add Attribute**:

| # | Label | Type | Required | Default |
|---|-------|------|----------|---------|
| 1 | Code Item | Page Item | Yes | - |
| 2 | Button Label | Text | No | Generiraj Izvještaj |
| 3 | Max Rows | Integer | No | 1000 |

## 📖 Korištenje

1. Dodajte **Textarea** na stranicu (npr. `P1_SQL_CODE`)
2. Kreirajte **Dynamic Action**:
   - **Event**: `Page Load`
   - **Action**: `SQL Report Generator`
   - **Code Item**: `P1_SQL_CODE`
3. Spremite i pokrenite stranicu
4. Gumb "Generiraj Izvještaj" će se automatski pojaviti ispod textarea!

## ✨ Funkcionalnosti

- ✅ Automatski dodaje gumb ispod textarea polja
- ✅ Izvršava SELECT upite i prikazuje rezultate u tablici
- ✅ Izvršava PL/SQL blokove
- ✅ Generira lijepi HTML izvještaj
- ✅ Prikazuje greške ako SQL nije ispravan
- ✅ HTML se može printati kao PDF (Print → Save as PDF)
- ✅ Konfigurabilni label gumba i max broj redova

## 📁 Datoteke

- **`EXPORT_SQL_REPORT_PLUGIN.sql`** - Glavna instalacijska skripta (dijelite ovu!)
- **`SQL_PDF_PLUGIN_FINAL.sql`** - Alternativna verzija s više komentara
- **`BRZE_UPUTE.md`** - Kratke upute na hrvatskom
- **`README.md`** - Ova dokumentacija

## 🔧 Zahtjevi

- Oracle APEX 5.0 ili noviji
- Oracle Database 11g ili noviji

## 📝 Napomena

Plugin generira **HTML izvještaj** koji se preuzima. Za PDF format:
1. Otvorite preuzetu HTML datoteku u browseru
2. File → Print → Save as PDF

---

**Verzija**: 1.0.0  
**Autor**: Vaše ime
