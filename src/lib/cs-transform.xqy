xquery version "1.0-ml";

module namespace cs-ext = "http://marklogic.com/CS";
declare namespace html = "http://www.w3.org/1999/xhtml";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cs-lib = "http://marklogic.com/CS/lib" at "/lib/cs-lib.xqy";


declare function cs-ext:transform(
 $content as map:map,
 $context as map:map
) as map:map*
{
  let $skip-row :=
 xs:integer((map:get($context, "transform_param"), 0)[1])
  let $logger := xdmp:log(map:get($content, "uri"))
  let $doc-type := functx:substring-after-last(map:get($content, "uri"), '.')
    let $metadata := <cs>test</cs>
  return
    (  switch ($doc-type) 
      case "pdf" return  cs-lib:process-binary(map:get($content, "uri"))
      case "docx" return  cs-lib:process-binary(map:get($content, "uri"))
      case "docx" return  cs-lib:process-binary(map:get($content, "uri"))
      case "xlsx" return   cs-lib:process-excel(map:get($content, "uri"),$skip-row)
      default return () )
};

