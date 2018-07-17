<html>
  <head>
    <meta charset="utf-8"/>
    <title>TITLE, js: Amynka, data: mgorny, updated: DATE</title>
  </head>
  <body>
    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
      google.charts.load('current', {'packages':['timeline']});
      google.charts.setOnLoadCallback(drawChart);
      function drawChart() {
        var container = document.getElementById('timeline');
        var chart = new google.visualization.Timeline(container);
        var dataTable = new google.visualization.DataTable();

        dataTable.addColumn({ type: 'string', id: 'Developer' });
        dataTable.addColumn({ type: 'string', id: 'Commit count' });
        dataTable.addColumn({ type: 'date', id: 'Start' });
        dataTable.addColumn({ type: 'date', id: 'End' });
        dataTable.addRows([
#include DATAFILE
        ]);

        var options = {
          colors: [ '53777A', '#542437', '#C02942', '#D95B43', '#ECD078'],
          timeline: { showBarLabels: false }
        };
        chart.draw(dataTable,options);
      }
    </script>
    <div id="timeline" style="height:100%"></div>
  </body>
</html>

