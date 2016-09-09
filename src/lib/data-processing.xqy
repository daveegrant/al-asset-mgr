xquery version "1.0-ml";

module namespace lib = "http://marklogic.com/kpmg/gwpc/data-processing";

import module namespace excel = "http://marklogic.com/excel" at "/lib/excel-lib.xqy";

declare namespace gw = "http://marklogic.com/kpmg/gwpc";

declare variable $lib:default-permissions := (
  xdmp:permission("kpmg-gwpc-role", "read"),
  xdmp:permission("kpmg-gwpc-role", "update")
);

declare function lib:related($id)
{
  cts:search(/*,
    cts:element-range-query(xs:QName("WellIdentifier"), "=", $id,
      "collation=http://marklogic.com/collation/codepoint"),
    "unfiltered")
};

(: todo: exclude elements by qname :)
declare function lib:transform($x as node())
{
  typeswitch($x)
  case element() return
    element { fn:QName("http://marklogic.com/kpmg/gwpc", fn:local-name($x)) } {
    $x/@*,
    if ($x/*)
    then
      ($x/node() except $x/WellIdentifier) ! lib:transform(.)
    else
      fn:normalize-space($x/fn:string())
    }
  default return $x
};

declare function lib:extract($x)
{
  if ($x/Latitude ne "" and $x/Longitude ne "")
  then (
    element gw:lat { $x/Latitude/fn:string() },
    element gw:long { $x/Longitude/fn:string() }
  )
  else (),
  if ($x/TotalVerticalDepth ne "")
  then element gw:depth { $x/TotalVerticalDepth/fn:string() }
  else ()
};

declare function lib:combine($id)
{
  let $related := lib:related($id)
  let $well := $related/self::well
  (: throw error if no well :)
  return
    element gw:combined {
      element gw:WellIdentifier { $id },
      element gw:extracted { lib:extract($well) },
      lib:transform($well),
      element gw:dispositions { $related/self::disposition ! lib:transform(.) },
      element gw:injections { $related/self::injection ! lib:transform(.) },
      element gw:perforations { $related/self::perforation ! lib:transform(.) },
      element gw:productions { $related/self::production ! lib:transform(.) },
      element gw:stimulation-fluids { $related/self::stimulation-fluid ! lib:transform(.) },
      element gw:stimulation-proppants { $related/self::stimulation-proppant ! lib:transform(.) },
      (: todo: treatment :)
      element gw:disposition-units { $related/self::well-disposition-unit ! lib:transform(.) },
      element gw:formations { $related/self::well-formation ! lib:transform(.) },
      element gw:injection-units { $related/self::well-injection-unit ! lib:transform(.) },
      element gw:producing-units { $related/self::well-producing-unit ! lib:transform(.) },
      element gw:tests { $related/self::well-test ! lib:transform(.) }
    }
};

declare function lib:process($id)
{
  let $new-uri := "/combined-wells/combined-well-" || $id || ".xml"
  return xdmp:document-insert($new-uri, lib:combine($id), $lib:default-permissions, "combined-wells")
};

declare function lib:task-fn($size, $total, $fn)
{
  let $batchCount := $total idiv $size + 1
  for $count at $i in (1 to $batchCount)
  (: 6674 :)
  let $offset := ($count - 1) * $size
  let $from := $offset + 1
  let $to := $offset + $size
  return
    xdmp:spawn-function(function() {
        xdmp:log("batch " || $i || " of " || $batchCount || "; offset = " || $offset),
        $fn($from, $to)
      },
      <options xmlns="xdmp:eval">
        <transaction-mode>update-auto-commit</transaction-mode>
      </options>)
};

declare function lib:transform-all()
{
  let $size := 100
  let $total := xdmp:estimate(fn:collection("wells"))
  let $fn := function($from, $to) {
    for $id in cts:values(cts:element-reference(xs:QName("WellIdentifier")), (), (), cts:collection-query("wells"))[ $from to $to ]
    return lib:process($id)
  }
  return lib:task-fn($size, $total, $fn)
};

(: TODO: merge into lib:extract() :)
declare function lib:material($id)
{
  let $well :=
    cts:search(/gw:combined,
      cts:and-query((
        cts:element-range-query(xs:QName("gw:WellIdentifier"), "=", $id, "collation=http://marklogic.com/collation/codepoint"),
        cts:element-query(xs:QName("gw:production"), cts:and-query(()))
      )),
      "unfiltered")
  let $productions := $well/gw:productions/gw:production
  return
    if ($productions)
    then
      let $materials := fn:distinct-values($productions/(gw:Oil|gw:Gas|gw:Water|gw:CO2|gw:Sulfur)[. ne ""]/fn:local-name(.))
      return
        xdmp:node-insert-child($well/gw:extracted,
          element gw:production-materials {
            $materials ! element gw:production-material {.}
          })
    else ()
};

declare function lib:process-materials()
{
  let $size := 500
  let $total := xdmp:estimate(fn:collection("combined-wells"))
  let $fn := function($from, $to) {
    for $id in cts:values(cts:element-reference(xs:QName("gw:WellIdentifier")), (), (), cts:collection-query("combined-wells"))[ $from to $to ]
    return lib:material($id)
  }
  return lib:task-fn($size, $total, $fn)
};

declare function lib:load-excel($doc as binary())
{
  let $wb := excel:load($doc)
  let $sheetname := fn:exactly-one(excel:get-sheet-names($wb))
  let $sheet := excel:get-sheet-by-name($sheetname)
  let $colnames := excel:get-sheet-column-names($sheet, 1)

  for $row in excel:get-sheet-rows($sheet, 2)
  let $row-xml := element well {
    excel:row-to-xml($row,$colnames,("pascal"))
  }
  return $row-xml
};

declare function lib:merge-excel($doc as binary())
{
  for $well in lib:load-excel($doc)
  let $combined :=
    cts:search(/gw:combined,
      cts:and-query((
        cts:collection-query(("combined-wells", "updated-wells")),
        cts:element-range-query(xs:QName("gw:WellIdentifier"), "=",
          $well/WellIdentifier,
          "collation=http://marklogic.com/collation/codepoint"))),
      "unfiltered")
  return
    if (fn:not($combined))
    then fn:error((), "UNKNOWN-INPUT", "unknown excel input doc")
    else (
      lib:backup-merged($combined),
      xdmp:document-insert(
        $combined/fn:base-uri(),
        element { fn:node-name($combined) } {
          $combined/@*,
          $combined/(gw:WellIdentifier|gw:extracted),
          lib:transform($well),
          $combined/* except $combined/(gw:WellIdentifier|gw:extracted|gw:well)
        },
        $lib:default-permissions,
        ("combined-wells", "updated-wells"))
    )
};

declare function lib:backup-merged($combined as element(gw:combined))
{
  let $uri := "/backups" || $combined/fn:base-uri()
  return
    if (fn:doc-available($uri)) then ()
    else
      xdmp:document-insert($uri, $combined, $lib:default-permissions, ("backup-wells"))
};

declare function lib:revert-merge()
{
  for $doc in fn:collection("backup-wells")
  let $uri := $doc/fn:base-uri()
  let $orig-uri := fn:replace($uri, "^/backups", "")
  return (
    xdmp:document-insert($orig-uri, $doc, $lib:default-permissions, "combined-wells"),
    xdmp:document-delete($uri)
  )
};
