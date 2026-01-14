set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- ORACLE APEX PLUGIN: SQL/PL-SQL Report Generator
-- Verzija: 1.0
--
-- Ovaj plugin dodaje gumb "Generiraj Izvještaj" ispod bilo kojeg textarea
-- polja i generira HTML izvještaj s SQL kodom i rezultatima.
--
-- INSTALACIJA:
-- 1. SQL Workshop -> SQL Scripts -> Upload -> Run
-- 2. Shared Components -> Plug-ins -> Create -> From Scratch
-- 3. Slijedite upute na kraju skripte
--
--------------------------------------------------------------------------------

PROMPT ========================================================================
PROMPT   SQL/PL-SQL Report Generator - Instalacija
PROMPT ========================================================================
PROMPT

-- Kreiraj PL/SQL paket
PROMPT Kreiram PL/SQL paket...

CREATE OR REPLACE PACKAGE pkg_sql_report_plugin AS
    
    -- Render funkcija - dodaje JavaScript na stranicu
    FUNCTION render (
        p_dynamic_action IN apex_plugin.t_dynamic_action,
        p_plugin         IN apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_render_result;
    
    -- AJAX funkcija - izvršava SQL i generira izvještaj
    FUNCTION ajax (
        p_dynamic_action IN apex_plugin.t_dynamic_action,
        p_plugin         IN apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_ajax_result;

END pkg_sql_report_plugin;
/

CREATE OR REPLACE PACKAGE BODY pkg_sql_report_plugin AS

    ----------------------------------------------------------------------------
    -- RENDER FUNKCIJA
    ----------------------------------------------------------------------------
    FUNCTION render (
        p_dynamic_action IN apex_plugin.t_dynamic_action,
        p_plugin         IN apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_render_result
    AS
        l_result apex_plugin.t_dynamic_action_render_result;
        l_item_name VARCHAR2(255);
        l_button_label VARCHAR2(255);
        l_max_rows NUMBER;
    BEGIN
        -- Dohvati postavke iz atributa
        l_item_name := p_dynamic_action.attribute_01;
        l_button_label := NVL(p_dynamic_action.attribute_02, 'Generiraj Izvještaj');
        l_max_rows := NVL(p_dynamic_action.attribute_03, 1000);
        
        -- JavaScript funkcija koja se izvršava
        l_result.javascript_function := '
function() {
    var itemName = "' || apex_javascript.escape(l_item_name) || '";
    var buttonLabel = "' || apex_javascript.escape(l_button_label) || '";
    var maxRows = ' || l_max_rows || ';
    var ajaxId = "' || apex_plugin.get_ajax_identifier || '";
    
    // Pronađi textarea element
    var $item = $("#" + itemName);
    if (!$item.length) {
        $item = apex.item(itemName).element;
    }
    
    if (!$item || !$item.length) {
        console.error("SQL Report Plugin: Item " + itemName + " nije pronađen!");
        return;
    }
    
    // Provjeri je li gumb već dodan
    var btnId = "btn_sql_report_" + itemName;
    if ($("#" + btnId).length) {
        return; // Gumb već postoji
    }
    
    // Kreiraj gumb
    var $btn = $("<button/>", {
        "id": btnId,
        "type": "button",
        "class": "t-Button t-Button--hot t-Button--stretch"
    })
    .css({
        "margin-top": "12px",
        "margin-bottom": "12px"
    })
    .html("<span class=\"t-Icon fa fa-file-text-o\" style=\"margin-right:8px\"></span><span class=\"t-Button-label\">" + buttonLabel + "</span>");
    
    // Dodaj gumb nakon textarea ili njegovog containera
    var $container = $item.closest(".t-Form-fieldContainer");
    if ($container.length) {
        $btn.insertAfter($container);
    } else {
        $btn.insertAfter($item);
    }
    
    // Click event handler
    $btn.on("click", function(e) {
        e.preventDefault();
        e.stopPropagation();
        
        // Dohvati SQL kod
        var sqlCode = "";
        if (apex.item(itemName).node) {
            sqlCode = apex.item(itemName).getValue();
        } else {
            sqlCode = $item.val();
        }
        
        // Validiraj
        if (!sqlCode || !sqlCode.trim()) {
            apex.message.clearErrors();
            apex.message.showErrors([{
                type: "error",
                location: "page",
                message: "Molimo unesite SQL ili PL/SQL kod prije generiranja izvještaja!",
                unsafe: false
            }]);
            return;
        }
        
        // Disable gumb i prikaži loading
        var $thisBtn = $(this);
        var originalHtml = $thisBtn.html();
        $thisBtn.prop("disabled", true);
        $thisBtn.html("<span class=\"t-Icon fa fa-spinner fa-spin\" style=\"margin-right:8px\"></span><span class=\"t-Button-label\">Generiram...</span>");
        
        // AJAX poziv
        apex.server.plugin(ajaxId, {
            x01: sqlCode,
            x02: maxRows
        }, {
            success: function(data) {
                // Vrati gumb u originalno stanje
                $thisBtn.prop("disabled", false);
                $thisBtn.html(originalHtml);
                
                if (data.success) {
                    // Kreiraj i preuzmi HTML datoteku
                    var blob = new Blob([data.html_content], {type: "text/html;charset=utf-8"});
                    var url = URL.createObjectURL(blob);
                    var a = document.createElement("a");
                    a.href = url;
                    a.download = "sql_izvjestaj_" + new Date().toISOString().slice(0,10).replace(/-/g,"") + "_" + new Date().toTimeString().slice(0,8).replace(/:/g,"") + ".html";
                    document.body.appendChild(a);
                    a.click();
                    setTimeout(function() {
                        document.body.removeChild(a);
                        URL.revokeObjectURL(url);
                    }, 100);
                    
                    apex.message.clearErrors();
                    apex.message.showPageSuccess("Izvještaj je uspješno generiran! Za PDF: otvorite HTML datoteku i koristite Print → Save as PDF.");
                } else {
                    apex.message.clearErrors();
                    apex.message.showErrors([{
                        type: "error",
                        location: "page",
                        message: data.error || "Greška pri generiranju izvještaja.",
                        unsafe: false
                    }]);
                }
            },
            error: function(jqXHR, textStatus, errorThrown) {
                $thisBtn.prop("disabled", false);
                $thisBtn.html(originalHtml);
                apex.message.clearErrors();
                apex.message.showErrors([{
                    type: "error",
                    location: "page",
                    message: "Greška pri komunikaciji sa serverom: " + errorThrown,
                    unsafe: false
                }]);
            },
            dataType: "json"
        });
    });
}';
        
        RETURN l_result;
    END render;

    ----------------------------------------------------------------------------
    -- AJAX FUNKCIJA - Izvršava SQL i generira HTML izvještaj
    ----------------------------------------------------------------------------
    FUNCTION ajax (
        p_dynamic_action IN apex_plugin.t_dynamic_action,
        p_plugin         IN apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_ajax_result
    AS
        l_result apex_plugin.t_dynamic_action_ajax_result;
        l_sql_code CLOB;
        l_max_rows NUMBER;
        l_html CLOB;
        l_status VARCHAR2(4000);
        l_rows_html CLOB;
        l_error VARCHAR2(4000);
        l_cursor INTEGER;
        l_col_cnt INTEGER;
        l_desc DBMS_SQL.DESC_TAB;
        l_val VARCHAR2(4000);
        l_row_count NUMBER := 0;
        l_dummy NUMBER;
        l_is_select BOOLEAN := FALSE;
        l_start TIMESTAMP := SYSTIMESTAMP;
        l_duration VARCHAR2(50);
    BEGIN
        -- Dohvati parametre
        l_sql_code := apex_application.g_x01;
        l_max_rows := NVL(TO_NUMBER(apex_application.g_x02), 1000);
        
        -- Validiraj input
        IF l_sql_code IS NULL OR LENGTH(TRIM(l_sql_code)) = 0 THEN
            apex_json.open_object;
            apex_json.write('success', FALSE);
            apex_json.write('error', 'SQL/PL-SQL kod je prazan!');
            apex_json.close_object;
            RETURN l_result;
        END IF;
        
        -- Provjeri tip SQL-a
        IF UPPER(LTRIM(l_sql_code)) LIKE 'SELECT%' THEN
            l_is_select := TRUE;
        END IF;
        
        -- Inicijaliziraj CLOB za rezultate
        DBMS_LOB.CREATETEMPORARY(l_rows_html, TRUE);
        
        BEGIN
            IF l_is_select THEN
                -- Izvršavanje SELECT upita
                l_cursor := DBMS_SQL.OPEN_CURSOR;
                DBMS_SQL.PARSE(l_cursor, l_sql_code, DBMS_SQL.NATIVE);
                DBMS_SQL.DESCRIBE_COLUMNS(l_cursor, l_col_cnt, l_desc);
                
                -- Definiraj kolone
                FOR i IN 1..l_col_cnt LOOP
                    DBMS_SQL.DEFINE_COLUMN(l_cursor, i, l_val, 4000);
                END LOOP;
                
                l_dummy := DBMS_SQL.EXECUTE(l_cursor);
                
                -- Generiraj tablicu - header
                l_rows_html := '<div class="table-wrapper"><table class="data-table"><thead><tr>';
                FOR i IN 1..l_col_cnt LOOP
                    l_rows_html := l_rows_html || '<th>' || 
                        REPLACE(REPLACE(l_desc(i).col_name, '<', '&lt;'), '>', '&gt;') || '</th>';
                END LOOP;
                l_rows_html := l_rows_html || '</tr></thead><tbody>';
                
                -- Fetch redova
                LOOP
                    EXIT WHEN DBMS_SQL.FETCH_ROWS(l_cursor) = 0 OR l_row_count >= l_max_rows;
                    l_row_count := l_row_count + 1;
                    l_rows_html := l_rows_html || '<tr>';
                    
                    FOR i IN 1..l_col_cnt LOOP
                        DBMS_SQL.COLUMN_VALUE(l_cursor, i, l_val);
                        l_rows_html := l_rows_html || '<td>' || 
                            NVL(REPLACE(REPLACE(SUBSTR(l_val, 1, 1000), '<', '&lt;'), '>', '&gt;'), 
                                '<span class="null-value">NULL</span>') || '</td>';
                    END LOOP;
                    
                    l_rows_html := l_rows_html || '</tr>';
                END LOOP;
                
                DBMS_SQL.CLOSE_CURSOR(l_cursor);
                l_rows_html := l_rows_html || '</tbody></table></div>';
                
                -- Status
                l_duration := ROUND(EXTRACT(SECOND FROM (SYSTIMESTAMP - l_start)), 3);
                IF l_row_count = 0 THEN
                    l_rows_html := '<div class="msg msg-warning">Upit nije vratio rezultate.</div>';
                    l_status := '<span class="status-ok">✓ Uspješno</span> - 0 redova';
                ELSIF l_row_count >= l_max_rows THEN
                    l_rows_html := l_rows_html || '<div class="msg msg-info">Prikazano prvih ' || l_max_rows || ' redova.</div>';
                    l_status := '<span class="status-ok">✓ Uspješno</span> - ' || l_row_count || '+ redova, ' || l_col_cnt || ' kolona';
                ELSE
                    l_status := '<span class="status-ok">✓ Uspješno</span> - ' || l_row_count || ' redova, ' || l_col_cnt || ' kolona';
                END IF;
                l_status := l_status || ' (' || l_duration || 's)';
                
            ELSE
                -- Izvršavanje PL/SQL bloka
                BEGIN
                    EXECUTE IMMEDIATE l_sql_code;
                    l_duration := ROUND(EXTRACT(SECOND FROM (SYSTIMESTAMP - l_start)), 3);
                    l_status := '<span class="status-ok">✓ Uspješno</span> - PL/SQL izvršen (' || l_duration || 's)';
                    l_rows_html := '<div class="msg msg-success">PL/SQL blok je uspješno izvršen bez grešaka.</div>';
                EXCEPTION
                    WHEN OTHERS THEN
                        l_error := SQLERRM;
                        l_status := '<span class="status-error">✗ Greška</span>';
                        l_rows_html := '<div class="msg msg-error"><strong>Greška:</strong><br>' || 
                            REPLACE(REPLACE(l_error, '<', '&lt;'), '>', '&gt;') || '</div>';
                END;
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                l_error := SQLERRM;
                l_status := '<span class="status-error">✗ Greška</span>';
                l_rows_html := '<div class="msg msg-error"><strong>Greška:</strong><br>' || 
                    REPLACE(REPLACE(l_error, '<', '&lt;'), '>', '&gt;') || '</div>';
        END;
        
        -- Generiraj HTML izvještaj
        l_html := '<!DOCTYPE html>
<html lang="hr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>SQL Izvještaj - ' || TO_CHAR(SYSDATE, 'DD.MM.YYYY HH24:MI') || '</title>
<style>
:root {
    --primary: #0073e6;
    --success: #28a745;
    --error: #dc3545;
    --warning: #ffc107;
    --info: #17a2b8;
    --dark: #1a1a2e;
    --light: #f8f9fa;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
    color: #e8e8e8;
    min-height: 100vh;
    padding: 30px 20px;
    line-height: 1.6;
}
.container { max-width: 1400px; margin: 0 auto; }
header {
    background: rgba(255,255,255,0.05);
    border-radius: 12px;
    padding: 25px 30px;
    margin-bottom: 25px;
    border: 1px solid rgba(255,255,255,0.1);
}
h1 {
    font-size: 1.8rem;
    font-weight: 600;
    color: #00d4ff;
    margin-bottom: 15px;
}
.meta { display: flex; flex-wrap: wrap; gap: 20px; color: #a0a0a0; font-size: 0.9rem; }
.meta-item { display: flex; align-items: center; gap: 8px; }
.meta-item strong { color: #e8e8e8; }
section {
    background: rgba(255,255,255,0.03);
    border-radius: 12px;
    padding: 25px;
    margin-bottom: 20px;
    border: 1px solid rgba(255,255,255,0.08);
}
h2 {
    font-size: 1.1rem;
    color: #00d4ff;
    margin-bottom: 15px;
    padding-bottom: 10px;
    border-bottom: 1px solid rgba(255,255,255,0.1);
}
.code-block {
    background: #0d1117;
    border: 1px solid #30363d;
    border-radius: 8px;
    padding: 20px;
    font-family: "Fira Code", "Consolas", "Monaco", monospace;
    font-size: 0.85rem;
    line-height: 1.7;
    overflow-x: auto;
    white-space: pre-wrap;
    word-wrap: break-word;
    color: #c9d1d9;
}
.table-wrapper { overflow-x: auto; border-radius: 8px; }
.data-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.85rem;
}
.data-table th {
    background: linear-gradient(135deg, var(--primary) 0%, #005bb5 100%);
    color: white;
    padding: 12px 15px;
    text-align: left;
    font-weight: 600;
    text-transform: uppercase;
    font-size: 0.75rem;
    letter-spacing: 0.5px;
    position: sticky;
    top: 0;
}
.data-table td {
    padding: 10px 15px;
    border-bottom: 1px solid rgba(255,255,255,0.05);
    color: #c0c0c0;
}
.data-table tbody tr:hover td {
    background: rgba(0, 212, 255, 0.1);
    color: #fff;
}
.null-value { color: #666; font-style: italic; font-size: 0.8rem; }
.status-ok { color: var(--success); font-weight: 600; }
.status-error { color: var(--error); font-weight: 600; }
.msg {
    padding: 15px 20px;
    border-radius: 8px;
    margin: 10px 0;
}
.msg-success { background: rgba(40, 167, 69, 0.15); border: 1px solid rgba(40, 167, 69, 0.3); color: #5dd879; }
.msg-error { background: rgba(220, 53, 69, 0.15); border: 1px solid rgba(220, 53, 69, 0.3); color: #ff6b6b; }
.msg-warning { background: rgba(255, 193, 7, 0.15); border: 1px solid rgba(255, 193, 7, 0.3); color: #ffc107; }
.msg-info { background: rgba(23, 162, 184, 0.15); border: 1px solid rgba(23, 162, 184, 0.3); color: #5bc0de; margin-top: 15px; font-size: 0.85rem; }
footer {
    text-align: center;
    padding: 25px;
    color: #666;
    font-size: 0.8rem;
    border-top: 1px solid rgba(255,255,255,0.05);
    margin-top: 30px;
}
@media print {
    body { background: #fff; color: #333; padding: 10px; }
    header, section { background: #fff; border: 1px solid #ddd; }
    h1, h2 { color: var(--primary); }
    .code-block { background: #f5f5f5; color: #333; border: 1px solid #ddd; }
    .data-table th { background: var(--primary); -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    .data-table td { color: #333; border-color: #ddd; }
    .meta { color: #666; }
}
</style>
</head>
<body>
<div class="container">
<header>
<h1>📊 SQL/PL-SQL Izvještaj</h1>
<div class="meta">
<div class="meta-item"><strong>Status:</strong> ' || l_status || '</div>
<div class="meta-item"><strong>Vrijeme:</strong> ' || TO_CHAR(SYSDATE, 'DD.MM.YYYY HH24:MI:SS') || '</div>
<div class="meta-item"><strong>Korisnik:</strong> ' || NVL(V('APP_USER'), USER) || '</div>
<div class="meta-item"><strong>Baza:</strong> ' || SYS_CONTEXT('USERENV', 'DB_NAME') || '</div>
</div>
</header>

<section>
<h2>📝 SQL/PL-SQL Kod</h2>
<div class="code-block">' || REPLACE(REPLACE(REPLACE(l_sql_code, '&', '&amp;'), '<', '&lt;'), '>', '&gt;') || '</div>
</section>

<section>
<h2>📋 Rezultati</h2>
' || l_rows_html || '
</section>

<footer>
SQL/PL-SQL Report Generator Plugin | Za PDF: File → Print → Save as PDF
</footer>
</div>
</body>
</html>';

        -- Vrati JSON response
        apex_json.open_object;
        apex_json.write('success', TRUE);
        apex_json.write('html_content', l_html);
        apex_json.close_object;
        
        RETURN l_result;
        
    EXCEPTION
        WHEN OTHERS THEN
            apex_json.open_object;
            apex_json.write('success', FALSE);
            apex_json.write('error', SQLERRM);
            apex_json.close_object;
            RETURN l_result;
    END ajax;

END pkg_sql_report_plugin;
/

SHOW ERRORS

PROMPT
PROMPT ========================================================================
PROMPT   PL/SQL PAKET USPJEŠNO KREIRAN!
PROMPT ========================================================================
PROMPT
PROMPT   SADA KREIRAJTE PLUGIN U APEX-u:
PROMPT
PROMPT   1. Shared Components -> Plug-ins -> Create
PROMPT   2. Odaberite "From Scratch"
PROMPT
PROMPT   3. Unesite osnovne podatke:
PROMPT      ┌─────────────────────────────────────────────────────────┐
PROMPT      │ Name:          SQL Report Generator                     │
PROMPT      │ Internal Name: SQL_REPORT_GENERATOR                     │
PROMPT      │ Type:          Dynamic Action                           │
PROMPT      │ Category:      Execute                                  │
PROMPT      └─────────────────────────────────────────────────────────┘
PROMPT
PROMPT   4. U "Source" sekciji:
PROMPT      ┌─────────────────────────────────────────────────────────┐
PROMPT      │ Render Function Name:  pkg_sql_report_plugin.render     │
PROMPT      │ AJAX Function Name:    pkg_sql_report_plugin.ajax       │
PROMPT      └─────────────────────────────────────────────────────────┘
PROMPT
PROMPT   5. U "Standard Attributes" - OZNAČITE:
PROMPT      [x] Fire on Initialization
PROMPT
PROMPT   6. Kliknite "Create Plug-in"
PROMPT
PROMPT   7. Otvorite plugin i dodajte CUSTOM ATTRIBUTES:
PROMPT
PROMPT      ATTRIBUTE 1:
PROMPT      ┌─────────────────────────────────────────────────────────┐
PROMPT      │ Label:         Code Item                                │
PROMPT      │ Type:          Page Item                                │
PROMPT      │ Required:      Yes                                      │
PROMPT      └─────────────────────────────────────────────────────────┘
PROMPT
PROMPT      ATTRIBUTE 2:
PROMPT      ┌─────────────────────────────────────────────────────────┐
PROMPT      │ Label:         Button Label                             │
PROMPT      │ Type:          Text                                     │
PROMPT      │ Required:      No                                       │
PROMPT      │ Default:       Generiraj Izvještaj                      │
PROMPT      └─────────────────────────────────────────────────────────┘
PROMPT
PROMPT      ATTRIBUTE 3:
PROMPT      ┌─────────────────────────────────────────────────────────┐
PROMPT      │ Label:         Max Rows                                 │
PROMPT      │ Type:          Integer                                  │
PROMPT      │ Required:      No                                       │
PROMPT      │ Default:       1000                                     │
PROMPT      └─────────────────────────────────────────────────────────┘
PROMPT
PROMPT ========================================================================
PROMPT   KORIŠTENJE NA STRANICI:
PROMPT ========================================================================
PROMPT
PROMPT   1. Dodajte Textarea na stranicu (npr. P1_SQL_CODE)
PROMPT
PROMPT   2. Kreirajte Dynamic Action:
PROMPT      - Event: Page Load
PROMPT      - Action: SQL Report Generator (vaš plugin)
PROMPT      - Code Item: P1_SQL_CODE
PROMPT
PROMPT   3. Spremite i pokrenite stranicu
PROMPT
PROMPT   4. Gumb "Generiraj Izvještaj" će se automatski pojaviti!
PROMPT
PROMPT ========================================================================
PROMPT   INSTALACIJA ZAVRŠENA!
PROMPT ========================================================================

