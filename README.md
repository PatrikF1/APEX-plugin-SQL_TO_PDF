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

### 1. Install PL/SQL Package

Upload and run the `EXPORT_SQL_REPORT_PLUGIN.sql` file in SQL Workshop.

### 2. Create Plugin in APEX

Create the plugin through Shared Components → Plug-ins → Create → From Scratch

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

---

**The plugin is written and ready to use!** 🎉
