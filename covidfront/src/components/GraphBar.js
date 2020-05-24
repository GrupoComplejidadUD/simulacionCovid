import React from 'react';
import HighchartsReact from 'highcharts-react-official'

const GraphBar = ({options, highcharts}) => {
    return(
        <HighchartsReact
            highcharts={highcharts}
            options={options}
          />
    );
}

export default GraphBar;