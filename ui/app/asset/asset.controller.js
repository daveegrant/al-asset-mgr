/* global X2JS,vkbeautify */
(function () {
  'use strict';
  angular.module('app.asset')
  .controller('AssetCtrl', AssetCtrl);

  AssetCtrl.$inject = ['doc', '$stateParams', 'MLRest', '$filter'];
  function AssetCtrl(doc, $stateParams, mlRest, $filter) {
    var ctrl = this;
    var source = $stateParams.source;
    var id = $stateParams.id;
    var bookCode = $stateParams.bookCode;
    var costType = $stateParams.costType;
    var totalCost = 0;

    Highcharts.setOptions({
      lang: {
        thousandsSep: ','
      }
    });

    var pieChartConfig = {
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
        text: 'Cost by Bookcode'
      },

      loading: false
    };

    var barChartConfig = {
      options: {
        chart: {
          type: 'bar'
        },
        xAxis: {
          categories: [],
          title: {
            text: '<b>Bookcode</b>',
            style: {
              fontSize: '18px'
            }
          }
        },
        yAxis: {
          // min: 1,
          // type: 'logarithmic',
          title: {
            text: '<b>Cost</b>',
            style: {
              fontSize: '18px'
            }
          },
          labels: {
            overflow: 'justify'
          }
        },
        tooltip: {
          pointFormat: 'Count: <b>{point.count}</b><br/>{series.name}: <b>${point.y:,.2f}</b>'
        },
        plotOptions: {
          bar: {
            dataLabels: {
              enabled: true,
              format: '${point.y:,.2f}'
            }
          }
        },
        legend: {
          layout: 'vertical',
          align: 'right',
          verticalAlign: 'top',
          x: -40,
          y: 40,
          floating: true,
          borderWidth: 1,
          backgroundColor: ((Highcharts.theme && Highcharts.theme.legendBackgroundColor) || '#FFFFFF'),
          shadow: true
        },
        credits: {
          enabled: false
        }
      },
      series: [{
        name: 'Cost ($)',
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
        text: 'Cost by Bookcode'
      }
    };

    var bar2ChartConfig = {
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
            text: 'Bookcode',
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
          pointFormat: 'Count: <b>{point.count}</b><br/>{series.name}: <b>${point.y:,.2f}</b>'
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
        name: 'Bookcode',
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
        text: 'Cost by Bookcode'
      }
    };

    var costTypePieChartConfig = {
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
        text: 'Cost by Elements by Type'
      },

      loading: false
    };

    angular.extend(ctrl, {
      doc : doc.data,
      source: source,
      id: id,
      bookCode: bookCode,
      costType: costType,
      totalCost: totalCost,
      pieChartConfig: pieChartConfig,
      barChartConfig: barChartConfig,
      bar2ChartConfig: bar2ChartConfig,
      costTypePieChartConfig: costTypePieChartConfig
    });

    ctrl.updateChartData = function(data) {
      var chartData = [];
      var costTypeChartData = [];
      var bookNameList = [];
      var bookCostList = [];
      var costTypeMap = {};
      for (var i=0; i < data.matchingProducts.length; i++) {
        var url = 'asset?source=' + $filter('escape')(source)
          + '&id=' + $filter('escape')(id)
          + '&bookCode=' + $filter('escape')(data.matchingProducts[i].bookCode);

        if (costType) {
          url += '&costType=' + $filter('escape')(costType);
        }

        chartData.push({
          name: data.matchingProducts[i].bookCode,
          y: data.matchingProducts[i].cost,
          count: data.matchingProducts[i].count,
          url: url
        });

        bookNameList.push(data.matchingProducts[i].bookCode);
        bookCostList.push({
          y: data.matchingProducts[i].cost,
          count: data.matchingProducts[i].count,
          url: url
        });

        ctrl.totalCost += data.matchingProducts[i].cost;
      }

      for (var i=0; i < data.matchingElements.length; i++) {
        if (costTypeMap[data.matchingElements[i].costType]) {
          costTypeMap[data.matchingElements[i].costType].cost += Number(data.matchingElements[i].cost);
          costTypeMap[data.matchingElements[i].costType].count++;
        }
        else {
          costTypeMap[data.matchingElements[i].costType] = {
            cost: Number(data.matchingElements[i].cost),
            count: 1
          }
        }
      }

      for (var property in costTypeMap) {
        if (costTypeMap.hasOwnProperty(property)) {
          var url = 'asset?source=' + $filter('escape')(source)
            + '&id=' + $filter('escape')(id)
            + '&costType=' + $filter('escape')(property);


          if (bookCode) {
            url += '&bookCode=' + $filter('escape')(bookCode);
          }

          costTypeChartData.push({
            name: property,
            y: costTypeMap[property].cost,
            count: costTypeMap[property].count,
            url: url
          });
        }
      }

      ctrl.barChartConfig.options.xAxis.categories = bookNameList;
      ctrl.barChartConfig.series[0].data = bookCostList;
      ctrl.bar2ChartConfig.series[0].data = chartData;
      ctrl.pieChartConfig.series[0].data = chartData;
      ctrl.costTypePieChartConfig.series[0].data = costTypeChartData;

    };

    ctrl.updateChartData(ctrl.doc);
  }
}());
