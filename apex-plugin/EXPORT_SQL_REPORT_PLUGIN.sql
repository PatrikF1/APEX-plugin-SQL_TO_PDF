set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
--  ██████╗ ██╗     ██╗   ██╗ ██████╗ ██╗███╗   ██╗
--  ██╔══██╗██║     ██║   ██║██╔════╝ ██║████╗  ██║
--  ██████╔╝██║     ██║   ██║██║  ███╗██║██╔██╗ ██║
--  ██╔═══╝ ██║     ██║   ██║██║   ██║██║██║╚██╗██║
--  ██║     ███████╗╚██████╔╝╚██████╔╝██║██║ ╚████║
--  ╚═╝     ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝
--
--  SQL/PL-SQL REPORT GENERATOR PLUGIN
--  Verzija: 1.0.0
--  
--  Kompajlira i izvršava SQL/PL-SQL kod te generira HTML izvještaj
--
--------------------------------------------------------------------------------
--
--  INSTALACIJA - SUPER JEDNOSTAVNO:
--
--  1. Otvorite APEX
--  2. SQL Workshop -> SQL Scripts -> Upload
--  3. Uploadajte ovu datoteku
--  4. Kliknite RUN
--  5. Slijedite upute koje će se prikazati
--
--------------------------------------------------------------------------------

PROMPT
PROMPT ╔══════════════════════════════════════════════════════════════════════╗
PROMPT ║                                                                      ║
PROMPT ║   SQL/PL-SQL REPORT GENERATOR PLUGIN - INSTALACIJA                  ║
PROMPT ║                                                                      ║
PROMPT ╚══════════════════════════════════════════════════════════════════════╝
PROMPT

--------------------------------------------------------------------------------
-- KORAK 1: Kreiranje PL/SQL paketa
--------------------------------------------------------------------------------

PROMPT [1/2] Kreiram PL/SQL paket...

CREATE OR REPLACE PACKAGE pkg_sql_report_plugin AS
    FUNCTION render (
        p_dynamic_action IN apex_plugin.t_dynamic_action,
        p_plugin         IN apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_render_result;
    
    FUNCTION ajax (
        p_dynamic_action IN apex_plugin.t_dynamic_action,
        p_plugin         IN apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_ajax_result;
END pkg_sql_report_plugin;
/

CREATE OR REPLACE PACKAGE BODY pkg_sql_report_plugin AS

    FUNCTION render (
        p_dynamic_action IN apex_plugin.t_dynamic_action,
        p_plugin         IN apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_render_result
    AS
        l_result apex_plugin.t_dynamic_action_render_result;
        l_item VARCHAR2(255) := p_dynamic_action.attribute_01;
        l_label VARCHAR2(255) := NVL(p_dynamic_action.attribute_02, 'Generiraj Izvještaj');
        l_max NUMBER := NVL(p_dynamic_action.attribute_03, 1000);
    BEGIN
        l_result.javascript_function := '
function(){
var item="'||apex_javascript.escape(l_item)||'",label="'||apex_javascript.escape(l_label)||'",max='||l_max||',ajax="'||apex_plugin.get_ajax_identifier||'";
var $i=$("#"+item);if(!$i.length)$i=apex.item(item).element;if(!$i||!$i.length){console.error("Plugin: Item "+item+" not found");return}
var bid="btn_rpt_"+item;if($("#"+bid).length)return;
var $b=$("<button/>",{id:bid,type:"button","class":"t-Button t-Button--hot t-Button--stretch"}).css({"margin-top":"12px","margin-bottom":"12px"}).html("<span class=\"t-Icon fa fa-file-text-o\" style=\"margin-right:8px\"></span><span class=\"t-Button-label\">"+label+"</span>");
var $c=$i.closest(".t-Form-fieldContainer");$c.length?$b.insertAfter($c):$b.insertAfter($i);
$b.on("click",function(e){
e.preventDefault();e.stopPropagation();
var sql=apex.item(item).node?apex.item(item).getValue():$i.val();
if(!sql||!sql.trim()){apex.message.clearErrors();apex.message.showErrors([{type:"error",location:"page",message:"Molimo unesite SQL ili PL/SQL kod!",unsafe:false}]);return}
var $t=$(this),orig=$t.html();$t.prop("disabled",true).html("<span class=\"t-Icon fa fa-spinner fa-spin\" style=\"margin-right:8px\"></span><span class=\"t-Button-label\">Generiram...</span>");
apex.server.plugin(ajax,{x01:sql,x02:max},{
success:function(d){$t.prop("disabled",false).html(orig);if(d.success){var b=new Blob([d.html],{type:"text/html;charset=utf-8"}),u=URL.createObjectURL(b),a=document.createElement("a");a.href=u;a.download="sql_report_"+Date.now()+".html";document.body.appendChild(a);a.click();setTimeout(function(){document.body.removeChild(a);URL.revokeObjectURL(u)},100);apex.message.clearErrors();apex.message.showPageSuccess("Izvještaj generiran! Za PDF: Print → Save as PDF")}else{apex.message.clearErrors();apex.message.showErrors([{type:"error",location:"page",message:d.error||"Greška",unsafe:false}])}},
error:function(x,t,e){$t.prop("disabled",false).html(orig);apex.message.clearErrors();apex.message.showErrors([{type:"error",location:"page",message:"Server error: "+e,unsafe:false}])},
dataType:"json"});
});}';
        RETURN l_result;
    END render;

    FUNCTION ajax (
        p_dynamic_action IN apex_plugin.t_dynamic_action,
        p_plugin         IN apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_ajax_result
    AS
        l_result apex_plugin.t_dynamic_action_ajax_result;
        l_sql CLOB := apex_application.g_x01;
        l_max NUMBER := NVL(TO_NUMBER(apex_application.g_x02),1000);
        l_html CLOB;
        l_status VARCHAR2(500);
        l_rows CLOB;
        l_cur INTEGER;
        l_cnt INTEGER;
        l_desc DBMS_SQL.DESC_TAB;
        l_val VARCHAR2(4000);
        l_rc NUMBER := 0;
        l_d NUMBER;
        l_t TIMESTAMP := SYSTIMESTAMP;
        l_err VARCHAR2(4000);
    BEGIN
        IF l_sql IS NULL OR LENGTH(TRIM(l_sql))=0 THEN
            apex_json.open_object;apex_json.write('success',FALSE);apex_json.write('error','Kod je prazan');apex_json.close_object;
            RETURN l_result;
        END IF;
        
        DBMS_LOB.CREATETEMPORARY(l_rows,TRUE);
        
        BEGIN
            IF UPPER(LTRIM(l_sql)) LIKE 'SELECT%' THEN
                l_cur:=DBMS_SQL.OPEN_CURSOR;
                DBMS_SQL.PARSE(l_cur,l_sql,DBMS_SQL.NATIVE);
                DBMS_SQL.DESCRIBE_COLUMNS(l_cur,l_cnt,l_desc);
                FOR i IN 1..l_cnt LOOP DBMS_SQL.DEFINE_COLUMN(l_cur,i,l_val,4000);END LOOP;
                l_d:=DBMS_SQL.EXECUTE(l_cur);
                l_rows:='<div style="overflow-x:auto"><table style="width:100%;border-collapse:collapse;font-size:14px"><thead><tr>';
                FOR i IN 1..l_cnt LOOP l_rows:=l_rows||'<th style="background:#0073e6;color:#fff;padding:12px;text-align:left">'||REPLACE(REPLACE(l_desc(i).col_name,'<','&lt;'),'>','&gt;')||'</th>';END LOOP;
                l_rows:=l_rows||'</tr></thead><tbody>';
                LOOP
                    EXIT WHEN DBMS_SQL.FETCH_ROWS(l_cur)=0 OR l_rc>=l_max;
                    l_rc:=l_rc+1;l_rows:=l_rows||'<tr style="border-bottom:1px solid #eee">';
                    FOR i IN 1..l_cnt LOOP
                        DBMS_SQL.COLUMN_VALUE(l_cur,i,l_val);
                        l_rows:=l_rows||'<td style="padding:10px">'||NVL(REPLACE(REPLACE(SUBSTR(l_val,1,500),'<','&lt;'),'>','&gt;'),'<i style="color:#999">NULL</i>')||'</td>';
                    END LOOP;
                    l_rows:=l_rows||'</tr>';
                END LOOP;
                DBMS_SQL.CLOSE_CURSOR(l_cur);
                l_rows:=l_rows||'</tbody></table></div>';
                l_d:=ROUND(EXTRACT(SECOND FROM(SYSTIMESTAMP-l_t)),3);
                IF l_rc=0 THEN l_rows:='<div style="padding:20px;background:#fff3cd;border-radius:8px;color:#856404">Nema rezultata</div>';l_status:='✓ OK - 0 redova';
                ELSIF l_rc>=l_max THEN l_rows:=l_rows||'<div style="padding:10px;background:#d1ecf1;border-radius:8px;color:#0c5460;margin-top:15px">Prikazano '||l_max||' redova</div>';l_status:='✓ OK - '||l_rc||'+ redova ('||l_d||'s)';
                ELSE l_status:='✓ OK - '||l_rc||' redova, '||l_cnt||' kolona ('||l_d||'s)';END IF;
            ELSE
                BEGIN
                    EXECUTE IMMEDIATE l_sql;
                    l_d:=ROUND(EXTRACT(SECOND FROM(SYSTIMESTAMP-l_t)),3);
                    l_status:='✓ OK - PL/SQL izvršen ('||l_d||'s)';
                    l_rows:='<div style="padding:20px;background:#d4edda;border-radius:8px;color:#155724">PL/SQL blok uspješno izvršen</div>';
                EXCEPTION WHEN OTHERS THEN
                    l_err:=SQLERRM;l_status:='✗ Greška';
                    l_rows:='<div style="padding:20px;background:#f8d7da;border-radius:8px;color:#721c24"><b>Greška:</b><br>'||REPLACE(REPLACE(l_err,'<','&lt;'),'>','&gt;')||'</div>';
                END;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            l_err:=SQLERRM;l_status:='✗ Greška';
            l_rows:='<div style="padding:20px;background:#f8d7da;border-radius:8px;color:#721c24"><b>Greška:</b><br>'||REPLACE(REPLACE(l_err,'<','&lt;'),'>','&gt;')||'</div>';
        END;

        l_html:='<!DOCTYPE html><html lang="hr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>SQL Report</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:linear-gradient(135deg,#1a1a2e,#16213e);color:#eee;min-height:100vh;padding:30px}
.c{max-width:1200px;margin:0 auto}
header{background:rgba(255,255,255,.05);border-radius:12px;padding:25px;margin-bottom:25px}
h1{font-size:1.8rem;color:#00d4ff;margin-bottom:10px}
.meta{color:#aaa;font-size:.9rem}
section{background:rgba(255,255,255,.03);border-radius:12px;padding:25px;margin-bottom:20px}
h2{font-size:1.1rem;color:#00d4ff;margin-bottom:15px;padding-bottom:10px;border-bottom:1px solid rgba(255,255,255,.1)}
pre{background:#0d1117;border:1px solid #30363d;border-radius:8px;padding:20px;font-family:monospace;font-size:.85rem;overflow-x:auto;white-space:pre-wrap;color:#c9d1d9}
footer{text-align:center;padding:25px;color:#666;font-size:.8rem}
@media print{body{background:#fff;color:#333}header,section{background:#fff;border:1px solid #ddd}h1,h2{color:#0073e6}pre{background:#f5f5f5;color:#333}}
</style></head><body><div class="c">
<header><h1>📊 SQL/PL-SQL Izvještaj</h1><div class="meta"><b>Status:</b> '||l_status||' | <b>Vrijeme:</b> '||TO_CHAR(SYSDATE,'DD.MM.YYYY HH24:MI:SS')||' | <b>Korisnik:</b> '||NVL(V('APP_USER'),USER)||'</div></header>
<section><h2>📝 Kod</h2><pre>'||REPLACE(REPLACE(REPLACE(l_sql,'&','&amp;'),'<','&lt;'),'>','&gt;')||'</pre></section>
<section><h2>📋 Rezultati</h2>'||l_rows||'</section>
<footer>SQL Report Generator | Za PDF: Print → Save as PDF</footer>
</div></body></html>';

        apex_json.open_object;
        apex_json.write('success',TRUE);
        apex_json.write('html',l_html);
        apex_json.close_object;
        RETURN l_result;
    EXCEPTION WHEN OTHERS THEN
        apex_json.open_object;apex_json.write('success',FALSE);apex_json.write('error',SQLERRM);apex_json.close_object;
        RETURN l_result;
    END ajax;

END pkg_sql_report_plugin;
/

SHOW ERRORS

PROMPT [2/2] Paket kreiran!
PROMPT
PROMPT ╔══════════════════════════════════════════════════════════════════════╗
PROMPT ║                    INSTALACIJA USPJEŠNA!                             ║
PROMPT ╚══════════════════════════════════════════════════════════════════════╝
PROMPT
PROMPT ┌──────────────────────────────────────────────────────────────────────┐
PROMPT │  SADA NAPRAVITE SLJEDEĆE:                                            │
PROMPT │                                                                      │
PROMPT │  1. Idite u Shared Components → Plug-ins → Create                   │
PROMPT │                                                                      │
PROMPT │  2. Odaberite "From Scratch"                                         │
PROMPT │                                                                      │
PROMPT │  3. Unesite:                                                         │
PROMPT │     ┌────────────────────────────────────────────────────────────┐   │
PROMPT │     │ Name:           SQL Report Generator                       │   │
PROMPT │     │ Internal Name:  SQL_REPORT_GENERATOR                       │   │
PROMPT │     │ Type:           Dynamic Action                             │   │
PROMPT │     │ Category:       Execute                                    │   │
PROMPT │     └────────────────────────────────────────────────────────────┘   │
PROMPT │                                                                      │
PROMPT │  4. Source sekcija:                                                  │
PROMPT │     ┌────────────────────────────────────────────────────────────┐   │
PROMPT │     │ Render Function:  pkg_sql_report_plugin.render             │   │
PROMPT │     │ AJAX Function:    pkg_sql_report_plugin.ajax               │   │
PROMPT │     └────────────────────────────────────────────────────────────┘   │
PROMPT │                                                                      │
PROMPT │  5. Standard Attributes - OZNAČITE:                                  │
PROMPT │     [x] Fire on Initialization                                       │
PROMPT │                                                                      │
PROMPT │  6. Kliknite CREATE PLUG-IN                                          │
PROMPT │                                                                      │
PROMPT │  7. Otvorite plugin i idite na Custom Attributes → Add:             │
PROMPT │                                                                      │
PROMPT │     ATTRIBUTE 1:                                                     │
PROMPT │     ┌────────────────────────────────────────────────────────────┐   │
PROMPT │     │ Label:    Code Item                                        │   │
PROMPT │     │ Type:     Page Item                                        │   │
PROMPT │     │ Required: Yes                                              │   │
PROMPT │     └────────────────────────────────────────────────────────────┘   │
PROMPT │                                                                      │
PROMPT │     ATTRIBUTE 2:                                                     │
PROMPT │     ┌────────────────────────────────────────────────────────────┐   │
PROMPT │     │ Label:    Button Label                                     │   │
PROMPT │     │ Type:     Text                                             │   │
PROMPT │     │ Default:  Generiraj Izvještaj                              │   │
PROMPT │     └────────────────────────────────────────────────────────────┘   │
PROMPT │                                                                      │
PROMPT │     ATTRIBUTE 3:                                                     │
PROMPT │     ┌────────────────────────────────────────────────────────────┐   │
PROMPT │     │ Label:    Max Rows                                         │   │
PROMPT │     │ Type:     Integer                                          │   │
PROMPT │     │ Default:  1000                                             │   │
PROMPT │     └────────────────────────────────────────────────────────────┘   │
PROMPT │                                                                      │
PROMPT └──────────────────────────────────────────────────────────────────────┘
PROMPT
PROMPT ┌──────────────────────────────────────────────────────────────────────┐
PROMPT │  KORIŠTENJE NA STRANICI:                                             │
PROMPT │                                                                      │
PROMPT │  1. Dodajte Textarea (npr. P1_SQL_CODE)                              │
PROMPT │                                                                      │
PROMPT │  2. Kreirajte Dynamic Action:                                        │
PROMPT │     - Event: Page Load                                               │
PROMPT │     - Action: SQL Report Generator                                   │
PROMPT │     - Code Item: P1_SQL_CODE                                         │
PROMPT │                                                                      │
PROMPT │  3. Spremite i pokrenite - gumb se automatski pojavi!                │
PROMPT │                                                                      │
PROMPT └──────────────────────────────────────────────────────────────────────┘
PROMPT

