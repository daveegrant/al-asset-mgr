/* global X2JS,vkbeautify */
(function () {
  'use strict';
  angular.module('app.detail')
  .controller('DetailCtrl', DetailCtrl);

  DetailCtrl.$inject = ['doc', '$stateParams', 'MLRest', '$filter'];
  function DetailCtrl(doc, $stateParams, mlRest, $filter) {
    var ctrl = this;

    var uri = $stateParams.uri;
    var costType = $stateParams.costType;
    var contentType = doc.headers('content-type');
    Highcharts.setOptions({
      lang: {
        thousandsSep: ','
      }
    });

    var elementData = null;
    var productData = null;
    var elementChartConfig = {
      options: {
        chart: {
          plotBackgroundColor: null,
          plotBorderWidth: null,
          plotShadow: false,
          type: 'pie'
        },
        tooltip: {
          pointFormat: 'Count: <b>{point.count}</b><br/>{series.name}: <b>${point.y:,.2f}</b>'
        },
        plotOptions: {
            pie: {
                allowPointSelect: true,
                cursor: 'pointer',
                dataLabels: {
                    enabled: true,
                    format: '<b>{point.name}</b>: {point.percentage:.1f} %',
                    style: {
                        color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
                    }
                }
            }
        },
        yAxis: {
          title: {
            text: 'Cost ($)'
          }
        },
        xAxis: {
            type: 'category',
            labels: {
                rotation: -45,
                style: {
                    fontSize: '13px',
                    fontFamily: 'Verdana, sans-serif'
                }
            }
        }
      },
      series: [{
        name: 'Cost',
        data: [],
        point: {
          events: {
            click: function(e) {
              location.href = e.point.url;
              e.preventDefault();
            }
          }
        }
      }],
      title: {
        text: 'Cost of Elements by Source'
      },

      loading: false
    };

    var elementCostTypeChartConfig = {
      options: {
        chart: {
          plotBackgroundColor: null,
          plotBorderWidth: null,
          plotShadow: false,
          type: 'pie'
        },
        tooltip: {
          pointFormat: 'Count: <b>{point.count}</b><br/>{series.name}: <b>${point.y:,.2f}</b>'
        },
        plotOptions: {
            pie: {
                allowPointSelect: true,
                cursor: 'pointer',
                dataLabels: {
                    enabled: true,
                    format: '<b>{point.name}</b>: {point.percentage:.1f} %',
                    style: {
                        color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
                    }
                }
            }
        },
        yAxis: {
          title: {
            text: 'Cost ($)'
          }
        },
        xAxis: {
            type: 'Type',
            labels: {
                rotation: -45,
                style: {
                    fontSize: '13px',
                    fontFamily: 'Verdana, sans-serif'
                }
            }
        }
      },
      series: [{
        name: 'Cost',
        data: [],
        point: {
          events: {
            click: function(e) {
              location.href = e.point.url;
              e.preventDefault();
            }
          }
        }
      }],
      title: {
        text: 'Cost of Elements by Type'
      },

      loading: false
    };

    var productChartConfig = {
      options: {
        chart: {
          plotBackgroundColor: null,
          plotBorderWidth: null,
          plotShadow: false,
          type: 'pie'
        },
        tooltip: {
          pointFormat: '{series.name}: <b>{point.y:,.0f}</b><br/>Cost: <b>${point.data:,.2f}</b>'
        },
        plotOptions: {
            pie: {
                allowPointSelect: true,
                cursor: 'pointer',
                dataLabels: {
                    enabled: true,
                    format: '<b>{point.name}</b>: {point.y}',
                    style: {
                        color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
                    }
                }
            }
        },
        yAxis: {
          title: {
            text: 'Cost ($)'
          }
        },
        xAxis: {
            type: 'category',
            labels: {
                rotation: -45,
                style: {
                    fontSize: '13px',
                    fontFamily: 'Verdana, sans-serif'
                }
            }
        }
      },
      series: [{
        name: 'Sources',
        data: []
      }],
      title: {
        text: 'Element Count by Bookcode'
      },

      loading: false
    };

    var elementCostBarChartConfig = {
      options: {
        lang: {
          thousandsSep: ','
        },
        chart: {
          type: 'column'
        },
        xAxis: {
          type: 'category',
          labels: {
            rotation: -45
          },
          title: {
            text: 'Source',
            style: {
              fontSize: '18px'
            }
          }
        },
        yAxis: {
          min: 0,
          // type: 'logarithmic',
          title: {
            text: 'Cost',
            style: {
              fontSize: '18px'
            }
          }
        },
        tooltip: {
          pointFormat: 'Count: <b>{point.count}</b><br/>Cost: <b>${point.y:,.2f} </b>'
        },
        plotOptions: {
          bar: {
            dataLabels: {
              enabled: true
            }
          }
        },
        legend: {
          enabled: false
        }
      },
      series: [{
        name: 'Source',
        data: [],
        dataLabels: {
          enabled: true,
          rotation: -90,
          color: '#FFFFFF',
          align: 'right',
          format: '${point.y:,.2f}',
          y: 10, // 10 pixels down from the top
          style: {
            fontSize: '13px',
            fontFamily: 'Verdana, sans-serif'
          }
        },
        point: {
          events: {
            click: function(e) {
              location.href = e.point.url;
              e.preventDefault();
            }
          }
        }
      }],
      title: {
        text: 'Cost by Source'
      }
    };


    var x2js = new X2JS();
    /* jscs: disable */
    if (contentType.lastIndexOf('application/json', 0) === 0) {
      /*jshint camelcase: false */
      ctrl.xml = vkbeautify.xml(x2js.json2xml_str(doc.data));
      ctrl.json = doc.data;
      ctrl.type = 'json';
    } else if (contentType.lastIndexOf('application/xml', 0) === 0) {
      ctrl.xml = vkbeautify.xml(doc.data);
      /*jshint camelcase: false */
      ctrl.json = x2js.xml_str2json(doc.data);
      ctrl.type = 'xml';
      /* jscs: enable */
    } else if (contentType.lastIndexOf('text/plain', 0) === 0) {
      ctrl.xml = doc.data;
      ctrl.json = {'Document' : doc.data};
      ctrl.type = 'text';
    } else if (contentType.lastIndexOf('application', 0) === 0 ) {
      ctrl.xml = 'Binary object';
      ctrl.json = {'Document type' : 'Binary object'};
      ctrl.type = 'binary';
    } else {
      ctrl.xml = 'Error occured determining document type.';
      ctrl.json = {'Error' : 'Error occured determining document type.'};
    }

    angular.extend(ctrl, {
      doc : doc.data,
      uri : uri,
      costType: costType,
      elementData: elementData,
      productData: productData,
      elementChartConfig: elementChartConfig,
      productChartConfig: productChartConfig,
      elementCostBarChartConfig: elementCostBarChartConfig,
      elementCostTypeChartConfig: elementCostTypeChartConfig
    });

    if (ctrl.json.envelope.source.product) {
      var params = {
        'rs:bookCode': ctrl.json.envelope.commonBookCode
      };

      if (ctrl.costType) {
        params['rs:costType'] = ctrl.costType;
      }

      mlRest.extension('element-cost-by-product',
          {
            method: 'GET',
            params: params
          })
          .then(function(res) {
            ctrl.elementData = res.data;
            ctrl.updateElementChartData(ctrl.elementData);
          });
    }

    if (ctrl.json.envelope.source.element) {
      mlRest.extension('products-using-element',
          {
            method: 'GET',
            params:
              {
                'rs:source': ctrl.json.envelope.source.element.Source,
                'rs:sourceTrackingNumber': ctrl.json.envelope.source.element.Source_Tracking_Number
              }
          })
          .then(function(res) {
            ctrl.productData = res.data;
            ctrl.updateProductChartData(ctrl.productData);
          });
    }

    ctrl.updateElementChartData = function(data) {
      var chartData = [];
      var sourceMap = {};
      var costTypeMap = {};
      var costTypeChartData = [];
      for (var i=0; i < data.results.length; i++) {
        if (sourceMap[data.results[i].source]) {
          sourceMap[data.results[i].source].cost += Number(data.results[i].cost);
          sourceMap[data.results[i].source].count++;
        }
        else {
          sourceMap[data.results[i].source] = {
            cost: Number(data.results[i].cost),
            count: 1
          }
        }

        if (costTypeMap[data.results[i].costType]) {
          costTypeMap[data.results[i].costType].cost += Number(data.results[i].cost);
          costTypeMap[data.results[i].costType].count++;
        }
        else {
          costTypeMap[data.results[i].costType] = {
            cost: Number(data.results[i].cost),
            count: 1
          }
        }
      }

      for (var property in sourceMap) {
        if (sourceMap.hasOwnProperty(property)) {
          var url = 'source?id=' + $filter('escape')(property);

          chartData.push({
            name: property,
            y: sourceMap[property].cost,
            count: sourceMap[property].count,
            url: url
          });
        }
      }

      for (var property in costTypeMap) {
        if (costTypeMap.hasOwnProperty(property)) {
          var url = 'detail' + ctrl.uri
            + '?costType=' + $filter('escape')(property);

          costTypeChartData.push({
            name: property,
            y: costTypeMap[property].cost,
            count: costTypeMap[property].count,
            url: url
          });
        }
      }

      ctrl.elementChartConfig.series[0].data = chartData;
      ctrl.elementCostBarChartConfig.series[0].data = chartData;
      ctrl.elementCostTypeChartConfig.series[0].data = costTypeChartData;
    };

    ctrl.updateProductChartData = function(data) {
      var chartData = [];
      var bookMap = {};
      for (var i=0; i < data.matchingElements.length; i++) {
        if (bookMap[data.matchingElements[i].bookCode]) {
          bookMap[data.matchingElements[i].bookCode].cost += Number(data.matchingElements[i].cost);
          bookMap[data.matchingElements[i].bookCode].count++;
        }
        else {
          bookMap[data.matchingElements[i].bookCode] = {
            cost: Number(data.matchingElements[i].cost),
            count: 1
          }
        }
      }

      for (var property in bookMap) {
        if (bookMap.hasOwnProperty(property)) {
          chartData.push({
            name: property,
            y: bookMap[property].count,
            data: bookMap[property].cost
          });
        }
      }

      ctrl.productChartConfig.series = [{
        name: 'Count',
        data: chartData
      }];
    };
  }
}());
