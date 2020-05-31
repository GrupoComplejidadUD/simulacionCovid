import React from 'react'
import { Statistic } from 'semantic-ui-react'

const items = [
    { key: 'faves', label: 'Dias', value: '22'},
    { key: 'views', label: 'Poblacion', value: '300' }
  ]
  
  const StatisticHead = () => <Statistic.Group items={items} />
  
  export default StatisticHead