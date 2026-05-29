import { evaluate } from './src/connection.js';

(async () => {
  try {
    // Try to access the study's internal properties
    const r = await evaluate(`
      (function() {
        var chart = window.TradingViewApi._activeChartWidgetWV.value()._chartWidget;
        var model = chart.model();
        var sources = model.model().dataSources();
        var smcSource = null;
        for (var si = 0; si < sources.length; si++) {
          var s = sources[si];
          if (!s.metaInfo) continue;
          var meta = s.metaInfo();
          var name = meta.description || meta.shortDescription || '';
          if (name.indexOf('Smart Money Concepts') >= 0) {
            smcSource = s;
            break;
          }
        }
        if (!smcSource) return { error: 'SMC not found' };

        // Try different ways to access the study data
        var result = { id: smcSource.id() };
        
        // Check if it has a _dataSource
        try {
          var ds = smcSource._dataSource;
          result.hasDataSource = !!ds;
          if (ds) {
            result.dsKeys = Object.keys(ds).filter(function(k) { return k.indexOf('_') !== 0; }).slice(0, 20);
          }
        } catch(e) { result.dsError = e.message; }

        // Check common properties
        try {
          var keys = Object.keys(smcSource).filter(function(k) { return k.indexOf('_') !== 0; }).slice(0, 30);
          result.publicKeys = keys;
        } catch(e) { result.keysError = e.message; }

        // Try to access study result / output
        try {
          // Try series
          if (smcSource._series) {
            var seriesKeys = [];
            smcSource._series.forEach(function(v, k) { seriesKeys.push(k); });
            result.seriesKeys = seriesKeys;
          }
        } catch(e) { result.seriesError = e.message; }

        // Try mainSeries
        try {
          var ms = smcSource.mainSeries();
          result.hasMainSeries = !!ms;
        } catch(e) {}

        // Try getting last value
        try {
          // A common method is series()
          var seriesData = smcSource.series ? smcSource.series() : null;
          result.hasSeries = !!seriesData;
          if (seriesData) {
            result.seriesSize = seriesData.size();
          }
        } catch(e) { result.seriesError2 = e.message; }

        return result;
      })()
    `);
    console.log('SMC properties:', JSON.stringify(r, null, 2));
  } catch (err) {
    console.error('Error:', err.message);
  }
  process.exit(0);
})();
