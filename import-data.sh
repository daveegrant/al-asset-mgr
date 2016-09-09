#!/usr/bin/env bash

XLXS_PROD_PARMS="import \
-input_file_type \
documents \
-document_type \
binary \
-output_permissions \
al-asset-mgr-role,read,al-asset-mgr-role,update \
-output_uri_replace \
\".*\/content/,'/data/'\" \
-transform_module \
\"/lib/ingest-product-xlsx.xqy\" \
-transform_namespace \
\"http://marklogic.com/rest-api/transform/ingest-product-xlsx\" "


XLXS_ELEM_PARMS="import \
-input_file_type \
documents \
-document_type \
binary \
-output_permissions \
al-asset-mgr-role,read,al-asset-mgr-role,update \
-output_uri_replace \
\".*\/content/,'/data/'\" \
-transform_module \
\"/lib/ingest-element-xlsx.xqy\" \
-transform_namespace \
\"http://marklogic.com/rest-api/transform/ingest-element-xlsx\" "


for entry in "content/products"/*
do
  echo "Importing $entry"
  ./ml local mlcp $XLXS_PROD_PARMS -input_file_path $entry -transform_param "uri-prefix=/$entry."
done


for entry in "content/elements"/*
do
  echo "Importing $entry"
  ./ml local mlcp $XLXS_ELEM_PARMS -input_file_path $entry -transform_param "uri-prefix=/$entry."
done
