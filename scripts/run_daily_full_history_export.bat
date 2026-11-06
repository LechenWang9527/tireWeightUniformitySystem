@echo off
set "PYTHON_EXE=C:\Users\<user>\AppData\Local\Programs\Python\Python312\python.exe"
set "SCRIPT_PATH=\\YOUR-SERVER-IP\d\TU AI\TireWeight_Uniformity_Analysis\backend\etl\export_cgrs_full_history.py"

"%PYTHON_EXE%" "%SCRIPT_PATH%"
