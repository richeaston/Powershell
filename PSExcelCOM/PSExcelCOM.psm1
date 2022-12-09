<#
Functions for working with Excel COM object
#>

# Set column width 
# usage: PSSetColumnWidth -sheet sheet1 -column "A" -width 10
function PSSetColumnWidth($sheet, $column, $width) {
        $sheetWS = $WB.Worksheets.item("$sheet")
        $sheetWS.Columns("$column").ColumnWidth = $width
}



# Set row height 
# usage: PSSetRowHeight -sheet sheet1 -rows "1" -height 10
function PSSetRowHeight($sheet, $rows, $height) {
    $sheetWS = $WB.Worksheets.item($sheet)
    $selection = $sheetWS.Rows("$rows")
    [void]$selection.select()
    $selection.RowHeight = "$height"
    $selection | Out-Null
}

Function PSSaveWorkbook($file) {
    $WB.SaveAs($file)
    Write-host "Excel sheet is done.." -ForegroundColor Yellow
}

# Set borderaround area 
# usage: PSSetBorderAround -sheet sheet1 -range "A1:b3" -criteria 1,1,1 (linestyle,weight,colorindex)
function PSSetBorderAround($sheet, $range, $linestyle, $weight, $colorindexindex) {
    $sheetWS = $WB.Worksheets.item("$sheet")
    $selection = $sheetWS.Range($range)
    [void]$selection.select()
    $selection.BorderAround($linestyle,$weight,$colorindexindex)
    $selection | Out-Null
}

<#
$Continuous=1
$DiagonalDown=5
$DiagonalUp=6
$EdgeBottom=9
$EdgeLeft=7
$EdgeRight=10
$EdgeTop=8
$InsideHorizontal=12
$InsideVertical=11
#>

Function PSSetBorderInside($sheet, $range, $weight, $colorindexindex) {
    $sheetWS = $WB.Worksheets.item($sheet)
    $selection = $sheetWS.Range($range)
    [void]$selection.select()
    $selection.Borders.item(11).Linestyle = 1
    $selection.Borders.item(12).Linestyle = 1
    $selection.Borders.item(11).Weight = $weight
    $selection.Borders.item(12).Weight = $weight
    $selection.Borders.item(11).Colorindex = $colorindexindex
    $selection.Borders.item(12).Colorindex = $colorindexindex
    $selection | Out-Null
}

# Set background color on area 
# usage: PSSetbackgroundcolor -sheet sheet1 -range "a1:b3" -color 15
function PSSetbackgroundcolor($sheet, $range, $colorindex) {
    $sheetWS = $WB.Worksheets.item("$sheet")
    $selection = $sheetWS.Range("$range")
    [void]$selection.select()
    $selection.Interior.ColorIndex = "$colorindex"
    $selection | Out-Null
}

# Set font on area 
# usage: PSSetfont -sheet sheet1 -range "a1:b3" -fname 'arial' -fsize 12 -color 0
function PSSetfont($sheet, $range, $fname, $fsize, $colorindex) {
    $sheetWS = $WB.Worksheets.item("$sheet")
    $selection = $sheetWS.Range("$range")
    [void]$selection.select()
    $selection.Font.Name = "$fname"
    $selection.Font.Size = "$fsize"
    $selection.Font.ColorIndex = $colorindex
    $selection | Out-Null
}

# Set font Bold
# usage: PSSetfontBold -sheet sheet1 -range "a1:b3"
function PSSetFontBold($sheet, $range) {
    $sheetWS = $WB.Worksheets.item($sheet)
    $selection = $sheetWS.Range($range)
    [void]$selection.select()
    $selection.font.bold = $True
    $selection | Out-Null
    
}

function PSSetFontUnderlined($sheet, $range) {
    $sheetWS = $WB.Worksheets.item($sheet)
    $selection = $sheetWS.Range($range)
    [void]$selection.select()
    $selection.font.underline = $True
    $selection | Out-Null
}

# Set cell content
# usage: PSSetcellcontent -sheet sheet1 -column 1 -row 2 -content "hello world"
function PSSetCellContent($sheet, $column, $row, $content) {
    $sheetWS = $WB.Worksheets.item($sheet)
    $sheetWS.cells.item($row,$column) = $content
    
}

function PSSetCellContentWrap($sheet, $range) {
    $sheetWS = $WB.Worksheets.item($sheet)
    $selection = $sheetWS.Range($range)
    [void]$selection.select()
    $selection.WrapText = $True
    $selection | Out-Null
}

# Set  Active sheet
# usage: PSActiveSheet -sheet sheet1
function PSActiveSheet($sheet) {
    $active = $WB.ActiveSheet.name
    if ($active -ne $sheet) {
        Write-host "`nSheet active: $active, " -NoNewline -ForegroundColor Red
        Write-host "changing to $sheet`n" -ForegroundColor Yellow
        $sheetWS = $WB.Worksheets.item("$sheet")
        $sheetWS.activate()
    }else{
        Write-host "`nSheet active: $active`n" -ForegroundColor Green
    }
}

function PSMergecells($sheet, $range) {
    $sheetWS = $WB.Worksheets.item($sheet)
    $selection = $sheetWS.Range($range)
    [void]$selection.select()
    $selection.MergeCells = $True
    $selection | Out-Null
}

Function PSAddPicture($sheet, $path, $top, $left, $width, $height) {
    $sheetWS = $WB.Worksheets.item($sheet)
    $sheetWS.Shapes.AddPicture($path, $msoFalse, $msoTrue, $top, $left, $width, $height)
}

Function PSSetHAlignment($sheet, $range, $alignment) {
    $sheetWS = $WB.Worksheets.item($sheet)
    $sheetWS.Range($range).HorizontalAlignment = $alignment
    
}

# Set valignment
# usage: PSSetVAlignment -sheet sheet1 -range "a1:a3" -Alignment 1  #4 = double spaced, 3 = bottom, 2 = middle, 1 = top
   
function PSSetVAlignment($sheet, $range, $Alignment) {
    $sheetWS = $WB.Worksheets.item($sheet)
    $selection = $sheetWS.Range($range).VerticalAlignment = $Alignment
}
