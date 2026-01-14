# 🚀 Brze upute za instalaciju

## Koristite datoteku: `INSTALL_PLUGIN.sql`

### Korak 1: Upload skripte (1 minuta)

1. Otvorite APEX
2. Idite na **SQL Workshop** → **SQL Scripts**
3. Kliknite **Upload**
4. Odaberite datoteku **`INSTALL_PLUGIN.sql`**
5. Kliknite **Upload**
6. Kliknite **Run** da pokrenete skriptu

### Korak 2: Kreirajte plugin u App Builderu (2 minute)

1. Otvorite vašu aplikaciju
2. Idite na **Shared Components** → **Plug-ins**
3. Kliknite **Create** → **From Scratch**
4. Unesite:

| Polje | Vrijednost |
|-------|-----------|
| **Name** | `SQL/PL-SQL to PDF Generator` |
| **Internal Name** | `SQL_PDF_GENERATOR` |
| **Type** | `Dynamic Action` |
| **Render Function Name** | `apex_plugin_sql_pdf.render` |
| **AJAX Function Name** | `apex_plugin_sql_pdf.ajax` |

5. Kliknite **Create Plug-in**

### Korak 3: Dodajte atribute (1 minuta)

Nakon kreiranja plugina:

1. Kliknite na plugin da ga otvorite
2. Idite na **Custom Attributes** → **Add Attribute**
3. Dodajte:

**Attribute 1:**
- Label: `Code Item`
- Type: `Page Item`
- Required: `Yes`

**Attribute 2:**
- Label: `Button Text`  
- Type: `Text`
- Default: `Generiraj Izvještaj`

**Attribute 4:**
- Label: `Max Rows`
- Type: `Integer`
- Default: `1000`

### Korak 4: Korištenje na stranici (2 minute)

1. Otvorite stranicu gdje želite koristiti plugin
2. Dodajte **Page Item**:
   - Type: `Textarea`
   - Name: `P1_SQL_CODE`
   - Label: `SQL/PL-SQL Kod`
   - Rows: `15`

3. Dodajte **Dynamic Action**:
   - Event: `Page Load`
   - Action: `SQL/PL-SQL to PDF Generator` (plugin)
   - Code Item: `P1_SQL_CODE`

4. Spremite i pokrenite stranicu

### Testiranje

1. Unesite SQL kod:
```sql
SELECT * FROM dual
```

2. Kliknite **"Generiraj Izvještaj"**

3. HTML datoteka će se preuzeti

4. Za PDF: Otvorite HTML → Print → Save as PDF

---

## 📁 Struktura datoteka

| Datoteka | Opis |
|----------|------|
| **`INSTALL_PLUGIN.sql`** | ⭐ Glavna instalacijska skripta |
| `f100_sql_pdf_demo.sql` | Alternativna verzija s više komentara |
| `MANUAL_INSTALL.md` | Detaljne upute za ručnu instalaciju |
| `EXAMPLE_USAGE.md` | Primjeri SQL koda za testiranje |

---

## ❓ Česta pitanja

**Q: Zašto se generira HTML umjesto PDF-a?**
A: APEX nema ugrađenu podršku za PDF generiranje. HTML se može lako pretvoriti u PDF preko Print → Save as PDF.

**Q: Greška "package does not exist"?**
A: Pokrenite `INSTALL_PLUGIN.sql` skriptu u SQL Workshop-u.

**Q: Plugin se ne pojavljuje u Dynamic Actions?**
A: Provjerite da ste postavili Type na "Dynamic Action" prilikom kreiranja plugina.

