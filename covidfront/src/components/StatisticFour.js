import React from 'react'
import { Icon, Image, Statistic } from 'semantic-ui-react'

const StatisticFour = ({variables}) => {
    return(
        <Statistic.Group widths='five'>
        <Statistic>
            <Statistic.Value>{variables.promMuertes.muertos.toFixed(2)}</Statistic.Value>
            <Statistic.Label>Promedio muertes</Statistic.Label>
        </Statistic>

        <Statistic>
            <Statistic.Value>
                <Icon name='bus' />{variables.promViajeIda}
                  </Statistic.Value>
            <Statistic.Label>Promedio Viaje Ida</Statistic.Label>
        </Statistic>

        <Statistic>
            <Statistic.Value>
                <Icon name='bus' />{variables.promViajeVuelta}
                  </Statistic.Value>
            <Statistic.Label>Promedio Viaje Vuelta</Statistic.Label>
        </Statistic>

        <Statistic>
            <Statistic.Value>
                <Image src='https://react.semantic-ui.com/images/avatar/small/joe.jpg' className='circular inline' />
                  {variables.totalMuertos}
                  </Statistic.Value>
            <Statistic.Label>Muertos</Statistic.Label>
        </Statistic>
        <Statistic>
            <Statistic.Value>
                <Image src='https://react.semantic-ui.com/images/avatar/small/matt.jpg' className='circular inline' />
                  {variables.totalContagiados}
                  </Statistic.Value>
            <Statistic.Label>Contagiados</Statistic.Label>
        </Statistic>
    </Statistic.Group>
    );
}

export default StatisticFour
