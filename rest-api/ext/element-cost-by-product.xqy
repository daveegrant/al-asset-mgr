xquery version "1.0-ml";

module namespace ext = "http://marklogic.com/rest-api/resource/element-cost-by-product";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace roxy = "http://marklogic.com/roxy";

(:
 : To add parameters to the functions, specify them in the params annotations.
 : Example
 :   declare %roxy:params("uri=xs:string", "priority=xs:int") ext:get(...)
 : This means that the get function will take two parameters, a string and an int.
 :)

(:
 :)
declare
%roxy:params("bookCode=xs:string,costType=xs:string")
function ext:get(
  $context as map:map,
  $params  as map:map
) as document-node()*
{
  ext:post($context, $params, ())
};

(:
 :)
declare
%roxy:params("bookCode=xs:string,costType=xs:string")
function ext:post(
  $context as map:map,
  $params  as map:map,
  $input   as document-node()*
) as document-node()*
{
  let $output-types := map:put($context, "output-types", "application/json")
  let $book-code := map:get($params, "bookCode")
  let $cost-type := map:get($params, "costType")
  let $response := json:object()
  let $results := json:array()
  let $element-queries := (
    cts:element-range-query(xs:QName("commonBookCode"), "=", $book-code),
    cts:element-range-query(xs:QName("Cost_calc"), "!=", ""),
    cts:element-range-query(xs:QName("Cost_calc"), "!=", "0"),
    if ($cost-type) then
      cts:element-range-query(xs:QName("costType"), "=", $cost-type)
    else
      ()
  )

  let $elements := cts:search(
    fn:collection("xlsx-element")/envelope,
    cts:and-query($element-queries),
    cts:index-order(cts:element-reference(xs:QName("Source")))
  )

  let $_ :=
    for $element in $elements
    return
      let $el := json:object()
      let $_ := map:put($el, "uri", xdmp:node-uri($element))
      let $_ := map:put($el, "cost", $element/source/element/Cost_calc/data())
      let $_ := map:put($el, "costType", $element/costType/data())
      let $_ := map:put($el, "imageCalc", $element/source/element/Image_Name_calc_long/data())
      let $_ := map:put($el, "source", $element/source/element/Source/data())
      let $_ := map:put($el, "sourceTrackingNumber", $element/source/element/Source_Tracking_Number/data())
      return json:array-push($results, $el)

  let $cost-sum :=
    fn:sum(
      for $element in $elements
      return fn:number($element/source/element/Cost_calc/data())
    )

  let $_ := map:put($response, "bookCode", $book-code)
  let $_ :=
    if ($cost-type) then
      map:put($response, "costType", $cost-type)
    else
      ()
  let $_ := map:put($response, "sum", $cost-sum)
  let $_ := map:put($response, "results", $results)
  return (xdmp:set-response-code(200, "OK"), document { xdmp:to-json($response) })
};
