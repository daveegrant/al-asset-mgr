xquery version "1.0-ml";

module namespace cs-lib = "http://marklogic.com/CS/lib" ;

import module namespace excel = "http://marklogic.com/excel" at "/lib/excel-lib.xqy";
import module namespace lib = "http://marklogic.com/kpmg/gwpc/data-processing" at "/lib/data-processing.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
declare option xdmp:mapping "false";


declare function cs-lib:process-binary($uri as xs:string){
  let $logger := xdmp:log("Processing binary")
  let $_ := xdmp:document-filter(xdmp:document-get(xdmp:url-decode($uri)))
  let $new_doc := <doc>{$_}</doc>
  return xdmp:document-insert(fn:concat($uri,'-processed.xml'), $new_doc,(),"Processed")
};

declare function cs-lib:process-excel($uri as xs:string, $skip-row as xs:integer){
let $doc := xdmp:document-get($uri)/binary()
let $wb := excel:load($doc)
let $sheetname := fn:exactly-one(excel:get-sheet-names($wb))
let $sheet := excel:get-sheet-by-name($sheetname)

 let $colnames := excel:get-sheet-column-names($sheet, $skip-row + 1)
 let $column-names-count := fn:count($colnames)

  for $row at $ctr in excel:get-sheet-rows($sheet, $skip-row + 2)
  let $row-xml := element well {
     for $cell in excel:get-row-cells($row)[1 to $column-names-count]
   let $value :=excel:cell-string-value($cell)
   let $pos := excel:get-cell-col-index($cell)

   return
    let $colname := excel:colname-to-qname($colnames[$pos],("pascal"))
    return element {xs:QName($colname)}{$value}
  }
  return
  if (fn:string-length(fn:data($row-xml)) lt 1)  then ()
    else
    xdmp:spawn-function(function() { xdmp:document-insert(fn:concat(fn:concat($sheetname,"-"),$ctr), $row-xml) },<options xmlns="xdmp:eval">
  <transaction-mode>update-auto-commit</transaction-mode>
</options>)

};

declare function cs-lib:process-excel-data(
  $uri-prefix as xs:string,
  $doc as binary(),
  $skip-row as xs:integer,
  $permissions as node()*,
  $collections as xs:string*,
  $is-product as xs:boolean
)
{
  let $wb := excel:load($doc)
  let $sheetname := fn:exactly-one(excel:get-sheet-names($wb))
  let $_ := xdmp:log($sheetname)
  let $sheet := excel:get-sheet-by-name($sheetname)

  let $colnames := excel:get-sheet-column-names($sheet, $skip-row + 1)
  let $column-names-count := fn:count($colnames)

  for $row at $ctr in excel:get-sheet-rows($sheet, $skip-row + 2)
    let $row-xml := element content {
      for $cell in excel:get-row-cells($row)[1 to $column-names-count]
        let $value :=excel:cell-string-value($cell)
        let $pos := excel:get-cell-col-index($cell)

        return
          let $colname := excel:colname-to-qname($colnames[$pos], ())
          return element {xs:QName($colname)}{$value}
    }

    let $book-code :=
      if ($is-product) then
        $row-xml/BookCode/data()
      else
        $row-xml/Bookcode/data()

    let $elem-cost-type :=
      if ($is-product) then
        ()
      else
        if ($row-xml/Cost_01_Plate/data()) then
          "Plate"
        else if ($row-xml/Cost_02_Author/data()) then
          "Author"
        else if ($row-xml/Cost_03_RF_Sub/data()) then
          "RF Sub"
        else if ($row-xml/Cost_04_PhotoShoot/data()) then
          "Shoot"
        else if ($row-xml/Cost_05_Cover/data()) then
          "Cover"
        else
          "Unknown"

    let $row-doc := element envelope {
      if ($book-code) then
        (:element commonBookCode { $book-code }:)
        element commonBookCode { fn:replace($book-code, "&#13;", "") }
      else
        (),
      if ($elem-cost-type) then
        element costType { $elem-cost-type }
      else
        (),
      element source {
        if ($is-product) then
          element product { $row-xml/* }
        else
          element element { $row-xml/* }
      },
      element metadata {}
    }

    return
      if (fn:string-length(fn:data($row-xml)) lt 1)  then ()
      else
        xdmp:spawn-function(
          function() {
            xdmp:document-insert(
              fn:concat($uri-prefix, $sheetname, "-", $ctr, ".xml"),
              $row-doc,
              $permissions,
              $collections
            )
          },
          <options xmlns="xdmp:eval">
            <transaction-mode>update-auto-commit</transaction-mode>
          </options>
        )

};
