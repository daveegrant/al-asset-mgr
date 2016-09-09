xquery version "1.0-ml";
module namespace trans = "http://marklogic.com/rest-api/transform/ingest-product-xlsx";

import module namespace cs-lib = "http://marklogic.com/CS/lib" at "/lib/cs-lib.xqy";


declare function trans:transform(
 $content as map:map,
 $context as map:map
) as map:map*
{
  let $params := map:get($context, "transform_param")
  let $permissions := (
    xdmp:permission("al-asset-mgr-role", "read"),
    xdmp:permission("al-asset-mgr-role", "update")
  )
  let $collections := ("data", "xlsx-product")
  let $the-doc := map:get($content, "value")

  let $_ := xdmp:log(xdmp:binary-size($the-doc))
  let $_ := xdmp:log("Params " || $params)

  let $res := cs-lib:process-excel-data(trans:get-uri-prefix($params), $the-doc, 0, $permissions, $collections, fn:true())
  (:let $_ := xdmp:log($res):)

  (:let $book-code := $the-doc/product/BookCode/data()
  let $mod-doc :=
    element envelope {
      if ($book-code) then
        element commonBookCode { $book-code }
      else
        (),
      element source { map:get($content, "value") },
      element metadata {}
    }
  let $_ := map:put($content, "value", document { $mod-doc }):)

  return (
    $content
  )
};

declare function trans:get-uri-prefix(
  $param as xs:string
) as item()*
{
  let $prefix :=
    if (fn:contains($param, "uri-prefix=")) then
      let $params := fn:tokenize($param, ";")
      return
        for $p in $params
        return
          if (fn:starts-with($p, "uri-prefix=")) then
            fn:substring($p, fn:string-length("uri-prefix=") + 1)
          else
            ()
    else
      ()

  return $prefix
};

declare function trans:get-collections(
  $param as xs:string
) as item()*
{
  let $collections :=
    if (fn:contains($param, "collections=")) then
      let $params := fn:tokenize($param, ";")
      let $coll-data :=
        for $p in $params
        return
          if (fn:starts-with($p, "collections=")) then
            fn:substring($p, fn:string-length("collections=") + 1)
          else
            ()
      return fn:tokenize($coll-data, ",")
    else
      ()

  return $collections
};
