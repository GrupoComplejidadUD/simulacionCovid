import React from 'react'
import { Icon, Image, Statistic } from 'semantic-ui-react'

const StatisticContagio = ({ variables }) => {
    return (
        <Statistic.Group widths='four'>
            <Statistic>
                <Statistic.Value>
                    <Icon name='briefcase' />{variables.trabajo}
                </Statistic.Value>
                <Statistic.Label>Contagios trabajo</Statistic.Label>
            </Statistic>
            <Statistic>
                <Statistic.Value>
                    <Icon name='home' />{variables.casa}
                </Statistic.Value>
                <Statistic.Label>Contagios casa</Statistic.Label>
            </Statistic>

            <Statistic>
                <Statistic.Value>
                    <Icon name='bus' />{variables.transporte}
                </Statistic.Value>
                <Statistic.Label>Contagios transporte</Statistic.Label>
            </Statistic>

            <Statistic>
                <Statistic.Value>
                    <Icon name='question circle outline' />{variables["sin definir"]}
                </Statistic.Value>
                <Statistic.Label>Contagios sin definir</Statistic.Label>
            </Statistic>
        </Statistic.Group>
    );
}

export default StatisticContagio
