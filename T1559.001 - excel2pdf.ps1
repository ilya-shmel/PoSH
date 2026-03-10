$ExcelObject = New-Object -ComObject Excel.Application
$ExcelObject.Visible = $false
$workbook = $ExcelObject.Workbooks.Open("C:\report.xlsx")
$workbook.ExportAsFixedFormat(0, "C:\report.pdf")
$ExcelObject.Quit()