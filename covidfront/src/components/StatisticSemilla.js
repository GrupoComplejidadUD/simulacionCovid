import React from 'react'
import { Segment, Statistic, Header, Icon } from 'semantic-ui-react'

const StatisticSemilla = ({ valoresSemilla }) => (

    <Segment>
        <Header as='h2' icon textAlign='center'>
            <Header.Content>Valores Iniciales - Semilla</Header.Content>
        </Header>
        <Statistic.Group widths='five'>
            <Statistic >
                <Statistic.Value>{valoresSemilla.poblacionInicial}</Statistic.Value>
                <Statistic.Label>Poblacion</Statistic.Label>
            </Statistic>
            <Statistic color='red' >
                <Statistic.Value>{valoresSemilla["%confinamiento"]}</Statistic.Value>
                <Statistic.Label>% confinamiento</Statistic.Label>
            </Statistic>
            <Statistic color='orange' >
                <Statistic.Value>{valoresSemilla.duracionVirus}</Statistic.Value>
                <Statistic.Label>duracion virus dias</Statistic.Label>
            </Statistic>
            <Statistic color='yellow' >
                <Statistic.Value>{valoresSemilla.camasUCI}</Statistic.Value>
                <Statistic.Label>Camas UCI</Statistic.Label>
            </Statistic>
            <Statistic color='olive' >
                <Statistic.Value>{valoresSemilla.infeccioso}</Statistic.Value>
                <Statistic.Label>% infeccioso</Statistic.Label>
            </Statistic>
        </Statistic.Group>
        <Statistic.Group widths='five'>
            <Statistic color='green' >
                <Statistic.Value>{valoresSemilla.numeroInfectados}</Statistic.Value>
                <Statistic.Label>infectados iniciales</Statistic.Label>
            </Statistic>
            <Statistic color='teal' >
                <Statistic.Value>{valoresSemilla.tiempoLatencia}</Statistic.Value>
                <Statistic.Label>tiempo Latencia dias</Statistic.Label>
            </Statistic>
            <Statistic color='blue' >
                <Statistic.Value>{valoresSemilla["%vehiculoPropio"]}</Statistic.Value>
                <Statistic.Label>% vehiculo Propio</Statistic.Label>
            </Statistic>
            <Statistic color='violet' >
                <Statistic.Value>{valoresSemilla["%infectadosAsintomaticos"]}</Statistic.Value>
                <Statistic.Label>% asintomaticos</Statistic.Label>
            </Statistic>
        </Statistic.Group>
    </Segment>

)

export default StatisticSemilla