xquery version "1.0-ml";
module namespace trans = "http://marklogic.com/rest-api/transform/ingest-product";


declare function trans:transform(
 $content as map:map,
 $context as map:map
) as map:map*
{
  let $uri := map:get($context, "uri")
  let $the-doc := map:get($content, "value")
  let $book-code := $the-doc/product/BookCode/data()
  let $mod-doc :=
    element envelope {
      if ($book-code) then
        element commonBookCode { $book-code }
      else
        (),
      element source { map:get($content, "value") },
      element metadata {}
    }
  let $_ := map:put($content, "value", document { $mod-doc })

  return (
    $content
  )
};
