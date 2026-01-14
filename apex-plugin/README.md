# SQL/PL-SQL Report Generator Plugin

**Oracle APEX Plugin** developed for automatic report generation from SQL/PL-SQL code.

This plugin is written and developed as a complete Oracle APEX Dynamic Action plugin that automatically adds report generation functionality to any page in your APEX application.

## 📋 About the Plugin

The plugin is written in **PL/SQL** and **JavaScript** and consists of:
- PL/SQL package (`pkg_sql_report_plugin`) that executes SQL code and generates HTML reports
- JavaScript code that automatically adds a button to the page
- Complete HTML template for beautifully formatted reports

## 🚀 Installation

The plugin is installed in two steps:

### Step 1: Install PL/SQL Package

1. Open APEX
2. **SQL Workshop** → **SQL Scripts** → **Upload**
3. Upload the file **`EXPORT_SQL_REPORT_PLUGIN.sql`**
4. Click **Run**

### Step 2: Create Plugin in APEX

1. **Shared Components** → **Plug-ins** → **Create** → **From Scratch**
2. Enter:
   - **Name**: `SQL Report Generator`
   - **Internal Name**: `SQL_REPORT_GENERATOR`
   - **Type**: `Dynamic Action`
   - **Category**: `Execute`
3. **Source**:
   - **Render Function**: `pkg_sql_report_plugin.render`
   - **AJAX Function**: `pkg_sql_report_plugin.ajax`
4. **Standard Attributes**: ✅ `Fire on Initialization`
5. Click **Create Plug-in**

### Step 3: Add Attributes

Open plugin → **Custom Attributes** → **Add Attribute**:

| # | Label | Type | Required | Default |
|---|-------|------|----------|---------|
| 1 | Code Item | Page Item | Yes | - |
| 2 | Button Label | Text | No | Generate Report |
| 3 | Max Rows | Integer | No | 1000 |

## 📖 Usage

1. Add **Textarea** to page (e.g. `P1_SQL_CODE`)
2. Create **Dynamic Action**:
   - **Event**: `Page Load`
   - **Action**: `SQL Report Generator`
   - **Code Item**: `P1_SQL_CODE`
3. Save and run the page
4. Button "Generate Report" will automatically appear below textarea!

## ✨ Features

The plugin is written to:
- Automatically add a "Generate Report" button below any textarea field
- Execute SELECT queries and display results in a formatted table
- Execute PL/SQL blocks and display execution status
- Generate professional HTML reports with code and results
- Display detailed errors if SQL code is incorrect
- Allow configuration of button label and maximum number of rows

## 📁 Plugin Structure

The plugin is written as:
- **Render function** - adds JavaScript to the page
- **AJAX function** - executes SQL and generates HTML report
- **Custom attributes** - allow plugin configuration

## 🔧 Technical Details

- **Language**: PL/SQL, JavaScript, HTML/CSS
- **APEX Version**: 5.0+
- **Database**: Oracle 11g+
- **Plugin Type**: Dynamic Action

## 📝 Notes

The plugin generates **HTML report** that is downloaded. For PDF format:
1. Open the downloaded HTML file in browser
2. File → Print → Save as PDF

---

**The plugin is written and ready to use!** 🎉

**Version**: 1.0.0
