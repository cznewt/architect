var QuantitativePlot = function(QuantitativePlot){
    /**
     * Stacked area chart rendering method
     * @param dataUrl - Data endpoint URL
     * @param graphSelector - Graph parent <div> CSS selector
     * @param refreshInterval - Refresh interval in seconds (null for disabled)
     */
    QuantitativePlot.areaStackedChart = function(dataUrl, graphSelector, refreshInterval) {

        var graph = this;
        this._data = {};
        this._data_group = [];

        this.init = function(alreadyRunning) {

            if(alreadyRunning && graph.svg) {
                graph.chart.remove()
            }

            if(!alreadyRunning){
                graph.requestData(dataUrl, graph.render);

                $(window).on('resize', function(ev){
                    graph.init(true);
                    graph.render();
                });

                if(refreshInterval){
                    setInterval(function(){
                        graph.requestData(dataUrl, function(){
                            graph.init(true);
                            graph.render();
                        });
                    }, refreshInterval * 1000);
                }
            }
        };

        this.render = function() {
            graph.chart = bb.generate({
              data: {
                x: "x",
                xFormat: '%Y-%m-%d %H:%M:%S',
                columns: graph._data,
                type: "area-spline",
                groups: [
                  graph._data_group
                ]
              },
              point: {
                show: false
              },
              axis: {
                x: {
                  type: "timeseries",
                  tick: {
                    format: '%Y-%m-%d %H:%M'
                  }
                }
              },
              bindto: graphSelector
            });

        };

        this.requestData = function(dataUrl, callback){
            d3.json(dataUrl, function(res){
                graph._data = res.data;
                graph._data_group = [];
                for (var i = 0; i < graph._data.length; i++) {
                    if (graph._data[i][0] !== 'x') {
                        graph._data_group.push(graph._data[i][0]);
                    }
                }
                if(typeof callback === 'function'){
                    callback();
                }
            });
        };
    };
    return QuantitativePlot;
}(QuantitativePlot || {});
