xquery version '1.0-ml';

module namespace excel = "http://marklogic.com/excel";

declare namespace zip   = "xdmp:zip";
declare namespace ss = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";
declare namespace rel = "http://schemas.openxmlformats.org/package/2006/relationships";
declare namespace rel2 = "http://schemas.openxmlformats.org/officeDocument/2006/relationships";


import module namespace ooxml="http://marklogic.com/openxml" at "/MarkLogic/openxml/package.xqy";
import module namespace ml-excel="http://marklogic.com/openxml/excel" at "spreadsheet-ml-support2.xqy";

declare option xdmp:mapping "false";

declare variable $WORKSHEET-REL-TYPE := "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet";
declare variable $EXCEL-MAP := map:map();
declare variable $SHARED-STRINGS := ();


(::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  :: GENERIC EXCEL FUNCTIONS
 ::)
declare function excel:get-parts($excel as node(), $part-uris as xs:string*) as node()* {
	let $parts :=  ooxml:package-parts($excel)
	for $uri at $pos in ooxml:package-uris($excel)
	where $uri = $part-uris
	return
		$parts[$pos]
};

declare function excel:row-is-empty($row as element(ss:row)) as xs:boolean {
    every $c in $row/ss:c
    satisfies fn:normalize-space(fn:string($c/ss:v)) eq ""
    and fn:not($c/ss:v)
};

declare function excel:get-number($string as xs:string) as xs:integer? {
    if ($string castable as xs:float) then
         xs:float($string) cast as xs:integer
    else ()
};

(:~
 : Loads an excel spreadsheet into a map
~:)
declare function excel:load($excel as binary()) as map:map {
    let $excelmap := map:map()

	let $parts := ooxml:package-parts($excel)
	let $_ :=
	    for $uri at $pos in ooxml:package-uris($excel)
	        let $content :=  fn:subsequence($parts,$pos,1)
    	    return
    	        if (fn:contains($uri,'.xml'))
    	        then (map:put($excelmap,$uri,$content))
    	        else ()

     return (
        xdmp:set($EXCEL-MAP,$excelmap),
        xdmp:set($SHARED-STRINGS,excel:shared-strings()),
        $excelmap
     )
};
(:~
 : Gets the workbook element from excel file.
~:)
declare function excel:get-workbook() as element(ss:workbook)? {
   map:get($EXCEL-MAP,"xl/workbook.xml")/ss:workbook
};

(:~
 : Returns a a ss:worksheet element by name
~:)
declare function excel:get-sheet-by-name(
    $sheetname as xs:string
) as element(ss:worksheet)?
{
 let $sheet-ref := map:get($EXCEL-MAP,"xl/workbook.xml")/ss:workbook/ss:sheets/ss:sheet[@name eq $sheetname]
 let $rels-ptr  := map:get($EXCEL-MAP,"xl/_rels/workbook.xml.rels")/rel:Relationships/rel:Relationship[
    @Type eq $WORKSHEET-REL-TYPE and
    @Id eq $sheet-ref/@rel2:id
 ]/@Target
 return
    map:get($EXCEL-MAP,fn:concat("xl/",$rels-ptr))/ss:worksheet
};

(:~
 : Gets the sheet names from an excel workbook
~:)
declare function excel:get-sheet-names(
    $EXCEL-MAP as map:map
) as xs:string*
{
  map:get($EXCEL-MAP,"xl/workbook.xml")/ss:workbook/ss:sheets/ss:sheet/@name
};

(:~
 : Replaces a part of the excel document with a new part
~:)
declare function excel:replace-parts($excel as node(), $part-uris as xs:string*, $parts as node()*) as node() {
	let $uris :=
		ooxml:package-uris($excel)
	let $new-parts :=
		for $part at $pos in ooxml:package-parts($excel)
		let $uri := $uris[$pos]
		return
			if ($uri = $part-uris) then
				let $index := fn:index-of($part-uris, $uri)
				return
					$parts[$index]
			else
				$part
	let $manifest :=
		<zip:parts>{
			for $uri in $uris
			return
				<zip:part>{$uri}</zip:part>
		}</zip:parts>
    let $add :=
        for $uri at $pos in $part-uris
        return
          if($uri = $uris) then ()
          else
            (xdmp:set($new-parts,($new-parts,$parts[$pos])),
             xdmp:set($manifest,
              <zip:parts>{
                $manifest/*,
                <zip:part>{$uri}</zip:part>
              }</zip:parts>)
           )
	return
		xdmp:zip-create($manifest, $new-parts)
};
(:~
 : Returns the sheet uris from a given excel document
~:)
declare function excel:get-sheet-uris($excel as node()) as xs:string* {
	for $uri in ooxml:package-uris($excel)
	where fn:contains($uri, 'worksheets/sheet')
	order by $uri
	return
		$uri
};

(:~
 : Returns the URI of the shared strings
~:)
declare function excel:get-shared-strings-uri($excel as node()) as xs:string? {
	for $uri at $pos in ooxml:package-uris($excel)
	where fn:contains($uri, 'sharedStrings')
	return
		$uri
};
(:~
 :
~:)
declare function excel:get-sheet-rows(
    $sheet as element(ss:worksheet)
) as element(ss:row)* {
	fn:subsequence($sheet/ss:sheetData/ss:row,1)
};
(:~
 : Gets the rows from a worksheet
~:)
declare function excel:get-sheet-rows(
    $sheet as element(ss:worksheet),
    $start as xs:integer
) as element(ss:row)* {
	fn:subsequence($sheet/ss:sheetData/ss:row,$start)
};
(:~
 :
~:)
declare function excel:get-sheet-rows(
    $sheet as element(ss:worksheet),
    $start as xs:integer,
    $end as xs:integer
) as element(ss:row)* {
	fn:subsequence($sheet/ss:sheetData/ss:row,$start,$end)
};

declare function excel:replace-sheet-rows($sheet as element(ss:worksheet), $rows as element(ss:row)*) as element(ss:worksheet) {
	let $sheetData := $sheet/ss:sheetData
	return
		<ss:worksheet> {
			$sheet/@*,
			$sheet/node()[. << $sheetData],
			<ss:sheetData> {
				$sheetData/@*,
				$rows
			} </ss:sheetData>,
			$sheet/node()[. >> $sheetData]
		} </ss:worksheet>
};

declare function excel:get-cell-row-index($cell as element(ss:c)) as xs:integer {
	ml-excel:a1-row($cell/@r)
};
declare function excel:get-cell-col-index($cell as element(ss:c)) as xs:integer {
	ml-excel:col-letter-to-idx(ml-excel:a1-column($cell/@r))
};

declare function excel:get-row-cells($row as element(ss:row)?) as element(ss:c)* {
	excel:get-row-cells($row, fn:true())
};

declare function excel:get-row-cells
(
  $row as element(ss:row)?,
  $expand-cells as xs:boolean) as element(ss:c)*
{
  (: no cells if no row :)
  if (fn:not($row))
  then ()

	else if ($expand-cells) then
		(: This works, but adds unformatted cells that may not fit in nicely.
		 : Could use copy-cell, but which best to copy?
		 :)
		for $c at $pos in $row/ss:c
		let $row-index := excel:get-cell-row-index($c)
		let $col-index := excel:get-cell-col-index($c)
		let $prev-col := $row/ss:c[$pos - 1]
		let $prev-col-index :=
			if ($prev-col) then
				ml-excel:col-letter-to-idx(ml-excel:a1-column($prev-col/@r))
			else if ($pos = 1) then
				0
			else
				$col-index
		return (
			for $i in ($prev-col-index + 1) to ($col-index - 1)
			let $r := ml-excel:r1c1-to-a1($row-index, $i)
			return
				ml-excel:cell($r, ()),
			$c
		)
	else
		$row/ss:c
};

(: Improved version of the one in spreadsheet-ml-support.xqy :-/ :)
declare function excel:cell-string-value(
	$cells as element(ss:c)*
) as xs:string*
{
  for $c at $pos in $cells
  let $value :=
    if ( $c/@t="s" )
    then
      let $shared-string :=
        fn:subsequence($SHARED-STRINGS/ss:si,fn:data($c/ss:v) + 1,1)/ss:t
      return
        if ($shared-string)
        then
          $shared-string
        else
          (:fn:error(xs:QName("excel:missingstr"), fn:concat("Shared string missing for cell ", $pos)):)
        ()
    else if ($c/@t eq "inlineStr")
    then
      $c/ss:is/ss:t
    else
      $c/ss:v
  order by $pos
  return
    (: use fn:string() to account for empty cells, makes sure count
     : of return strings always equals count of input cells
     :)
    fn:string($value)
};
(: Uses maps to speed up processing of value lookups :-/ :)
declare function excel:cell-values(
	$cells as element(ss:c)*,
	$SHARED-STRINGS as map:map
) as xs:string*
{
  for $c at $pos in $cells
  let $value :=
    if ( $c/@t="s" )
    then
      let $shared-string := map:get($SHARED-STRINGS,fn:string($c/ss:v + 1))
        (:$SHARED-STRINGS/ss:si[ fn:data($c/ss:v) + 1 ]/ss:t:)
      return
        if ($shared-string)
        then
          $shared-string
        else
          (:fn:error(xs:QName("excel:missingstr"), fn:concat("Shared string missing for cell ", $pos)):)
        ()
    else if ($c/@t eq "inlineStr")
    then
      $c/ss:is/ss:t
    else
      $c/ss:v
  return
    (: use fn:string() to account for empty cells, makes sure count
     : of return strings always equals count of input cells
     :)
    fn:string($value)
};

declare function excel:normalize-cell(
	$cells          as element(ss:c)*,
	$SHARED-STRINGS as element(ss:sst)?
) as element(ss:c)*
{
    for $c at $pos in $cells
    let $value :=
        if ( $c/@t="s" ) then
			let $shared-string :=
				$SHARED-STRINGS/ss:si[ fn:data($c/ss:v) + 1 ]/ss:t
			return
				if ($shared-string) then
					$shared-string
				else
					(:fn:error(xs:QName("excel:missingstr"), fn:concat("Shared string missing for cell ", $pos)):)
					()
        else
			$c//text()
	return
		(: use fn:string() to account for empty cells, makes sure count
		 : of return strings always equals count of input cells
		 :)
		<ss:c t="inlineStr">
		  { $c/@*[fn:local-name(.) ne "t"] }
		  <ss:is>
        <ss:v>{$value}</ss:v>
      </ss:is>
    </ss:c>
};

declare function excel:set-cell-value(
	$cell    as element(ss:c),
	$value   as xs:anyAtomicType?,
	$formula as xs:string?,
	$date-id as xs:integer?
) as element(ss:c)
{
    if ($value castable as xs:integer or fn:empty($value)) then
		let $date-attr :=
			if (fn:empty($date-id)) then
				$cell/@s
			else
				attribute s { $date-id }
        let $formula :=
			if(fn:not(fn:empty($formula))) then
                <ss:f>{$formula}</ss:f>
            else ()
        let $value :=
			if(fn:not($value eq 0) and fn:not(fn:empty($value)))then
				<ss:v>{$value}</ss:v>
            else ()
        return
			<ss:c>{
				$cell/@* except $cell/(@t|@s),
				$date-attr,
				$formula,
				$value
			}</ss:c>
    else
		<ss:c t="inlineStr">
			{ $cell/@* except $cell/@t }
			<ss:is>
				<ss:t>{$value}</ss:t>
			</ss:is>
		</ss:c>
};

declare function excel:copy-cell(
	$cell     as element(ss:c),
	$dest-row as xs:integer,
	$dest-col as xs:integer
) as element(ss:c)
{
	<ss:c r="{ml-excel:r1c1-to-a1($dest-row, $dest-col)}">{
		$cell/@* except $cell/@r,
		$cell/node()
	}</ss:c>
};
declare function excel:get-sheet-column-names(
$sheet as element(ss:worksheet)
) as xs:string* {
    excel:get-sheet-column-names($sheet,1)
};

declare function excel:get-sheet-column-names(
        $sheet as element(ss:worksheet),
        $row-index as xs:integer
    ) as xs:string* {
	for $value at $pos in excel:get-row-cells(fn:subsequence(excel:get-sheet-rows($sheet),$row-index,1))
	let $colname := excel:cell-string-value($value)
	return
	   if($colname) then $colname else fn:concat("Column",$pos)
};
declare function excel:get-sheet-column-names-map(
    $sheet as element(ss:worksheet)
    ) as xs:string*  {
   excel:get-sheet-column-names-map($sheet, 1)
};
declare function excel:get-sheet-column-names-map(
    $sheet as element(ss:worksheet),
    $row-index as xs:integer
    ) as xs:string* {
	for $value in
		excel:cell-values(
			excel:get-row-cells(
				excel:get-sheet-rows($sheet)[$row-index],
				fn:true()
			),
			$SHARED-STRINGS
		)
	where fn:string-length($value) > 0
	return
		fn:normalize-space($value)
};

declare function excel:string-to-element-name($string as xs:string) as xs:QName {
	(: remove unwanted chars :)
	xs:QName(fn:replace($string, '[^a-zA-Z0-9\\-\\_]', ''))
};

declare function excel:shared-strings-map() as map:map {
  let $ss := excel:shared-strings()
  let $map := map:map()
  let $_ :=
     for $s at $pos in $ss/ss:si
     return
       map:put($map,fn:string($pos),fn:data($s/ss:t))
  return $map
};

declare function excel:shared-strings() as node() {
      let $ss-key := map:keys($EXCEL-MAP)[fn:contains(.,"sharedStrings")]
      return
         map:get($EXCEL-MAP,$ss-key)/element()
};

declare function excel:map-row-cells-to-elements(
    $row as element(ss:row)?,
    $column-names as xs:string*
    ) as element()* {
	for $cell in excel:get-row-cells($row)[1 to fn:count($column-names)]
	let $pos := excel:get-cell-col-index($cell)
	let $row-number := excel:get-cell-row-index($cell)
	let $value :=
	  fn:normalize-space(fn:translate(excel:cell-string-value($cell), '&#160;', ' '))
	where $value
	return
		element field {
		  attribute columnName { $column-names[$pos] },
		  attribute row { $row-number },
		  attribute col { $pos },
			$value
		}
};
declare function excel:row-to-xml(
  $row as element(ss:row),
  $column-names as xs:string*,
  $options as xs:string*
) {
   for $cell in excel:get-row-cells($row)[1 to fn:count($column-names)]
   let $value := if(fn:string-length($cell) > 0) then excel:cell-string-value($cell) else "N.A"
   let $pos := excel:get-cell-col-index($cell)
   where $pos le fn:count($column-names)
   return
    let $colname := excel:colname-to-qname($column-names[$pos],$options)
    return element {xs:QName($colname)}{$value}
};

declare function excel:row-to-xml-cs(
  $row as element(ss:row),
  $column-names as xs:string*,
  $column-names-count as xs:integer*,
  $options as xs:string*
) {
   for $cell in excel:get-row-cells($row)[1 to $column-names-count]
   let $value := if(fn:string-length($cell) > 0) then excel:cell-string-value($cell) else "N.A"
   let $pos := excel:get-cell-col-index($cell)
   where $pos le $column-names-count
   return
    let $colname := excel:colname-to-qname($column-names[$pos],$options)
    return element {xs:QName($colname)}{$value}
};

(:~
 : Converts a column to a QName
~:)
declare function excel:colname-to-qname(
    $name as xs:string,
    $options as xs:string*
 ) as xs:QName {
   let $mod-name :=
      (:if (fn:number(fn:substring($name, 1, 1)) eq (0,1,2,3,4,5,6,7,8,9)) then:)
      if (fn:matches(fn:substring($name, 1, 1), "\d")) then
        fn:concat("_", $name)
      else
        $name

   let $mod-name := fn:replace($mod-name, ":", "_")
   (:let $_ := xdmp:log("mod-name: " || $mod-name):)

   (:let $pattern := "[^\i\c]":)
   let $pattern := "[\i\c*]"
   let $tokens := fn:analyze-string($mod-name,$pattern)
   (:let $_ := xdmp:log($tokens):)
   return fn:string-join((
     for $tok in $tokens/*
     return
       switch(fn:local-name($tok))
         case "match" return
           fn:data($tok)
         case "non-match" return
           "_"
         default return ""
     ),"") ! xs:QName(
        if($options = "camel" )
        then fn:concat(fn:lower-case(fn:substring(.,1,1)),fn:substring(.,2))
        else if($options = "pascal")
        then fn:concat(fn:upper-case(fn:substring(.,1,1)),fn:substring(.,2))
        else .
      )
};

declare function excel:colname-to-qname-original(
    $name as xs:string,
    $options as xs:string*
 ) as xs:QName {
   let $mod-name :=
      (:if (fn:number(fn:substring($name, 1, 1)) eq (0,1,2,3,4,5,6,7,8,9)) then:)
      if (fn:matches(fn:substring($name, 1, 1), "\d")) then
        fn:concat("_", $name)
      else
        $name

   let $_ := xdmp:log("mod-name: " || $mod-name)

   (:let $pattern := "[^\i\c]":)
   let $pattern := "[\i\c*]"
   let $tokens := fn:analyze-string($mod-name,$pattern)
   let $_ := xdmp:log($tokens)
   return fn:string-join((
     for $tok in $tokens/*
     return
       switch(fn:local-name($tok))
         case "match" return
           let $conversions := fn:string-to-codepoints(fn:data($tok))
           return
            for $convert in $conversions return
            if($options = "strip-space" and $convert eq  32)
            then "" else fn:concat("_x",$convert,"_")
         case "non-match" return
           if($tok/preceding-sibling::*[1][contains(.," ")] and $options = "camel")
           then fn:concat(fn:upper-case(fn:substring($tok,1,1)),fn:substring($tok,2))
           else fn:data($tok)
         default return ""
     ),"") ! xs:QName(
        if($options = "camel" )
        then fn:concat(fn:lower-case(fn:substring(.,1,1)),fn:substring(.,2))
        else if($options = "pascal")
        then fn:concat(fn:upper-case(fn:substring(.,1,1)),fn:substring(.,2))
        else .
      )
};
(::)
declare function excel:map-row-cells-to-elements-map(
    $row as element(ss:row)?,
    $column-names as xs:string*
    ) as element()* {
	for $cell in excel:get-row-cells($row)[1 to fn:count($column-names)]
	let $pos := excel:get-cell-col-index($cell)
	let $row-number := excel:get-cell-row-index($cell)
	let $value :=
	  fn:normalize-space(fn:translate(excel:cell-values($cell, $SHARED-STRINGS), '&#160;', ' '))
	where $value
	return
		element field {
		  attribute columnName { $column-names[$pos] },
		  attribute row { $row-number },
		  attribute col { $pos },
			$value
		}
};

declare function get-last-column-index(
  $column-names as map:map
) as xs:integer {
  get-character-position(
    fn:max(
      for $key in map:keys($column-names)
        return map:get($column-names, $key)
    )
  )
};

declare function get-character-position(
  $letter as xs:string
) as xs:integer{
  fn:index-of(
    ("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "Q", "X", "Y", "Z"),
    $letter
  )
};

declare function excel:map-row-cells-to-elements-map-2(
  $row as element(ss:row)?,
  $column-names as map:map
) as element()* {
  let $cells := excel:get-row-cells($row)
  let $last-column := get-last-column-index($column-names)
  let $row-number := $row/@r
  return
	  for $column-name in map:keys($column-names)
      let $col := map:get($column-names, $column-name)
      let $cell-ref := $col || $row-number
      let $pos := excel:get-character-position($col)
      let $value := excel:get-cells($cells, $last-column, $cell-ref)
      order by $pos
    	return
    		element field {
    		  attribute columnName { $column-name },
    		  attribute row { $row-number },
    		  attribute col { $pos },
    			$value
  		}
};

declare %private function excel:get-cells(
  $cells as element(ss:c)*,
  $last-column as xs:integer,
  $cell-ref as xs:string
  ) as xs:string* {
  for $cell in $cells[1 to $last-column]
    let $value := fn:normalize-space(fn:translate(excel:cell-values($cell, $SHARED-STRINGS), '&#160;', ' '))
    where $cell/@r = $cell-ref
    return $value
};

declare function excel:set-cell-string-value(
	$cell    as element(ss:c),
	$value   as xs:anyAtomicType?,
	$formula as xs:string?,
	$date-id as xs:integer?
) as element(ss:c)
{
		<ss:c t="inlineStr">
			{ $cell/@* except $cell/@t }
			<ss:is>
				<ss:t>{fn:string($value)}</ss:t>
			</ss:is>
		</ss:c>
};

(:~
 : Extract column name from the cell (ie: cell [B4] -> B)
~:)
declare function excel:get-col-name(
  $cell as element(ss:c),
  $row-number as xs:integer
) as xs:string {
  fn:substring($cell/@r, 1, fn:string-length($cell/@r) - $row-number)
};

(:~
 : Return a map:map header / column-name (ie: "Header 1" / "A")
~:)
declare function excel:get-sheet-headers-map(
  $sheet as element(ss:worksheet)
) as map:map  {
   get-sheet-headers-map($sheet, 1)
};
(:~
 : Gets the sheet names into a map
~:)
declare function excel:get-sheet-headers-map(
  $sheet as element(ss:worksheet),
  $row-index as xs:integer
) as map:map {
      map:new(
        for $cell in
          excel:get-row-cells(
        		excel:get-sheet-rows($sheet)[$row-index],
        		fn:true()
      		)
      		let $col-name := excel:get-col-name($cell, $row-index)
      		return map:entry(excel:cell-values(
      			$cell,
      			$SHARED-STRINGS
      		), $col-name)
      )
};
declare function excel:date($date as xs:float) as xs:date {
    let $lotus-bug := if (xs:double($date) gt 59) then xs:dayTimeDuration("P1D") else xs:dayTimeDuration("P0D")
    let $date := math:trunc($date)
    let $start := xs:dateTime ('1899-12-31T00:00:00')
    let $dtd := xs:dayTimeDuration ('P'|| $date ||'D')
    return
       $start - $lotus-bug + $date
};
declare function excel:dateTime ($dt as xs:float) as xs:dateTime {
    let $lotus-bug := if ($dt gt 59) then xs:dayTimeDuration("P1D") else xs:dayTimeDuration("P0D")
    let $days := math:trunc($dt)
    let $seconds :=  xs:double ($dt - $days) * (24 * 60 * 60)
    let $dtd := xs:dayTimeDuration ('P'||$days||'DT'||$seconds||'S')
    let $start := xs:dateTime ('1899-12-31T00:00:00')
    return $start - $lotus-bug + $dtd
};

