xquery version "1.0-ml";

module namespace ext = "http://marklogic.com/rest-api/resource/elements-using-source";

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
%roxy:params("source=xs:string,bookCode=xs:string,costType=xs:string")
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
%roxy:params("source=xs:string,bookCode=xs:string,costType=xs:string")
function ext:post(
  $context as map:map,
  $params  as map:map,
  $input   as document-node()*
) as document-node()*
{
  let $output-types := map:put($context, "output-types", "application/json")
  let $source := map:get($params, "source")
  let $book-code := map:get($params, "bookCode")
  let $cost-type := map:get($params, "costType")
  let $response := json:object()
  let $elem-array := json:array()
  let $prod-array := json:array()
  let $element-queries := (
    cts:element-range-query(xs:QName("Source"), "=", $source),
    if ($book-code) then
      cts:element-range-query(xs:QName("commonBookCode"), "=", $book-code)
    else
      (),
    if ($cost-type) then
      cts:element-range-query(xs:QName("costType"), "=", $cost-type)
    else
      ()
  )

  let $elements := cts:search(
    fn:collection("xlsx-element")/envelope,
    cts:and-query($element-queries),
    cts:index-order(cts:element-reference(xs:QName("commonBookCode")))
  )

  let $_ :=
    for $element in $elements
    return
      let $el := json:object()
      let $_ := map:put($el, "uri", xdmp:node-uri($element))
      let $_ := map:put($el, "bookCode", $element/commonBookCode/data())
      let $_ := map:put($el, "cost", $element/source/element/Cost_calc/data())
      let $_ := map:put($el, "costType", $element/costType/data())
      let $_ := map:put($el, "imageCalc", $element/source/element/Image_Name_calc_long/data())
      let $_ := map:put($el, "source", $element/source/element/Source/data())
      let $_ := map:put($el, "sourceTrackingNumber", $element/source/element/Source_Tracking_Number/data())
      let $_ := map:put($el, "invoiceDate", $element/source/element/Invoice_Date/data())
      let $_ := map:put($el, "invoiceNumber", $element/source/element/Invoice_Number/data())
      let $_ := map:put($el, "processedDate", $element/source/element/Invoice_Processed_Date/data())
      return json:array-push($elem-array, $el)

  let $book-codes :=
    if ($book-code) then
      $book-code
    else
      fn:distinct-values(
        for $element in $elements
        return $element/commonBookCode/data()
      )

  let $_ :=
    for $product in cts:search(
      fn:collection("xlsx-product")/envelope,
      cts:element-range-query(xs:QName("commonBookCode"), "=", $book-codes),
      cts:index-order(cts:element-reference(xs:QName("commonBookCode")))
    )
    return
      let $pr := json:object()
      let $_ := map:put($pr, "uri", xdmp:node-uri($product))
      let $_ := map:put($pr, "bookCode", $product/commonBookCode/data())
      let $_ := map:put($pr, "title", $product/source/product/Title_big_calc/data())
      let $_ := map:put($pr, "productId", $product/source/product/Product_ID/data())
      let $_ := map:put($pr, "isbn", $product/source/product/ISBN_13/data())
      let $prod-book-code := $product/commonBookCode/data()
      let $cost-seq :=
        for $child-elem in $elements[commonBookCode=$prod-book-code]
        where $child-elem/source/element/Cost_calc/data() != "0" and $child-elem/source/element/Cost_calc/data() != ""
        return
          $child-elem/source/element/Cost_calc/data()

      let $_ := map:put($pr, "cost", fn:sum($cost-seq))
      let $_ := map:put($pr, "count", fn:count($elements[commonBookCode=$prod-book-code]))
      return json:array-push($prod-array, $pr)

  let $_ := map:put($response, "source", $source)
  let $_ :=
    if ($book-code) then
      map:put($response, "bookCode", $book-code)
    else
      ()
  let $_ :=
    if ($cost-type) then
      map:put($response, "costType", $cost-type)
    else
      ()
  let $_ := map:put($response, "matchingProducts", $prod-array)
  let $_ := map:put($response, "matchingElements", $elem-array)
  return (xdmp:set-response-code(200, "OK"), document { xdmp:to-json($response) })
};
